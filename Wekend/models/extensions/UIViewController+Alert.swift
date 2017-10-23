//
//  UIViewController+Alert.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 9. 14..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

extension UIViewController {
    
    func alert(message: String, title: String = "", completion: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: completion)
        alertController.addAction(OKAction)
        
        if let presentedVC = self.presentedViewController {
            presentedVC.dismiss(animated: false, completion: nil)
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
}
