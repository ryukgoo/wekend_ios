//
//  IAPHelper.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 5. 31..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import StoreKit

public typealias ProductIdentifier = String
//public typealias ProductRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> ()

open class IAPHelper: NSObject {
    
    static let PurchaseSuccessNotification = Notification.Name(rawValue: "com.wekend.Notification.IAP.purchaseSuccess")
    static let PurchaseFailedNotification = Notification.Name(rawValue: "com.wekend.Notification.IAP.purchaseFailed")
    static let RestoreSuccessNotification = Notification.Name(rawValue: "com.wekend.Notification.IAP.restore")
    static let ProductLoadedNotification = Notification.Name(rawValue: "com.wekend.Notification.IAP.productLoaded")
    static let SubcribeEnableNotification = Notification.Name(rawValue: "com.wekend.Notification.IAP.subcribe")
    
    fileprivate let productIdentifiers: Set<ProductIdentifier>
    fileprivate var productsRequest: SKProductsRequest?
//    fileprivate var productsRequestCompletionHandler: ProductRequestCompletionHandler?
    
    public var purchasedProducts = Set<ProductIdentifier>()
    
    var subscriptions: [SKProduct]? {
        didSet {
            NotificationCenter.default.post(name: IAPHelper.ProductLoadedNotification, object: subscriptions)
        }
    }
    
    var isSubscribed: Bool {
        
        guard let userInfo = UserInfoRepository.shared.userInfo,
              let purchaseTimeStr = userInfo.PurchaseTime,
              let expiresTimeStr = userInfo.ExpiresTime,
              let purchaseTime = Double(purchaseTimeStr),
              let expiresTime = Double(expiresTimeStr) else {
                print("isSubscribe has nil value!!!!!!!!")
            return false
        }
        
        let purchaseDate = Date(timeIntervalSince1970: purchaseTime / 1000.0)
        let expiresDate = Date(timeIntervalSince1970: expiresTime / 1000.0)
        
        print("purchaseDate: \(purchaseDate), expiresDate: \(expiresDate), Date: \(Date())")
        
        return (purchaseDate...expiresDate).contains(Date())
    }
    
    var hasReceitpt: Bool {
        return loadReceipt() != nil
    }
    
    public init(productIds: Set<ProductIdentifier>) {
        productIdentifiers = productIds
        purchasedProducts = Set(productIds.filter { UserDefaults.standard.bool(forKey: $0) })
        
        super.init()
        SKPaymentQueue.default().add(self)
        
        print("\(self.className) > \(#function) > productIds: \(productIds)")
    }
    
    private func loadReceipt() -> Data? {
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            print("Error loading receipt data: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - StoreKit API

extension IAPHelper {
    
    public func requestProducts() {
        productsRequest?.cancel()
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func buyProduct(_ product: SKProduct, with username: String) {
        print("\(className) > \(#function) > Buying \(product.productIdentifier)...")
        print("\(className) > \(#function) > username \(username)...")
        
        let payment = SKMutablePayment(product: product)
        payment.applicationUsername = username
        SKPaymentQueue.default().add(payment)
    }
    
    public func isPurchased(_ productIdentifier: ProductIdentifier) -> Bool {
        return purchasedProducts.contains(productIdentifier)
    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases() {
        print("\(className) > \(#function)")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        print("\(className) > \(#function) > response : \(response.invalidProductIdentifiers.description)")
        print("\(className) > \(#function) > Loaded list of products...")
//        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        subscriptions = response.products
        
        NotificationCenter.default.post(name: IAPHelper.ProductLoadedNotification, object: subscriptions)
        
        for product in products {
            print("\(className) > \(#function) > Found product: \(product.productIdentifier) \(product.localizedTitle) \(product.price.floatValue)")
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("\(className) > \(#function) > Failed to load list of products")
        print("\(className) > \(#function) > Error: \(error.localizedDescription)")
        
//        productsRequestCompletionHandler?(false, nil)
        clearRequestAndHandler()
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
//        productsRequestCompletionHandler = nil
    }
    
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        print("\(className) > \(#function)")
        
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
        NotificationCenter.default.post(name: IAPHelper.PurchaseFailedNotification, object: nil)
    }
    
    private func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
        
        StoreProducts.handlePurchase(productId: identifier)
    }
    
}

