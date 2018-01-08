//
//  EditImageView.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 8..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import UIKit

class EditImageView: UIView {

    var image: UIImageView!
    var plus: UIImageView!
    
    override func draw(_ rect: CGRect) {
        
        print("\(className) > \(#function)")

        image = UIImageView()
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        self.addSubview(image)
        
        image.translatesAutoresizingMaskIntoConstraints = false
        image.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5).isActive = true
        image.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5).isActive = true
        image.topAnchor.constraint(equalTo: self.topAnchor, constant: 5).isActive = true
        image.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5).isActive = true
        
        image.image = #imageLiteral(resourceName: "default_profile")
        
        plus = UIImageView(image: #imageLiteral(resourceName: "img_icon_plus"))
        self.addSubview(plus)
        
        plus.translatesAutoresizingMaskIntoConstraints = false
        plus.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        plus.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        plus.widthAnchor.constraint(equalToConstant: 20).isActive = true
        plus.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
}
