//
//  EnumCollection.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 4. 24..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

protocol EnumCollection: Hashable {
    var toString: String { get }
}

extension EnumCollection {
    
    static func cases() -> AnySequence<Self> {
        typealias S = Self
        return AnySequence { () -> AnyIterator<S> in
            var raw = 0
            return AnyIterator {
                let current : Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: S.self, capacity: 1) { $0.pointee } }
                guard current.hashValue == raw else { return nil }
                raw += 1
                return current
            }
        }
    }
    
    static func toStrings() -> AnySequence<String> {
        typealias S = Self
        return AnySequence { () -> AnyIterator<String> in
            var raw = 0
            return AnyIterator {
                let current : Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: S.self, capacity: 1) { $0.pointee } }
                guard current.hashValue == raw else { return nil }
                raw += 1
                return current.toString
            }
        }
    }
    
    static func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
        var i = 0
        return AnyIterator {
            let next = withUnsafeBytes(of: &i, { $0.load(as: T.self) })
            if next.hashValue != i { return nil }
            i += 1
            return next
        }
    }
}
