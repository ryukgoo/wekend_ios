//
//  EditProfileViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 8..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

protocol ImageUploadable {
    func uploadImage(info: [String : Any], index: Int)
    var onUploadPrepare: ((UIImage) -> Void)? { get set }
    var onUploadComplete: (() -> Void)? { get set }
    var onUploadFailed: (() -> Void)? { get set }
}

protocol UserUpdatable {
    func updateUser()
    func validateInfos() -> Bool
    var onUpdateUser: (() -> Void)? { get set }
}

struct UserProfileViewModel: UserLoadable, UserUpdatable, ImageUploadable {
    
    var user: Dynamic<UserInfo?>
    
    var onUploadPrepare: ((UIImage) -> Void)?
    var onUploadComplete: (() -> Void)?
    var onUploadFailed: (() -> Void)?
    
    var onUpdateUser: (() -> Void)?
    
    init() {
        self.user = Dynamic(nil)
    }
    
    func loadUser() {
        guard let userInfo = UserInfoManager.shared.userInfo else { return }
        self.user.value = userInfo
    }
    
    func updateUser() {
        onUpdateUser?()
    }
    
    func validateInfos() -> Bool {
        return false
    }
    
    func uploadImage(info: [String : Any], index: Int) {
        
        var selectedImage: UIImage!
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImage = image
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImage = image
        }
        
        guard let resizedImage = selectedImage.resize(targetSize: CGSize(width: 800, height: 800)) else { return }
        onUploadPrepare?(resizedImage)
        
        guard let userInfo = UserInfoManager.shared.userInfo else { return }
        
        let operation = UploadImageOperation(userInfo: userInfo, image: resizedImage,
                                             index: index, dataSource: UserInfoManager.shared)
        
        operation.execute { result in
            if case Result.success(object: _) = result {
                self.onUploadComplete?()
            } else if case let Result.failure(error) = result {
                print("\(#function) > error: \(String(describing: error))")
                self.onUploadFailed?()
            }
        }
    }
}
