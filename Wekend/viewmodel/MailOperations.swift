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
    let dataSource: UserInfoDataSource
    
    init(userId: String, dataSource: UserInfoDataSource) {
        self.userId = userId
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (Result<UserInfo, FailureReason>) -> Void) {
        dataSource.getUserInfo(id: userId) { result in
            if case let Result.success(object: value) = result {
                completion(.success(object: value))
            } else if case Result.failure(_) = result {
                completion(.failure(.notAvailable))
            }
        }
    }
}

struct LoadProductOperation {
    let productId: Int
    init(productId: Int) {
        self.productId = productId
    }
    
    func execute(completion: @escaping (Result<ProductInfo, FailureReason>) -> Void) {
        ProductRepository.shared.getProductInfo(productId: productId)
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
    let mailDataSource: MailDataSource
    let userDataSource: UserInfoDataSource
    init(mail: Mail, mailDataSource: MailDataSource, userDataSource: UserInfoDataSource) {
        self.mail = mail
        self.mailDataSource = mailDataSource
        self.userDataSource = userDataSource
    }
    
    func execute(completion: @escaping (Result<Any?, FailureReason>) -> Void) {
        
        userDataSource.consumePoint(point: 500) { result in
            if case Result.success(object: _) = result {
                completion(.success(object: nil))
            } else if case Result.failure(.notEnoughPoint?) = result {
                completion(.failure(.notEnough))
            } else {
                completion(.failure(.notAvailable))
            }
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
