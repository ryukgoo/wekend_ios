//
//  ConfirmPhoneViewController.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 3. 8..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import UIKit

class ConfirmPhoneViewController: UIViewController {
    
    var activeTextField: UITextField?
    
    var registedUsername: String?
    
    var viewModel: InsertPhoneViewModel?
    var confirmPhoneModel: UserSearchViewModel?
    
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
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SelectPhotoViewController.className {
            print("\(className) > \(#function) > identifier : \(String(describing: segue.identifier))")
        }
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
            
            if self?.registedUsername != nil {
                self?.confirmPhoneModel?.searchUser(username: self?.registedUsername)
            } else {
                self?.confirmPhoneModel?.searchUser(phone: self?.inputPhoneText.text)
            }
        }
        
        viewModel?.onConfirmCodeFailed = { [weak self] _ in
            let alert = ButtonAlert(title: nil, message: "인증번호가 일치하지 않습니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        confirmPhoneModel?.onSearchUsernameComplete = { [weak self] userInfo in
            self?.gotoResetPasswordView(userId: userInfo.userid, username: userInfo.username)
        }
        
        confirmPhoneModel?.onSearchUsernameFailed = { [weak self] _ in
            let alert = ButtonAlert(title: "계정찾기 실패", message: "입력하신 정보를 찾을 수 없습니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        confirmPhoneModel?.onSearchPhoneComplete = { [weak self] userInfo in
            self?.confirmAccount(userInfo: userInfo)
        }
        
        confirmPhoneModel?.onSearchPhoneFailed = { [weak self] _ in
            let alert = ButtonAlert(title: "계정찾기 실패", message: "입력하신 정보를 찾을 수 없습니다", actions: [AlertAction.done])
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

    func gotoResetPasswordView(userId: String, username: String?) {
        guard let username = username else { return }
        print("\(className) > \(#function) > username: \(username)")
        
        guard let resetVC = ResetPasswordViewController.storyboardInstance(from: "Login") as? ResetPasswordViewController else {
            return
        }
        
        resetVC.viewModel = ResetPasswordViewModel()
        resetVC.userId = userId
        resetVC.username = username
        navigationController?.pushViewController(resetVC, animated: true)
    }
    
    func confirmAccount(userInfo: UserInfo) {
        print("\(className) > \(#function)")
        
        guard let username = userInfo.username else { return }
        
        let loginAction = AlertAction(buttonTitle: "로그인 하기", style: .default, handler: { _ in
            self.gotoLoginView(userInfo: userInfo)
        })
        let resetAction = AlertAction(buttonTitle: "비밀번호 찾기", style: .default, handler: { _ in self.resetPassword() })
        
        let alert = ButtonAlert(title: "아이디 찾기", message: "\n\n해당 정보로 가입된 아이디는\n\n\(username)\n\n입니다",
            actions: [loginAction, resetAction])
        
        showButtonAlert(alert)
    }
    
    func gotoLoginView(userInfo: UserInfo) {
        print("\(className) > \(#function)")
        
        ApplicationNavigator.shared.showLoginViewController(with: userInfo.username)
    }
    
    func resetPassword() {
        print("\(className) > \(#function)")
        
    }
}

extension ConfirmPhoneViewController: UITextFieldDelegate {
    
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
