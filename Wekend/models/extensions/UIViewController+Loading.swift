//
//  Alertable.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 4. 27..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

extension UIViewController {
    
    func startLoading(message: String? = nil, completion: (() -> Void)? = nil) {
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        var loadingMessage = ""
        if message != nil {
            loadingMessage = message!;
        } else {
            loadingMessage = Constants.Title.Message.LOADING
        }
        
        let alertView = UIAlertController(title: nil, message: "\(loadingMessage)\n\n", preferredStyle: .alert)
        
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
