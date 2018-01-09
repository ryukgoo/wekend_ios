//
//  EditProfileViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 8..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct EditProfileViewModel: UserViewModel {
    
    var user: Dynamic<UserInfo?>
    
    init() {
        self.user = Dynamic(nil)
    }
    
    func loadUser() {
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else { return }
        self.user.value = userInfo
    }
}
