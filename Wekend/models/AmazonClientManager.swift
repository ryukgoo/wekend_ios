//
//  AmazonClientManager.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 11. 23..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

class AmazonClientManager: NSObject {
    
    // MARK: Singlton
    
    static let sharedInstance = AmazonClientManager()
    
    // MARK: Properties
    
    private var isInitialized : Bool
    var devIdentityProvider : AmazonIdentityProvider?
    var credentialsProvider : AWSCognitoCredentialsProvider?
    
    // MARK: initialization
    
    override init() {
//        super.init()
        isInitialized = false
    }
    
    func didFinishLaunching(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        printLog("didFinishLaunchingWithOptions > start")
        
        // AWS Initialization
        devIdentityProvider = AmazonIdentityProvider(regionType: .APNortheast1, identityPoolId: Configuration.IDENTITY_POOL_ID, useEnhancedFlow: true, identityProviderManager: nil)
        credentialsProvider = AWSCognitoCredentialsProvider(regionType: .APNortheast1, identityProvider: devIdentityProvider!)
        let configuration = AWSServiceConfiguration(region: .APNortheast1, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        guard let _ = UserDefaults.Account.string(forKey: .userName) else {
            
            printLog("get username from device is nil")
            
            if self.credentialsProvider?.identityId != nil {
                self.credentialsProvider?.clearKeychain()
            }
            
            self.gotoLoginViewController()
            
            return true
        }
        
        // Goto Main View
        
        guard let userId = UserDefaults.Account.string(forKey: .userId) else {
            fatalError("AmazonClientManager > didFinishLaunching > get userId from UserDefaults Error")
        }
        
        printLog("didFinishLaunching > userID : \(String(describing: userId))")
        
        UserInfoManager.sharedInstance.getOwnedUserInfo(userId: userId).continueWith(executor: AWSExecutor.mainThread(), block: {
            (getUserTask : AWSTask) -> Any! in
            
            print("Fetch UserInfo Complete")
            
            if getUserTask.error != nil || getUserTask.result == nil {
                self.gotoLoginViewController()
                return nil
            }
            
            UserInfoManager.sharedInstance.registEndpointARN()
            
            self.gotoMainViewController()
            
            return nil
        })
        
        isInitialized = true
        
        printLog("didFinishLaunching > finished")
        
        return true
    }
    
    private func gotoMainViewController() {
        DispatchQueue.main.async {
            let mainStoryboard = Constants.StoryboardName.Main
            let storyboard = UIStoryboard(name: mainStoryboard.rawValue, bundle: nil)
            
            guard let mainVC = storyboard.instantiateViewController(withIdentifier: mainStoryboard.identifier) as? MainViewController,
                let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                    fatalError("AmazonClientManager > didFinishLaunching > get MainVC and AppDelegate Error")
            }
            
            appDelegate.window!.rootViewController = mainVC
            appDelegate.window!.makeKeyAndVisible()
        }
    }
    
    private func gotoLoginViewController() {
        DispatchQueue.main.async {
            let loginStoryBoard = Constants.StoryboardName.Login
            let loginboard = UIStoryboard(name: loginStoryBoard.rawValue, bundle: nil)
            
            guard let loginVC = loginboard.instantiateViewController(withIdentifier: loginStoryBoard.identifier) as? UINavigationController,
                let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                    fatalError("AmazonClientManager > didFinishLaunching > get VC and AppDelegate Error")
            }
            appDelegate.window!.rootViewController = loginVC
            appDelegate.window!.makeKeyAndVisible()
        }
    }
    
}
