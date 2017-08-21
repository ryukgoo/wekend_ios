//
//  FullWidthMenuCell.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 3. 26..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import DropDownMenuKit

class FullWidthMenuCell: DropDownMenuCell {

    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        
        if let textLabel = textLabel {
            if customView != nil && textLabel.text == nil {
                textLabel.text = "Custom View Origin Hint"
            }
            textLabel.isHidden = customView != nil
        }
        
        if let imageView = imageView, imageView.image != nil {
            imageView.frame.size = CGSize(width: 24, height: 24)
            imageView.center = CGPoint(x: imageView.center.x, y: bounds.size.height / 2)
        }
        
        if let customView = customView {
            if let textLabel = textLabel, imageView?.image != nil {
                customView.frame.origin.x = textLabel.frame.origin.x
            }
            else
            {
                customView.center.x = bounds.width / 2
            }
            customView.center.y =  bounds.height / 2
            
        }
        
    }
}
