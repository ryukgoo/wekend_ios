//
//  NSObjectExtension.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 5. 14..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

extension NSObject {
    var className: String {
        return String(describing: type(of: self))
    }
    
    class var className: String {
        return String(describing: self)
    }
    
    public func printLog(_ message: String) {
        print("\(className) > \(message)")
    }
}
