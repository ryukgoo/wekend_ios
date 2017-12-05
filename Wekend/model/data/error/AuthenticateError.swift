//
//  AuthenticateError.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 10. 19..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

enum AuthenticateError: Error {
    case userNotFound
    case userDisabled
    case unknown
}

enum PurchaseError: Error {
    case notEnoughPoint
}
