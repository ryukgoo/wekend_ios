//
//  EditImageView.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 8..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import UIKit

class EditCell: UIView {

    @IBInspectable var index: Int = 0
    
    var imageView: UIImageView!
    var plus: UIImageView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }
    
    private func initView() {
        imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        self.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5).isActive = true
        imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -5).isActive = true
        imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 5).isActive = true
        imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -5).isActive = true
        
        imageView.image = #imageLiteral(resourceName: "default_profile")
        
        plus = UIImageView(image: #imageLiteral(resourceName: "img_icon_plus"))
        self.addSubview(plus)
        
        plus.translatesAutoresizingMaskIntoConstraints = false
        plus.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        plus.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        plus.widthAnchor.constraint(equalToConstant: 20).isActive = true
        plus.heightAnchor.constraint(equalToConstant: 20).isActive = true
    }
    
    override func draw(_ rect: CGRect) {
//        print("\(className) > \(#function)")
    }
}
