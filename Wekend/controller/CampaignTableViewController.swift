//
//  CampaignTableViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 11. 22..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit
import DropDownMenuKit
import SDWebImage
import AWSCore

class CampaignTableViewController: UIViewController {
    
    deinit {
        removeNotificationObservers()
        printLog("deinit")
    }
    
    // MARK: Properties
    
    var isLoading: Bool = false
    
    // MARK: custom Views
    
    let refreshControl = UIRefreshControl()
    
    var dropDownTitleView: DropDownTitleView!
    var dropDownMenu: DropDownMenu!
    var selectedMenuCell: FilterMenuCell?
    
    var sortMode: SortMode = .date
    
    // MARK: IBOutlet
    @IBOutlet weak var noResultLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: override Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTableView()
        initRefreshControl()
        
        navigationItem.rightBarButtonItem = getSearchBarItem()
        dropDownTitleView = getDropDownTitleView()
        navigationItem.titleView = dropDownTitleView
        
        dropDownMenu = getDropDownMenu()
        updateMenuContentOffsets()
        
        refreshList(true)
        addNotificationObservers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        printLog("viewWillAppear")
        
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.tintColor = .black
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dropDownMenu.container = self.view
    }
    
    // MARK: ScrollView Delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height) && self.isLoading != true {
//            printLog("scrollViewDidScroll > refreshList")
//            tableView.tableFooterView?.isHidden = false
//            refreshList(startFromBeginning: false)
        }
    }
}

extension CampaignTableViewController {
    
    func initTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 260
        
        noResultLabel.isHidden = true
    }
    
    func initRefreshControl() {
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
    }
    
    func refresh(_ sender: Any) {
        refreshList(true)
    }
    
    func refreshList(_ startFromBeginning: Bool) {
        
        isLoading = true

        if startFromBeginning {
            self.tabBarController?.startLoading()
        }
        
        ProductInfoManager.sharedInstance.loadData(startFromBeginning: startFromBeginning).continueWith(block: {
            (task: AWSTask) -> Any? in
            
            if let _ = task.result as? Array<ProductInfo> {
                
                self.isLoading = false
                
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.refreshControl.endRefreshing()
                    self.tabBarController?.endLoading()
                    
                    if let count = ProductInfoManager.sharedInstance.datas?.count {
                        if count == 0 {
                            self.noResultLabel.isHidden = false
                        } else {
                            self.noResultLabel.isHidden = true
                        }
                    }
                    
                    self.tableView.reloadData()
                    
                    if startFromBeginning {
                        self.tableView.beginUpdates()
                        self.tableView.setContentOffset(.zero, animated: false)
                        self.tableView.endUpdates()
                    }
                }
            }
            
            return nil
        })
    }
    
}

// MARK: TableView DataSource
extension CampaignTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let rowCount = ProductInfoManager.sharedInstance.datas?.count {
            return rowCount
        } else {
            return 0
        }
    }
}

// MARK: TableView Delegate
extension CampaignTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(for: indexPath) as CampaignTableViewCell
        
        guard let productInfo = ProductInfoManager.sharedInstance.datas?[indexPath.row] else {
            fatalError("CampaignTableViewController > tableView > get ProductInfo Error")
        }
        
        if let productRegion = productInfo.ProductRegion, let regionEnum = ProductRegion(rawValue: productRegion as! Int) {
            cell.campaignTitle.text = "[\(regionEnum.toString)] " + productInfo.TitleKor!
        } else {
            cell.campaignTitle.text = "[지역정보없음] \(productInfo.TitleKor!)"
        }
        
        cell.campaignDescription.text = productInfo.SubTitle
        
        let imageName = String(productInfo.ProductId) + "/" + Configuration.S3.PRODUCT_IMAGE_NAME(0)
        let imageUrl = Configuration.S3.PRODUCT_IMAGE_URL + imageName
        
        cell.campaignImage.tag = indexPath.row
        cell.campaignImage.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "bg_default_logo_gray"), options: .refreshCached) {
            (image, error, cacheType, imageURL) in
        }
        
        cell.campaignHeart.setTitle(String(productInfo.realLikeCount), for: .normal)
        cell.campaignHeart.isSelected = LikeDBManager.sharedInstance.hasLike(productId: productInfo.ProductId)
        
        cell.campaignHeart.tag = indexPath.row
        cell.campaignHeart.addTarget(self, action: #selector(self.heartButtonTapped(_:)), for: .touchUpInside)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if UIScreen.main.bounds.width == 320.0 {
            return 260.0
        } else if UIScreen.main.bounds.width == 375.0 {
            return 300.0
        } else {
            return 325.0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == ProductInfoManager.sharedInstance.datas?.count {
            
            printLog("tableView > willDisplay > refreshList")
            refreshList(false)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        printLog("tableView > didSelectRowAt > index : \(indexPath.row)")
        
        guard let detailVC: CampaignViewController = CampaignViewController.storyboardInstance(from: "SubItems") else {
            fatalError("CampaignTableViewController > initialize CampaignViewcontroller Error")
        }
        
        let selectedCampaign = ProductInfoManager.sharedInstance.datas?[indexPath.row]
        detailVC.productId = selectedCampaign?.ProductId
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func heartButtonTapped(_ sender: UIButton) {
        
        let index = sender.tag
        
        guard let productInfo = ProductInfoManager.sharedInstance.datas?[index] else {
            fatalError("CampaignTableViewController > heartButtonTapped > productInfo Error")
        }
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
            fatalError("CampaignTableViewController > heartButtonTapped > userInfo Error")
        }
        
        if sender.isSelected {
            
            if let likeIndex = LikeDBManager.sharedInstance.datas?.index(where: { $0.ProductId == productInfo.ProductId } ) {
                if let deleteItem = LikeDBManager.sharedInstance.datas?[likeIndex] {
                    tableView.isUserInteractionEnabled = false
                    LikeDBManager.sharedInstance.deleteLike(item: deleteItem).continueWith(block: {
                        (task: AWSTask) -> Any? in
                        
                        if task.error != nil { self.printLog("error : \(String(describing: task.error))") }
                        
                        return nil
                    })
                }
            }
        } else {
            tableView.isUserInteractionEnabled = false
            LikeDBManager.sharedInstance.addLike(userInfo: userInfo, productInfo: productInfo)
        }
    }
    
    func scrollToTop(animated: Bool) {
        tableView.setContentOffset(.zero, animated: true)
    }
}

// MARK: DropDownMenuDelegate

extension CampaignTableViewController: DropDownMenuDelegate {
    
    func getDropDownTitleView() -> DropDownTitleView {
        
        let titleView = DropDownTitleView(frame: CGRect(x: 0, y: 0, width: 150, height: 40))
        titleView.addTarget(self, action: #selector(self.willToggleNavigationBarMenu(_:)), for: .touchUpInside)
        titleView.addTarget(self, action: #selector(self.didToggleNavigationBarMenu(_:)), for: .valueChanged)
        titleView.titleLabel.textColor = .black
        titleView.title = Constants.Title.View.MAIN
        
        return titleView
    }
    
    func getDropDownMenu() -> DropDownMenu {
        let dropDownMenu = DropDownMenu(frame: view.bounds)
        dropDownMenu.delegate = self
        
        dropDownMenu.menuView.estimatedRowHeight = 45.0
        dropDownMenu.menuView.rowHeight = 45.0
        
        let sortCell = getSortCell()
        let categoryCell = getCategoryCell()
        let subCategoryCell = getSubCategoryCell()
        let regionCell = getRegionCell()
        let buttonCell = getButtonCell()
        
        dropDownMenu.menuCells = [sortCell, categoryCell, subCategoryCell, regionCell, buttonCell]
        
        dropDownMenu.backgroundView = UIView(frame: dropDownMenu.bounds)
        dropDownMenu.backgroundView?.backgroundColor = .black
        dropDownMenu.backgroundAlpha = 0.7
        
        return dropDownMenu
    }
    
    func getSortCell() -> DropDownMenuCell {
        let sortCell = FullWidthMenuCell()
        let sortKeys = [SortMode.like.toString, SortMode.date.toString]
        let sortSwitcher = UISegmentedControl(items: sortKeys)
        sortSwitcher.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: sortCell.frame.height)
        
        sortSwitcher.removeBorders()
        sortSwitcher.customizeText()
        
        sortSwitcher.selectedSegmentIndex = sortKeys.index(of: sortMode.toString)!
        sortSwitcher.addTarget(self, action: #selector(self.sort(_:)), for: .valueChanged)
        sortCell.customView = sortSwitcher
        sortCell.textLabel!.text = "Sort"
        sortCell.showsCheckmark = false
        
        return sortCell as DropDownMenuCell
    }
    
    func getCategoryCell() -> FilterMenuCell {
        printLog("\(#function) > cases : \(Category.allStrings)")
        let categoryCell = FilterMenuCell(data: Category.allStrings)
        categoryCell.tag = 1
        categoryCell.setEnabled(true)
        categoryCell.delegate = self
        
        return categoryCell
    }
    
    func getSubCategoryCell() -> FilterMenuCell {
        let subCategoryCell = FilterMenuCell(data: [Food.category.toString])
        subCategoryCell.tag = 2
        subCategoryCell.setEnabled(false)
        subCategoryCell.delegate = self
        
        return subCategoryCell
    }
    
    func getRegionCell() -> FilterMenuCell {
        let regionCell = FilterMenuCell(data: [ProductRegion.none.toString])
        regionCell.tag = 3
        regionCell.setEnabled(false)
        regionCell.delegate = self
        
        return regionCell
    }
    
    func getButtonCell() -> DropDownMenuCell {
        let buttonCell = DropDownMenuCell()
        let doneButton = UIButton(frame: buttonCell.frame)
        doneButton.setTitle(Constants.Title.Button.DONE, for: .normal)
        doneButton.setTitleColor(UIColor(netHex: 0xf2797c), for: .normal)
        doneButton.addTarget(self, action: #selector(self.doneFilter(_:)), for: .touchUpInside)
        buttonCell.customView = doneButton
        
        return buttonCell
    }
    
    func updateMenuContentOffsets() {
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        dropDownMenu.visibleContentOffset = navigationController!.navigationBar.frame.size.height + statusBarSize.height
    }
    
    func didTapInDropDownMenuBackground(_ menu: DropDownMenu) {
        
        if menu == dropDownMenu {
            if let menuCell = self.selectedMenuCell {
                menuCell.dismiss()
            }
            
            dropDownTitleView.toggleMenu()
        } else {
            if let menuCell = self.selectedMenuCell {
                menuCell.dismiss()
            }
            
            menu.hide()
        }
    }
    
    // MARK: DropDownMenu AddTarget Functions
    
    func willToggleNavigationBarMenu(_ sender: DropDownTitleView) {
        updateMenuContentOffsets()
        
        if sender.isUp {
            dropDownMenu.hide()
            self.tableView.isScrollEnabled = true
        } else {
            dropDownMenu.show()
            self.tableView.isScrollEnabled = false
        }
    }
    
    func didToggleNavigationBarMenu(_ menu: DropDownMenu) {
        
    }
    
    // MARK: FilterMenuCell AddTarget Functions
    func sort(_ sender: UISegmentedControl) {
        sortMode = SortMode(rawValue: sender.selectedSegmentIndex)!
    }
}

// MARK: -FilterMenuCellDelegate

extension CampaignTableViewController: FilterMenuCellDelegate {
    
    func editingDidBegin(tag: Int) {
        
        printLog("editingDidBegin > tag : \(tag)")
        
        dropDownMenu.selectMenuCell(dropDownMenu.menuCells[tag])
        selectedMenuCell = dropDownMenu.menuCells[tag] as? FilterMenuCell
    }
    
    func editingDidEnd(tag: Int, index: Int) {
        printLog("editingDidEnd > tag :\(tag), index: \(index)")
        
        guard let subCategoryCell = dropDownMenu.menuCells[2] as? FilterMenuCell,
              let regionCell = dropDownMenu.menuCells[3] as? FilterMenuCell else {
            printLog("FilterMenuCellDelegate > menuCell not created")
            return
        }
        
        if tag == 1 {
            
            switch index {
            case 0:
                subCategoryCell.data = [Food.category.toString]
                regionCell.data = [ProductRegion.none.toString]
                subCategoryCell.selectedRow = 0
                regionCell.selectedRow = 0
                subCategoryCell.setEnabled(false)
                regionCell.setEnabled(false)
                break
            case 1:
                subCategoryCell.data = Array(Food.allStrings)
                regionCell.data = Array(ProductRegion.allStrings)
                subCategoryCell.selectedRow = 0
                regionCell.selectedRow = 0
                subCategoryCell.setEnabled(true)
                regionCell.setEnabled(true)
                break
            case 2:
                subCategoryCell.data = Array(Concert.allStrings)
                regionCell.data = Array(ProductRegion.allStrings)
                subCategoryCell.selectedRow = 0
                regionCell.selectedRow = 0
                subCategoryCell.setEnabled(true)
                regionCell.setEnabled(true)
                break
            case 3:
                subCategoryCell.data = Array(Leisure.allStrings)
                regionCell.data = Array(ProductRegion.allStrings)
                subCategoryCell.selectedRow = 0
                regionCell.selectedRow = 0
                subCategoryCell.setEnabled(true)
                regionCell.setEnabled(true)
                break
            default:
                subCategoryCell.data = [Food.category.toString]
                regionCell.data = [ProductRegion.none.toString]
                subCategoryCell.selectedRow = 0
                regionCell.selectedRow = 0
                subCategoryCell.setEnabled(false)
                regionCell.setEnabled(false)
                break
            }
        }
        
    }
    
    func doneFilter(_ sender: Any) {
        
        printLog("doneFilter > sender")
        
        if let menuCell = self.selectedMenuCell {
            menuCell.dismiss()
        }
        
        dropDownTitleView.toggleMenu()
        
        // query
        
        var filterOptions = FilterOptions()
        filterOptions.sortMode = sortMode
        
        guard let selectedCategory = (dropDownMenu.menuCells[1] as? FilterMenuCell)?.selectedRow,
              let selectedSubCategory = (dropDownMenu.menuCells[2] as? FilterMenuCell)?.selectedRow,
              let selectedRegion = (dropDownMenu.menuCells[3] as? FilterMenuCell)?.selectedRow else {
            printLog("doneFilter > selectedRow Error")
            return
        }
        
        filterOptions.category = Array(Category.cases())[selectedCategory]
        filterOptions.region = Array(ProductRegion.cases())[selectedRegion]
        
        switch selectedCategory {
        case 1:
            filterOptions.food = Array(Food.cases())[selectedSubCategory]
            break
        case 2:
            filterOptions.concert = Array(Concert.cases())[selectedSubCategory]
            break
        case 3:
            filterOptions.leisure = Array(Leisure.cases())[selectedSubCategory]
            break
        default:
            break
        }
        
        var titleText = "전체보기"
        
        if filterOptions.category.rawValue == Category.category.rawValue {
            if filterOptions.region.rawValue != ProductRegion.none.rawValue {
                titleText = filterOptions.region.toString
            }
        } else {
            titleText = filterOptions.category.toString
            
            if (filterOptions.food != nil) && (filterOptions.food?.rawValue != Food.category.rawValue) {
                titleText = titleText + "+" + (filterOptions.food?.toString ?? "")
            } else if (filterOptions.concert != nil) && (filterOptions.concert?.rawValue != Concert.category.rawValue) {
                titleText = titleText + "+" + (filterOptions.concert?.toString ?? "")
            } else if (filterOptions.leisure != nil) && (filterOptions.leisure?.rawValue != Leisure.category.rawValue) {
                titleText = titleText + "+" + (filterOptions.leisure?.toString ?? "")
            }
            
            if filterOptions.region.rawValue != ProductRegion.none.rawValue {
                titleText = titleText + "+" + filterOptions.region.toString
            }
        }
        
        navigationItem.titleView = nil
        dropDownTitleView.title = titleText
        navigationItem.titleView = dropDownTitleView
        
        ProductInfoManager.sharedInstance.filterOptions = filterOptions
        ProductInfoManager.sharedInstance.searchKeyword = nil
        
        refreshList(true)
        
    }
}

// MARK: SearchBar Delegate

extension CampaignTableViewController: UISearchBarDelegate {
    
    func getSearchBarItem() -> UIBarButtonItem {
        return UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchBarItemTapped(_:)))
    }
    
    func searchBarItemTapped(_ sender: Any) {
        if navigationItem.titleView is UISearchBar {
            navigationItem.titleView = dropDownTitleView
        } else {
            let searchBar = UISearchBar()
            searchBar.showsCancelButton = true
            searchBar.placeholder = "상점명/지역명으로 검색"
            searchBar.delegate = self
            searchBar.becomeFirstResponder()
            
            navigationItem.rightBarButtonItem = nil
            navigationItem.titleView = searchBar
        }
    }
    
    // MARK: UISearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        navigationItem.titleView = dropDownTitleView
        navigationItem.rightBarButtonItem = getSearchBarItem()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        printLog("searchBarTextdidBeginEditing")
        
        if dropDownTitleView.isUp {
            dropDownMenu.hide()
            dropDownTitleView.toggleMenu()
        }
        
        tableView.isUserInteractionEnabled = false
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        printLog("searchBarTextDidEndEditing")
        tableView.isUserInteractionEnabled = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        guard let searchText = searchBar.text else {
            printLog("searchBarSearchButtonClicked > no input")
            return
        }
        
        printLog("searchBarSearchButtonClicked > text : \(searchText)")
        searchBar.resignFirstResponder()
        
        
        navigationItem.titleView = nil
        dropDownTitleView.title = "\"\(searchText)\"(으)로 검색"
        navigationItem.titleView = dropDownTitleView
        
        navigationItem.titleView = dropDownTitleView
        navigationItem.rightBarButtonItem = getSearchBarItem()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        ProductInfoManager.sharedInstance.filterOptions = nil
        ProductInfoManager.sharedInstance.searchKeyword = searchText
        refreshList(true)
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        printLog("searchBar > textDidChange > text : \(searchText)")
    }
}

// MARK: Observerable

extension CampaignTableViewController: Observerable {
    
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.addLikeNotification(_:)),
                                               name: Notification.Name(rawValue: LikeDBManager.AddNotification),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.deleteLikeNotification(_:)),
                                               name: NSNotification.Name(rawValue: LikeDBManager.DeleteNotification),
                                               object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: LikeDBManager.AddNotification),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: LikeDBManager.DeleteNotification),
                                                  object: nil)
    }
    
    func addLikeNotification(_ notification: Notification) -> Void {
        
        guard let productId = notification.userInfo![LikeDBManager.NotificationDataProductId] as? Int else {
            return
        }
        
        printLog("addLikeNotification > productId : \(productId)")
        
        if let index = ProductInfoManager.sharedInstance.datas?.index(where: { $0.ProductId == productId }) {
            
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                self.tableView.isUserInteractionEnabled = true
            }
            
        }
    }
    
    func deleteLikeNotification(_ notification: Notification) -> Void {
        
        guard let productId = notification.userInfo![LikeDBManager.NotificationDataProductId] as? Int else {
            return
        }
        
        printLog("deleteLikeNotification > productId : \(productId)")
        
        if let index = ProductInfoManager.sharedInstance.datas?.index(where: { $0.ProductId == productId }) {
            
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                self.tableView.isUserInteractionEnabled = true
            }
            
        }
    }
    
}
