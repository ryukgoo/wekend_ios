//
//  MailProfileViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 12. 7..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

typealias MailProfileViewModelProtocol = UserLoadable & MailLoadable & ProductLoadable & FriendLoadable & MailViewModel

struct MailProfileViewModel: MailProfileViewModelProtocol {
    
    let productId: Int
    let friendId: String
    let userDataSource: UserInfoDataSource
    let mailDataSource: MailDataSource
    let productDataSource: ProductDataSource
    
    var user: Dynamic<UserInfo?>
    var mail: Dynamic<Mail?>
    var product: Dynamic<ProductInfo?>
    var friend: Dynamic<UserInfo?>
    
    var onProposePrepare: StringComletionHandler?
    var onProposeComplete: StringComletionHandler?
    var onProposeFailed: NonCompletionHandler?
    
    var onAcceptComplete: StringComletionHandler?
    var onAcceptFailed: NonCompletionHandler?
    
    var onRejectComplete: StringComletionHandler?
    var onRejectFailed: NonCompletionHandler?
    
    init(productId: Int, friendId: String,
         mailDataSource: MailDataSource,
         userDataSource: UserInfoDataSource,
         productDataSource: ProductDataSource) {
        
        self.productId = productId
        self.friendId = friendId
        self.mailDataSource = mailDataSource
        self.userDataSource = userDataSource
        self.productDataSource = productDataSource
        
        self.user = Dynamic(nil)
        self.product = Dynamic(nil)
        self.friend = Dynamic(nil)
        self.mail = Dynamic(nil)
    }
    
    func loadUser() {
        guard let userInfo = userDataSource.userInfo else { return }
        self.user.value = userInfo
    }
    
    func loadFriend() {
        let operation = LoadUserOperation(userId: self.friendId, dataSource: userDataSource)
        operation.execute { result in
            print(#function)
            if case let Result.success(object: value) = result {
                self.friend.value = value
            }
        }
    }
    
    func loadProduct() {
        print("\(#function) > productId : \(self.productId)")
        let operation = LoadProductOperation(productId: self.productId, dataSource: productDataSource)
        operation.execute { result in
            print(#function)
            if case let Result.success(object: value) = result {
                self.product.value = value
            }
        }
    }
    
    func loadMail() {
        print(#function)
        guard let userId = userDataSource.userId else { return }
        let operation = LoadMailOperation(userId: userId, friendId: friendId, productId: productId,
                                          dataSource: mailDataSource)
        operation.execute { result in
            print("\(#function) > in")
            if case let Result.success(object: value) = result {
                self.mail.value = value
            } else if case let Result.failure(error) = result {
                if error == .notFound {
                    print("\(#function) > value is nil")
                    self.mail.value = nil
                }
            }
        }
    }
    
    func propose(message: String?) {
        print("\(#function) > message: \(String(describing: message))")
        guard let user = userDataSource.userInfo else { return }
        guard let mail = SendMail() else { return }
        mail.UserId = user.userid
        mail.ReceiverId = friendId
        mail.ProductId = productId
        mail.ProductTitle = product.value?.TitleKor
        mail.SenderNickname = user.nickname
        mail.ReceiverNickname = friend.value?.nickname
        mail.ProposeStatus = ProposeStatus.notMade.rawValue
        mail.Message = (message?.isEmpty)! ? nil : message
        mail.IsRead = 0
        let timestamp = Date().iso8601
        mail.UpdatedTime = timestamp
        mail.ResponseTime = timestamp
        
        let operation = ProposeOperation(mail: mail, mailDataSource: mailDataSource, userDataSource: userDataSource)
        operation.execute { result in
            if case let Result.success(object: value) = result {
                print(#function)
                self.mail.value = mail
                self.user.value = value
                guard let nickname = mail.FriendNickname else { return }
                
                self.onProposeComplete?(nickname)
                
                NotificationCenter.default.post(name: MailNotification.Send.Add, object: nil)
            } else if case let Result.failure(error) = result {
                if error == .notAvailable {
                    self.onProposeFailed?()
                }
            }
        }
    }
    
    func accept() {
        guard let user = user.value,
              let mail = mail.value,
              let friend = friend.value,
              let product = product.value else { return }
        
        let operation = AcceptOperation(mail: mail, user: user, friend: friend, product: product, dataSource: mailDataSource)
        
        operation.execute { result in
            if case let Result.success(object: value) = result {
                self.mail.value = value
                guard let nickname = self.friend.value?.nickname else { return }
                self.onAcceptComplete?(nickname)
                NotificationCenter.default.post(name: MailNotification.Receive.Add, object: nil)
            } else {
                self.onAcceptFailed?()
            }
        }
    }
    
    func reject() {
        guard let user = user.value,
              let mail = mail.value,
              let friend = friend.value,
              let product = product.value else { return }
        
        let operation = RejectOperation(mail: mail, user: user, friend: friend, product: product, dataSource: mailDataSource)
        
        operation.execute { result in
            if case let Result.success(object: value) = result {
                self.mail.value = value
                guard let nickname = self.friend.value?.nickname else { return }
                self.onRejectComplete?(nickname)
                NotificationCenter.default.post(name: MailNotification.Receive.Add, object: nil)
            } else {
                self.onRejectFailed?()
            }
        }
    }
    
    func proposeButtonTapped() {
        guard let nickname = friend.value?.nickname else { return }
        self.onProposePrepare?(nickname)
    }
}
