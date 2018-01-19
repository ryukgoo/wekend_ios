//
//  AuthenticateProtocol.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 17..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

protocol UserLoggable {
    
    var onLoggin: (() -> ())? { get set }
    
    func login(username: String, password: String)
    func validateUsername(_ username: String) -> Bool
    func validatePassword(_ password: String) -> Bool
}

protocol UserRegistable {
    func register(username: String)
}
