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
                self.mailDataSource.updateMail(mail: self.mail) { isSuccess in
                    if isSuccess {
                        completion(.success(object: nil))
                    } else {
                        completion(.failure(.notAvailable))
                    }
                }
            } else if case Result.failure(.notEnoughPoint?) = result {
                completion(.failure(.notEnough))
            } else {
                completion(.failure(.notAvailable))
            }
        }
    }
}

struct AcceptOperation {
    
    let mail: Mail
    let user: UserInfo
    let friend: UserInfo
    let product: ProductInfo
    let dataSource: MailDataSource
    
    init(mail: Mail, user: UserInfo, friend: UserInfo, product: ProductInfo, dataSource: MailDataSource) {
        self.mail = mail
        self.user = user
        self.friend = friend
        self.product = product
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (Result<Mail, FailureReason>) -> Void) {
        guard let acceptedMail = ReceiveMail() else {
            completion(.failure(.notAvailable))
            return
        }
        
        acceptedMail.UserId = user.userid
        acceptedMail.SenderId = friend.userid
        acceptedMail.ReceiverNickname = user.nickname
        acceptedMail.SenderNickname = friend.nickname
        acceptedMail.ProductId = product.ProductId
        acceptedMail.ProductTitle = product.TitleKor
        acceptedMail.Message = mail.Message
        acceptedMail.IsRead = ReadState.read.rawValue
        acceptedMail.ProposeStatus = ProposeStatus.made.rawValue
        
        let timestamp = Date().iso8601
        acceptedMail.UpdatedTime = mail.UpdatedTime
        acceptedMail.ResponseTime = timestamp
        
        dataSource.updateMail(mail: acceptedMail) { isSuccess in
            DispatchQueue.main.async {
                if isSuccess {
                    completion(.success(object: acceptedMail))
                } else {
                    completion(.failure(.notAvailable))
                }
            }
        }
    }
}

struct RejectOperation {
    
    let mail: Mail
    let user: UserInfo
    let friend: UserInfo
    let product: ProductInfo
    let dataSource: MailDataSource
    
    init(mail: Mail, user: UserInfo, friend: UserInfo, product: ProductInfo, dataSource: MailDataSource) {
        self.mail = mail
        self.user = user
        self.friend = friend
        self.product = product
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (Result<Mail, FailureReason>) -> Void) {
        guard let rejectedMail = ReceiveMail() else {
            completion(.failure(.notAvailable))
            return
        }
        
        rejectedMail.UserId = user.userid
        rejectedMail.SenderId = friend.userid
        rejectedMail.ReceiverNickname = user.nickname
        rejectedMail.SenderNickname = friend.nickname
        rejectedMail.ProductId = product.ProductId
        rejectedMail.ProductTitle = product.TitleKor
        rejectedMail.Message = mail.Message
        rejectedMail.IsRead = ReadState.read.rawValue
        rejectedMail.ProposeStatus = ProposeStatus.reject.rawValue
        
        let timestamp = Date().iso8601
        rejectedMail.UpdatedTime = mail.UpdatedTime
        rejectedMail.ResponseTime = timestamp
        
        dataSource.updateMail(mail: rejectedMail) { isSuccess in
            DispatchQueue.main.async {
                if isSuccess {
                    completion(.success(object: rejectedMail))
                } else {
                    completion(.failure(.notAvailable))
                }
            }
        }
    }
}

struct UpdateMailOperation {
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
