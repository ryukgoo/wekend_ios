//
//  LikeCollectionViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 20..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit

class LikeCollectionViewController: UICollectionViewController {

    deinit {
        removeNotificationObservers()
        printLog("deinit")
    }
    
    // MARK: Properties
    
    let refreshControl = UIRefreshControl()
    var productId: Int?
    var datas: Array<LikeItem>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn_icon_back_w"), style: .plain, target: self, action: #selector(self.backButtonTapped(_:)))
        navigationItem.leftBarButtonItem = backButton
        
        initCollectionView()
        loadLikeFriends()
        addNotificationObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.tintColor = .black
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: load Datas
    func loadLikeFriends() {
        
        printLog("loadLikeFriends")
        
        startLoading()
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
            fatalError("LikeCollectionViewController > get UserInfo Error")
        }
        
        LikeDBManager.sharedInstance.getFriends(productId: self.productId!, userId: userInfo.userid, gender: userInfo.gender!).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            self.datas = []
            
            guard let result = task.result else {
                fatalError("LikeCollectionViewController > loadLikeFriends Error")
            }
            
            self.datas = result as? Array<LikeItem>
            
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
                self.refreshControl.endRefreshing()
                self.endLoading()
            }
            
            return nil
        })
    }

    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
        
        printLog("prepare > identifier : \(String(describing: segue.identifier))")
        
        // Goto LikeProfileViewController
        if #available(iOS 9.0, *) {
            if segue.identifier == LikeProfileViewController.className {
                
                guard let profileViewController = segue.destination as? LikeProfileViewController else {
                    fatalError("LikeCollectionViewController > destination Error")
                }
                
                guard let likeCollectionCell = sender as? LikeCollectionViewCell else {
                    fatalError("LikeCollectionViewController > cell Error")
                }
                
                guard let indexPath = collectionView?.indexPath(for: likeCollectionCell) else {
                    fatalError("LikeCollectionViewController > indexPath Error")
                }
                
                guard let selectedLike = datas?[indexPath.row] else {
                    fatalError("LikeCollectionViewController > get data Error")
                }
                
                guard let userId = UserInfoManager.sharedInstance.userInfo?.userid else {
                    fatalError("LikeCollectionViewController > get UserId Error")
                }
                
                guard let likeId = selectedLike.LikeId else {
                    fatalError("LikeCollectionViewController > LikeId is nil")
                }
                
                profileViewController.friendUserId = selectedLike.UserId
                profileViewController.productId = selectedLike.ProductId
                
                // TODO: - Check Friend Read
                
                LikeDBManager.sharedInstance.updateReadState(id: likeId, userId: userId, productId: selectedLike.ProductId, likeUserId: selectedLike.UserId)
            }
        } else {
            // Fallback on earlier versions
        }
    }
     */
}

extension LikeCollectionViewController {
    
    func initCollectionView() {
        
        collectionView?.contentInset = UIEdgeInsetsMake(12, 0, 0, 0)
        
        refreshControl.backgroundColor = UIColor.white
        refreshControl.backgroundColor = UIColor.white
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        
        if #available(iOS 10.0, *) {
            collectionView?.refreshControl = refreshControl
        } else {
            collectionView?.addSubview(refreshControl)
        }
        
    }
    
    func refresh(_ sender: Any) {
        loadLikeFriends()
    }
}

// MARK: Observerable

extension LikeCollectionViewController: Observerable {
    
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(LikeCollectionViewController.handleReadFriendNotification(_:)),
                                               name: Notification.Name(rawValue: LikeDBManager.FriendReadNotification),
                                               object: nil)
        
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: LikeDBManager.FriendReadNotification),
                                                  object: nil)
    }
    
    func handleReadFriendNotification(_ notification: Notification) {
        
        printLog("handleReadFriendNotification > notification : \(notification.description)")
        
        guard let likeUserId = notification.userInfo![LikeDBManager.NotificationDataUserId] as? String else {
            return
        }
        
        if let index = datas?.index(where: { $0.UserId == likeUserId }) {
            datas?[index].isRead = true
            
            DispatchQueue.main.async {
                self.collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
            }
        }
    }
}

// MARK: CollectionViewController Delegate / DataSource

extension LikeCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        
        guard let rowCount = datas?.count else {
            return 0
        }
        
        return rowCount
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(for: indexPath) as LikeCollectionViewCell
        
        // Configure the cell
        
        guard let data = datas?[indexPath.row] else {
            fatalError("LikeCollectionViewController > No Cell data")
        }
        
        let imageName = data.UserId + "/" + Configuration.S3.PROFILE_IMAGE_NAME(0)
        let imageUrl = Configuration.S3.PROFILE_THUMB_URL + imageName
        
        let defaultImage : UIImage
        if data.Gender == UserInfo.RawValue.GENDER_MALE {
            defaultImage = #imageLiteral(resourceName: "img_bg_thumb_s_default_male")
        } else {
            defaultImage = #imageLiteral(resourceName: "img_bg_thumb_s_default_Female")
        }
        
        cell.likeImageView.frame = CGRect(x: 5.0, y: 5.0, width: UIScreen.main.bounds.size.width/3.0 - 10.0, height: UIScreen.main.bounds.size.width/3.0 - 10.0)
        
        cell.likeImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: defaultImage, options: .cacheMemoryOnly) {
            (image, error, cacheType, imageURL) in
            
        }
        cell.likeImageView.toMask(mask: #imageLiteral(resourceName: "img_bg_thumb_s_2"))
        
        cell.likeNickname.text = data.Nickname
        cell.newIcon.isHidden = data.isRead
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width/3, height: UIScreen.main.bounds.width/3)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let profileViewController: LikeProfileViewController = LikeProfileViewController.storyboardInstance(from: "SubItems") as? LikeProfileViewController else {
            fatalError()
        }
        
        guard let selectedLike = datas?[indexPath.row] else {
            fatalError("LikeCollectionViewController > get data Error")
        }
        
        guard let userId = UserInfoManager.sharedInstance.userInfo?.userid else {
            fatalError("LikeCollectionViewController > get UserId Error")
        }
        
        guard let likeId = selectedLike.LikeId else {
            fatalError("LikeCollectionViewController > LikeId is nil")
        }
        
        profileViewController.friendUserId = selectedLike.UserId
        profileViewController.productId = selectedLike.ProductId
        
        // TODO: - Check Friend Read
        
        navigationController?.pushViewController(profileViewController, animated: true)
        LikeDBManager.sharedInstance.updateReadState(id: likeId, userId: userId, productId: selectedLike.ProductId, likeUserId: selectedLike.UserId)
    }
}
