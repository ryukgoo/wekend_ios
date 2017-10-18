//
//  FriendProfileViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 10..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import KRWordWrapLabel

/*
 * Receive Profile
 */
@available(iOS 9.0, *)
class FriendProfileViewController: UIViewController, PagerViewDelegate, UIScrollViewDelegate {

    let minimumAlpha: CGFloat = 0.1
    
    // MARK : Properties
    
    var mail: ReceiveMail?
    var friendUserId: String?
    var friendUserInfo: UserInfo?
    var productId: Int?
    var productInfo: ProductInfo?
    var proposeStatus: ProposeStatus = .none
    var isLoading: Bool = false
    
    // MARK : IBOutlet
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var pagerView: PagerView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nicknameStackView: UIStackView!
    @IBOutlet weak var ageStackView: UIStackView!
    @IBOutlet weak var phoneStackView: UIStackView!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var descriptionLabel: KRWordWrapLabel!
    @IBOutlet weak var proposeStatusButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var containerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var pagerViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var stackViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn_icon_back_w"), style: .plain, target: self, action: #selector(self.backButtonTapped(_:)))
        navigationItem.leftBarButtonItem = backButton
        
        buttonsStackView.isHidden = true
        
        if let mail = self.mail {
            proposeStatus = ProposeStatus(rawValue: mail.ProposeStatus!)!
        } else {
            proposeStatus = .none
        }
        
        loadProfileInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        UIApplication.shared.isStatusBarHidden = true
        
        var colors = [UIColor]()
        colors.append(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5))
        colors.append(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0))
        navigationController?.navigationBar.setGradientBackground(colors: colors)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.tintColor = .white
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isStatusBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK : Initialize Views
    
    private func initViews() {
        
        guard let userInfo = self.friendUserInfo else {
            fatalError("FriendProfileViewController > initView > get friend info Error")
        }
        
        let photos: Set<String>
        
        if userInfo.photos == nil {
            photos = Set<String>()
        } else {
            photos = userInfo.photos as! Set<String>
        }
        
        printLog("initViews > photos.count : \(photos.count)")
        
        pagerView.delegate = self
        pagerView.pageCount = max(photos.count, 1)
        
        scrollView.delegate = self
        
        guard let birth = userInfo.birth as! Int! else {
            fatalError("FriendProfileViewController > initViews > get birth Error")
        }
        
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date)
        let year = components.year
        
        nicknameLabel.text = userInfo.nickname
        ageLabel.text = String(year! - birth) + "세"
        phoneLabel.text = userInfo.phone?.toPhoneFormat()
        
        guard let productInfo = self.productInfo else {
            fatalError("FriendProfileViewController > initViews > productInfo Error")
        }
        
        descriptionLabel.text = productInfo.TitleKor
        if productInfo.Description != nil {
            descriptionLabel.text! += "\n\n" + productInfo.Description!
        }
        
        descriptionLabel.sizeToFit()
        
        refreshLayout()
        
    }
    
    private func refreshLayout() {
        
        buttonsStackView.isHidden = false
        
        var scrollableHeight = pagerView.frame.height
        scrollableHeight += nicknameStackView.frame.height
        scrollableHeight += ageStackView.frame.height
        scrollableHeight += 27
        scrollableHeight += descriptionLabel.frame.height
        scrollableHeight += 20
        
        switch proposeStatus {
            
        case .notMade:
            
            proposeStatusButton.isUserInteractionEnabled = true
            proposeStatusButton.setTitle("수락", for: .normal)
            phoneStackView.isHidden = true
            rejectButton.isHidden = false
            
            break
            
        case .made:
            
            proposeStatusButton.isUserInteractionEnabled = false
            proposeStatusButton.setTitle(proposeStatus.message(), for: .normal)
            phoneStackView.isHidden = false
            rejectButton.isHidden = true
            scrollableHeight += phoneLabel.frame.height
            
            break
            
        default:
            
            proposeStatusButton.isUserInteractionEnabled = false
            proposeStatusButton.setTitle(proposeStatus.message(), for: .normal)
            rejectButton.isHidden = true
            phoneStackView.isHidden = true
            
            break
        }
        
        self.containerViewHeight.constant = scrollableHeight
        self.backgroundHeight.constant = scrollableHeight - self.pagerView.frame.height
        
    }
    
    // MARK : Load Datas
    
    private func loadProfileInfo() {
        
        startLoading()
        isLoading = true
        containerView.alpha = 0.0
        
        UserInfoManager.sharedInstance.getUserInfo(userId: friendUserId!).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let info = task.result else {
                fatalError("FriendProfileViewController > get Friend Info Error")
            }
            
            self.friendUserInfo = info as? UserInfo
            
            ProductInfoManager.sharedInstance.getProductInfo(productId: self.productId!).continueWith(executor: AWSExecutor.mainThread(), block: {
                (productTask: AWSTask) -> Any! in
                
                guard let productInfo = productTask.result else {
                    fatalError("FriendProfileViewController > loadProfileInfo > get product Error")
                }
                
                self.productInfo = productInfo as? ProductInfo
                self.isLoading = false
                
                DispatchQueue.main.async {
                    self.initViews()
                    self.endLoading()
                    UIView.animate(withDuration: 0.3, animations: {
                        self.containerView.alpha = 1.0
                    })
                }
                
                return nil
            })
            
            return nil
        })
        
    }
    
    // MARK : PagerView Delegates
    
    func loadPageViewItem(imageView: UIImageView, page: Int) {
        
        printLog("loadPageViewItem > page : \(page)")
        
        guard let userInfo = self.friendUserInfo else {
            fatalError("FriendProfileViewController > loadPageViewItem > userInfo Error")
        }
        
        let imageName = userInfo.userid + "/" + Configuration.S3.PROFILE_IMAGE_NAME(page)
        let imageUrl = Configuration.S3.PROFILE_IMAGE_URL + imageName
        
        imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "default_profile"), options: .cacheMemoryOnly) {
            (image, error, cacheType, imageURL) in
        }
    }
    
    func onPageTapped(page: Int) {
        printLog("onPageTapped > page : \(page)")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let yOffset = self.scrollView.contentOffset.y
        let alpha = 1 - (yOffset / pagerView.frame.height)
        let halfOffsetY = yOffset * 0.5
        
        pagerView.alpha = alpha
        pagerViewOffsetY.constant = halfOffsetY
        backViewOffsetY.constant = -halfOffsetY
        stackViewOffsetY.constant = -halfOffsetY
    }
    
    // MARK : IBAction
    
    @IBAction func acceptButtonTapped(_ sender: Any) {
        
        printLog("acceptButtonTapped")
        
        guard let receiverId = UserInfoManager.sharedInstance.userInfo?.userid else {
            fatalError("FriendProfileViewController > acceptButtonTapped > receiverId Error")
        }
        
        guard let senderId = self.friendUserId else {
            fatalError("FriendProfileViewController > acceptButtonTapped > senderId Error")
        }
        
        guard let productId = self.productId else {
            fatalError("FriendProfileViewController > acceptButtonTapped > productId Error")
        }
        
        guard let receiverNickname = UserInfoManager.sharedInstance.userInfo?.nickname else {
            fatalError("FriendProfileViewController > acceptButtonTapped > receiverNickname Error")
        }
        
        guard let senderNickname = self.friendUserInfo?.nickname else {
            fatalError("FriendProfileViewController > acceptButtonTapped > senderNickname Error")
        }
        
        guard let productTitle = self.productInfo?.TitleKor else {
            fatalError("FriendProfileViewController > acceptButtonTapped > productTitle Error")
        }
        
        guard let receiveMail = ReceiveMail() else {
            fatalError("FriendProfileViewController > acceptButtonTapped > init ReceiveMail Error")
        }
        
        receiveMail.UserId = receiverId
        receiveMail.SenderId = senderId
        receiveMail.ProductId = productId
        receiveMail.ReceiverNickname = receiverNickname
        receiveMail.SenderNickname = senderNickname
        receiveMail.ProductTitle = productTitle
        receiveMail.IsRead = 1
        receiveMail.ProposeStatus = ProposeStatus.made.rawValue

        let timestamp = Date().iso8601
        
        if let mail = self.mail {
            receiveMail.UpdatedTime = mail.UpdatedTime
        } else {
            receiveMail.UpdatedTime = timestamp
        }
        receiveMail.ResponseTime = timestamp
        
        self.proposeStatusButton.setTitle("", for: .normal)
        ReceiveMailManager.sharedInstance.updateReceiveMail(mail: receiveMail).continueWith(/*executor: AWSExecutor.mainThread(),*/ block: {
            (task: AWSTask) -> Any! in
            
            if task.error == nil {
                self.printLog("acceptButtonTapped > Success")
            }
            
            DispatchQueue.main.async {
                self.proposeStatus = ProposeStatus(rawValue: (receiveMail.ProposeStatus!))!
                self.refreshLayout()
                
                self.alert(message: "\(senderNickname)님과 함께가기를 수락하였습니다", title: "함께가기 성공", completion: {
                    (action) -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: ReceiveMailManager.AddNotification), object: nil)
                })
            }
            
            return nil
        })
        
    }
    
    @IBAction func rejectButtonTapped(_ sender: Any) {
        
        printLog("rejectButtonTapped")
        
        guard let receiverId = UserInfoManager.sharedInstance.userInfo?.userid else {
            fatalError("FriendProfileViewController > rejectButtonTapped > receiverId Error")
        }
        
        guard let senderId = self.friendUserId else {
            fatalError("FriendProfileViewController > rejectButtonTapped > senderId Error")
        }
        
        guard let productId = self.productId else {
            fatalError("FriendProfileViewController > rejectButtonTapped > productId Error")
        }
        
        guard let receiverNickname = UserInfoManager.sharedInstance.userInfo?.nickname else {
            fatalError("FriendProfileViewController > rejectButtonTapped > receiverNickname Error")
        }
        
        guard let senderNickname = self.friendUserInfo?.nickname else {
            fatalError("FriendProfileViewController > rejectButtonTapped > senderNickname Error")
        }
        
        guard let productTitle = self.productInfo?.TitleKor else {
            fatalError("FriendProfileViewController > rejectButtonTapped > productTitle Error")
        }
        
        guard let receiveMail = ReceiveMail() else {
            fatalError("FriendProfileViewController > rejectButtonTapped > init ReceiveMail")
        }
        
        receiveMail.UserId = receiverId
        receiveMail.SenderId = senderId
        receiveMail.ProductId = productId
        receiveMail.ReceiverNickname = receiverNickname
        receiveMail.SenderNickname = senderNickname
        receiveMail.ProductTitle = productTitle
        receiveMail.IsRead = 1
        receiveMail.ProposeStatus = ProposeStatus.reject.rawValue
        
        let timestamp = Date().iso8601
        
        if let mail = self.mail {
            receiveMail.UpdatedTime = mail.UpdatedTime
        } else {
            receiveMail.UpdatedTime = timestamp
        }
        receiveMail.ResponseTime = timestamp
        
        self.proposeStatusButton.setTitle("", for: .normal)
        ReceiveMailManager.sharedInstance.updateReceiveMail(mail: receiveMail).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            if task.error == nil {
                self.printLog("acceptButtonTapped > Success")
            }
            
            DispatchQueue.main.async {
                self.proposeStatus = ProposeStatus(rawValue: (receiveMail.ProposeStatus!))!
                self.refreshLayout()
                
                self.alert(message: "\(senderNickname)님과 함께가기를 거절하였습니다", title: "함께가기 거절")
            }
            
            return nil
        })
        
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
