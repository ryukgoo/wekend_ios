//
//  MailProfileViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 12. 7..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

protocol UserViewModel {
    var user: Dynamic<UserInfo?> { get }
    func loadUser()
}

protocol MailViewModel {
    var mail: Dynamic<Mail?> { get }
    func loadMail()
}

protocol MailProposable{
    func propose(message: String?)
    func accept()
    func reject()
    var onShowAlert: ((MultipleButtonAlert) -> Void)? { get set }
    var onShowMessage: (() -> Void)? { get set }
}

protocol CampaignViewModel {
    var product: Dynamic<ProductInfo?> { get }
    func loadProduct()
}

protocol FriendViewModel {
    var friend: Dynamic<UserInfo?> { get }
    func loadFriend()
}

typealias MailProfileViewModelProtocol = UserViewModel & MailViewModel & CampaignViewModel & FriendViewModel & MailProposable

struct MailProfileViewModel: MailProfileViewModelProtocol {
    
    let productId: Int
    let friendId: String
    
    var user: Dynamic<UserInfo?>
    var mail: Dynamic<Mail?>
    var product: Dynamic<ProductInfo?>
    var friend: Dynamic<UserInfo?>
    
    var onShowAlert: ((MultipleButtonAlert) -> Void)?
    var onShowMessage: (() -> Void)?
    
    init(productId: Int, friendId: String) {
        
        self.productId = productId
        self.friendId = friendId
        
        self.user = Dynamic(nil)
        self.product = Dynamic(nil)
        self.friend = Dynamic(nil)
        self.mail = Dynamic(nil)
    }
    
    func loadUser() {
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else { return }
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
        guard let userId = UserInfoManager.sharedInstance.userInfo?.userid else { return }
        let operation = LoadMailOperation(userId: userId, friendId: friendId, productId: productId)
        operation.execute { result in
            print(#function)
            if case let Result.success(object: value) = result {
                if let mail = value as? SendMail {
                    self.mail.value = mail
                }
            } else if case let Result.failure(error) = result {
                if error == .notFound {
                    self.mail.value = nil
                }
            }
        }
    }
    
    func propose(message: String?) {
        
        print(#function)
        
        guard let user = UserInfoManager.sharedInstance.userInfo else { return }
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
        
        let operation = ProposeOperation(mail: mail!)
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
            } else  if case let Result.failure(error) = result {
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
        
    }
    
    func reject() {
        
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
