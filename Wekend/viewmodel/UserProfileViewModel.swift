//
//  EditProfileViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 8..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

typealias UserProfileViewModelProtocol = UserLoadable & UserInfoEditable & ImageEditable & PhoneEditable

struct UserProfileViewModel: UserProfileViewModelProtocol, Alertable {
    
    let userDataSource: UserInfoDataSource
    
    var user: Dynamic<UserInfo?>
    
    var onUploadPrepare: ((UIImage) -> Void)?
    var onUploadComplete: (() -> Void)?
    var onUploadFailed: (() -> Void)?
    
    var onDeletePrepare: (() -> Void)?
    var onDeleteComplete: (() -> Void)?
    var onDeleteFailed: (() -> Void)?
    
    var onUpdateUser: (() -> Void)?
    
    var onShowAlert: ((ButtonAlert) -> Void)?
    var onShowMessage: (() -> Void)?
    
    init(userDataSource: UserInfoDataSource) {
        self.userDataSource = userDataSource
        self.user = Dynamic(nil)
    }
    
    func loadUser() {
        guard let userInfo = userDataSource.userInfo else { return }
        self.user.value = userInfo
    }
    
    func updateUser(company: String?, school: String?, introduce: String?) {
        
        guard let userInfo = user.value else { return }
        userInfo.company = company
        userInfo.school = school
        userInfo.introduce = introduce
        
        let operation = UpdateUserOperation(userInfo: userInfo, dataSource: userDataSource)
        operation.execute { isSuceess in
            if isSuceess {
                let action = AlertAction(buttonTitle: "확인", style: .default, handler: { self.onUpdateUser?() })
                let alert = ButtonAlert(title: nil, message: "사용자 정보가 수정되었습니다", actions: [action])
                self.onShowAlert?(alert)
            } else {
                let alert = ButtonAlert(title: nil, message: "사용자 정보수정에 실패하였습니다", actions: [AlertAction.done])
                self.onShowAlert?(alert)
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
        onUploadPrepare?(resizedImage)
        
        guard let userInfo = user.value else { return }
        
        let operation = UploadImageOperation(userInfo: userInfo, image: resizedImage,
                                             index: index, dataSource: userDataSource)
        
        operation.execute { result in
            if case Result.success(object: _) = result {
                // TODO: uploaded image display sync issue
                self.onUploadComplete?()
                let alert = ButtonAlert(title: nil,
                                                message: "프로필 이미지가 변경되었습니다",
                                                actions: [AlertAction.done])
                self.onShowAlert?(alert)
            } else if case let Result.failure(error) = result {
                print("\(#function) > error: \(String(describing: error))")
                self.onUploadFailed?()
                let alert = ButtonAlert(title: nil,
                                        message: "이미지 변경에 실패하였습니다\n다시 시도해 주십시오",
                                        actions: [AlertAction.done])
                self.onShowAlert?(alert)
            }
        }
    }
    
    func deleteImage(index: Int) {
        print("\(#function) > index: \(index)")
        
        guard let userInfo = user.value else { return }
        
        let operation = DeleteImageOperation(userInfo: userInfo, index: index,
                                                   dataSource: userDataSource)
        
        operation.execute { result in
            if case let Result.success(object: newUserInfo) = result {
                self.user.value = newUserInfo
                self.onDeleteComplete?()
                let alert = ButtonAlert(title: nil,
                                                message: "프로필 이미지가 삭제되었습니다",
                                                actions: [AlertAction.done])
                self.onShowAlert?(alert)
            } else if case let Result.failure(error) = result {
                print("\(#function) > error: \(String(describing: error))")
                self.onDeleteFailed?()
                let alert = ButtonAlert(title: nil,
                                        message: "이미지 삭제에 실패하였습니다\n다시 시도해 주십시오",
                                        actions: [AlertAction.done])
                self.onShowAlert?(alert)
            }
        }
    }
    
    func requestVerificationCode(phone: String) {
        let operation = RequestCodeOperation(phone: phone, dataSource: userDataSource)
        operation.execute { result in
            if case let Result.success(object: code) = result {
                print("\(#function) > code: \(code)")
                let alert = ButtonAlert(title: nil,
                                        message: "인증번호가 발송되었습니다\n잠시만 기다려 주십시오",
                                        actions: [AlertAction.done])
                self.onShowAlert?(alert)
            } else if case let Result.failure(error) = result {
                print("\(#function) > error: \(String(describing: error))")
                let alert = ButtonAlert(title: nil,
                                        message: "인증번호 발송에 실패하였습니다\n다시 시도새 주십시오",
                                        actions: [AlertAction.done])
                self.onShowAlert?(alert)
            }
        }
    }
    
    func confirmVerificationCode(code: String, phone: String) {
        if userDataSource.confirmVerificationCode(code: code) {
            guard let userInfo = user.value else { return }
            userInfo.phone = phone
            let operation = UpdateUserOperation(userInfo: userInfo, dataSource: userDataSource)
            operation.execute { isSuccess in
                if isSuccess {
                    let alert = ButtonAlert(title: nil, message: "휴대폰 정보가 수정되었습니다", actions: [AlertAction.done])
                    self.onShowAlert?(alert)
                } else {
                    let alert = ButtonAlert(title: nil, message: "휴대폰 정보 수정에 실패하였습니다", actions: [AlertAction.done])
                    self.onShowAlert?(alert)
                }
            }
        } else {
            let alert = ButtonAlert(title: nil, message: "인증번호가 일치하지 않습니다", actions: [AlertAction.done])
            self.onShowAlert?(alert)
        }
    }
}
