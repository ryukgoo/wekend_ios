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
    
    var onProposePrepare: StringComletionHandler? { get set }
    var onProposeComplete: StringComletionHandler? { get set }
    var onProposeFailed: NonCompletionHandler? { get set }
    
    func accept()
    var onAcceptComplete: StringComletionHandler? { get set }
    var onAcceptFailed: NonCompletionHandler? { get set }
    
    func reject()
    var onRejectComplete: StringComletionHandler? { get set }
    var onRejectFailed: NonCompletionHandler? { get set }
}

protocol MailListLoadable {
    var datas: Dynamic<Array<Mail>?> { get }
    func loadMailList()
}

protocol MailDeletable {
    func delete(mail: Mail, index: Int, completion: @escaping (Bool) -> Void)
}
