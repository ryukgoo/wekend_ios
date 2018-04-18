//
//  UserDefaultsProtocol.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 4. 20..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

protocol KeyNamespaceable {}

extension KeyNamespaceable {
    static func namespace<T>(_ key: T) -> String where T: RawRepresentable {
        return "\(Self.self).\(key.rawValue)"
    }
}

protocol ValueUserDefaultable: KeyNamespaceable {
    associatedtype ValueDefaultKey: RawRepresentable
}

extension ValueUserDefaultable where ValueDefaultKey.RawValue == String {
    
    static func set(_ value: Bool, forKey key: ValueDefaultKey) {
        let key = namespace(key)
        UserDefaults.standard.set(value, forKey: key)
    }
    
    static func bool(forKey key: ValueDefaultKey) -> Bool {
        let key = namespace(key)
        return UserDefaults.standard.bool(forKey: key)
    }
    
    static func set(_ value: Int, forKey key: ValueDefaultKey) {
        let key = namespace(key)
        UserDefaults.standard.set(value, forKey: key)
    }
    
    static func integer(forKey key: ValueDefaultKey) -> Int {
        let key = namespace(key)
        return UserDefaults.standard.integer(forKey: key)
    }
    
    static func set(_ value: String?, forKey key: ValueDefaultKey) {
        let key = namespace(key)
        UserDefaults.standard.set(value, forKey: key)
    }
    
    static func string(forKey key: ValueDefaultKey) -> String? {
        let key = namespace(key)
        return UserDefaults.standard.string(forKey: key)
    }
    
    static func remove(forKey key: ValueDefaultKey) {
        let key = namespace(key)
        UserDefaults.standard.removeObject(forKey: key)
    }
}

extension UserDefaults {
    
    struct Account: ValueUserDefaultable {
        enum ValueDefaultKey: String {
            case isUserLoggedIn
            case userName
            case userId
            case deviceUid
            case deviceKey
            case noMoreGuide
        }
    }
    
    struct Authentication: ValueUserDefaultable {
        enum ValueDefaultKey: String {
            case identityId
        }
    }
    
    struct NotificationCount: ValueUserDefaultable {
        enum ValueDefaultKey: String {
            case like
            case receiveMail
            case sendMail
        }
    }
    
    struct RemoteNotification: ValueUserDefaultable {
        enum ValueDefaultKey: String {
            case deviceToken
        }
    }
    
    struct Subscription: ValueUserDefaultable {
        enum ValueDefaultKey: String {
            case expirationDate
        }
    }
}
