//
//  VerticallyCenteredTextView.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 3. 29..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class VerticallyCenteredTextView: UITextView {

    override var contentSize: CGSize {
        didSet {
            
            printLog("contentSize > didSet")
            
            var topCorrection = (bounds.size.height - contentSize.height * zoomScale) / 2.0
            topCorrection = max(0, topCorrection)
            contentInset = UIEdgeInsets(top: -topCorrection - 2, left: 0, bottom: 0, right: 0)
        }
    }

}
