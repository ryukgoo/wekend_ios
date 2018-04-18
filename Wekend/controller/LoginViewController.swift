//
//  LoginViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 2. 1..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import AWSCore
import MessageUI

class LoginViewController: UIViewController {

    // MARK: IBOutlet
    @IBOutlet weak var usernameInputText: UITextField!
    @IBOutlet weak var passwordInputText: UITextField!
    @IBOutlet weak var loginButton: RoundedButton!
    @IBOutlet weak var signupButton: RoundedButton!
    @IBOutlet weak var signupConditionLabel: UILabel!
    
    var activeTextField: UITextField?
    var viewModel: LoginViewModel?
    var registedUsername: String?
    
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
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
        
        navigationController?.isNavigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        usernameInputText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
        passwordInputText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
    }
    
    // MARK: IBAction
    
    @IBAction func loginButtonTapped(_ sender: Any) { login() }
    
    @IBAction func signupButtonTapped(_ sender: Any) { showAgreementViewController() }
    
    func login() {
        viewModel?.login(username: usernameInputText.text, password: passwordInputText.text)
    }

    @IBAction func onFindAccountButtonTapped(_ sender: Any) {
        print("\(className) > \(#function)")
        
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let findEmailAction = UIAlertAction(title: "이메일 찾기", style: .default) { _ in
            guard let phoneViewController = ConfirmPhoneViewController.storyboardInstance(from: "Login") as? ConfirmPhoneViewController else { return }
            phoneViewController.viewModel = InsertPhoneViewModel(userDataSource: UserInfoRepository.shared)
            phoneViewController.confirmPhoneModel = UserSearchViewModel(userDataSource: UserInfoRepository.shared)
            self.navigationController?.pushViewController(phoneViewController, animated: true)
        }
        let findPasswordAction = UIAlertAction(title: "비밀번호 찾기", style: .default) { _ in
            guard let vc = FindAccountViewController.storyboardInstance(from: "Login") as? FindAccountViewController else { return }
            vc.viewModel = UserSearchViewModel(userDataSource: UserInfoRepository.shared)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        let helpAction = UIAlertAction(title: "문의하기", style: .default) { _ in
            self.sendMail()
        }
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in }
        
        sheet.addAction(findEmailAction)
        sheet.addAction(findPasswordAction)
        sheet.addAction(helpAction)
        sheet.addAction(cancelAction)
        
        present(sheet, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == SignupViewController.className {
            print("\(className) > \(#function) > prepare > identifier : \(String(describing: segue.identifier))")
        }
    }
}

extension LoginViewController {
    fileprivate func bindViewModel() {
        
        self.viewModel?.notAvailableInput = { [weak self] _ in
            print("\(#function) > notAvailableInput")
            let alert = ButtonAlert(title: "로그인 실패", message: "이메일 또는 비밀번호가 비어있습니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.notValidUsernameFormat = { [weak self] _ in
            print("\(#function) > notValidUsernameFormat")
            let alert = ButtonAlert(title: "E-mail 오류", message: "지원하지 않는 이메일 형식입니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.notValidPasswordFormar = { [weak self] _ in
            print("\(#function) > notValidPasswordFormar")
            let alert = ButtonAlert(title: "비밀번호 오류",
                                    message: "패스워드는 영문과 숫자 조합 6자리 이상이어야 합니다",
                                    actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.onLoginPrepare = { [weak self] _ in
            print("\(#function) > onLoginPrepare")
            self?.startLoading(message: "로그인중입니다")
        }
        
        self.viewModel?.onLoginComplete = { [weak self] _ in
            self?.endLoading()
            guard let mainVC = MainViewController.storyboardInstance(from: "Main") as? MainViewController else { return }
            self?.present(mainVC, animated: true, completion: nil)
        }
        
        self.viewModel?.onLoginFailed = { [weak self] _ in
            print("\(#function) > onLoginFailed")
            let alert = ButtonAlert(title: "로그인 실패",
                                         message: "등록되지 않은 계정이거나\n비밀번호가 일치하지 않습니다",
                                         actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.onLoginError = { [weak self] _ in
            print("\(#function) > onLoginError")
            let alert = ButtonAlert(title: "Unknown Error", message: "다시 시도해 주세요", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
    }
}

// MARK: -UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    
    func initTextFields() {

        usernameInputText.keyboardType = .emailAddress
        usernameInputText.delegate = self
        usernameInputText.inputAccessoryView = getKeyboardToolbar()
        usernameInputText.addTarget(self, action: #selector(self.usernameDidChange(_:)), for: .editingChanged)
        
        passwordInputText.isSecureTextEntry = true
        passwordInputText.delegate = self
        passwordInputText.inputAccessoryView = getKeyboardToolbar()
        passwordInputText.addTarget(self, action: #selector(self.passwordDidChange(_:)), for: .editingChanged)
        
        if let username = registedUsername {
            usernameInputText.text = username
        }
        
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

extension LoginViewController: MFMailComposeViewControllerDelegate {
    
    func sendMail() {
        if MFMailComposeViewController.canSendMail() {
            
            let mailVC = MFMailComposeViewController()
            mailVC.mailComposeDelegate = self
            
            mailVC.setToRecipients(["entuitiondevelop@gmail.com"])
            mailVC.setSubject("고객센터 문의메일")
            mailVC.setMessageBody("계정 이메일:\n문의내용:", isHTML: false)
            
            present(mailVC, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}
