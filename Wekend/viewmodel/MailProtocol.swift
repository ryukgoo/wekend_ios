//
//  MailProtocol.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 11..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

protocol MailLoadable {
    var mail: Dynamic<Mail?> { get }
    func loadMail()
}

protocol MailViewModel {
    func propose(message: String?)
    func accept()
    func reject()
}

protocol MailListLoadable {
    var datas: Dynamic<Array<Mail>?> { get }
    func loadMailList()
}

protocol MailDeletable {
    func delete(mail: Mail, index: Int, completion: @escaping (Bool) -> Void)
}
