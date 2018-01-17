//
//  MailProfileViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 12. 7..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

typealias MailProfileViewModelProtocol = UserLoadable & MailLoadable & ProductLoadable & FriendLoadable & MailViewModel

struct MailProfileViewModel: MailProfileViewModelProtocol, Alertable {
    
    let productId: Int
    let friendId: String
    let userDataSource: UserInfoDataSource
    let mailDataSource: MailDataSource
    let productDataSource: ProductDataSource
    
    var user: Dynamic<UserInfo?>
    var mail: Dynamic<Mail?>
    var product: Dynamic<ProductInfo?>
    var friend: Dynamic<UserInfo?>
    
    var onShowAlert: ((ButtonAlert) -> Void)?
    var onShowMessage: (() -> Void)?
    
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
        print(#function)
        guard let user = userDataSource.userInfo else { return }
        let mail = SendMail()
        mail?.UserId = user.userid
        mail?.ReceiverId = friendId
        mail?.ProductId = productId
        mail?.ProductTitle = product.value?.TitleKor
        mail?.SenderNickname = user.nickname
        mail?.ReceiverNickname = friend.value?.nickname
        mail?.ProposeStatus = ProposeStatus.notMade.rawValue
        mail?.Message = message
        mail?.IsRead = 0
        let timestamp = Date().iso8601
        mail?.UpdatedTime = timestamp
        mail?.ResponseTime = timestamp
        
        let operation = ProposeOperation(mail: mail!, mailDataSource: mailDataSource, userDataSource: userDataSource)
        operation.execute { result in
            if case Result.success(object: _) = result {
                print(#function)
                self.mail.value = mail
                guard let nickname = mail?.FriendNickname else { return }
                let alert = ButtonAlert(title: "함께가기 신청",
                                                message: "\(nickname)에게 함께가기를 신청하였습니다",
                                                actions: [AlertAction.done])
                self.onShowAlert?(alert)
            } else if case let Result.failure(error) = result {
                if error == .notAvailable {
                    let alert = ButtonAlert(title: "함께가기 신청 실패",
                                            message: "다시 시도해 주십시오",
                                            actions: [AlertAction.done])
                    self.onShowAlert?(alert)
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
                let alert = ButtonAlert(title: "함께가기 성공",
                                        message: "\(nickname)님과 함께가기를 수락하였습니다",
                    actions: [AlertAction.done])
                self.onShowAlert?(alert)
                NotificationCenter.default.post(name: Notification.Name(rawValue: MailNotification.Receive.Add), object: nil)
            } else {
                let alert = ButtonAlert(title: "오류", message: "다시 시도해 주세요", actions: [AlertAction.done])
                self.onShowAlert?(alert)
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
                let alert = ButtonAlert(title: "함께가기 거절",
                                        message: "\(nickname)님과 함께가기를 거절하였습니다",
                    actions: [AlertAction.done])
                self.onShowAlert?(alert)
                NotificationCenter.default.post(name: Notification.Name(rawValue: MailNotification.Receive.Add), object: nil)
            } else {
                let alert = ButtonAlert(title: "오류", message: "다시 시도해 주세요", actions: [AlertAction.done])
                self.onShowAlert?(alert)
            }
        }
    }
    
    func proposeButtonTapped() {
        guard let nickname = friend.value?.nickname else { return }
        let okAction = AlertAction(buttonTitle: "확인", style: .default, handler: { _ in self.onShowMessage?() })
        let alert = ButtonAlert(title: "함께가기 신청\n",
                                        message: "\(nickname)님에게 함께가기를 신청하시겠습니까?\n(500포인트가 차감됩니다)",
                                        actions: [AlertAction.cancel, okAction])
        self.onShowAlert?(alert)
    }
}
