//
//  UserProtocol.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 11..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

public typealias NonCompletionHandler = () -> Void
public typealias StringComletionHandler = (String) -> Void
public typealias ImageCompletionHandler = (UIImage) -> Void

typealias UserInfoCompletionHandler = (UserInfo) -> Void

protocol UserLoadable {
    var user: Dynamic<UserInfo?> { get }
    func loadUser()
}

protocol FriendLoadable {
    var friend: Dynamic<UserInfo?> { get }
    func loadFriend()
}

protocol UserInfoEditable {
    func updateUser(company: String?, school: String?, area: String?, introduce: String?)
    var onUpdateUser: NonCompletionHandler? { get set }
    var onUpdateUserFailed: NonCompletionHandler? { get set }
}

protocol UserSearchable {
    func searchUser(username: String?)
    var onSearchUsernameComplete: UserInfoCompletionHandler? { get set }
    var onSearchUsernameFailed: NonCompletionHandler? { get set }
    
    func searchUser(phone: String?)
    var onSearchPhoneComplete: UserInfoCompletionHandler? { get set }
    var onSearchPhoneFailed: NonCompletionHandler? { get set }
}

protocol PhoneVerifiable {
    func requestVerificationCode(phone: String?)
    var onRequestCodeStart: NonCompletionHandler? { get set }
    var onRequestComplete: NonCompletionHandler? { get set }
    var onRequestCodeFailed: NonCompletionHandler? { get set }
    var notAvailablePhone: NonCompletionHandler? { get set }
    
    func confirmVerificationCode(code: String?, phone: String?)
    var onConfirmCodeComplete: NonCompletionHandler? { get set }
    var onConfirmCodeFailed: NonCompletionHandler? { get set }
    var notAvailableCode: NonCompletionHandler? { get set }
}

protocol PasswordResetable {
    func reset(userId: String, password: String?, confirm: String?)
    
    var onResetPasswordPrepare: NonCompletionHandler? { get set }
    var onResetPasswordComplete: NonCompletionHandler? { get set }
    var onResetPasswordFailed: NonCompletionHandler? { get set }
    
    var invalidPasswordFormat: NonCompletionHandler? { get set }
    var notEqualPasswordConfirm: NonCompletionHandler? { get set }
}

protocol ImageEditable {
    func uploadImage(info: [String : Any], index: Int)
    var onUploadPrepare: ImageCompletionHandler? { get set }
    var onUploadComplete: NonCompletionHandler? { get set }
    var onUploadFailed: NonCompletionHandler? { get set }
    
    func deleteImage(index: Int)
    var onDeletePrepare: NonCompletionHandler? { get set }
    var onDeleteComplete: NonCompletionHandler? { get set }
    var onDeleteFailed: NonCompletionHandler? { get set }
}

protocol ReceiptVerifable {
    func verifyReceipt()
}
