//
//  LoadMailOperation.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 12. 12..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

struct LoadMailOperation {
    
    let userId: String
    let friendId: String
    let productId: Int
    let dataSource: MailDataSource
    
    init(userId: String, friendId: String, productId: Int, dataSource: MailDataSource) {
        self.userId = userId
        self.friendId = friendId
        self.productId = productId
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (Result<Mail, FailureReason>) -> Void) {
        
        dataSource.getMail(friendId: friendId, productId: productId) { result in
            if case let Result.success(object: value) = result {
                DispatchQueue.main.async {
                    completion(.success(object: value))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(.notFound))
                }
            }
        }
    }
}

struct LoadUserOperation {
    
    let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    func execute(completion: @escaping (Result<UserInfo, FailureReason>) -> Void) {
        UserInfoManager.sharedInstance.getUserInfo(userId: userId)
            .continueWith(executor: AWSExecutor.mainThread()) { task in
                guard let userInfo = task.result as? UserInfo else {
                    DispatchQueue.main.async {
                        completion(.failure(.notFound))
                    }
                    return nil
                }
                
                DispatchQueue.main.async {
                    completion(.success(object: userInfo))
                }
            return nil
        }
    }
}

struct LoadProductOperation {
    let productId: Int
    init(productId: Int) {
        self.productId = productId
    }
    
    func execute(completion: @escaping (Result<ProductInfo, FailureReason>) -> Void) {
        ProductInfoManager.sharedInstance.getProductInfo(productId: productId)
            .continueWith(executor: AWSExecutor.mainThread()) { task in
                guard let productInfo = task.result as? ProductInfo else {
                    DispatchQueue.main.async {
                        completion(.failure(.notAvailable))
                    }
                    return nil
                }
                
                DispatchQueue.main.async {
                    completion(.success(object: productInfo))
                }
            return nil
        }
    }
}

struct ProposeOperation {
    let mail: Mail
    let dataSource: MailDataSource
    init(mail: Mail, dataSource: MailDataSource) {
        self.mail = mail
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (Result<Any?, FailureReason>) -> Void) {
        do {
            try UserInfoManager.sharedInstance.consumePoint { isSuccess in
                if isSuccess {
                    
                    self.dataSource.updateMail(mail: self.mail) { isUpdateSuccess in
                        if isUpdateSuccess {
                            completion(.success(object: nil))
                        } else {
                            completion(.failure(.notAvailable))
                        }
                    }
                }
            }
        } catch PurchaseError.notEnoughPoint {
            completion(.failure(.notEnough))
        } catch {
            completion(.failure(.notAvailable))
        }
    }
}

struct UpdateOperation {
    let mail: ReceiveMail
    init(mail: ReceiveMail) {
        self.mail = mail
    }
    
    func execute(completion: @escaping (Result<Any?, FailureReason>) -> Void) {
        ReceiveMailRepository.shared.updateMail(mail: mail) { isSuccess in
            if isSuccess {
                completion(.success(object: nil))
            } else {
                completion(.failure(.notAvailable))
            }
        }
    }
}

enum Result<T, U> where U: Error {
    case success(object: T)
    case failure(U?)
}

enum FailureReason: Error {
    case notFound, notAvailable, notEnough
}
