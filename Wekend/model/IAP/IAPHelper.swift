//
//  IAPHelper.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 5. 31..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import StoreKit

public typealias ProductIdentifier = String
public typealias ProductRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> ()

open class IAPHelper: NSObject {
    
    static let IAPHelperPurchaseNotification = "com.wekend.Notification.IAP.purchase"
    static let IAPHelperFailNotification = "com.wekend.Notification.IAP.fail"
    
    fileprivate let productIdentifiers: Set<ProductIdentifier>
//    fileprivate var purchasedProductIdentifiers = Set<ProductIdentifier>()
    fileprivate var productsRequest: SKProductsRequest?
    fileprivate var productsRequestCompletionHandler: ProductRequestCompletionHandler?
    
    public init(productIds: Set<ProductIdentifier>) {
        productIdentifiers = productIds
//        for productIdentifier in productIds {
//            let purchased = UserDefaults.standard.bool(forKey: productIdentifier)
//            if purchased {
//                purchasedProductIdentifiers.insert(productIdentifier)
//                print("IAPHelper > init > previously purchased : \(productIdentifier)")
//            } else {
//                print("IAPHelper > init > Not purchased : \(productIdentifier)")
//            }
//        }
        
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
}

// MARK: - StoreKit API

extension IAPHelper {
    public func requestProducts(completionHandler: @escaping ProductRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func buyProduct(_ product: SKProduct) {
        print("\(className) > \(#function) > Buying \(product.productIdentifier)...")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
//    public func isProductPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
//        return purchasedProductIdentifiers.contains(productIdentifier)
//    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        print("\(className) > \(#function) > response : \(response.invalidProductIdentifiers.description)")
        print("\(className) > \(#function) > Loaded list of products...")
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        for product in products {
            print("\(className) > \(#function) > Found product: \(product.productIdentifier) \(product.localizedTitle) \(product.price.floatValue)")
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("\(className) > \(#function) > Failed to load list of products")
        print("\(className) > \(#function) > Error: \(error.localizedDescription)")
        
        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
    
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                complete(transaction: transaction)
                break
            case .failed:
                fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred:
                break
            case .purchasing:
                break
            }
        }
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        print("\(className) > \(#function) > complete....")
        deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        print("\(className) > \(#function) > restore... \(productIdentifier)")
        deliverPurchaseNotificationFor(identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        print("\(className) > \(#function) > fail.....")
        
        if let transactionError = transaction.error as NSError? {
            if transactionError.code != SKError.paymentCancelled.rawValue {
                print("\(className) > \(#function) > Transaction Error: \(String(describing: transaction.error?.localizedDescription))")
            }
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
        NotificationCenter.default.post(name: Notification.Name(rawValue: IAPHelper.IAPHelperFailNotification), object: nil)
    }
    
    private func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
        
//        purchasedProductIdentifiers.insert(identifier)
        UserDefaults.standard.set(true, forKey: identifier)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: Notification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification), object: identifier)
    }
    
}
