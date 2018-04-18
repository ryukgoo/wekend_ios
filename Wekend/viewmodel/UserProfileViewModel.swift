//
//  EditProfileViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 8..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

typealias UserProfileViewModelProtocol = UserLoadable & UserInfoEditable & ImageEditable & PhoneVerifiable

struct UserProfileViewModel: UserProfileViewModelProtocol {
    
    let userDataSource: UserInfoDataSource
    
    var user: Dynamic<UserInfo?>
    
    var onUploadPrepare: ImageCompletionHandler?
    var onUploadComplete: NonCompletionHandler?
    var onUploadFailed: NonCompletionHandler?
    
    var onDeletePrepare: NonCompletionHandler?
    var onDeleteComplete: NonCompletionHandler?
    var onDeleteFailed: NonCompletionHandler?
    
    var onUpdateUser: NonCompletionHandler?
    var onUpdateUserFailed: NonCompletionHandler?
    
    var onRequestCodeStart: NonCompletionHandler?
    var onRequestComplete: NonCompletionHandler?
    var onRequestCodeFailed: NonCompletionHandler?
    var notAvailablePhone: NonCompletionHandler?
    
    var onConfirmCodeComplete: NonCompletionHandler?
    var onConfirmCodeFailed: NonCompletionHandler?
    var notAvailableCode: NonCompletionHandler?
    
    init(userDataSource: UserInfoDataSource) {
        self.userDataSource = userDataSource
        self.user = Dynamic(nil)
    }
    
    func loadUser() {
        guard let userInfo = userDataSource.userInfo else { return }
        self.user.value = userInfo
    }
    
    func updateUser(company: String?, school: String?, area: String?, introduce: String?) {
        
        guard let userInfo = user.value else { return }
        
        if let company = company, company.isEmpty {
            userInfo.company = nil
        } else {
            userInfo.company = company
        }
        
        if let school = school, school.isEmpty {
            userInfo.school = nil
        } else {
            userInfo.school = school
        }
        
        if let area = area, area.isEmpty {
            userInfo.area = nil
        } else {
            userInfo.area = area
        }
        
        if let introduce = introduce, introduce.isEmpty {
            userInfo.introduce = nil
        } else {
            userInfo.introduce = introduce
        }
        
        let operation = UpdateUserOperation(userInfo: userInfo, dataSource: userDataSource)
        operation.execute { isSuceess in
            if isSuceess {
                self.onUpdateUser?()
            } else {
                self.onUpdateUserFailed?()
            }
        }
    }
    
    func uploadImage(info: [String : Any], index: Int) {
        
        var selectedImage: UIImage!
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImage = image
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImage = image
        }
        
        guard let resizedImage = selectedImage.resize(targetSize: CGSize(width: 800, height: 800)) else { return }
        guard let userInfo = user.value else { return }
        
        let operation = UploadImageOperation(userInfo: userInfo, image: resizedImage,
                                             index: index, dataSource: userDataSource)
        
        onUploadPrepare?(resizedImage)
        operation.execute { result in
            if case Result.success(object: _) = result {
                self.onUploadComplete?()
            } else if case let Result.failure(error) = result {
                print("\(#function) > error: \(String(describing: error))")
                self.onUploadFailed?()
            }
        }
    }
    
    func deleteImage(index: Int) {
        
        print("\(#function) > index: \(index)")
        guard let userInfo = user.value else { return }
        
        let operation = DeleteImageOperation(userInfo: userInfo, index: index, dataSource: userDataSource)
        
        onDeletePrepare?()
        operation.execute { result in
            if case let Result.success(object: newUserInfo) = result {
                self.user.value = newUserInfo
                self.onDeleteComplete?()
            } else if case let Result.failure(error) = result {
                print("\(#function) > error: \(String(describing: error))")
                self.onDeleteFailed?()
            }
        }
    }
    
    func requestVerificationCode(phone: String?) {
        
        guard let phone = phone else {
            notAvailablePhone?()
            return
        }
        
        onRequestCodeStart?()
        
        let operation = RequestCodeOperation(phone: phone, dataSource: userDataSource)
        operation.execute { result in
            if case let Result.success(object: code) = result {
                print("\(#function) > code: \(code)")
                self.onRequestComplete?()
            } else if case let Result.failure(error) = result {
                print("\(#function) > error: \(String(describing: error))")
                self.onRequestCodeFailed?()
            }
        }
    }
    
    func confirmVerificationCode(code: String?, phone: String?) {
        
        guard let code = code else {
            notAvailableCode?()
            return
        }
        
        if userDataSource.confirmVerificationCode(code: code) {
            guard let userInfo = user.value else { return }
            userInfo.phone = phone
            let operation = UpdateUserOperation(userInfo: userInfo, dataSource: userDataSource)
            operation.execute { success in
                if success {
                    self.onConfirmCodeComplete?()
                } else {
                    self.onUpdateUserFailed?()
                }
            }
        } else {
            self.onConfirmCodeFailed?()
        }
    }
}
