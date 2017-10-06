//
//  MainViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 13..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class MainViewController: UITabBarController {

    static var isFirstLoad: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (MainViewController.isFirstLoad) {
            
            printLog("MainViewController.isFirstLoad : \(MainViewController.isFirstLoad)")
            
            MainViewController.isFirstLoad = false
            showGuide()
        }
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.displayTabbarBadge),
                                               name: Notification.Name(AppDelegate.WillEnterForeground), object: nil)
    }
    
    func handleLikeRemoteNotification(_ notification: Notification) {
        
        guard let likeTab = tabBar.items?[1] else {
            return
        }
        
        let newCount = UserDefaults.NotificationCount.integer(forKey: .like)
        likeTab.badgeValue = newCount == 0 ? nil : String(newCount)
    }
    
    func handleMailNotification(_ notification: Notification) {
        
        printLog("handleMailNotification > notification : \(notification.description)")
        
        guard let mailTab = tabBar.items?[2] else {
            return
        }
        
        let receiveCount = UserDefaults.NotificationCount.integer(forKey: .receiveMail)
        let sendCount = UserDefaults.NotificationCount.integer(forKey: .sendMail)
        let badgeCount = receiveCount + sendCount
        
        mailTab.badgeValue = badgeCount == 0 ? nil : String(badgeCount)
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
            displayTabbarBadge()
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
        
        guard let drawerViewController: DrawerViewController = DrawerViewController.storyboardInstance() else {
            fatalError("MainViewController > onDrawerTapped > drawerVC from storyBoard Error")
        }
        
        drawerViewController.delegate = self
        
        view.addSubview(drawerViewController.view)
        addChildViewController(drawerViewController)
        
        drawerViewController.view.layoutIfNeeded()
        drawerViewController.slideIn()
    }
    
    func slideMenuItemSelectedAtIndex(_ index: Int) {
        
    }
    
    func onCloseSlideMenu() {
        
    }
}

extension MainViewController {
    
    func showGuide() {
    
        printLog("UserDefaults.Account.bool(forKey: .isNoMoreGuide) : \(UserDefaults.Account.bool(forKey: .isNoMoreGuide))")
        
        if (UserDefaults.Account.bool(forKey: .isNoMoreGuide)) { return }
        
        if let presentingVC = self.presentedViewController as? UIAlertController {
            printLog("presenting ViewController is dismissed")
            presentingVC.dismiss(animated: false, completion: {
                let guideVC: GuideViewController = GuideViewController.nibInstance()
                guideVC.modalPresentationStyle = .overCurrentContext
                guideVC.modalTransitionStyle = .crossDissolve
                
                self.present(guideVC, animated: true, completion: nil)
            })
        } else {
            let guideVC: GuideViewController = GuideViewController.nibInstance()
            guideVC.modalPresentationStyle = .overCurrentContext
            guideVC.modalTransitionStyle = .crossDissolve
            
            self.present(guideVC, animated: true, completion: nil)
        }
        
    }
    
}
