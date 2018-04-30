//
//  StoreProducts.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 5. 31..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

struct StoreProducts {
    
    public static let Price1 = "com.entuition.wekend.purchase.point.1"
    public static let Price2 = "com.entuition.wekend.purchase.point.2"
    public static let Price3 = "com.entuition.wekend.purchase.point.3"
    public static let Price4 = "com.entuition.wekend.purchase.point.4"
    public static let Price5 = "com.entuition.wekend.purchase.point.5"
    
    static let Subscription = "com.entuition.wekend.purchase.subscription.1monthly"
    
    static let productPoints = [Price1 : 1000,
                                Price2 : 3000,
                                Price3 : 5000,
                                Price4 : 10000,
                                Price5 : 30000]
    
    static let productBonuses = [Price1 : 0,
                                 Price2 : 500,
                                 Price3 : 1000,
                                 Price4 : 2500,
                                 Price5 : 8500]
    
    fileprivate static let productIdentifiers: Set<ProductIdentifier> = [StoreProducts.Price1,
                                                                         StoreProducts.Price2,
                                                                         StoreProducts.Price3,
                                                                         StoreProducts.Price4,
                                                                         StoreProducts.Price5]
    
    fileprivate static let subscribeIdentifiers: Set<ProductIdentifier> = [StoreProducts.Subscription]
    
    public static let store = IAPHelper(productIds: StoreProducts.productIdentifiers.union(subscribeIdentifiers))
    
    public static func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
        return productIdentifier.components(separatedBy: ".").last
    }
    
    public static func handlePurchase(productId: String) {
        
        print("\(#function) : \(productId)")
        
        if productIdentifiers.contains(productId) {
            store.purchasedProducts.insert(productId)
            UserDefaults.standard.set(true, forKey: productId)
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: IAPHelper.PurchaseSuccessNotification, object: productId)
        } else if subscribeIdentifiers.contains(productId) {
            
            UserInfoRepository.shared.validateReceipt(purchaseId: productId) { result in
                if case let Result.success(object: state) = result {
                    print("\(#function) > state: \(state)")
                    if state == "verified" {
                        print("\(#function) > post SubscribeEnableNotification")
                        NotificationCenter.default.post(name: IAPHelper.SubcribeEnableNotification, object: nil)
//                        NotificationCenter.default.post(name: IAPHelper.SubcribeEnableNotification, object: nil)
                        return
                    }
                }
                // For closing progressbar
                NotificationCenter.default.post(name: IAPHelper.SubcribeEnableNotification, object: nil)
            }
        }
    }
}

