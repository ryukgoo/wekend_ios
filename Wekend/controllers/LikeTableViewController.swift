//
//  LikeTableViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 16..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit
import AWSDynamoDB

class LikeTableViewController: UITableViewController {
    
    let refreshControlView = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        printLog("viewDidLoad")
        
        initTableView()
        startLoading()
        refreshList(true)
        addNotificationObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.tintColor = .black
        
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
    }
 
    func initTableView() {
        tableView.contentInset = UIEdgeInsetsMake(12, 0, 0, 0)
        
        refreshControlView.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControlView.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControlView
        } else {
            tableView.addSubview(refreshControlView)
        }
        
    }
    
    func refresh(_ sender: Any) {
        // TODO: -edit plz......
        
//        LikeDBManager.sharedInstance.datas = []
        refreshList(true)
    }
    
    // MARK: Functions
    func refreshList(_ startFromBegin: Bool) {
        
        printLog("refreshList > startFromBegin : \(startFromBegin)")
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
            fatalError("LikeTableViewController > refreshList > getUserInfo Failed")
        }
        
        LikeDBManager.sharedInstance.getDatas(userId: userInfo.userid).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let _ = task.result else {
                fatalError("LikeTableViewController > refreshList > getDatas Failed")
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.tableView.reloadData()
                self.refreshControlView.endRefreshing()
                self.endLoading()
            }
            
            return nil
        })
    }

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
}

// MARK: -Observerable

extension LikeTableViewController: Observerable {
    
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(LikeTableViewController.handleAddLikeNotification(_:)),
                                               name: Notification.Name(rawValue: LikeDBManager.AddNotification),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LikeTableViewController.handleRemoteNotification(_:)),
                                               name: Notification.Name(rawValue: LikeDBManager.NewRemoteNotification),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LikeTableViewController.handleReadNotification(_:)),
                                               name: Notification.Name(rawValue: LikeDBManager.ReadNotification),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LikeTableViewController.handleDeleteNotification(_:)),
                                               name: Notification.Name(rawValue: LikeDBManager.DeleteNotification),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LikeTableViewController.refresh(_:)),
                                               name: Notification.Name(rawValue: LikeDBManager.RefreshNotification),
                                               object: nil)
    }
    
    func handleAddLikeNotification(_ notification: Notification) {
        
        guard let productId = notification.userInfo![LikeDBManager.NotificationDataProductId] as? Int else {
            return
        }
        
        if let index = LikeDBManager.sharedInstance.datas?.index(where: { $0.ProductId == productId }) {
            DispatchQueue.main.async {
                self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .left)
            }
        }
        
    }
    
    func handleRemoteNotification(_ notification: Notification) {
        
//        guard let productId = notification.userInfo![LikeDBManager.NotificationDataProductId] as? Int else {
//            return
//        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
//        if let index = LikeDBManager.sharedInstance.datas?.index(where: { $0.ProductId == productId }) {
//            DispatchQueue.main.async {
//                self.tableView.reloadIndex(index: index)
//            }
//        }
    }
    
    func handleReadNotification(_ notification: Notification) {
        
        printLog("handleReadNotification > notification : \(notification)")
        
        guard let productId = notification.userInfo![LikeDBManager.NotificationDataProductId] as? Int else {
            return
        }
        
        if let index = LikeDBManager.sharedInstance.datas?.index(where: { $0.ProductId == productId }) {
            DispatchQueue.main.async {
                self.tableView.reloadIndex(index: index)
            }
        }
    }
    
    func handleDeleteNotification(_ notification: Notification) {
        
        printLog("handleDeleteNotification > notification : \(notification)")
        
        guard let productId = notification.userInfo![LikeDBManager.NotificationDataProductId] as? Int else {
            return
        }
        
        if let index = LikeDBManager.sharedInstance.datas?.index(where: { $0.ProductId == productId }) {
            DispatchQueue.main.async {
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
            }
        }
        
    }
    
}


// MARK: - UITableViewController DataSource

extension LikeTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        printLog("numberOfRowsInSection")
        
        guard let datas = LikeDBManager.sharedInstance.datas else {
            return 0
        }
        
        return datas.count
    }
}

// MARK: - UITableViewController Delegate

extension LikeTableViewController {
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(for: indexPath) as LikeTableViewCell
        
        printLog("indexPath : \(indexPath.row)")
        
        guard let likeItem = LikeDBManager.sharedInstance.datas?[indexPath.row] else {
            // FatalError > Index out of range
//            fatalError("LikeTableViewController > No data Error")
            return cell
        }
        
        let imageName = String(likeItem.ProductId) + "/" + Configuration.S3.PRODUCT_IMAGE_NAME(0)
        let imageUrl = Configuration.S3.PRODUCT_THUMB_URL + imageName
        
        cell.likeImage.downloadedFrom(link: imageUrl, defaultImage: #imageLiteral(resourceName: "img_bg_thumb_s_logo"))
        cell.likeImage.toMask(mask: #imageLiteral(resourceName: "img_bg_thumb_s_2"))
        
        cell.likeTitleLabel.text = likeItem.ProductTitle ?? ""
        cell.likeSubTitleLabel.text = likeItem.ProductDesc ?? ""
        
        cell.likeNewIcon.isHidden = likeItem.isRead
        
        return cell
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
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
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
        let whitespace = whitespaceString(width: tableView.rowHeight)
        let deleteAction = UITableViewRowAction(style: .normal, title: whitespace) {
            (rowAction, indexPath) in
            
            guard let deleteItem = LikeDBManager.sharedInstance.datas?[indexPath.row] else {
                fatalError("LikeTableViewController > deleteItem Failed")
            }
            
            LikeDBManager.sharedInstance.deleteLike(item: deleteItem).continueWith(block: {
                (task: AWSTask) -> Any? in
                
                if task.error == nil {
//                    DispatchQueue.main.async {
//                        self.tableView.deleteRows(at: [indexPath], with: .fade)
//                    }
                }
                
                return nil
            })
        }
        
        deleteAction.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "img_bg_delete"))
    
        return [deleteAction]
    }
    
    func scrollToTop(animated: Bool) {
        let yOffSet = -tableView.contentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: yOffSet), animated: true)
    }
 
}
