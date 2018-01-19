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

    // MARK: IBOutlet
    @IBOutlet weak var usernameInputText: UITextField!
    @IBOutlet weak var passwordInputText: UITextField!
    @IBOutlet weak var loginButton: RoundedButton!
    @IBOutlet weak var signupButton: RoundedButton!
    @IBOutlet weak var signupConditionLabel: UILabel!
    
    var activeTextField: UITextField?
    var viewModel: LoginViewModel?
    
    deinit {
        print("\(className) > \(#function)")
        removeKeyboardObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTextFields()
        
        loginButton.isEnabled = false
        signupButton.isEnabled = true
        
        bindViewModel()
        addKeyboardObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: IBAction
    
    @IBAction func loginButtonTapped(_ sender: Any) { login() }
    
    @IBAction func signupButtonTapped(_ sender: Any) { showAgreementViewController() }
    
    func login() {
        
        guard let username = usernameInputText.text,
              let password = passwordInputText.text else {
                print("\(className) > \(#function) > username Input Error")
                alert(message: "이메일 또는 비밀번호가 비어있습니다", title: "로그인 실패")
                return
        }
        
        guard let viewModel = viewModel else { return }
        
        if !viewModel.validateUsername(username) {
            alert(message: "지원하지 않는 이메일 형식입니다", title: "E-mail 오류")
            return
        }
        
        if !viewModel.validatePassword(password) {
            alert(message: "패스워드는 영문과 숫자 조합 6자리 이상이어야 합니다", title: "Password 오류")
            return
        }
        
        startLoading(message: "로그인중입니다")
        viewModel.login(username: username, password: password)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == SignupViewController.className {
            print("\(className) > \(#function) > prepare > identifier : \(String(describing: segue.identifier))")
        }
    }
}

extension LoginViewController {
    fileprivate func bindViewModel() {
        self.viewModel?.onShowAlert = { [weak self] alert in
            let alertController = UIAlertController(title: alert.title,
                                                    message: alert.message,
                                                    preferredStyle: .alert)
            for action in alert.actions {
                alertController.addAction(UIAlertAction(title: action.buttonTitle,
                                                        style: action.style,
                                                        handler: { _ in action.handler?() }))
            }
            if let viewController = self?.presentedViewController as? UIAlertController {
                viewController.dismiss(animated: false, completion: nil)
            }
            self?.present(alertController, animated: true, completion: nil)
        }
        
        self.viewModel?.onLoggin = { [weak self] _ in
            self?.endLoading()
            guard let mainVC = MainViewController.storyboardInstance(from: "Main") as? MainViewController else { return }
            self?.present(mainVC, animated: true, completion: nil)
        }
    }
}

// MARK: -UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    
    func initTextFields() {

        usernameInputText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
        usernameInputText.keyboardType = .emailAddress
        usernameInputText.delegate = self
        usernameInputText.inputAccessoryView = getKeyboardToolbar()
        usernameInputText.addTarget(self, action: #selector(self.usernameDidChange(_:)), for: .editingChanged)
        
        passwordInputText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
        passwordInputText.isSecureTextEntry = true
        passwordInputText.delegate = self
        passwordInputText.inputAccessoryView = getKeyboardToolbar()
        passwordInputText.addTarget(self, action: #selector(self.passwordDidChange(_:)), for: .editingChanged)
        
        signupConditionLabel.text = "회원가입을 하면 위켄드의 서비스 약관, 결제서비스 약관, 개인정보 보호정책, 환불 정책, 보호 프로그램 이용약관에 동의하는 것으로 간주됩니다."
    }
    
    override func getFocusView() -> UIView? {
        return activeTextField
    }
    
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
            fatalError("\(className) > \(#function) > get UINavigationViewController Failed")
        }
        
        guard let agreementViewController = navigationController.topViewController as? AgreementViewController else {
            fatalError("\(className) > \(#function) > get AgreementViewController failed")
        }
        
        agreementViewController.delegate = self
        
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func onAgreementTapped() {
        self.performSegue(withIdentifier: SignupViewController.className, sender: self)
    }
}
