//
//  InsertPhoneViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 2. 2..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import AWSCore

class InsertPhoneViewController: UIViewController {
    
    // MARK: Properties
    var username: String?
    var password: String?
    var nickname: String?
    var gender: String?
    var birth: Int?
    
    var activeTextField: UITextField?
    
    var viewModel: InsertPhoneViewModel?
    var registerModel: RegisterUserModel?
    var loginModel: LoginViewModel?
    
    // MARK: IBOutlet
    @IBOutlet weak var inputPhoneText: UITextField!
    @IBOutlet weak var inputCodeText: UITextField!
    @IBOutlet weak var requestCodeButton: RoundedButton!
    @IBOutlet weak var confirmCodeButton: RoundedButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initTextFields()
        
        requestCodeButton.isEnabled = false
        confirmCodeButton.isEnabled = false
        
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
        addKeyboardObserver(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        removeKeyboardObserver(self)
    }
    
    override func viewWillLayoutSubviews() {
        inputPhoneText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
        inputCodeText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func bindViewModel() {
        
        viewModel?.onRequestCodeStart = { [weak self] _ in
            self?.startLoading(message: "인증번호 발송중입니다..")
        }
        
        viewModel?.onRequestComplete = { [weak self] _ in
            let action = AlertAction(buttonTitle: "확인", style: .default, handler: { _ in self?.inputCodeText.becomeFirstResponder() })
            let alert = ButtonAlert(title: nil,
                                    message: "인증번호가 발송되었습니다\n잠시만 기다려 주세요",
                                    actions: [action])
            self?.showButtonAlert(alert)
        }
        
        viewModel?.onRequestCodeFailed = { [weak self] _ in
            let alert = ButtonAlert(title: nil, message: "인증번호 발송에 실패하였습니다\n다시 시도해 주십시오", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        viewModel?.notAvailablePhone = { [weak self] _ in
            let alert = ButtonAlert(title: "전화번호 입력오류", message: "전화번호를 정확히 입력해주세요", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        viewModel?.notAvailableCode = { [weak self] _ in
            let alert = ButtonAlert(title: "인증번호 입력오류", message: "인증번호를 입력해 주세요", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        viewModel?.onConfirmCodeComplete = { [weak self] _ in
            self?.startLoading(message: "가입중입니다")
            self?.registerUser()
            // TODO : register
        }
        
        viewModel?.onConfirmCodeFailed = { [weak self] _ in
            let alert = ButtonAlert(title: nil, message: "인증번호가 일치하지 않습니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        registerModel?.notAvailableInputs = { [weak self] _ in
            let alert = ButtonAlert(title: "가입 오류", message: "입력하지 않은 정보가 있습니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        registerModel?.onRegisterPrepare = { [weak self] _ in
            self?.startLoading(message: "가입중입니다")
        }
        
        registerModel?.onRegisterComplete = { [weak self] username, password in
            self?.loginUser(username: username, password: password)
        }
        
        registerModel?.onRegisterFailed = { [weak self] _ in
            self?.endLoading()
            let alert = ButtonAlert(title: "가입 오류", message: "가입에 실패하였습니다\n다시 시도해 주세요", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        loginModel?.onLoginComplete = { [weak self] _ in
            self?.endLoading()
            self?.performSegue(withIdentifier: SelectPhotoViewController.className, sender: self)
        }
        
        loginModel?.onLoginFailed = { [weak self] _ in
            self?.endLoading()
            let alert = ButtonAlert(title: "Unknown Error", message: "다시 시도해 주세요", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        loginModel?.onLoginError = { [weak self] _ in
            self?.endLoading()
            let alert = ButtonAlert(title: "Unknown Error", message: "다시 시도해 주세요", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
    }
    
    // MARK: IBAction
    @IBAction func requestCodeButtonTapped(_ sender: Any) {
        print("\(className) > \(#function)")
        
        inputPhoneText.resignFirstResponder()
        
        viewModel?.requestVerificationCode(phone: inputPhoneText.text)
    }
    
    @IBAction func confirmCodeButtonTapped(_ sender: Any) {
        viewModel?.confirmVerificationCode(code: inputCodeText.text, phone: inputPhoneText.text)
    }
    
    func registerUser() {
        
        registerModel?.register(username: username, password: password, nickname: nickname, gender: gender, birth: birth, phone: inputPhoneText.text)
        
    }
    
    func loginUser(username: String?, password: String?) {
        loginModel?.login(username: username, password: password)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SelectPhotoViewController.className {
            print("\(className) > \(#function) > identifier : \(String(describing: segue.identifier))")
        }
    }
}

extension InsertPhoneViewController: UITextFieldDelegate {
    
    func initTextFields() {
        inputPhoneText.keyboardType = .phonePad
        inputCodeText.keyboardType = .numberPad
        
        let toolbar: UIToolbar = getToolbar()
        inputPhoneText.inputAccessoryView = toolbar
        inputCodeText.inputAccessoryView = toolbar
        
        inputPhoneText.addTarget(self, action: #selector(self.phoneTextDidChanged(_:)), for: .editingChanged)
        inputCodeText.addTarget(self, action: #selector(self.codeTextDidChanged(_:)), for: .editingChanged)
        
        inputPhoneText.delegate = self
        inputCodeText.delegate = self
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
        self.view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func phoneTextDidChanged(_ textField: UITextField) {
        requestCodeButton.isEnabled = textField.text!.count == 11
    }
    
    func codeTextDidChanged(_ textField: UITextField) {
        confirmCodeButton.isEnabled = textField.text!.count == 6
    }
    
    override func getFocusView() -> UIView? {
        return activeTextField
    }
}
