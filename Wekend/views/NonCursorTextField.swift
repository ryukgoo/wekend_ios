//
//  NonCursorTextField.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 23..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class NonCursorTextField: UITextField {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initView()
    }
    
    required override init(frame: CGRect) {
        super.init(frame: frame)
        
        initView()
    }
    
    override var isEnabled: Bool {
        didSet {
            switch isEnabled {
            case true:
                self.textColor = .black
                break
            case false:
                self.textColor = UIColor(netHex: 0x9b9b9b)
                break
            }
        }
    }
    
    func initView() {
        
        self.borderStyle = .none
        self.textAlignment = .center
    }
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        return CGRect.zero
    }
    
    override func selectionRects(for range: UITextRange) -> [Any] {
        return []
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) || action == #selector(selectAll(_:)) || action == #selector(paste(_:)) {
            return false
        }
        
        return super.canPerformAction(action, withSender: sender)
    }
 
}
