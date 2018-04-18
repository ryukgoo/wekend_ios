//
//  UIViewController+Alert.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 9. 14..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

extension UIViewController {
    
    func alert(message: String, title: String? = nil, completion: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: completion)
        alertController.addAction(OKAction)
        
        if let presentedVC = self.presentedViewController {
            presentedVC.dismiss(animated: false, completion: nil)
        }
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showButtonAlert(_ alert: ButtonAlert) {
        
        let alertController = UIAlertController(title: alert.title,
                                                message: alert.message,
                                                preferredStyle: .alert)
        for action in alert.actions {
            alertController.addAction(UIAlertAction(title: action.buttonTitle,
                                                    style: action.style,
                                                    handler: { _ in action.handler?() }))
        }
        if let viewController = presentedViewController as? UIAlertController {
            viewController.dismiss(animated: false, completion: nil)
        }
        
        present(alertController, animated: true, completion: nil)
    }
}
