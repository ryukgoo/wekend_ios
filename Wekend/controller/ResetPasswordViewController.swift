//
//  ResetPasswordViewController.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 3. 2..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import UIKit

class ResetPasswordViewController: UIViewController {

    var userId: String?
    var username: String?
    var viewModel: ResetPasswordViewModel?
    
    var activeTextView: UITextField?
    
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var confirmText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboardObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObserver(self)
    }
    
    override func viewWillLayoutSubviews() {
        passwordText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
        confirmText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onConfirmButtonTapped(_ sender: Any) {
        
        guard let userId = userId else { fatalError() }
        
        viewModel?.reset(userId: userId, password: passwordText.text, confirm: confirmText.text)
    }
    
    func gotoLoginView() {
        ApplicationNavigator.shared.showLoginViewController(with: username)
    }
    
    fileprivate func bindViewModel() {
        
        viewModel?.invalidPasswordFormat = { [weak self] _ in
            let alert = ButtonAlert(title: "비밀번호 재설정 실패", message: "비밀번호는 영문과 숫자의 조합 6자리 이상이어야 합니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        viewModel?.notEqualPasswordConfirm = { [weak self] _ in
            let alert = ButtonAlert(title: "비밀번호 재설정 실패", message: "비밀번호가 일치하지 않습니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        viewModel?.onResetPasswordPrepare = { [weak self] _ in
            self?.startLoading(message: "재설정중입니다...")
        }
        
        viewModel?.onResetPasswordFailed = { [weak self] _ in
            self?.endLoading()
            
            let alert = ButtonAlert(title: "비밀번호 재설정 실패", message: "비밀번호가 일치하지 않습니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        viewModel?.onResetPasswordComplete = { [weak self] _ in
            self?.endLoading()
            
            let action = AlertAction(buttonTitle: "확인", style: .default, handler: { self?.gotoLoginView() })
            let alert = ButtonAlert(title: "비밀번호 재설정", message: "비밀번호가 재설정되었습니다\n로그인화면으로 돌아갑니다", actions: [action])
            self?.showButtonAlert(alert)
        }
    }
    
}

extension ResetPasswordViewController: UITextFieldDelegate {
    
    func initTextFields() {
        passwordText.delegate = self
        passwordText.inputAccessoryView = getKeyboardToolbar()
        
        confirmText.delegate = self
        confirmText.inputAccessoryView = getKeyboardToolbar()
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        print("\(className) > \(#function)")
        activeTextView = textField
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func doneKeyboard(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    override func getFocusView() -> UIView? {
        return activeTextView
    }
    
}
