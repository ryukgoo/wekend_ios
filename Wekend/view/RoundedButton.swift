//
//  RoundedButton.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 10..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedButton: UIButton {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = 6.0
        
        self.setTitleColor(.white, for: .disabled)
        self.setTitleColor(UIColor(netHex: 0xf2797c), for: .normal)
    }
    
    override var isEnabled: Bool {
        didSet {
            
            switch isEnabled {
            case true:
                self.layer.backgroundColor = UIColor.white.cgColor
                self.layer.borderWidth = 0.0
                self.layer.borderColor = UIColor.clear.cgColor
                break
            case false :
                self.layer.backgroundColor = UIColor.clear.cgColor
                self.layer.borderWidth = 1.0
                self.layer.borderColor = UIColor.white.cgColor
                break
            }
        }
    }

}
