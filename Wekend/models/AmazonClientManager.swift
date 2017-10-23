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
    
    var isInitialized : Bool = false
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
        isInitialized = true
        
        printLog("didFinishLaunching > finished")
        
        return true
    }
    
    func loadUserInfo(completion: @escaping (_: Bool) -> Void) {
        
        guard let userId = UserDefaults.Account.string(forKey: .userId),
              let _ = UserDefaults.Account.string(forKey: .userName) else {
                
                printLog("register user not yet")
                if self.credentialsProvider?.identityId != nil {
                    self.credentialsProvider?.clearKeychain()
                }
                
                completion(false)
                return
        }
        
        UserInfoManager.sharedInstance.getOwnedUserInfo(userId: userId).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any? in
            
            if task.error != nil || task.result == nil {
                completion(false)
            }
            
            completion(true)
            
            return nil
        })
    }
    
    func clearCredentials() {
        self.credentialsProvider?.clearKeychain()
        self.credentialsProvider?.clearCredentials()
    }
}
