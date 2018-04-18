//
//  InsertPhoneViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 3. 2..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct InsertPhoneViewModel: PhoneVerifiable {
    
    let userDataSource: UserInfoDataSource
    
    var notAvailablePhone: NonCompletionHandler?
    var onRequestCodeStart: NonCompletionHandler?
    var onRequestComplete: NonCompletionHandler?
    var onRequestCodeFailed: NonCompletionHandler?
    
    var onConfirmCodeFailed: NonCompletionHandler?
    var onConfirmCodeComplete: NonCompletionHandler?
    var notAvailableCode: NonCompletionHandler?
    
    init(userDataSource: UserInfoDataSource) {
        self.userDataSource = userDataSource
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
            onConfirmCodeComplete?()
        } else {
            onConfirmCodeFailed?()
        }
    }
}
