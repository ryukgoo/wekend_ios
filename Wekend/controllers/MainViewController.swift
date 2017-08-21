//
//  MainViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 13..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class MainViewController: UITabBarController {

    var overlayBackground: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        printLog("MainViewController > viewDidLoad")
        
        delegate = self
        
        tabBar.tintColor = UIColor(netHex: Constants.ColorInfo.MAIN)
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
            printLog("viewDidLoad > get UserInfo Error")
            return
        }
        
        guard let tabArray = self.tabBar.items else {
            printLog("tabBarController > tabBar items Error")
            return
        }
        
        let likeTab = tabArray[1]
        likeTab.badgeValue = userInfo.NewLikeCount == 0 ? nil : String(userInfo.NewLikeCount)
        
        let mailCount = userInfo.NewSendCount + userInfo.NewReceiveCount
        let mailTab = tabArray[2]
        mailTab.badgeValue = mailCount == 0 ? nil : String(mailCount)
        
        addNotificationObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func displayTabbarBadge() {
        
        guard let tabArray = self.tabBar.items else {
            printLog("tabBarController > tabBar items Error")
            return
        }
        
        let newLikeCount = UserDefaults.NotificationCount.integer(forKey: .like)
        let newReceiveMailCount = UserDefaults.NotificationCount.integer(forKey: .receiveMail)
        let newSendMailCount = UserDefaults.NotificationCount.integer(forKey: .sendMail)
        
        let likeTab = tabArray[1]
        likeTab.badgeValue = newLikeCount == 0 ? nil : String(newLikeCount)
        
        let mailTab = tabArray[2]
        let mailCount = newReceiveMailCount + newSendMailCount
        mailTab.badgeValue = mailCount == 0 ? nil : String(mailCount)
        
        UIApplication.shared.applicationIconBadgeNumber = newLikeCount + newReceiveMailCount + newSendMailCount
        
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        printLog("prepare > segue.identifier : \(String(describing: segue.identifier))")
    }

}

// MARK: -Observerable

extension MainViewController: Observerable {
    
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleLikeRemoteNotification(_:)),
                                               name: Notification.Name(rawValue: LikeDBManager.NewRemoteNotification),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleMailNotification(_:)),
                                               name: Notification.Name(rawValue: ReceiveMailManager.NewRemoteNotification),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleMailNotification(_:)),
                                               name: Notification.Name(SendMailManager.NewRemoteNotification),
                                               object: nil)
    }
    
    func handleLikeRemoteNotification(_ notification: Notification) {
        
        guard let likeTab = tabBar.items?[1] else {
            return
        }
        
        guard let newCount = notification.userInfo![LikeDBManager.NotificationDataCount] as? Int else {
            return
        }
        
        likeTab.badgeValue = String(newCount)
    }
    
    func handleMailNotification(_ notification: Notification) {
        
        printLog("handleMailNotification > notification : \(notification.description)")
        
        guard let mailTab = tabBar.items?[2] else {
            return
        }
        
        let receiveCount = UserDefaults.NotificationCount.integer(forKey: .receiveMail)
        let sendCount = UserDefaults.NotificationCount.integer(forKey: .sendMail)
        let badgeCount = receiveCount + sendCount
        
        if badgeCount > 0 {
            mailTab.badgeValue = String(badgeCount)
        }
    }
    
}

// MARK: -UITabBarControllerDelegate

extension MainViewController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        printLog("didSelect > selectedIndex : \(selectedIndex)")
        guard let selectedType = NavigationType(rawValue: selectedIndex) else {
                fatalError("MainViewController > tabBarController > no viewController Title")
        }
        
        switch selectedType {
            
        case .campaign:
            break
            
        case .like:
            UserInfoManager.sharedInstance.clearNotificationCount(selectedType).continueWith(block: {
                task -> Any! in return nil
            })
            UserDefaults.NotificationCount.set(0, forKey: .like)
            displayTabbarBadge()
            break
            
        case .mail:
            UserInfoManager.sharedInstance.clearNotificationCount(selectedType).continueWith(block: {
                task -> Any! in return nil
            })
            UserDefaults.NotificationCount.set(0, forKey: .receiveMail)
            UserDefaults.NotificationCount.set(0, forKey: .sendMail)
            self.displayTabbarBadge()
            break
            
        case .drawer:
            break
        default:
            break
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        printLog("tabBarController > shouldSelect : \(selectedIndex)")
        
        guard let previousType = NavigationType(rawValue: selectedIndex) else {
            printLog("tabConroller > navigationType Error")
            fatalError("MainViewController > tabBarController > no viewController Title")
        }
        
        guard let navigationController = viewController as? UINavigationController else {
            // Goto Drawer
            onDrawerTapped(self)
            return false
        }
        
        if selectedIndex == previousType.rawValue {
            switch previousType {
            case .campaign:
                if let campaignTableViewController = navigationController.topViewController as? CampaignTableViewController {
                    campaignTableViewController.scrollToTop(animated: true)
                }
                return true
            case .like:
                if let likeTableViewController = navigationController.topViewController as? LikeTableViewController {
                    likeTableViewController.scrollToTop(animated: true)
                }
                return true
            case .mail:
                if let mailTableViewController = navigationController.topViewController as? MailBoxViewController {
                    mailTableViewController.scrollToTop(animated: true)
                }
                return true
            case .store:
                return true
            case .drawer:
                return false
            }
        }
        
        return true
    }
}

extension MainViewController: SlideMenuDelegate {
    
    // MARK: -DrawViewController
    
    func onDrawerTapped(_ sender: Any) {
        
        overlayBackground = UIView(frame: self.view.frame)
        overlayBackground?.backgroundColor = UIColor.clear
        self.view.addSubview(overlayBackground!)
        
        let identifier = DrawerViewController.className
        
        guard let drawerViewController = self.storyboard!.instantiateViewController(withIdentifier: identifier) as? DrawerViewController else {
            fatalError("MainViewController > onDrawerTapped > drawerVC from storyBoard Error")
        }
        
        drawerViewController.delegate = self
        
        view.addSubview(drawerViewController.view)
        addChildViewController(drawerViewController)
        
        drawerViewController.view.layoutIfNeeded()
        
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        
        drawerViewController.view.frame = CGRect(x: screenWidth, y: 0, width: screenWidth, height: screenHeight);
        
        UIView.animate(withDuration: 0.3, animations: {
            () -> Void in
            drawerViewController.view.frame = CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
        })
        
        UIView.animate(withDuration: 0.3, animations: {
            () -> Void in
            self.overlayBackground?.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.4)
        })
    }
    
    func slideMenuItemSelectedAtIndex(_ index: Int) {
        
    }
    
    func onCloseSlideMenu() {
        
        UIView.animate(withDuration: 0.3, animations: {
            () -> Void in
            self.overlayBackground?.backgroundColor = UIColor(red:0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        }, completion: {
            (finished) -> Void in
            self.overlayBackground?.removeFromSuperview()
        })
        
        overlayBackground?.removeFromSuperview()
    }
}
