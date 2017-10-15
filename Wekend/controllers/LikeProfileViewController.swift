//
//  ProfileViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 4..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import KRWordWrapLabel

/*
 *
 */
@available(iOS 9.0, *)
class LikeProfileViewController: UIViewController, PagerViewDelegate, UIScrollViewDelegate {

    let minimumAlpha: CGFloat = 0.1
    
    // MARK: Properties
    
    var mail: SendMail?
    var friendUserId: String?
    var friendUserInfo: UserInfo?
    var productId: Int?
    var productInfo: ProductInfo?
    var proposeStatus: ProposeStatus = .none
    var isLoading: Bool = false
        
    // MARK: IBOutlet
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var pagerView: PagerView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nicknameStackView: UIStackView!
    @IBOutlet weak var ageStackView: UIStackView!
    @IBOutlet weak var phoneStackView: UIStackView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var descriptionLabel: KRWordWrapLabel!
    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var proposeButton: UIButton!
    @IBOutlet weak var containerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var pagerViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var stackViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn_icon_back_w"), style: .plain, target: self, action: #selector(self.backButtonTapped(_:)))
        navigationItem.leftBarButtonItem = backButton
        
        if let mail = self.mail {
            proposeStatus = ProposeStatus(rawValue: mail.ProposeStatus!)!
        } else {
            proposeStatus = .none
        }
        
        loadProfileInfo()
        loadProposeStatus()
        
        addNotificationObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.isStatusBarHidden = true
        
        var colors = [UIColor]()
        colors.append(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5))
        colors.append(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0))
        navigationController?.navigationBar.setGradientBackground(colors: colors)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.tintColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
    
    private func loadProfileInfo() {
        
//        startLoading()
        
        isLoading = true
        self.containerView.alpha = 0.0
        
        UserInfoManager.sharedInstance.getUserInfo(userId: friendUserId!).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let info = task.result else {
                fatalError("ProfileViewController > get Friend UserInfo Error")
            }
            
            self.friendUserInfo = info as? UserInfo
            
            ProductInfoManager.sharedInstance.getProductInfo(productId: self.productId!).continueWith(executor: AWSExecutor.mainThread(), block: {
                (productTask: AWSTask) -> Any! in
                
                guard let productInfo = productTask.result else {
                    fatalError("ProfileViewController > get ProductInfo Error")
                }
                
                self.productInfo = productInfo as? ProductInfo
                self.isLoading = false
                
                DispatchQueue.main.async {
                    self.initViews()
//                    self.endLoading()
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        self.containerView.alpha = 1.0
                    })
                }
                
                return nil
            })
            
            return nil
        })
    }
    
    private func loadProposeStatus() {
        
        printLog("loadProposeStatus start")
        
        guard let senderId = UserInfoManager.sharedInstance.userInfo?.userid else {
            fatalError("ProfileViewController > loadProposeStatus > get UserInfo Error")
        }
        
        guard let receiverId = self.friendUserId else {
            fatalError("ProfileViewController > loadProposeStatus > ReceiverId Error")
        }
        
        guard let productId = self.productId else {
            fatalError("ProfileViewController > loadProposeStatus > ProductId Error")
        }
        
        SendMailManager.sharedInstance.getSendMail(senderId: senderId, receiverId: receiverId, productId: productId).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let mail = task.result as? SendMail else {
                DispatchQueue.main.async {
                    self.updateProposeButton(status: ProposeStatus.none)
                }
                return nil
            }
            
            guard let status = ProposeStatus(rawValue: mail.ProposeStatus!) else {
                fatalError("ProfileViewController > loadProposeStatus > enum cast Error")
            }
            
            DispatchQueue.main.async {
                self.updateProposeButton(status: status)
            }
            
            return nil
        })
        
    }
    
    private func initViews() {
        
        guard let userInfo = self.friendUserInfo else {
            fatalError("ProfileViewController > get UserInfo Error")
        }
        
        let photos: Set<String>
        
        if userInfo.photos == nil {
            photos = Set<String>()
        } else {
            photos = userInfo.photos as! Set<String>
        }
        
        pagerView.delegate = self
        pagerView.pageCount = max(photos.count, 1)
        
        scrollView.delegate = self
        
        printLog("photos count : \(photos.count)")
        
        guard let birth = userInfo.birth as! Int! else {
            fatalError("ProfileViewController > userInfo age Error")
        }
        
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date)
        let year = components.year
        
        nicknameLabel.text = userInfo.nickname
        ageLabel.text = String(year! - birth) + "세"
        
        guard let productInfo = self.productInfo else {
            fatalError("ProfileViewController > getProductInfo Error")
        }
        
        descriptionLabel.text = productInfo.TitleKor! + "\n\n" + (productInfo.Description?.htmlToString)!
        descriptionLabel.sizeToFit()
        
        if let point = UserInfoManager.sharedInstance.userInfo?.balloon as! Int! {
            pointLabel.text = "보유포인트 : " + String(point) + "P"
        } else {
            pointLabel.text = "보유포인트 : " + String(0) + "P"
        }
        
        refreshLayout()
    }
    
    private func refreshLayout() {
        var scrollableHeight = pagerView.frame.height
        scrollableHeight += nicknameStackView.frame.height
        scrollableHeight += ageStackView.frame.height
        scrollableHeight += 27 // margin
        scrollableHeight += descriptionLabel.frame.height
        scrollableHeight += 20 // bottom margin
        
        switch proposeStatus {
        case .made:
            
            phoneLabel.text = friendUserInfo?.phone?.toPhoneFormat()
            phoneStackView.isHidden = false
            scrollableHeight += phoneLabel.frame.height
            
            break
        default:
            
            phoneStackView.isHidden = true
            
            break
        }
        
        containerViewHeight.constant = scrollableHeight
        backgroundHeight.constant = scrollableHeight - pagerView.frame.size.height
    }
    
    private func updateProposeButton(status: ProposeStatus) {
        
        printLog("updateProposeButton > status : \(status.rawValue)")
        
        proposeButton.setTitle(status.message(), for: .normal)
        
        switch status {
        case .none :
            proposeButton.isUserInteractionEnabled = true
            proposeButton.addTarget(self, action: #selector(proposeButtonTapped(_:)), for: .touchUpInside)
            
            break
        case .notMade :
            proposeButton.isUserInteractionEnabled = false
            break
        case .made :
            proposeButton.isUserInteractionEnabled = false
            break
        case .reject :
            
            proposeButton.isUserInteractionEnabled = false
            proposeButton.setTitle("함께가기 거절", for: .normal)
            
            break
        case .alreadyMade :
            proposeButton.isUserInteractionEnabled = false
            break
        case .delete :
            proposeButton.isUserInteractionEnabled = false
            break
        }
    }
    
    // MARK: Delegates
    
    func loadPageViewItem(imageView: UIImageView, page: Int) {
        printLog(#function)
        guard let userInfo = self.friendUserInfo else {
            fatalError("ProfileViewController > loadPageViewItem > userInfo Error")
        }
        
        let imageName = userInfo.userid + "/" + Configuration.S3.PROFILE_IMAGE_NAME(page)
        let imageUrl = Configuration.S3.PROFILE_IMAGE_URL + imageName
        
        imageView.downloadedFrom(link: imageUrl, defaultImage: #imageLiteral(resourceName: "default_profile"), contentMode: .scaleAspectFill, reload: true)
    }
    
    func onPageTapped(page: Int) {
        printLog("onPageTapped > page: \(page)")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = scrollView.contentOffset.y
        let alpha = 1 - (yOffset / pagerView.frame.size.height)
        let halfOffsetY = yOffset * 0.5
        
        pagerView.alpha = alpha
        pagerViewOffsetY.constant = halfOffsetY
        backViewOffsetY.constant = -halfOffsetY
        stackViewOffsetY.constant = -halfOffsetY
    }
    
    // MARK : Button click event
    
    /*
     * update sendMail DB -> SendMailEvent
     */
    func proposeButtonTapped(_ sender: Any) {
        printLog("proposeButtonTapped!!!!!")
        
        guard let receiverNickname = self.friendUserInfo?.nickname else {
            fatalError("ProfileViewController > proposeButtonTapped > receiverNickname Error")
        }
        
        let alertController = UIAlertController(title: "함께가기 신청\n",
                                                message: "\(receiverNickname)님에게 함께가기를 신청하시겠습니까?\n(500포인트가 차감됩니다)",
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "신청", style: .default, handler: { (action) in self.propose() })
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func propose() {
        guard let senderId = UserInfoManager.sharedInstance.userInfo?.userid else {
            fatalError("ProfileViewController > proposeButtonTapped > senderId Error")
        }
        
        guard let receiverId = self.friendUserId else {
            fatalError("ProfileViewcontroller > proposeButtonTapped > receiverId Error")
        }
        
        guard let productId = self.productId else {
            fatalError("ProfileViewController > proposeButtonTapped > productId Error")
        }
        
        guard let senderNickname = UserInfoManager.sharedInstance.userInfo?.nickname else {
            fatalError("ProfileViewController > proposeButtonTapped > senderNickname Error")
        }
        
        guard let receiverNickname = self.friendUserInfo?.nickname else {
            fatalError("ProfileViewController > proposeButtonTapped > receiverNickname Error")
        }
        
        guard let productTitle = self.productInfo?.TitleKor else {
            fatalError("ProfileViewController > proposeButtonTapped > ProductTitle Error")
        }
        
        let sendMail = SendMail()
        sendMail?.UserId = senderId
        sendMail?.ReceiverId = receiverId
        sendMail?.ProductId = productId
        sendMail?.ProposeStatus = ProposeStatus.notMade.rawValue
        sendMail?.SenderNickname = senderNickname
        sendMail?.ReceiverNickname = receiverNickname
        sendMail?.ProductTitle = productTitle
        sendMail?.IsRead = 0
        let timestamp = Date().iso8601
        sendMail?.UpdatedTime = timestamp
        sendMail?.ResponseTime = timestamp
        
        UserInfoManager.sharedInstance.consumePoint().continueWith(block: {
            (task: AWSTask) -> Any? in
            
            if task.error == nil {
                
                SendMailManager.sharedInstance.updateSendMail(mail: sendMail!).continueWith(executor: AWSExecutor.mainThread(), block: {
                    (task: AWSTask) -> Any! in
                    
                    if task.error == nil {
                        DispatchQueue.main.async {
                            self.proposeButton.setTitle(ProposeStatus.notMade.message(), for: .normal)
                            self.proposeButton.removeTarget(self, action: #selector(self.proposeButtonTapped(_:)), for: .touchUpInside)
                            
                            self.alert(message: "\(receiverNickname)에게 함께가기를 신청하였습니다", title: "함께가기신청", completion: {
                                (action) -> Void in
                                NotificationCenter.default.post(name: Notification.Name(rawValue: SendMailManager.AddNotification), object: nil)
                            })
                        }
                    }
                    
                    return nil
                })
                
            } else if task.error is PurchaseError {
                self.alert(message: "포인트를 충분하지 않습니다", title: "포인트 부족")
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

@available(iOS 9.0, *)
extension LikeProfileViewController: Observerable {
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(LikeProfileViewController.handleUpdatePointNotification(_:)),
                                               name: Notification.Name(rawValue: UserInfoManager.UpdatePointNotification),
                                               object: nil)
    }
    
    func handleUpdatePointNotification(_ notification: Notification) {
        guard let point = notification.userInfo![UserInfoManager.NotificationDataPoint] as? Int else {
            return
        }
        
        DispatchQueue.main.async {
            self.pointLabel.text = "보유포인트 : \(point)P"
        }
    }
}
