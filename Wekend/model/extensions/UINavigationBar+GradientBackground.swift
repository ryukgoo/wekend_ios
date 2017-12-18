//
//  UINavigationBar+GradientBackground.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 6. 26..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

extension CAGradientLayer {
    
    convenience init(frame: CGRect, colors: [UIColor]) {
        self.init()
        self.frame = frame
        self.colors = []
        for color in colors {
            self.colors?.append(color.cgColor)
        }
        startPoint = CGPoint(x: 0, y: 0)
        endPoint = CGPoint(x: 0, y: 1)
    }
    
    func creatGradientImage() -> UIImage? {
        
        var image: UIImage? = nil
        UIGraphicsBeginImageContext(bounds.size)
        if let context = UIGraphicsGetCurrentContext() {
            render(in: context)
            image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        return image
    }
    
}

extension UINavigationBar {
    
    func setGradientBackground(colors: [UIColor]) {
        
        let updatedFrame = bounds
        let gradientLayer = CAGradientLayer(frame: updatedFrame, colors: colors)
        
        setBackgroundImage(gradientLayer.creatGradientImage(), for: UIBarMetrics.default)
    }
    
    func viewWillAppear() {
        UIApplication.shared.isStatusBarHidden = true
        setBackgroundImage(UIImage(), for: .default)
        shadowImage = UIImage()
        tintColor = .white
    }
    
    func viewDidAppear() {
        var colors = [UIColor]()
        colors.append(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5))
        colors.append(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0))
        setGradientBackground(colors: colors)
    }
}
