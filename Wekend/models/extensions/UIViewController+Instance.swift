//
//  UIViewController+Instance.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 9. 15..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

extension UIViewController {
    class func nibInstance<T: UIViewController>() -> T {
        return T(nibName: String(describing: self), bundle: nil)
    }
    
    class func storyboardInstance<T: UIViewController>() -> T? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? T
    }
    
    class func storyboardInstance<T: UIViewController>(from filename: String) -> T? {
        let storyboard = UIStoryboard(name: filename, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: String(describing: self)) as? T
    }
}
