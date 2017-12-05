//
//  UIViewExtension.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 5. 15..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

extension UIView {
    static let LOADING_VIEW_TAG = 23513
    
    func startLoading() -> Void {
        let loadingView = self.viewWithTag(UIView.LOADING_VIEW_TAG)
        if loadingView == nil {
            let loadingView = UIView.init(frame: self.bounds)
            loadingView.tag = UIView.LOADING_VIEW_TAG
            self.addSubview(loadingView)
            
            let activityIndicator = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
            activityIndicator.center = loadingView.center
            activityIndicator.startAnimating()
            loadingView.addSubview(activityIndicator)
            
            loadingView.alpha = 0
            UIView.animate(withDuration: 0.3, animations: {
                loadingView.alpha = 1
            })
        }
    }
    
    func stopLoading() -> Void {
        if let loadingView = self.viewWithTag(UIView.LOADING_VIEW_TAG) {
            UIView.animate(withDuration: 0.3, animations: {
                loadingView.alpha = 0
            }, completion: { (finished) in
                loadingView.removeFromSuperview()
            })
        }
    }
    
    func addGradient(){
        
        let gradient:CAGradientLayer = CAGradientLayer()
        gradient.frame.size = self.frame.size
        gradient.colors = [UIColor.white.cgColor,UIColor.white.withAlphaComponent(0).cgColor]
        self.layer.addSublayer(gradient)
        
    }
}
