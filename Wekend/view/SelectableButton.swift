//
//  SelectableButton.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 8. 29..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

@IBDesignable
class SelectableButton: UIButton {

    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = 6.0
        
        self.titleLabel?.backgroundColor = .clear
        
        self.setTitleColor(.white, for: .normal)
        self.setTitleColor(UIColor(netHex: 0xf2797c), for: .selected)
        
    }
    
    override var isSelected: Bool {
        didSet {
            
            switch isSelected {
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
