//
//  UIApplicationExtension.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 4. 27..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

extension UIApplication {
    var statusBarView: UIView? {
        return value(forKey: "statusBar") as? UIView
    }
}
