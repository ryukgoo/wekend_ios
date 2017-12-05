//
//  ViewExtension.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 4. 27..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation
 
// MARK: UIImageView + Mask

extension UIImageView {
    func toMask(mask: UIImage) {
        
        let maskView = UIImageView()
        maskView.image = mask
        
        self.mask = maskView
        maskView.frame = self.bounds
    }
    
    func toCircle() {
        self.layer.borderWidth = 0.0
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.cornerRadius = self.frame.size.width / 2.0
        self.clipsToBounds = true
    }
    
    func toCircle(size: CGSize) {
        self.layer.borderWidth = 0.0
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.cornerRadius = size.width / 2
        self.clipsToBounds = true
    }
}
