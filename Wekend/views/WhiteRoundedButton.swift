//
//  WhiteRoundedButton.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 3. 17..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class WhiteRoundedButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = 6.0
        
        self.setTitleColor(UIColor(netHex: 0xf2797c), for: .disabled)
        self.setTitleColor(.white, for: .normal)
    }
    
    override var isEnabled: Bool {
        didSet {
            
            switch isEnabled {
            case true:
                self.layer.backgroundColor = UIColor(netHex: 0xf2797c).cgColor
                self.layer.borderWidth = 0.0
                self.layer.borderColor = UIColor.white.cgColor
                break
            case false :
                self.layer.backgroundColor = UIColor.white.cgColor
                self.layer.borderWidth = 1.0
                self.layer.borderColor = UIColor(netHex: 0xf2797c).cgColor
                break
            }
        }
    }
}
