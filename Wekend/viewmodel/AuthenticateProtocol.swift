//
//  AuthenticateProtocol.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 17..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

protocol UserLoggable {
    
    var onLoginPrepare: NonCompletionHandler? { get set }
    var onLoginComplete: NonCompletionHandler? { get set }
    var onLoginFailed: NonCompletionHandler? { get set }
    var onLoginError: NonCompletionHandler? { get set }
    
    var notAvailableInput: NonCompletionHandler? { get set }
    var notValidUsernameFormat: NonCompletionHandler? { get set }
    var notValidPasswordFormar: NonCompletionHandler? { get set }
    
    func login(username: String?, password: String?)
}

protocol UserRegistable {
    func register(username: String?, password: String?, nickname: String?, gender: String?, birth: Int?, phone: String?)
    
    var onRegisterPrepare: NonCompletionHandler? { get set }
    var onRegisterComplete: ((String, String) -> Void)? { get set }
    var onRegisterFailed: NonCompletionHandler? { get set }
    var notAvailableInputs: NonCompletionHandler? { get set }
}
