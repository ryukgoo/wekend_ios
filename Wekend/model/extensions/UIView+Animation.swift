//
//  UIView+Animation.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 5. 25..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

extension UIView {
    static let ANIMATION_DURATION = 0.3
    
    func fadeIn(withDuration duration: TimeInterval = ANIMATION_DURATION) {
        self.alpha = 0.0
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 1.0
        })
    }
    
    func fadeOut(withDuration duration: TimeInterval = ANIMATION_DURATION) {
        self.alpha = 1.0
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        })
    }
}
