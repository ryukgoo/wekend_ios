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
    
    // MARK: IBOutlet
    @IBOutlet weak var noResultLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Properties
    var isLoading: Bool = false
    
    // MARK: custom Views
    let refreshControl = UIRefreshControl()
    
    var dropDownTitleView: DropDownTitleView!
    var dropDownMenu: DropDownMenu!
    var selectedMenuCell: FilterMenuCell?
    var sortMode: SortMode = .date
    
    var viewModel: CampaignListViewModel?
    
    deinit {
        removeNotificationObservers()
        print("\(className) > \(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTableView()
        initRefreshControl()
        
        navigationItem.rightBarButtonItem = getSearchBarItem()
        dropDownTitleView = getDropDownTitleView()
        navigationItem.titleView = dropDownTitleView
        
        dropDownMenu = getDropDownMenu()
        updateMenuContentOffsets()
        
        viewModel = CampaignListViewModel(dataSource: ProductRepository.shared)
        bindViewModel()
        
        loadProductData(options: nil, keyword: nil)
        addNotificationObservers()
    }
    
    fileprivate func bindViewModel() {
        guard let viewModel = viewModel else { return }
        viewModel.datas.bind { [weak self] datas in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self?.isLoading = false
            self?.refreshControl.endRefreshing()
            self?.tabBarController?.endLoading()
            
            if datas?.count == 0 {
                self?.noResultLabel.isHidden = false
            } else {
                self?.noResultLabel.isHidden = true
            }
            
            self?.tableView.reloadData()
            self?.tableView.beginUpdates()
            self?.tableView.setContentOffset(.zero, animated: false)
            self?.tableView.endUpdates()
            
            self?.navigationItem.titleView = nil
            self?.dropDownTitleView.title = viewModel.getTitleText()
            self?.navigationItem.titleView = self?.dropDownTitleView
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("\(className) > \(#function)")
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dropDownMenu.container = self.view
    }
    
    @IBAction func reloadButtonTapped(_ sender: Any) {
        loadProductData(options: nil, keyword: nil)
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
        refreshControl.attributedTitle = NSAttributedString(string: "업데이트중...")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
    }
    
    func refresh(_ sender: Any) {
        loadProductData(options: viewModel?.options.value, keyword: viewModel?.keyword.value)
    }
    
    func loadProductData(options: FilterOptions?, keyword: String?) {
        
        isLoading = true
        self.tabBarController?.startLoading()
        
        viewModel?.loadProductList(options: options, keyword: keyword)
    }
}

// MARK: TableView DataSource
extension CampaignTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ProductRepository.shared.cachedData.count
    }
}

// MARK: TableView Delegate
extension CampaignTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(for: indexPath) as CampaignTableViewCell
        let productInfo = ProductRepository.shared.cachedData[indexPath.row]
        
        let isSelected = LikeRepository.shared.hasLike(productId: productInfo.ProductId)
        var viewModel = CampaignCellViewModel(info: productInfo, isSelected: isSelected)
        viewModel.listener = { info in self.heartButtonTapped(info) }
        cell.viewModel = viewModel
        
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
        print("\(className) > \(#function)")
        if indexPath.row == ProductRepository.shared.cachedData.count {
            print("\(className) > \(#function) > refreshList")
//            loadProductData(options: nil, keyword: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let detailVC = CampaignViewController.storyboardInstance(from: "SubItems") as? CampaignViewController else {
            fatalError("\(className) > \(#function) > initialize CampaignViewcontroller Error")
        }
        
        let selectedCampaign = ProductRepository.shared.cachedData[indexPath.row]
        detailVC.viewModel = CampaignViewModel(id: selectedCampaign.ProductId,
                                               isLikeEnabled: true,
                                               dataSource: ProductRepository.shared)
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func heartButtonTapped(_ productInfo: ProductInfo) {
        
        guard let userInfo = UserInfoRepository.shared.userInfo else { return }
        
        if let likeIndex = LikeRepository.shared.datas?.index(where: { $0.ProductId == productInfo.ProductId } ) {
            if let deleteItem = LikeRepository.shared.datas?[likeIndex] {
                tableView.isUserInteractionEnabled = false
                LikeRepository.shared.deleteLike(item: deleteItem).continueWith(executor: AWSExecutor.mainThread()) { task in
                    if task.error != nil { print("\(self.className) > \(#function) > error : \(String(describing: task.error))") }
                    return nil
                }
            }
        } else {
            tableView.isUserInteractionEnabled = false
            LikeRepository.shared.addLike(userInfo: userInfo, productInfo: productInfo)
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
        
        if UIScreen.main.bounds.width == 320.0 {
            dropDownMenu.menuView.estimatedRowHeight = 46.0
            dropDownMenu.menuView.rowHeight = 46.0
        } else {
            dropDownMenu.menuView.estimatedRowHeight = 54.0
            dropDownMenu.menuView.rowHeight = 54.0
        }
        
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
        print("\(className) > \(#function) > cases : \(Category.allStrings)")
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
        let frame = CGRect(x: buttonCell.frame.origin.x, y: buttonCell.frame.origin.y + 2, width: buttonCell.frame.width, height: buttonCell.frame.height - 4)
        
        let stackView = UIStackView(frame: frame)
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 10.0
        
        let allButton = WhiteRoundedButton()
        allButton.backgroundColor = UIColor(netHex:0xf2797c)
        allButton.setTitle(Constants.Title.View.MAIN, for: .normal)
        allButton.setTitleColor(UIColor(netHex: 0xf2797c), for: .normal)
        allButton.addTarget(self, action: #selector(self.showAll(_:)), for: .touchUpInside)
        
        let doneButton = WhiteRoundedButton()
        doneButton.backgroundColor = UIColor(netHex:0xf2797c)
        doneButton.setTitle(Constants.Title.Button.DONE, for: .normal)
        doneButton.setTitleColor(UIColor(netHex: 0xf2797c), for: .normal)
        doneButton.addTarget(self, action: #selector(self.doneFilter(_:)), for: .touchUpInside)
        
        stackView.addArrangedSubview(allButton)
        stackView.addArrangedSubview(doneButton)
        
        buttonCell.customView = stackView
        
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
    
    func didToggleNavigationBarMenu(_ menu: DropDownMenu) { }
    
    // MARK: FilterMenuCell AddTarget Functions
    func sort(_ sender: UISegmentedControl) {
        sortMode = SortMode(rawValue: sender.selectedSegmentIndex)!
    }
}

// MARK: -FilterMenuCellDelegate
extension CampaignTableViewController: FilterMenuCellDelegate {
    
    func editingDidBegin(tag: Int) {
        print("\(className) > \(#function) > tag : \(tag)")
        dropDownMenu.selectMenuCell(dropDownMenu.menuCells[tag])
        selectedMenuCell = dropDownMenu.menuCells[tag] as? FilterMenuCell
    }
    
    func editingDidEnd(tag: Int, index: Int) {
        print("\(className) > \(#function) > tag :\(tag), index: \(index)")
        guard let subCategoryCell = dropDownMenu.menuCells[2] as? FilterMenuCell,
              let regionCell = dropDownMenu.menuCells[3] as? FilterMenuCell else {
                print("\(className) > \(#function) > menuCell not created")
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
        print("\(className) > \(#function) > sender")
        if let menuCell = self.selectedMenuCell {
            menuCell.dismiss()
        }
        
        dropDownTitleView.toggleMenu()
        
        var filterOptions = FilterOptions()
        filterOptions.sortMode = sortMode
        
        guard let selectedCategory = (dropDownMenu.menuCells[1] as? FilterMenuCell)?.selectedRow,
              let selectedSubCategory = (dropDownMenu.menuCells[2] as? FilterMenuCell)?.selectedRow,
              let selectedRegion = (dropDownMenu.menuCells[3] as? FilterMenuCell)?.selectedRow else {
            print("\(className) > \(#function) > selectedRow Error")
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
        
        loadProductData(options: filterOptions, keyword: nil)
        
    }
    
    func showAll(_ sender: Any) {
        if let menuCell = self.selectedMenuCell {
            menuCell.dismiss()
        }
        
        guard let mainCategoryCell = dropDownMenu.menuCells[1] as? FilterMenuCell,
            let subCategoryCell = dropDownMenu.menuCells[2] as? FilterMenuCell,
            let regionCell = dropDownMenu.menuCells[3] as? FilterMenuCell else {
                print("\(className) > \(#function) > menuCell not created")
                return
        }
        
        mainCategoryCell.data = Category.allStrings
        subCategoryCell.data = [Food.category.toString]
        regionCell.data = [ProductRegion.none.toString]
        mainCategoryCell.selectedRow = 0
        subCategoryCell.selectedRow = 0
        regionCell.selectedRow = 0
        subCategoryCell.setEnabled(false)
        regionCell.setEnabled(false)
        
        dropDownTitleView.toggleMenu()
        loadProductData(options: FilterOptions(), keyword: nil)
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
        print("\(className) > \(#function)")
        
        if dropDownTitleView.isUp {
            dropDownMenu.hide()
            dropDownTitleView.toggleMenu()
        }
        
        tableView.isUserInteractionEnabled = false
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        print("\(className) > \(#function)")
        tableView.isUserInteractionEnabled = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        guard let searchText = searchBar.text else {
            print("\(className) > \(#function) > no input")
            return
        }
        
        searchBar.resignFirstResponder()
        
        navigationItem.rightBarButtonItem = getSearchBarItem()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        loadProductData(options: nil, keyword: searchText)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("\(className) > \(#function) > text : \(searchText)")
    }
}

// MARK: Notification Observers
extension CampaignTableViewController {
    
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.addLikeNotification(_:)),
                                               name: Notification.Name(rawValue: LikeNotification.Add),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.deleteLikeNotification(_:)),
                                               name: NSNotification.Name(rawValue: LikeNotification.Delete),
                                               object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: LikeNotification.Add),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: LikeNotification.Delete),
                                                  object: nil)
    }
    
    func addLikeNotification(_ notification: Notification) -> Void {
        
        guard let productId = notification.userInfo![LikeNotification.Data.ProductId] as? Int else {
            return
        }
        
        print("\(className) > \(#function) > productId : \(productId)")
        
        if let index = ProductRepository.shared.cachedData.index(where: { $0.ProductId == productId }) {
            
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                self.tableView.isUserInteractionEnabled = true
            }
            
        }
    }
    
    func deleteLikeNotification(_ notification: Notification) -> Void {
        
        guard let productId = notification.userInfo![LikeNotification.Data.ProductId] as? Int else {
            return
        }
        
        print("\(className) > \(#function) > productId : \(productId)")
        
        if let index = ProductRepository.shared.cachedData.index(where: { $0.ProductId == productId }) {
            
            DispatchQueue.main.async {
                self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
                self.tableView.isUserInteractionEnabled = true
            }
        }
    }
}
