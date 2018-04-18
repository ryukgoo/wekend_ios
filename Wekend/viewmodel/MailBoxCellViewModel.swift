//
//  MailBoxCellViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 2. 2..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

typealias MailCompletionHandler = (Mail) -> Void

protocol MailBoxCellBindable {
    var user: UserInfo? { get }
    var mail: Mail? { get }
    var listener: MailCompletionHandler? { get }
}

struct MailBoxCellViewModel: MailBoxCellBindable {
    
    var user: UserInfo?
    var mail: Mail?
    var listener: MailCompletionHandler?
    
    init(user: UserInfo, mail: Mail) {
        self.user = user
        self.mail = mail
    }
}
