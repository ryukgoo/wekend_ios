//
//  UIButton+Indicator.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 6. 5..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

extension UIButton {
    
    func loadingIndicator(_ show: Bool) {
        let tag = 808404
        if show {
            
            isEnabled = false
            alpha = 0.5
            titleLabel?.layer.opacity = 0.0
            
            let indicator = UIActivityIndicatorView()
            let buttonHeight = bounds.size.height
            let buttonWidth = bounds.size.width
            indicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
            indicator.tag = tag
            addSubview(indicator)
            indicator.startAnimating()
            
        } else {
            
            isEnabled = true
            alpha = 1.0
            titleLabel?.layer.opacity = 1.0
            
            if let indicator = viewWithTag(tag) as? UIActivityIndicatorView {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }
    }
}
