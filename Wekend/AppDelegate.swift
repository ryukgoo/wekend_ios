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
        
        ApplicationNavigator.shared.showLaunchScreen()
        registerNotificationCenter(application)
        
        // register Google Map
        GMSServices.provideAPIKey(Configuration.GOOGLE_API_KEY)
        
        // FBSDKApplicationDelegate initialize --> For What?????
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return AmazonClientManager.sharedInstance.didFinishLaunching(application: application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.reduce("") { $0 + String(format: "%02.2hhx", $1) }
        printLog("\(#function) data: \(deviceToken)")
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
        printLog("\(#function) userInfo: \(userInfo)")
        completionHandler(.newData)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        printLog(#function)
    }
    
    /*
     * For FaceBook AppLnk & KakaoLink
     * Not work
     */
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        printLog(#function)
        return false
    }
    
    /*
     * For FaceBook AppLnk & KakaoLink
     * Work HERE!!
     */
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        printLog(#function)
        return DeepLinker.handleDeepLink(url: url)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        printLog(#function)
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        printLog(#function)
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        printLog(#function)
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        
        printLog(#function)
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        if let _ = UserInfoManager.sharedInstance.userInfo {
            DeepLinker.checkDeepLink()
            NotificationParser.shared.displayNotification()
        } else {
            AmazonClientManager.sharedInstance.loadUserInfo { isAutoLogin in
                if isAutoLogin {
                    DispatchQueue.main.async {
                        ApplicationNavigator.shared.showMainViewController() { DeepLinker.checkDeepLink() }
                    }
                } else {
                    DispatchQueue.main.async { ApplicationNavigator.shared.showLoginViewController() }
                }
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        // unregister Store Transaction observer
//        SKPaymentQueue.default().remove()
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func registerNotificationCenter(_ application: UIApplication) {
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
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive respone: UNNotificationResponse, withCompletionHandler completionHandler : @escaping () -> Void) {
        printLog("userNotificationCenter delegate > response : \(respone)")
        
        // Else handle actions for other notification types...
        
        completionHandler()
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        print(#function)
        
        // Application is Active
        // slient push notification handle... TBD
        NotificationParser.shared.displayNotification()
        completionHandler([])
    }
}
