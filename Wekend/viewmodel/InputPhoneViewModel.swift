//
//  InputPhoneViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 11..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct InputPhoneViewModel: PhoneEditable {
    
    var user: Dynamic<UserInfo?>
    
    init() {
        self.user = Dynamic(nil)
    }
    
    func loadUser() {
        
    }
    
    func requestVerificationCode(phone: String) {
        if validatePhone() {
            let operation = RequestCodeOperation(phone: phone, dataSource: UserInfoManager.shared)
            operation.execute { result in
                if case let Result.success(object: value) = result {
                    print(value)
                } else if case let Result.failure(error) = result {
                    print(error ?? "")
                }
            }
        }
    }
    
    func confirmVerificationCode(code: String) -> Bool {
        return true
    }
    
    private func validatePhone() -> Bool {
        return true
    }
}
