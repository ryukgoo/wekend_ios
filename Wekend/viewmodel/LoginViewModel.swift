//
//  LoginViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 17..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct LoginViewModel: UserLoggable, Alertable {
    
    let userDataSource: UserInfoDataSource
    
    var onLoggin: (() -> ())?
    var onShowAlert: ((ButtonAlert) -> Void)?
    var onShowMessage: (() -> Void)?
    
    init(dataSource: UserInfoDataSource) {
        self.userDataSource = dataSource
    }
    
    func login(username: String, password: String) {
        AmazonClientManager.shared.devIdentityProvider?.loginUser(username: username, password: password).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            let loginError = ButtonAlert(title: "로그인 실패",
                                    message: "등록되지 않은 계정이거나\n비밀번호가 일치하지 않습니다",
                                    actions: [AlertAction.done])
            
            if let error = task.error as? AuthenticateError {
                if error == .unknown {
                    let alert = ButtonAlert(title: nil, message: "Unknown Error", actions: [AlertAction.done])
                    self.onShowAlert?(alert)
                } else {
                    self.onShowAlert?(loginError)
                }
                return nil
            }
            
            guard let enabled = task.result else {
                self.onShowAlert?(loginError)
                return nil
            }
            
            if enabled.isEqual(to: "true") {
                self.userDataSource.getOwnUserInfo() { result in
                    if case Result.success(object: _) = result {
                        self.userDataSource.registerEndpoint()
                        self.onLoggin?()
                    } else {
                        self.onShowAlert?(loginError)
                    }
                }
            }
            return nil
        }
    }
    
    func validateUsername(_ username: String) -> Bool {
        return username.isValidEmailAddress()
    }
    
    func validatePassword(_ password: String) -> Bool {
        return password.isValidPassword()
    }
}
