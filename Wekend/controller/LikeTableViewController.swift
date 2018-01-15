//
//  LikeTableViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 16..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit
import AWSDynamoDB

class LikeTableViewController: UIViewController {
    
    deinit {
        removeNotificationObservers()
        print("\(className) > \(#function)")
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noResultLabel: UILabel!
    let refreshControlView = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("\(className) > \(#function)")
        
        initTableView()
        self.tabBarController?.startLoading()
        refreshList(true)
        addNotificationObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
 
    func initTableView() {
        
        tableView.contentInset = UIEdgeInsetsMake(12, 0, 0, 0)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        refreshControlView.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControlView.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControlView
        } else {
            tableView.addSubview(refreshControlView)
        }
        
        noResultLabel.isHidden = true
    }
    
    func refresh(_ sender: Any) {
        // TODO: -edit plz......
        
//        LikeDBManager.sharedInstance.datas = []
        refreshList(true)
    }
    
    // MARK: Functions
    func refreshList(_ startFromBegin: Bool) {
        
        print("\(#function) > startFromBegin : \(startFromBegin)")
        
        guard let userInfo = UserInfoRepository.shared.userInfo else {
            fatalError("\(self.className) > \(#function) > getUserInfo Failed")
        }
        
        LikeRepository.shared.getDatas(userId: userInfo.userid).continueWith(executor: AWSExecutor.mainThread()) { task in
            guard let _ = task.result else {
                fatalError("\(self.className) > \(#function) > getDatas Failed")
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.tableView.reloadData()
                self.refreshControlView.endRefreshing()
                self.tabBarController?.endLoading()
                
                self.handleNoResultLabel()
            }
            
            return nil
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        printLog("sender : \(String(describing: sender))")
        
        if segue.identifier == CampaignViewController.className {
            
            guard let campaignDetailViewController = segue.destination as? CampaignViewController else {
                fatalError("LikeTableViewController > prepare destination Error")
            }
            
            guard let selectedLikeCell = sender as? LikeTableViewCell else {
                fatalError("LikeTableViewController > prepare cell Error")
            }
            
            guard let indexPath = tableView.indexPath(for: selectedLikeCell) else {
                fatalError("LikeTableViewController > prepare > indexPath Error")
            }
            
            guard let selectedLikeItem = LikeDBManager.sharedInstance.datas?[indexPath.row] else {
                return
            }
            
            campaignDetailViewController.productId = selectedLikeItem.ProductId
            LikeDBManager.sharedInstance.updateReadTime(likeItem: selectedLikeItem)
        }
    }
    */
}

// MARK: -Notification Observers
extension LikeTableViewController {
    
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(LikeTableViewController.handleAddLikeNotification(_:)),
                                               name: Notification.Name(rawValue: LikeNotification.Add),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LikeTableViewController.handleRemoteNotification(_:)),
                                               name: Notification.Name(rawValue: LikeNotification.New),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LikeTableViewController.handleReadNotification(_:)),
                                               name: Notification.Name(rawValue: LikeNotification.Read),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LikeTableViewController.handleDeleteNotification(_:)),
                                               name: Notification.Name(rawValue: LikeNotification.Delete),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LikeTableViewController.refresh(_:)),
                                               name: Notification.Name(rawValue: LikeNotification.Refresh),
                                               object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: LikeNotification.Add),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: LikeNotification.New),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: LikeNotification.Read),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: LikeNotification.Delete),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: LikeNotification.Refresh),
                                                  object: nil)
    }
    
    func handleAddLikeNotification(_ notification: Notification) {
        
        guard let productId = notification.userInfo![LikeNotification.Data.ProductId] as? Int else {
            return
        }
        
        if let index = LikeRepository.shared.datas?.index(where: { $0.ProductId == productId }) {
            DispatchQueue.main.async {
                self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .left)
                self.handleNoResultLabel()
            }
        }
        
    }
    
    func handleRemoteNotification(_ notification: Notification) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func handleReadNotification(_ notification: Notification) {
        print("\(className) > \(#function) > notification : \(notification)")
        guard let productId = notification.userInfo![LikeNotification.Data.ProductId] as? Int else {
            return
        }
        
        if let index = LikeRepository.shared.datas?.index(where: { $0.ProductId == productId }) {
            DispatchQueue.main.async {
                self.tableView.reloadIndex(index: index)
            }
        }
    }
    
    func handleDeleteNotification(_ notification: Notification) {
        
        print("\(className) > \(#function) > notification : \(notification)")
        
        guard let productId = notification.userInfo![LikeNotification.Data.ProductId] as? Int else {
            return
        }
        
        if let index = LikeRepository.shared.datas?.index(where: { $0.ProductId == productId }) {
            DispatchQueue.main.async {
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                self.handleNoResultLabel()
            }
        }
    }
}

// MARK: - UITableViewController DataSource
extension LikeTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\(className) > \(#function)")
        guard let datas = LikeRepository.shared.datas else {
            return 0
        }
        return datas.count
    }
    
    func handleNoResultLabel() {
        if LikeRepository.shared.datas?.count == 0 {
            noResultLabel.isHidden = false
        } else {
            noResultLabel.isHidden = true
        }
    }
}

// MARK: - UITableViewController Delegate
extension LikeTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(for: indexPath) as LikeTableViewCell
        
        print("\(className) > \(#function) > indexPath : \(indexPath.row)")
        guard let likeItem = LikeRepository.shared.datas?[indexPath.row] else {
            return cell
        }
        
        let imageName = String(likeItem.ProductId) + "/" + Configuration.S3.PRODUCT_IMAGE_NAME(0)
        let imageUrl = Configuration.S3.PRODUCT_THUMB_URL + imageName
        
        cell.likeImage.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "img_bg_thumb_s_logo"), options: .refreshCached) {
            (image, error, cacheType, imageURL) in
        }
        
        cell.likeImage.toMask(mask: #imageLiteral(resourceName: "img_bg_thumb_s_2"))
        
        cell.likeTitleLabel.text = likeItem.ProductTitle ?? ""
        cell.likeSubTitleLabel.text = likeItem.ProductDesc ?? ""
        
        cell.likeNewIcon.isHidden = likeItem.isRead
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let detailVC: CampaignViewController = CampaignViewController.storyboardInstance(from: "SubItems") else {
            fatalError("\(self.className) > \(#function) > initialize CampaignViewcontroller Error")
        }
        
        guard let selectedLikeItem = LikeRepository.shared.datas?[indexPath.row] else {
            return
        }
        detailVC.productId = selectedLikeItem.ProductId
        
        navigationController?.pushViewController(detailVC, animated: true)
        LikeRepository.shared.updateReadTime(likeItem: selectedLikeItem)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    fileprivate func whitespaceString(font: UIFont = UIFont.systemFont(ofSize: 15), width: CGFloat) -> String {
        let kPadding: CGFloat = 20
        let mutable = NSMutableString(string: "")
        let attribute = [NSFontAttributeName: font]
        while mutable.size(attributes: attribute).width < width - (2 * kPadding) {
            mutable.append(" ")
        }
        return mutable as String
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
        let whitespace = whitespaceString(width: tableView.rowHeight)
        let deleteAction = UITableViewRowAction(style: .normal, title: whitespace) {
            (rowAction, indexPath) in
            guard let deleteItem = LikeRepository.shared.datas?[indexPath.row] else {
                fatalError("\(self.className) > \(#function) > deleteItem Failed")
            }
            
            LikeRepository.shared.deleteLike(item: deleteItem).continueWith(executor: AWSExecutor.mainThread()) { task in
                if task.error == nil {
//                    DispatchQueue.main.async {
//                        self.tableView.deleteRows(at: [indexPath], with: .fade)
//                    }
                }
                return nil
            }
        }
        
        deleteAction.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "img_bg_delete"))
    
        return [deleteAction]
    }
    
    func scrollToTop(animated: Bool) {
        let yOffSet = -tableView.contentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: yOffSet), animated: true)
    }
}
