//
//  LoginViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 17..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct LoginViewModel: UserLoggable {
    
    let userDataSource: UserInfoDataSource
    
    var onLoginPrepare: NonCompletionHandler?
    var onLoginComplete: NonCompletionHandler?
    var onLoginFailed: NonCompletionHandler?
    var onLoginError: NonCompletionHandler?
    
    var notAvailableInput: NonCompletionHandler?
    var notValidUsernameFormat: NonCompletionHandler?
    var notValidPasswordFormar: NonCompletionHandler?
    
    init(dataSource: UserInfoDataSource) {
        self.userDataSource = dataSource
    }
    
    func login(username: String?, password: String?) {
        
        guard let username = username, let password = password else {
            notAvailableInput?()
            return
        }
        
        if !validateUsername(username) {
            notValidUsernameFormat?()
            return
        }
        if !validatePassword(password) {
            notValidPasswordFormar?()
            return
        }
        
        onLoginPrepare?()
        
        AmazonClientManager.shared.devIdentityProvider?.loginUser(username: username, password: password).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if let error = task.error as? AuthenticateError {
                if error == .unknown {
                    self.onLoginError?()
                } else {
                    self.onLoginFailed?()
                }
                return nil
            }
            
            guard let enabled = task.result else {
                self.onLoginFailed?()
                return nil
            }
            
            if enabled.isEqual(to: "true") {
                self.userDataSource.getOwnUserInfo() { result in
                    if case Result.success(object: _) = result {
                        self.userDataSource.registerEndpoint()
                        self.onLoginComplete?()
                    } else {
                        self.onLoginFailed?()
                    }
                }
            }
            return nil
        }
    }
    
    private func validateUsername(_ username: String) -> Bool {
        return username.isValidEmailAddress()
    }
    
    private func validatePassword(_ password: String) -> Bool {
        return password.isValidPassword()
    }
}
