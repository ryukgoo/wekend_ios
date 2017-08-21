//
//  Alertable.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 4. 27..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

extension UIViewController {
    
    func alert(message: String, title: String = "", completion: ((UIAlertAction) -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: completion)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func startLoading(completion: (() -> Void)? = nil) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let alertView = UIAlertController(title: nil, message: "\(Constants.Title.Message.LOADING)\n\n", preferredStyle: .alert)
        
        let spinnerIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinnerIndicator.center = CGPoint(x: 135, y: 65)
        spinnerIndicator.color = .black
        spinnerIndicator.startAnimating()
        
        alertView.view.addSubview(spinnerIndicator)
        
        present(alertView, animated: false, completion: completion)
    }
    
    func endLoading() {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        if let viewController = presentedViewController as? UIAlertController {
            viewController.dismiss(animated: false, completion: nil)
        }
    }
}
