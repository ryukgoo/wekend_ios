//
//  SignupViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 2. 1..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController {

    // MARK: IBOutlet
    
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var usernameInputText: UITextField!
    @IBOutlet weak var passwordInputText: UITextField!
    @IBOutlet weak var confirmInputText: UITextField!
    @IBOutlet weak var nextButton: RoundedButton!

    // Properties
    
    var activeTextField: UITextField?
    var isValidEmail: Bool = false
    var isValidPassword: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initTextFields()
        
        // Buttons
        nextButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        usernameInputText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
        passwordInputText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
        confirmInputText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: IBAction
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        
        printLog("nextButtonTapped")
        
        startLoading()
        
        guard let username = usernameInputText.text else {
            fatalError("nextButtonTapped > NextButton is enabled, username is nil")
        }
        
        UserInfoManager.sharedInstance.isUsernameAvailable(username: username).continueWith(block: {
            (task: AWSTask) -> Any! in
            
            guard let result = task.result as? Bool else {
                self.printLog("nextButtonTapped > check username duplicated Error > result is nil")
                return nil
            }
            
            self.printLog("nextButtonTapped > result : \(String(describing: result))")
            self.endLoading()
            
            if result {
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: InputUserInfoViewController.className, sender: self)
                }
            } else {
                DispatchQueue.main.async {
                    self.alert(message: "이미 등록된 E-mail입니다", title: "E-mail 중복오류")
                }
            }
            
            return nil
        })
    }
    
    func keyboardWillShow(_ notification: Notification) {
        var info: Dictionary = notification.userInfo!
        
        if let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            guard let textField = self.activeTextField else {
                printLog("keyboardWillShow > activeTextField is nil")
                return
            }
            
            let point = textField.convert(textField.frame.origin, to: self.view)
            
            let textFieldBottomY = point.y + self.view.frame.origin.y
            let keyboardY = self.view.frame.height - keyboardSize.height
            let moveY = textFieldBottomY - keyboardY
            
            UIView.animate(withDuration: 0.1, animations: {
                () -> Void in
                
                if moveY > 0 {
                    self.view.frame.origin.y -= moveY
                }
                
            })
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.1, animations: {
            () -> Void in
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y = 0
            }
        })
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == InputUserInfoViewController.className {
            printLog("prepare > identifier : \(String(describing: segue.identifier))")
            
            guard let destination = segue.destination as? InputUserInfoViewController else {
                fatalError("SignupViewController > prepare > destination Error")
            }
            
            destination.username = usernameInputText.text
            destination.password = passwordInputText.text
        }
    }
    
}

// MARK: -UITextFieldDelegate

extension SignupViewController: UITextFieldDelegate {
    
    func initTextFields() {
        // TextFields
        usernameInputText.keyboardType = .emailAddress
        passwordInputText.isSecureTextEntry = true
        passwordInputText.keyboardType = .alphabet
        confirmInputText.isSecureTextEntry = true
        confirmInputText.keyboardType = .alphabet
        
        usernameInputText.delegate = self
        passwordInputText.delegate = self
        confirmInputText.delegate = self
        
        usernameInputText.addTarget(self, action: #selector(self.usernameDidChange(_:)), for: .editingChanged)
        passwordInputText.addTarget(self, action: #selector(self.passwordDidChange(_:)), for: .editingChanged)
        confirmInputText.addTarget(self, action: #selector(self.passwordDidChange(_:)), for: .editingChanged)
        
        let toolbar = getToolbar()
        usernameInputText.inputAccessoryView = toolbar
        passwordInputText.inputAccessoryView = toolbar
        confirmInputText.inputAccessoryView = toolbar
    }
    
    func getToolbar() -> UIToolbar {
        
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
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        if textField == usernameInputText {
            passwordInputText.becomeFirstResponder()
        } else if textField == passwordInputText {
            confirmInputText.becomeFirstResponder()
        } else if textField == confirmInputText {
            nextButtonTapped(textField)
        }
        
        return true
    }
    
    func usernameDidChange(_ textField: UITextField) {
        
        printLog("usernameDidChange > text : \(String(describing: textField.text))")
        
        nextButton.isEnabled = isValidInfos()
    }
    
    func passwordDidChange(_ textField: UITextField) {
        
        printLog("passwordDidChange > text : \(String(describing: textField.text))")
        
        printLog("password is valid : \(textField.text!.isValidPassword())")
        
        nextButton.isEnabled = isValidInfos()
    }
    
    private func isValidInfos() -> Bool {
        guard let username = usernameInputText.text,
            let password = passwordInputText.text,
            let passwordConfirm = confirmInputText.text else {
                return false
        }
        
        return username.isValidEmailAddress() && password.isValidPassword() && passwordConfirm.isValidPassword()
    }
}
