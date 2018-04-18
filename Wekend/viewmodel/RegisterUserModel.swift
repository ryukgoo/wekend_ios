//
//  RegisterUserViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 3. 7..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct RegisterUserModel: UserRegistable {
    
    var onRegisterPrepare: NonCompletionHandler?
    var onRegisterComplete: ((String, String) -> Void)?
    var onRegisterFailed: NonCompletionHandler?
    var notAvailableInputs: NonCompletionHandler?
    
    func register(username: String?, password: String?, nickname: String?, gender: String?, birth: Int?, phone: String?) {
        guard let username = username, let password = password,
            let nickname = nickname, let gender = gender, let birth = birth, let phone = phone else {
            notAvailableInputs?()
                return
        }
        
        onRegisterPrepare?()
        
        AmazonClientManager.shared.devIdentityProvider?.register(username: username, password: password, nickname: nickname, gender: gender, birth: birth, phone: phone).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            guard let _ = task.result as String? else {
                self.onRegisterFailed?()
                return nil
            }
            
            self.onRegisterComplete?(username, password)
            
            return nil
        }
    }
    
}
