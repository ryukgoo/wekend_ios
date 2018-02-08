//
//  SignupViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 2. 1..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import AWSCore

class SignupViewController: UIViewController {

    deinit {
        print("\(className) > \(#function)")
    }
    
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
        super.viewWillAppear(animated)
        addKeyboardObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardObserver(self)
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
        
        print("\(className) > \(#function)")
        
        guard let username = usernameInputText.text,
              let password = passwordInputText.text,
              let confirm = confirmInputText.text else {
                print("\(className) > \(#function) > NextButton is enabled, username is nil")
                alert(message: "입력하지 않은 값이 있습니다")
                return;
        }
        
        if password != confirm {
            alert(message: "비밀번호가 일치하지 않습니다")
            return
        }
        
        startLoading(message: "중복 확인중 입니다")
        
        UserInfoRepository.shared.validateUsername(name: username) { available in
            
            DispatchQueue.main.async {
                if available {
                    self.endLoading()
                    self.performSegue(withIdentifier: InputUserInfoViewController.className, sender: self)
                } else {
                    self.endLoading()
                    self.alert(message: "이미 등록된 E-mail입니다", title: "E-mail 중복오류")
                }
            }
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == InputUserInfoViewController.className {
            print("\(className) > \(#function) > identifier : \(String(describing: segue.identifier))")
            
            guard let destination = segue.destination as? InputUserInfoViewController else {
                fatalError("\(className) > \(#function) > destination Error")
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
    
    override func doneKeyboard(_ sender: Any) {
        
        guard let textField = activeTextField else {
            return
        }
        
        validateEditingText(textField)
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        validateEditingText(textField)
        
        return true
    }
    
    func usernameDidChange(_ textField: UITextField) {
        print("\(className) > \(#function) > text : \(String(describing: textField.text))")
        nextButton.isEnabled = isValidInfos()
    }
    
    func passwordDidChange(_ textField: UITextField) {
        print("\(className) > \(#function) > text : \(String(describing: textField.text))")
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
    
    private func validateEditingText(_ textField: UITextField) {
        textField.resignFirstResponder()
        
        if textField == usernameInputText {
            
            if let username = usernameInputText.text {
                if username.isValidEmailAddress() {
                    passwordInputText.becomeFirstResponder()
                    return
                }
            }
            
            alert(message: "형식에 맞지 않는 이메일 주소입니다")
            
        } else if textField == passwordInputText {
            
            if let password = passwordInputText.text {
                if password.isValidPassword() {
                    confirmInputText.becomeFirstResponder()
                    return
                }
            }
            
            alert(message: "비밀번호는 영문과 숫자의 조합 6자리이상 입력해주세요")
            
        } else if textField == confirmInputText {
            
            if let passwordConfirm = confirmInputText.text {
                if passwordConfirm.isValidPassword() {
                    view.endEditing(true)
                    return
                }
            }
            
            alert(message: "비밀번호는 영문과 숫자의 조합 6자리이상 입력해주세요")
            
        }
    }
}

// MARK: - Notification Observers
extension SignupViewController {
    
    override func getFocusView() -> UIView? {
        return activeTextField
    }
    
    /*
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)),
                                               name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)),
                                               name: .UIKeyboardWillHide, object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(_ notification: Notification) {
        var info: Dictionary = notification.userInfo!
        
        if let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            
            guard let textField = self.activeTextField else {
                print("\(className) > \(#function) > activeTextField is nil")
                return
            }
            
            let point = textField.convert(textField.frame.origin, to: self.view)
            
            let textFieldBottomY = point.y + self.view.frame.origin.y
            let keyboardY = self.view.frame.height - keyboardSize.height
            let moveY = textFieldBottomY - keyboardY
            
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                if moveY > 0 {
                    self.view.frame.origin.y -= moveY
                }
            })
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            if self.view.frame.origin.y != 0 {
                self.view.frame.origin.y = 0
            }
        })
    }
 */
}
