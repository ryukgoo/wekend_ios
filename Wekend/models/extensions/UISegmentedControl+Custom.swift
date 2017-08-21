//
//  UISegmentedControlExtension.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 4. 27..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

extension UISegmentedControl {
    
    func removeBorders() {
        setBackgroundImage(UIImage(color: UIColor(netHex: 0xb3b3b3)), for: .normal, barMetrics: .default)
        setBackgroundImage(UIImage(color: UIColor(netHex: 0xf2797c)), for: .selected, barMetrics: .default)
    }
    
    func customizeText() {
        setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.white], for: .normal)
        setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.white], for: .highlighted)
        setTitleTextAttributes([NSFontAttributeName: UIFont.systemFont(ofSize: 18), NSForegroundColorAttributeName: UIColor.white], for: .selected)
    }
    
}
