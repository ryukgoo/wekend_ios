//
//  LoginViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 2. 1..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import AWSCore

class LoginViewController: UIViewController {

    deinit {
        printLog(#function)
    }
    
    // MARK: AlertController with IndicatorView
    
    var activeTextField: UITextField?
    
    // MARK: IBOutlet
    
    @IBOutlet weak var usernameInputText: UITextField!
    @IBOutlet weak var passwordInputText: UITextField!
    @IBOutlet weak var loginButton: RoundedButton!
    @IBOutlet weak var signupButton: RoundedButton!
    @IBOutlet weak var signupConditionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        printLog(#function)
        
        initTextFields()
        
        // buttons
        loginButton.isEnabled = false
        signupButton.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.isTranslucent = true
        
        addNotificationObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        removeNotificationObservers()
    }
    
    override func viewWillLayoutSubviews() {
        usernameInputText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
        passwordInputText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: IBAction
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        login()
    }
    
    @IBAction func signupButtonTapped(_ sender: Any) {
        showAgreementViewController()
    }
    
    func login() {
        
        guard let username = usernameInputText.text,
              let password = passwordInputText.text else {
                printLog("LoginViewController > login > username Input Error")
                alert(message: "이메일 또는 비밀번호가 비어있습니다", title: "로그인 실패")
                return
        }
        
        if !username.isValidEmailAddress() {
            printLog("login > username is not valid")
            alert(message: "지원하지 않는 이메일 형식입니다", title: "E-mail 오류")
        }
        
        if !password.isValidPassword() {
            printLog("login > password is not valid")
            alert(message: "패스워드는 영문과 숫자 조합 6자리 이상이어야 합니다", title: "Password 오류")
        }
        
        startLoading(message: "로그인중입니다")
        
        AmazonClientManager.sharedInstance.devIdentityProvider?.loginUser(username: username, password: password).continueWith(block: {
            (task: AWSTask) -> Any! in
            
            if let error = task.error as? AuthenticateError {
                self.printLog("error : \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.endLoading()
                    self.alert(message: "등록되지 않은 계정이거나\n비밀번호가 일치하지 않습니다.", title: "로그인실패", completion: nil)
                }
                return nil
            }
            
            guard let enabled = task.result else {
                DispatchQueue.main.async {
                    self.endLoading()
                    self.alert(message: "등록되지 않은 계정이거나\n비밀번호가 일치하지 않습니다.", title: "로그인실패", completion: nil)
                }
                self.printLog("LoginViewController > login > enabled Error")
                return nil
            }
            
            self.printLog("login > enabled : \(enabled)")
            
            if enabled.isEqual(to: "true") {
                self.printLog("go MainViewController")
                
                guard let userId = UserDefaults.Account.string(forKey: .userId) else {
                    fatalError("LoginViewController > login > get UserId from UserDefaults Error")
                }
                
                UserInfoManager.sharedInstance.getOwnedUserInfo(userId: userId).continueWith(block: {
                    (getUserTask : AWSTask) -> Any! in
                    
                    self.printLog("Fetch UserInfo Complete")
                    
                    if getUserTask.error != nil {
                        fatalError("LoginViewController > getUserTask > result Error")
                    }
                    
                    UserInfoManager.sharedInstance.registEndpointARN()
                    
                    DispatchQueue.main.async {
                        self.endLoading()
                        guard let mainVC = MainViewController.storyboardInstance(from: "Main") as? MainViewController else { return }
                        self.present(mainVC, animated: true, completion: nil)
                    }
                    return nil
                })
            }
            return nil
        })
        
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == SignupViewController.className {
            printLog("prepare > identifier : \(String(describing: segue.identifier))")
        }
        
    }
    
}

// MARK: -UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    
    func initTextFields() {

        usernameInputText.keyboardType = .emailAddress
        passwordInputText.isSecureTextEntry = true
        
        usernameInputText.delegate = self
        passwordInputText.delegate = self
        
        usernameInputText.addTarget(self, action: #selector(self.usernameDidChange(_:)), for: .editingChanged)
        passwordInputText.addTarget(self, action: #selector(self.passwordDidChange(_:)), for: .editingChanged)
        
        signupConditionLabel.text = "회원가입을 하면 위켄드의 서비스 약관, 결제서비스 약관, 개인정보 보호정책, 환불 정책, 보호 프로그램 이용약관에 동의하는 것으로 간주됩니다."
        
        let toolbar = getToolbar()
        
        usernameInputText.inputAccessoryView = toolbar
        passwordInputText.inputAccessoryView = toolbar
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
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        
        if textField == self.usernameInputText {
            passwordInputText.becomeFirstResponder()
        } else if textField == self.passwordInputText {
            login()
        }
        
        return true
    }
    
    func usernameDidChange(_ textField: UITextField) {
        self.loginButton.isEnabled = textField.text!.isValidEmailAddress()
        
    }
    
    func passwordDidChange(_ textField: UITextField) { }
}

/*
 * agreement privacy
 */
extension LoginViewController: AgreementDelegate {
    
    func showAgreementViewController() {
        
        let identifier = AgreementViewController.className
        
        guard let navigationController = self.storyboard?.instantiateViewController(withIdentifier: identifier) as? UINavigationController else {
            fatalError("LoginViewController > get UINavigationViewController Failed")
        }
        
        guard let agreementViewController = navigationController.topViewController as? AgreementViewController else {
            fatalError("LoginViewController > get AgreementViewController failed")
        }
        
        agreementViewController.delegate = self
        
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func onAgreementTapped() {
        self.performSegue(withIdentifier: SignupViewController.className, sender: self)
    }
}

extension LoginViewController: Observerable {
    
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
                printLog("keyboardWillShow > activeTextField is nil")
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
}
