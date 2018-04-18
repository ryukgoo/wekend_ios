//
//  ResetPasswordViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 3. 8..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct ResetPasswordViewModel: PasswordResetable {
    
    var onResetPasswordPrepare: NonCompletionHandler?
    var onResetPasswordComplete: NonCompletionHandler?
    var onResetPasswordFailed: NonCompletionHandler?
    
    var invalidPasswordFormat: NonCompletionHandler?
    var notEqualPasswordConfirm: NonCompletionHandler?
    
    func reset(userId: String, password: String?, confirm: String?) {
        
        if !validatePassword(password) {
            invalidPasswordFormat?()
            return
        }
        
        if password != confirm {
            notEqualPasswordConfirm?()
            return
        }
        
        guard let password = password else { return }
        print("\(#function) > password: \(password)")
        
        onResetPasswordPrepare?()
        
        let operation = ResetPasswordOperation(userId: userId, password: password)
        operation.execute { result in
            if case let Result.success(object: userId) = result {
                print("\(#function) > userId: \(userId)")
                self.onResetPasswordComplete?()
            } else {
                self.onResetPasswordFailed?()
            }
        }
    }
    
    func validatePassword(_ password: String?) -> Bool {
        guard let password = password else { return false }
        return password.isValidPassword()
    }
}
