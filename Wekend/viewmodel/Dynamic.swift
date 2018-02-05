//
//  Dynamic.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 12. 5..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

class Dynamic<T> {
    
    typealias Listener = (T) -> Void
    var listener: Listener?
    
    func bind(listener: Listener?) {
        self.listener = listener
    }
    
    func bindAndFire(listener: Listener?) {
        self.listener = listener
        listener?(value)
    }
    
    func unbind() {
        self.listener = nil
    }
    
    var value: T {
        didSet {
            listener?(value)
        }
    }
    
    init(_ v: T) {
        value = v
    }
}
