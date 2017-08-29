//
//  InputUserInfoViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 2. 1..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class InputUserInfoViewController: UIViewController {

    // MARK: Properties
    
    var username: String?
    var password: String?
    
    var yearArray : [Int] = []
    
    // MARK: IBOutlet
    
    @IBOutlet weak var nicknameInputText: UITextField!
    @IBOutlet weak var nicknameConfirmButton: RoundedButton!
    @IBOutlet weak var maleButton: SelectableButton!
    @IBOutlet weak var femaleButton: SelectableButton!
    @IBOutlet weak var nextButton: RoundedButton!
    @IBOutlet weak var birthPickerView: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        initTextFields()
        initPickerView()
        
        nicknameConfirmButton.isEnabled = false
        maleButton.isSelected = true
        femaleButton.isSelected = false
        nextButton.isEnabled = false
    }

    override func viewWillLayoutSubviews() {
        nicknameInputText.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.ui
    }

    // MARK: IBAction
    @IBAction func checkDuplicateTapped(_ sender: Any) {
        
        printLog("checkDuplication tapped")
        
        nicknameInputText.resignFirstResponder()
        
        guard let inputNickname = nicknameInputText.text else {
            printLog("check Duplication Error > text is nil")
            return
        }
        
        UserInfoManager.sharedInstance.isNicknameAvailable(nickname: inputNickname).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let result = task.result as? Bool else {
                self.printLog("check Duplication Error")
                
                DispatchQueue.main.async {
                    self.alert(message: "사용중인 닉네임입니다.", title: "닉네임 중복확인")
                }
                
                return nil
            }
            
            if result {
                self.printLog("check Duplication OKOK!!!!")
                DispatchQueue.main.async {
                    self.nextButton.isEnabled = true
                    self.alert(message: "사용가능한 닉네임입니다.", title: "닉네임 중복확인")
                }
            }
            
            return nil
        })
        
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        printLog("nextButtonTapped")
        performSegue(withIdentifier: InsertPhoneViewController.className, sender: self)
    }
    
    @IBAction func maleButtonTapped(_ sender: Any) {
        maleButton.isSelected = true
        femaleButton.isSelected = false
    }
    
    @IBAction func femaleButtonTapped(_ sender: Any) {
        maleButton.isSelected = false
        femaleButton.isSelected = true
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == InsertPhoneViewController.className {
            printLog("prepare > withIdentifier : \(String(describing: segue.identifier))")
            
            guard let destination = segue.destination as? InsertPhoneViewController else {
                fatalError("InputUserInfoViewController > prepare > destination Error")
            }
            
            guard let username = self.username else {
                fatalError("InputUserInfoViewController > prepare > username is nil")
            }
            
            guard let password = self.password else {
                fatalError("InputUserInfoViewController > prepare > password is nil")
            }
            
            destination.username = username
            destination.password = password
            destination.gender = self.maleButton.isSelected ? "male" : "female"
            destination.birth = yearArray[self.birthPickerView.selectedRow(inComponent: 0)]
            destination.nickname = self.nicknameInputText.text
        }
    }

}

// MARK: - UITextField

extension InputUserInfoViewController: UITextFieldDelegate {
    
    func initTextFields() {
        nicknameInputText.keyboardType = .default
        nicknameInputText.addTarget(self, action: #selector(self.textFieldDidChanged(_:)), for: .editingChanged)
        nicknameInputText.inputAccessoryView = getToolbar()
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
    
    // MARK: -UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChanged(_ textField: UITextField) {
        nextButton.isEnabled = false
        nicknameConfirmButton.isEnabled = textField.text!.characters.count > 1
    }
}

// MARK: -UIPickerView

extension InputUserInfoViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func initPickerView() {
        
        for i in 1950...1998 {
            yearArray.append(i)
        }
        
        birthPickerView.delegate = self
        birthPickerView.dataSource = self
        birthPickerView.selectRow(yearArray.count - 1, inComponent: 0, animated: false)
    }
    
    // MARK: -UIPickerViewDelegate, UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return yearArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40.0
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white
        label.textAlignment = .center
        label.text = String(yearArray[row])
        
        return label
    }
}
