//
//  InsertPhoneViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 2. 2..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class InsertPhoneViewController: UIViewController {
    
    // MARK: Properties
    
    var username: String?
    var password: String?
    var nickname: String?
    var gender: String?
    var birth: Int?
    var verficationCode: String?
    
    var activeTextField: UITextField?
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        inputPhoneText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
        inputCodeText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    // MARK: IBAction
    
    @IBAction func requestCodeButtonTapped(_ sender: Any) {
        printLog("requestCodeButtonTapped")
        
        inputPhoneText.resignFirstResponder()
        
        guard let phoneNumber = inputPhoneText.text else {
            self.alert(message: "전화번호를 정확히 입력해주세요", title: "전화번호 입력오류")
            return
        }
        
        UserInfoManager.sharedInstance.sendVerificationCode(phoneNumber: phoneNumber).continueWith(block: {
            (task: AWSTask) -> Any! in
            
            if task.error == nil {
                
                guard let result = task.result else {
                    self.printLog("getVerificationCode Failed")
                    
                    DispatchQueue.main.async {
                        self.alert(message: "다시 시도해주세요", title: "인증번호 발송오류")
                    }
                    
                    return nil
                }
                
                DispatchQueue.main.async {
                    self.requestCodeButton.isEnabled = false
                    self.alert(message: "인증번호가 발송되었습니다", title: "인증번호 발송", completion: {
                        action -> Void in
                        self.inputCodeText.becomeFirstResponder()
                    })
                    
                }
                
                self.verficationCode = result as String
            }
            
            return nil
        })
        
    }
    
    @IBAction func confirmCodeButtonTapped(_ sender: Any) {
        
        guard let inputVerificationCode = inputCodeText.text else {
            alert(message: "인증번호를 입력해 주세요", title: "인증번호 입력오류")
            return
        }
        
        if inputVerificationCode != verficationCode {
            alert(message: "인증번호가 맞지 않습니다", title: "인증번호 확인")
            return
        }
        
        guard let username = self.username else {
            fatalError("InsertPhoneViewController > register > username Error")
        }
        
        guard let password = self.password else {
            fatalError("InsertPhoneViewController > register > password Error")
        }
        
        guard let nickname = self.nickname else {
            fatalError("InsertPhoneViewController > register > nickname Error")
        }
        
        guard let gender = self.gender else {
            fatalError("InsertPhoneViewController > register > gender Error")
        }
        
        guard let birth = self.birth else {
            fatalError("InsertPhoneViewController > register > birth Error")
        }
        
        guard let phone = self.inputPhoneText.text else {
            fatalError("InsertPhoneViewController > register > phone Error")
        }
        
        startLoading(message: "가입중입니다")
        
        AmazonClientManager.sharedInstance.devIdentityProvider?.register(username: username, password: password, nickname: nickname, gender: gender, birth: birth, phone: phone).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let userId = task.result as NSString? else {
                fatalError("InsertPhoneViewController > register > userId is nil")
            }
            
            AmazonClientManager.sharedInstance.devIdentityProvider?.loginUser(username: username, password: password).continueWith(executor: AWSExecutor.mainThread(), block: {
                (loginTask: AWSTask) -> Any! in
                
                guard let loginEnable = loginTask.result as NSString? else {
                    fatalError("InsertPhoneViewController > loginUser > login result Error")
                }
                
                // OnSuccess
                if loginEnable == "true" {
                    
                    AmazonClientManager.sharedInstance.devIdentityProvider?.token().continueOnSuccessWith(executor: AWSExecutor.mainThread(), block: {
                        (tokenTask: AWSTask) -> Any! in
                        
                        guard let _ = tokenTask.result else {
                            fatalError("InsertPhoneViewController > getToken > token is nil")
                        }
                        
                        UserInfoManager.sharedInstance.getOwnedUserInfo(userId: userId as String).continueWith(executor: AWSExecutor.mainThread(), block: {
                            (getUserTask: AWSTask) -> Any! in
                            
                            if getUserTask.error != nil { return nil }
                            
                            UserInfoManager.sharedInstance.registEndpointARN()
                            
                            DispatchQueue.main.async {
                                self.endLoading()
                                self.performSegue(withIdentifier: SelectPhotoViewController.className, sender: self)
                            }
                            
                            return nil
                        })
                        
                        if tokenTask.error != nil {
                            DispatchQueue.main.async {
                                self.endLoading()
                            }
                        }
                        
                        return nil
                    })
                } else {
                    // LoginTask returns "false"
                    DispatchQueue.main.async {
                        self.endLoading()
                    }
                }
                
                return nil
            })
            
            return nil
        })
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == SelectPhotoViewController.className {
            printLog("prepare > identifier : \(String(describing: segue.identifier))")
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
    
    func doneKeyboard(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
    }
    
    func phoneTextDidChanged(_ textField: UITextField) {
        requestCodeButton.isEnabled = textField.text!.characters.count == 11
    }
    
    func codeTextDidChanged(_ textField: UITextField) {
        confirmCodeButton.isEnabled = textField.text!.characters.count == 6
    }
}
