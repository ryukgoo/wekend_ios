//
//  AppDelegate.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 11. 22..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit
import StoreKit
import UserNotifications
import GoogleMaps
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static let WillEnterForeground = "com.entuition.wekend.applicationWillEnterForeground"
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        print("AppDelegate > application > didFinishLaunchingWithOptions Start")
        
        let storyboard = UIStoryboard(name: Constants.StoryboardName.LaunchScreen.rawValue, bundle: nil)
        let launchScreen = storyboard.instantiateViewController(withIdentifier: Constants.StoryboardName.LaunchScreen.identifier)
        
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        appdelegate.window!.rootViewController = launchScreen
        appdelegate.window!.makeKeyAndVisible()
        
        if #available(iOS 10.0, *) {
            
            printLog("didFinishLaunchingWithOptions > register remote notification")
            
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: {
                (granted, error) in
                
                if granted {
                    self.printLog("UNUserNotificationCenter is granted")
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                    
                } else {
                    self.printLog("UNUserNotificationCenter not granted")
                }
                
            })
        } else {
            // Fallback on earlier versions
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        
        // register Google Map
        GMSServices.provideAPIKey(Configuration.GOOGLE_API_KEY)
        
        // FBSDKApplicationDelegate initialize
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return AmazonClientManager.sharedInstance.didFinishLaunching(application: application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        printLog("didRegisterForRemoteNotificationWithDeviceToken come come come")
        
        let token = deviceToken.reduce("") { $0 + String(format: "%02.2hhx", $1) }
        printLog("didRegisterForRemoteNotificationsWithDeviceToken > deviceToken : \(token)")
        
        // Forward the token to your provider, using a custom method
        UserDefaults.RemoteNotification.set(token, forKey: .deviceToken)
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // The token is not currently available
        printLog("Remote notification support is unavailable due to error: \(error.localizedDescription)")
        
    }
    
    /*
     * receive remote notification from server..
     * update data from notification..
     */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        printLog("application > didReceiveRemoteNotification > comes Messages : \(userInfo)")
        
        guard let type = userInfo[NotificationDataKey.type.rawValue] as? String,
            let productId = userInfo[NotificationDataKey.productId.rawValue] as? Int,
            let userId = userInfo[NotificationDataKey.userId.rawValue] as? String else {
            printLog("didReceiveRemoteNotification > data from RemoteNotification Error")
            return
        }
        
        printLog("didReceiveRemoteNotification > userId : \(userId)")
        printLog("didReceiveRemoteNotification > type : \(type), productId : \(productId)")
        
        guard let notificationKey = UserDefaults.NotificationCount.ValueDefaultKey(rawValue: type) else {
            printLog("didReceiveRemoteNotification > notificationType Error")
            return
        }
        
        let applicationState = application.applicationState
        
        if applicationState == .active {
            switch notificationKey {
            case .like:
                var likeBadgeCount = UserDefaults.NotificationCount.integer(forKey: .like)
                likeBadgeCount += 1
                UserDefaults.NotificationCount.set(likeBadgeCount, forKey: .like)
                LikeDBManager.sharedInstance.comeNewNotification(id: productId)
                break
                
            case .receiveMail:
                var newCount = UserDefaults.NotificationCount.integer(forKey: .receiveMail)
                newCount += 1
                UserDefaults.NotificationCount.set(newCount, forKey: .receiveMail)
                ReceiveMailManager.sharedInstance.comeNewNotification()
                break
                
            case .sendMail:
                var newCount = UserDefaults.NotificationCount.integer(forKey: .sendMail)
                newCount += 1
                UserDefaults.NotificationCount.set(newCount, forKey: .sendMail)
                SendMailManager.sharedInstance.comeNewNotification()
                break
            }
        }
        
        let newLikeCount = UserDefaults.NotificationCount.integer(forKey: .like)
        let newReceiveMailCount = UserDefaults.NotificationCount.integer(forKey: .receiveMail)
        let newSendMailCount = UserDefaults.NotificationCount.integer(forKey: .sendMail)
        
        UIApplication.shared.applicationIconBadgeNumber = newLikeCount + newReceiveMailCount + newSendMailCount
        
        completionHandler(.newData)
    }
    
    /*
     * For FaceBook AppLnk & KakaoLink
     */
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        if KLKTalkLinkCenter.shared().isTalkLinkCallback(url) {
            let params = url.query
            print("params : \(String(describing: params))")
            self.window?.rootViewController?.alert(message: "카카오링크 메시지 액션\n\(String(describing: params))")
            return true
        } else {
            return FBSDKApplicationDelegate.sharedInstance().application(
                application,
                open: url,
                sourceApplication: sourceApplication,
                annotation: annotation)
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if KLKTalkLinkCenter.shared().isTalkLinkCallback(url) {
            let params = url.query
            print("params : \(String(describing: params))")
            self.window?.rootViewController?.alert(message: "카카오링크 메시지 액션\n\(String(describing: params))")
            return true
        }
        return false
    }

    func applicationWillResignActive(_ application: UIApplication) {
        
        printLog("applicationWillResignActive")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
        printLog("applicationDidEnterBackground")
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
        printLog("applicationWillEnterForeground")
        
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
        printLog("applicationDidBecomeActive")
        
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        refreshNotification()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        // unregister Store Transaction observer
//        SKPaymentQueue.default().remove()
    }
    
    func refreshNotification() {
        guard let userId = UserInfoManager.sharedInstance.userInfo?.userid else {
            
            printLog("applicationDidBecomeActive > userId is nil")
            
            return
        }
        
        let likeCount = UserDefaults.NotificationCount.integer(forKey: .like)
        let receiveCount = UserDefaults.NotificationCount.integer(forKey: .receiveMail)
        let sendCount = UserDefaults.NotificationCount.integer(forKey: .sendMail)
        
        printLog("applicationDidBecomeActive > likeCount : \(likeCount)")
        printLog("applicationDidBecomeActive > receiveCount : \(receiveCount)")
        printLog("applicationDidBecomeActive > sendCount : \(sendCount)")
        
        UserInfoManager.sharedInstance.getOwnedUserInfo(userId: userId).continueWith(block:  {
            (task: AWSTask) -> Any? in
            
            guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
                self.printLog("applicationDidBecomeActive > userInfo is nil")
                return nil
            }
            
            self.printLog("applicationDidBecomeActive > NewLikeCount : \(userInfo.NewLikeCount)")
            self.printLog("applicationDidBecomeActive > NewReceiveCount : \(userInfo.NewReceiveCount)")
            self.printLog("applicationDidBecomeActive > NewSendCount : \(userInfo.NewSendCount)")
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: AppDelegate.WillEnterForeground),
                                            object: nil,
                                            userInfo: nil)
            
            if userInfo.NewLikeCount > likeCount {
                NotificationCenter.default.post(name: Notification.Name(rawValue: LikeDBManager.RefreshNotification),
                                                object: nil, userInfo: nil)
            }
            
            if userInfo.NewReceiveCount > receiveCount {
                NotificationCenter.default.post(name: Notification.Name(rawValue: ReceiveMailManager.NewRemoteNotification),
                                                object: nil, userInfo: nil)
            }
            
            if userInfo.NewSendCount > sendCount {
                NotificationCenter.default.post(name: Notification.Name(rawValue: SendMailManager.NewRemoteNotification),
                                                object: nil, userInfo: nil)
            }
            
            return nil
        })
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive respone: UNNotificationResponse, withCompletionHandler completionHandler : @escaping () -> Void) {
        
        printLog("userNotificationCenter delegate > response : \(respone)")
        
        // Else handle actions for other notification types...
        
        completionHandler()
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print(#function)
        
        // slient push notification handle... TBD
        refreshNotification()
        
        completionHandler([])
    }
}
