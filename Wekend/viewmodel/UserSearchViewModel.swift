//
//  ConfirmPhoneViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 3. 8..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct UserSearchViewModel: UserSearchable {
    
    let userDataSource: UserInfoDataSource
    
    var onSearchUsernameComplete: UserInfoCompletionHandler?
    var onSearchUsernameFailed: NonCompletionHandler?
    var onSearchPhoneComplete: UserInfoCompletionHandler?
    var onSearchPhoneFailed: NonCompletionHandler?
    
    init(userDataSource: UserInfoDataSource) {
        self.userDataSource = userDataSource
    }
    
    func searchUser(username: String?) {
        
        guard let username = username else {
            onSearchUsernameFailed?()
            return
        }
        
        let operation = SearchUserByUsernameOpration(username: username, dataSource: UserInfoRepository.shared)
        operation.execute { result in
            guard let info = result else {
                self.onSearchUsernameFailed?()
                return
            }
            self.onSearchUsernameComplete?(info)
        }
    }
    
    func searchUser(phone: String?) {
        
        guard let phone = phone else {
            onSearchPhoneFailed?()
            return
        }
        
        let operation = SearchUserByPhoneOperation(phone: phone, dataSource: UserInfoRepository.shared)
        operation.execute { result in
            guard let info = result else {
                self.onSearchPhoneFailed?()
                return
            }
            self.onSearchPhoneComplete?(info)
        }
    }
}
