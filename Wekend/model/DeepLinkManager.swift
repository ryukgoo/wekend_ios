//
//  DeepLinkManager.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 10. 18..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import AWSCore

let DeepLinker = DeepLinkManager()

class DeepLinkManager {
    fileprivate init() {}
    
    private var deepLinkType: DeepLinkType?
    
    func handleDeepLink(url: URL) -> Bool {
        print(#function)
        deepLinkType = DeepLinkParser.shared.parseDeepLink(url)
        return deepLinkType != nil
    }
    
    func checkDeepLink() {
        print(#function)
        guard let deepLinkType = deepLinkType else { return }
        
        DeepLinkNavigator.shared.proceedToDeepLink(deepLinkType)
        self.deepLinkType = nil
    }
}

class DeepLinkParser {
    
    static let shared = DeepLinkParser()
    private init() {}
    
    func parseDeepLink(_ url: URL) -> DeepLinkType? {
        
        var result: String?
        
        if KLKTalkLinkCenter.shared().isTalkLinkCallback(url) {
            result = parseKakaoLink(url)
        } else {
            result = parseFacebookLink(url)
        }
        
        guard let productId = result else { return nil }
        
        return DeepLinkType.detail(id: Int(productId)!)
    }
    
    private func parseKakaoLink(_ url: URL) -> String? {
        if let params = url.query {
            let paramsArr = params.components(separatedBy: "=")
            if paramsArr[0] == "productId" {
                return paramsArr[1]
            }
        }
        return nil
    }
    
    private func parseFacebookLink(_ url: URL) -> String? {
        if let bfurl = BFURL.init(url: url).targetURL {
            if let queryString = bfurl.query {
                let queryStringArr = queryString.components(separatedBy: "&")
                for infoSet in queryStringArr {
                    let keyValue = infoSet.components(separatedBy: "=")
                    if keyValue[0] == "productId" {
                        return keyValue[1]
                    }
                }
            }
        }
        return nil
    }
}

class DeepLinkNavigator {
    
    static let shared = DeepLinkNavigator()
    private init() {}
    
    func proceedToDeepLink(_ type: DeepLinkType) {
        switch type {
        case .detail(id: let productId):
            presentDetail(productId)
            break
        }
    }
    
    private func presentDetail(_ id: Int) {
        guard let detailVC: CampaignViewController = CampaignViewController.storyboardInstance(from: "SubItems") else {
            fatalError()
        }
        
        detailVC.productId = id
        
        if let presentedVC = UIApplication.topViewController()?.presentedViewController as? UIAlertController {
            presentedVC.dismiss(animated: false, completion: {
                UIApplication.topViewController()?.present(UINavigationController(rootViewController: detailVC),
                                                           animated: true, completion: nil)
            })
        } else {
            UIApplication.topViewController()?.present(UINavigationController(rootViewController: detailVC),
                                                       animated: true, completion: nil)
        }
    }
}

class ApplicationNavigator {
    static let shared = ApplicationNavigator()
    private init() {}
    
    func showLaunchScreen() {
        let storyboard = UIStoryboard(name: Constants.StoryboardName.LaunchScreen.rawValue, bundle: nil)
        let launchScreen = storyboard.instantiateViewController(withIdentifier: Constants.StoryboardName.LaunchScreen.identifier)
        
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        appdelegate.window!.rootViewController = launchScreen
        appdelegate.window!.makeKeyAndVisible()
    }
    
    func showLoginViewController() {
        let loginStoryBoard = Constants.StoryboardName.Login
        let loginboard = UIStoryboard(name: loginStoryBoard.rawValue, bundle: nil)
        
        guard let loginVC = loginboard.instantiateViewController(withIdentifier: loginStoryBoard.identifier) as? UINavigationController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                fatalError("AmazonClientManager > didFinishLaunching > get VC and AppDelegate Error")
        }
        appDelegate.window!.rootViewController = loginVC
        appDelegate.window!.makeKeyAndVisible()
    }
    
    func showMainViewController(completion: @escaping () -> Void) {
        let mainStoryboard = Constants.StoryboardName.Main
        let storyboard = UIStoryboard(name: mainStoryboard.rawValue, bundle: nil)
        
        guard let mainVC = storyboard.instantiateViewController(withIdentifier: mainStoryboard.identifier) as? MainViewController,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                fatalError("AmazonClientManager > didFinishLaunching > get MainVC and AppDelegate Error")
        }
        
        appDelegate.window!.rootViewController = mainVC
        appDelegate.window!.makeKeyAndVisible()
        completion()
    }
}

class NotificationParser {
    
    static let shared = NotificationParser()
    private init() {}
    
    func displayNotification() {
        
        guard let userId = UserInfoManager.shared.userInfo?.userid else {
            print("\(#function) > userId is nil")
            return
        }
        
        let likeCount = UserDefaults.NotificationCount.integer(forKey: .like)
        let receiveCount = UserDefaults.NotificationCount.integer(forKey: .receiveMail)
        let sendCount = UserDefaults.NotificationCount.integer(forKey: .sendMail)
        
        UserInfoManager.shared.getOwnedUserInfo(userId: userId).continueWith(block:  {
            (task: AWSTask) -> Any? in
            
            guard let userInfo = UserInfoManager.shared.userInfo else {
                print("\(#function) > userInfo is nil")
                return nil
            }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: AppDelegate.WillEnterForeground),
                                            object: nil,
                                            userInfo: nil)
            
            if userInfo.NewLikeCount > likeCount {
                NotificationCenter.default.post(name: Notification.Name(rawValue: LikeDBManager.RefreshNotification),
                                                object: nil,
                                                userInfo: nil)
            }
            
            if userInfo.NewReceiveCount > receiveCount {
                NotificationCenter.default.post(name: Notification.Name(rawValue: MailNotification.Receive.New),
                                                object: nil,
                                                userInfo: nil)
            }
            
            if userInfo.NewSendCount > sendCount {
                NotificationCenter.default.post(name: Notification.Name(rawValue: MailNotification.Send.New),
                                                object: nil,
                                                userInfo: nil)
            }
            
            return nil
        })
    }
}

enum DeepLinkType {
    case detail(id: Int)
}
