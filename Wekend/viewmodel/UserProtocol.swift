//
//  UserProtocol.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 11..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

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
    var onUpdateUser: (() -> Void)? { get set }
}

protocol PhoneEditable {
    func requestVerificationCode(phone: String)
    func confirmVerificationCode(code: String, phone: String)
}

protocol ImageEditable {
    func uploadImage(info: [String : Any], index: Int)
    
    var onUploadPrepare: ((UIImage) -> Void)? { get set }
    var onUploadComplete: (() -> Void)? { get set }
    var onUploadFailed: (() -> Void)? { get set }
    
    func deleteImage(index: Int)
    
    var onDeletePrepare: (() -> Void)? { get set }
    var onDeleteComplete: (() -> Void)? { get set }
    var onDeleteFailed: (() -> Void)? { get set }
}
