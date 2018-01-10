//
//  MailProfileViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 12. 7..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

protocol UserLoadable {
    var user: Dynamic<UserInfo?> { get }
    func loadUser()
}

protocol MailLoadable {
    var mail: Dynamic<Mail?> { get }
    func loadMail()
}

protocol MailViewModel{
    func propose(message: String?)
    func accept()
    func reject()
    var onShowAlert: ((MultipleButtonAlert) -> Void)? { get set }
    var onShowMessage: (() -> Void)? { get set }
}

protocol CampaignLoadable {
    var product: Dynamic<ProductInfo?> { get }
    func loadProduct()
}

protocol FriendLoadable {
    var friend: Dynamic<UserInfo?> { get }
    func loadFriend()
}

typealias MailProfileViewModelProtocol = UserLoadable & MailLoadable & CampaignLoadable & FriendLoadable & MailViewModel

struct MailProfileViewModel: MailProfileViewModelProtocol {
    
    let productId: Int
    let friendId: String
    let dataSource: MailDataSource
    
    var user: Dynamic<UserInfo?>
    var mail: Dynamic<Mail?>
    var product: Dynamic<ProductInfo?>
    var friend: Dynamic<UserInfo?>
    
    var onShowAlert: ((MultipleButtonAlert) -> Void)?
    var onShowMessage: (() -> Void)?
    
    init(productId: Int, friendId: String, dataSource: MailDataSource) {
        
        self.productId = productId
        self.friendId = friendId
        self.dataSource = dataSource
        
        self.user = Dynamic(nil)
        self.product = Dynamic(nil)
        self.friend = Dynamic(nil)
        self.mail = Dynamic(nil)
    }
    
    func loadUser() {
        guard let userInfo = UserInfoManager.shared.userInfo else { return }
        self.user.value = userInfo
    }
    
    func loadFriend() {
        let operation = LoadUserOperation(userId: self.friendId)
        operation.execute { result in
            print(#function)
            if case let Result.success(object: value) = result {
                self.friend.value = value
            }
        }
    }
    
    func loadProduct() {
        print("\(#function) > productId : \(self.productId)")
        let operation = LoadProductOperation(productId: self.productId)
        operation.execute { result in
            print(#function)
            if case let Result.success(object: value) = result {
                self.product.value = value
            }
        }
    }
    
    func loadMail() {
        print(#function)
        guard let userId = UserInfoManager.shared.userInfo?.userid else { return }
        let operation = LoadMailOperation(userId: userId, friendId: friendId, productId: productId, dataSource: dataSource)
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
        guard let user = UserInfoManager.shared.userInfo else { return }
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
        
        let operation = ProposeOperation(mail: mail!, dataSource: dataSource)
        operation.execute { result in
            if case Result.success(object: _) = result {
                print(#function)
                self.mail.value = mail
                guard let nickname = mail?.FriendNickname else { return }
                let action = AlertAction(buttonTitle: "확인", style: .default, handler: nil)
                let alert = MultipleButtonAlert(title: "함께가기 신청",
                                                message: "\(nickname)에게 함께가기를 신청하였습니다",
                                                actions: [action])
                self.onShowAlert?(alert)
            } else if case let Result.failure(error) = result {
                if error == .notAvailable {
                    let action = AlertAction(buttonTitle: "확인", style: .default, handler: nil)
                    let alert = MultipleButtonAlert(title: "함께가기 신청 실패",
                                                    message: "다시 시도해 주십시오",
                                                    actions: [action])
                    self.onShowAlert?(alert)
                }
            }
        }
    }
    
    func accept() {
        
        guard let user = self.user.value else { return }
        guard let acceptedMail = ReceiveMail() else { return }
        
        acceptedMail.UserId = user.userid
        acceptedMail.SenderId = friend.value?.userid
        acceptedMail.ReceiverNickname = user.nickname
        acceptedMail.SenderNickname = friend.value?.nickname
        acceptedMail.ProductId = product.value?.ProductId
        acceptedMail.ProductTitle = product.value?.TitleKor
        acceptedMail.Message = mail.value?.Message
        acceptedMail.IsRead = ReadState.read.rawValue
        acceptedMail.ProposeStatus = ProposeStatus.made.rawValue
        
        let timestamp = Date().iso8601
        acceptedMail.UpdatedTime = mail.value?.UpdatedTime ?? timestamp
        acceptedMail.ResponseTime = timestamp
        
        let operation = UpdateOperation(mail: acceptedMail)
        operation.execute { result in
            if case Result.success(object: _) = result {
                self.mail.value = acceptedMail
                let action = AlertAction(buttonTitle: "확인", style: .default, handler: nil)
                let alert = MultipleButtonAlert(title: "함께가기 성공",
                                                message: "\(self.friend.value?.nickname ?? "")님과 함께가기를 수락하였습니다",
                    actions: [action])
                self.onShowAlert?(alert)
                NotificationCenter.default.post(name: Notification.Name(rawValue: MailNotification.Receive.Add), object: nil)
            } else if case let Result.failure(error) = result {
                if error == .notAvailable {
                    let action = AlertAction(buttonTitle: "확인", style: .default, handler: nil)
                    let alert = MultipleButtonAlert(title: "오류", message: "다시 시도해 주세요", actions: [action])
                    self.onShowAlert?(alert)
                }
            }
        }
    }
    
    func reject() {
        guard let user = self.user.value else { return }
        guard let rejectedMail = ReceiveMail() else { return }
        
        rejectedMail.UserId = user.userid
        rejectedMail.SenderId = friend.value?.userid
        rejectedMail.ReceiverNickname = user.nickname
        rejectedMail.SenderNickname = friend.value?.nickname
        rejectedMail.ProductId = product.value?.ProductId
        rejectedMail.ProductTitle = product.value?.TitleKor
        rejectedMail.Message = mail.value?.Message
        rejectedMail.IsRead = ReadState.read.rawValue
        rejectedMail.ProposeStatus = ProposeStatus.reject.rawValue
        
        let timestamp = Date().iso8601
        rejectedMail.UpdatedTime = mail.value?.UpdatedTime ?? timestamp
        rejectedMail.ResponseTime = timestamp
        
        let operation = UpdateOperation(mail: rejectedMail)
        operation.execute { result in
            if case Result.success(object: _) = result {
                self.mail.value = rejectedMail
                let action = AlertAction(buttonTitle: "확인", style: .default, handler: nil)
                let alert = MultipleButtonAlert(title: "함께가기 거절",
                                                message: "\(self.friend.value?.nickname ?? "")님과 함께가기를 거절하였습니다",
                    actions: [action])
                self.onShowAlert?(alert)
                NotificationCenter.default.post(name: Notification.Name(rawValue: MailNotification.Receive.Add), object: nil)
            } else if case let Result.failure(error) = result {
                if error == .notAvailable {
                    let action = AlertAction(buttonTitle: "확인", style: .default, handler: nil)
                    let alert = MultipleButtonAlert(title: "오류", message: "다시 시도해 주세요", actions: [action])
                    self.onShowAlert?(alert)
                }
            }
        }
    }
    
    func proposeButtonTapped() {
        guard let nickname = friend.value?.nickname else { return }
        let cancelAction = AlertAction(buttonTitle: "취소", style: .cancel, handler: nil)
        let okAction = AlertAction(buttonTitle: "확인", style: .default, handler: { _ in self.onShowMessage?() })
        let alert = MultipleButtonAlert(title: "함께가기 신청\n",
                                        message: "\(nickname)님에게 함께가기를 신청하시겠습니까?\n(500포인트가 차감됩니다)",
                                        actions: [cancelAction, okAction])
        self.onShowAlert?(alert)
    }
}

struct AlertAction {
    let buttonTitle: String
    let style: UIAlertActionStyle
    let handler: (() -> Void)?
}

struct MultipleButtonAlert {
    let title: String
    let message: String?
    let actions: [AlertAction]
}
