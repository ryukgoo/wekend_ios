//
//  GradientView.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 8..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import UIKit

@IBDesignable
class GradientView: UIView {

    @IBInspectable var startColor: UIColor = UIColor.clear
    @IBInspectable var endColor: UIColor = UIColor.clear
    
    override func draw(_ rect: CGRect) {
        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = [startColor.cgColor, endColor.cgColor]
        gradient.zPosition = -1
        layer.addSublayer(gradient)
    }

}
