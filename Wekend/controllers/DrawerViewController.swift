//
//  DrawerViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 13..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import MessageUI

protocol SlideMenuDelegate {
    func slideMenuItemSelectedAtIndex(_ index : Int)
    func onCloseSlideMenu()
}

protocol Slidable {
    func slideIn()
    func slideOut()
}

class DrawerViewController: UIViewController {
    
    deinit {
        removeNotificationObservers()
        printLog("deinit")
    }
    
    // MARK: menuString -> to enum
    let menuString = ["공지사항", "도움말", "프로필", "고객센터", "알림설정", "로그아웃"]
    let menuIcons : [UIImage] = [#imageLiteral(resourceName: "img_icon_noti_n"), #imageLiteral(resourceName: "img_icon_help_n"), #imageLiteral(resourceName: "img_icon_profile_n"), #imageLiteral(resourceName: "img_icon_cc_n"), #imageLiteral(resourceName: "img_icon_setting_n"), #imageLiteral(resourceName: "img_icon_logout_n")]
    
    // MARK: Delegate of the SlideMenuDelegate
    
    var delegate : SlideMenuDelegate?
    
    // MARK: IBOutlet
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var overlayCloseButton: UIButton!
    @IBOutlet weak var menuTableView: UITableView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileHeader: UIView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var pointLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initViews()
        initTableView()
        addNotificationObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Initialize
    
    func initViews() {
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
            fatalError("DrawerViewController > viewDidLoad > userInfo Error")
        }
        
        let imageName = userInfo.userid + "/" + Configuration.S3.PROFILE_IMAGE_NAME(0)
        let imageUrl  = Configuration.S3.PROFILE_IMAGE_URL + imageName
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onProfileImageTapped(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGestureRecognizer)
        
        let defaultImage : UIImage
        if userInfo.gender == UserInfo.RawValue.GENDER_MALE {
            defaultImage = #imageLiteral(resourceName: "img_bg_thumb_s_default_male")
        } else {
            defaultImage = #imageLiteral(resourceName: "img_bg_thumb_s_default_Female")
        }
        
        profileImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: defaultImage, options: .cacheMemoryOnly) {
            (image, error, cacheType, imageURL) in
            self.profileImageView.toMask(mask: #imageLiteral(resourceName: "img_bg_thumb_default_2"))
        }
        
        nicknameLabel.text = userInfo.nickname!
        usernameLabel.text = userInfo.username!
        
        pointLabel.text = "보유포인트 : \(userInfo.balloon!)P"
        
        menuTableView.separatorColor = UIColor.clear
    }
    
    // MARK: Button Click Event
    
    @IBAction func onCloseButtonTapped(_ sender: Any) {
        slideOut()
    }
    
    func onProfileImageTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        
        performSegue(withIdentifier: MyProfileViewController.className, sender: nil)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == NoticeTableViewController.className {
            
            guard let navigationController = segue.destination as? UINavigationController else {
                return
            }
            
            guard let noticeTableViewController = navigationController.topViewController as? NoticeTableViewController else {
                return
            }
            
            noticeTableViewController.noticeType = sender as? String
        }
    }

}

// MARK: -UITableViewDelegate, UITableViewDataSource

extension DrawerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func initTableView() {
        menuTableView.delegate = self
        menuTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(for: indexPath) as DrawerMenuTableViewCell
        
        cell.menuImageView.image = menuIcons[indexPath.row]
        cell.menuLabel.text = menuString[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.slideMenuItemSelectedAtIndex(indexPath.row)
        
        guard let cell = tableView.cellForRow(at: indexPath) else {
            fatalError("DrawerViewController > tableView > Cell Error")
        }
        
        switch indexPath.row {
            
        case 0:
            performSegue(withIdentifier: NoticeTableViewController.className, sender: "Notice")
            break
            
        case 1:
            
            let guideVC: GuideViewController = GuideViewController.nibInstance()
            guideVC.modalPresentationStyle = .overCurrentContext
            guideVC.modalTransitionStyle = .crossDissolve
            guideVC.isShowButtons = false
            
            self.present(guideVC, animated: true, completion: nil)
            
            break
            
        case 2:
            performSegue(withIdentifier: MyProfileViewController.className, sender: cell)
            break
            
        case 3:
            sendMail()
            break
            
        case 4:
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                if UIApplication.shared.canOpenURL(appSettings) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                    } else {
                        // Fallback on earlier versions
                        UIApplication.shared.openURL(appSettings)
                    }
                }
            }
            break
            
        case 5:
            // Logout
            
            let alertController = UIAlertController(title: "로그아웃하시겠습니까?",
                                                    message: "로그아웃하시면\n로그인화면으로 돌아갑니다",
                                                    preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
            let okAction = UIAlertAction(title: "확인", style: .default, handler: {
                (action) in
                AmazonClientManager.sharedInstance.devIdentityProvider?.logout()
            })
            
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            
            self.present(alertController, animated: true, completion: nil)
            
            break
            
        default:
            performSegue(withIdentifier: NoticeTableViewController.className, sender: cell)
            break
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuString.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

// MARK: -MFMailCompseViewController

extension DrawerViewController: MFMailComposeViewControllerDelegate {
    
    func sendMail() {
        if !MFMailComposeViewController.canSendMail() {
            printLog("sendMail > MFMailCompseViewController > canSendMail false")
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        composeVC.setToRecipients(["entuitiondevelop@gmail.com"])
        composeVC.setSubject("고객센터 문의메일")
        composeVC.setMessageBody("계정 이메일:\n문의내용:", isHTML: false)
        
        present(composeVC, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension DrawerViewController: Observerable {
    
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(DrawerViewController.handleUpdatePointNotification(_:)),
                                               name: Notification.Name(rawValue: UserInfoManager.UpdatePointNotification),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(DrawerViewController.handleUpdateUserInfoNotification(_:)),
                                               name: Notification.Name(rawValue: UserInfoManager.UpdateUserInfoNotification),
                                               object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name:Notification.Name(rawValue: UserInfoManager.UpdatePointNotification),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: UserInfoManager.UpdateUserInfoNotification),
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
    
    func handleUpdateUserInfoNotification(_ notification: Notification) {
        printLog("handleUpdateUserInfoNotification")
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
            fatalError("DrawerViewController > viewDidLoad > userInfo Error")
        }
        
        let defaultImage : UIImage
        if userInfo.gender == UserInfo.RawValue.GENDER_MALE {
            defaultImage = #imageLiteral(resourceName: "img_bg_thumb_s_default_male")
        } else {
            defaultImage = #imageLiteral(resourceName: "img_bg_thumb_s_default_Female")
        }
        
        let imageName = userInfo.userid + "/" + Configuration.S3.PROFILE_IMAGE_NAME(0)
        let imageUrl  = Configuration.S3.PROFILE_IMAGE_URL + imageName
        
        profileImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: defaultImage, options: .cacheMemoryOnly) {
            (image, error, cacheType, imageURL) in
            self.profileImageView.toMask(mask: #imageLiteral(resourceName: "img_bg_thumb_default_2"))
        }
    }
}

extension DrawerViewController: Slidable {
    
    func slideIn() {
        
        let screenWidth = UIScreen.main.bounds.width
        let containerWidth = containerView.frame.size.width
        let containerHeight = containerView.frame.size.height
        
        self.containerView.frame = CGRect(x: screenWidth, y: 0, width: containerWidth, height: containerHeight)
        self.overlayCloseButton?.backgroundColor = UIColor(red:0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        
        UIView.animate(withDuration: 0.3, animations: {
            () -> Void in
            self.containerView.frame = CGRect(x: screenWidth - containerWidth, y: 0, width: containerWidth, height: containerHeight)
            self.overlayCloseButton?.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4)
        })
    }
    
    func slideOut() {
        
        let screenWidth = UIScreen.main.bounds.width
        let containerWidth = containerView.frame.size.width
        let containerHeight = containerView.frame.size.height
        
        UIView.animate(withDuration: 0.3, animations: {
            () -> Void in
            self.containerView.frame = CGRect(x: screenWidth, y: 0, width: containerWidth, height: containerHeight)
            self.overlayCloseButton?.backgroundColor = UIColor(red:0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        }, completion: { (finished) -> Void in
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
            
            self.delegate?.onCloseSlideMenu()
        })
    }
}
