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
    
    deinit {
        removeNotificationObservers()
        print("\(className) > \(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self
        
        tabBar.tintColor = UIColor(netHex: Constants.ColorInfo.MAIN)
        
        guard let userInfo = UserInfoRepository.shared.userInfo else {
            fatalError("\(className) > \(#function) > get UserInfo Error")
        }
        
        guard let tabArray = self.tabBar.items else {
            fatalError("\(className) > \(#function) > tabBar items Error")
        }
        
        let likeTab = tabArray[1]
        likeTab.badgeValue = userInfo.NewLikeCount == 0 ? nil : String(userInfo.NewLikeCount)
        
        let mailCount = userInfo.NewSendCount + userInfo.NewReceiveCount
        let mailTab = tabArray[2]
        mailTab.badgeValue = mailCount == 0 ? nil : String(mailCount)
        
        addNotificationObservers()
        UserInfoRepository.shared.registerEndpoint()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if (MainViewController.isFirstLoad) {
            print("\(className) > \(#function) > isFirstLoad : \(MainViewController.isFirstLoad)")
            MainViewController.isFirstLoad = false
            showGuide()
        }
    }
    
    func displayTabbarBadge() {
        
        guard let tabArray = self.tabBar.items else {
            fatalError("\(className) > \(#function) > tabBar items Error")
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
        print("\(className) > \(#function) > segue.identifier : \(String(describing: segue.identifier))")
    }

}

// MARK: -Notification Observers
extension MainViewController {
    
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleLikeRemoteNotification(_:)),
                                               name: Notification.Name(rawValue: LikeNotification.New),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleMailNotification(_:)),
                                               name: Notification.Name(rawValue: MailNotification.Receive.New),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.handleMailNotification(_:)),
                                               name: Notification.Name(MailNotification.Send.New),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MainViewController.displayTabbarBadge),
                                               name: Notification.Name(AppDelegate.WillEnterForeground),
                                               object: nil)
    }
    
    func removeNotificationObservers() {
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: LikeNotification.New),
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: MailNotification.Receive.New),
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name(MailNotification.Send.New),
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name(AppDelegate.WillEnterForeground),
                                                  object: nil)
    }
    
    func handleLikeRemoteNotification(_ notification: Notification) {
        
        guard let likeTab = tabBar.items?[1] else { return }
        
        let newCount = UserDefaults.NotificationCount.integer(forKey: .like)
        likeTab.badgeValue = newCount == 0 ? nil : String(newCount)
    }
    
    func handleMailNotification(_ notification: Notification) {
        
        print("\(className) > \(#function) > notification : \(notification.description)")
        
        guard let mailTab = tabBar.items?[2] else { return }
        
        let receiveCount = UserDefaults.NotificationCount.integer(forKey: .receiveMail)
        let sendCount = UserDefaults.NotificationCount.integer(forKey: .sendMail)
        let badgeCount = receiveCount + sendCount
        
        mailTab.badgeValue = badgeCount == 0 ? nil : String(badgeCount)
    }
    
}

// MARK: -UITabBarControllerDelegate

extension MainViewController: UITabBarControllerDelegate {
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print("\(className) > \(#function) > viewController : \(viewController.className)")
        guard let selectedType = NavigationType(rawValue: selectedIndex) else {
            fatalError("\(className) > \(#function) > no viewController Title")
        }
        
        switch selectedType {
            
        case .campaign:
            
            break
            
        case .like:
            guard let userInfo = UserInfoRepository.shared.userInfo else { return }
            userInfo.NewLikeCount = 0
            UserInfoRepository.shared.updateUser(info: userInfo) { _ in }
            UserDefaults.NotificationCount.set(0, forKey: .like)
            displayTabbarBadge()
            break
            
        case .mail:
            guard let userInfo = UserInfoRepository.shared.userInfo else { return }
            userInfo.NewSendCount = 0
            userInfo.NewReceiveCount = 0
            UserInfoRepository.shared.updateUser(info: userInfo) { _ in }
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
        
        print("\(className) > \(#function) > shouldSelect : \(selectedIndex)")
        
        guard let previousType = NavigationType(rawValue: selectedIndex) else { return false }
        
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
            fatalError("\(className) > \(#function) > drawerVC from storyBoard Error")
        }
        
        drawerViewController.delegate = self
        
        view.addSubview(drawerViewController.view)
        addChildViewController(drawerViewController)
        
        drawerViewController.view.layoutIfNeeded()
        drawerViewController.slideIn()
    }
    
    func slideMenuItemSelectedAtIndex(_ index: Int) { }
    
    func onCloseSlideMenu() { }
}

extension MainViewController {
    
    func showGuide() {
    
        print("\(className) > \(#function) > isNoMoreGuide : \(UserDefaults.Account.bool(forKey: .isNoMoreGuide))")
        
        if (UserDefaults.Account.bool(forKey: .isNoMoreGuide)) { return }
        
        if let presentingVC = self.presentedViewController as? UIAlertController {
            presentingVC.dismiss(animated: false, completion: { self.presentGuide() })
        } else {
            presentGuide()
        }
    }
    
    private func presentGuide() {
        let guideVC: GuideViewController = GuideViewController.nibInstance()
        guideVC.modalPresentationStyle = .overCurrentContext
        guideVC.modalTransitionStyle = .crossDissolve
        
        self.present(guideVC, animated: true, completion: nil)
    }
    
}
