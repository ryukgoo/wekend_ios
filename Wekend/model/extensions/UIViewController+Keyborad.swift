//
//  KeyboardObservable.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 9..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

protocol KeyboardObservable {
    func getFocusView() -> UIView?
    func getKeyboardToolbar() -> UIToolbar
    func addKeyboardObserver(_ observer: Any)
    func removeKeyboardObserver(_ observer: Any)
}

extension UIViewController: KeyboardObservable {
    
    func getFocusView() -> UIView? { return nil }
    
    func getKeyboardToolbar() -> UIToolbar {
        let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton: UIBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self,
                                                          action: #selector(self.doneKeyboard(_:)))
        
        var buttonArray = [UIBarButtonItem]()
        buttonArray.append(flexSpace)
        buttonArray.append(doneButton)
        
        toolbar.setItems(buttonArray, animated: false)
        toolbar.sizeToFit()
        
        return toolbar
    }
    
    func doneKeyboard(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    func addKeyboardObserver(_ observer: Any) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)),
                                               name: .UIKeyboardWillShow,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
    }
    
    func removeKeyboardObserver(_ observer: Any) {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(_ notification: Notification) {
        print("\(className) > \(#function)")
        var info: Dictionary = notification.userInfo!
        
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            guard let focusView = self.getFocusView() else { return }
            
            let point = focusView.convert(focusView.frame.origin, to: self.view)
            
            let textFieldBottomY = min(point.y + focusView.frame.size.height, self.view.frame.height)
            let keyboardY = self.view.frame.height - keyboardSize.height
            let moveY = textFieldBottomY - keyboardY
            
            print("\(className) > \(#function) > moveY : \(moveY)")
            
            UIView.animate(withDuration: 0.1, animations: {
                () -> Void in
                
                if moveY > 0 {
                    self.view.frame.origin.y = -moveY
                }
            })
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        print("\(className) > \(#function)")
        UIView.animate(withDuration: 0.1, animations: {
            () -> Void in
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y = 0
            }
        })
    }
}
