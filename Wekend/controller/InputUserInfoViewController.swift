//
//  InputUserInfoViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 2. 1..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import AWSCore

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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
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
        
        print("\(className) > \(#function)")
        
        nicknameInputText.resignFirstResponder()
        
        guard let inputNickname = nicknameInputText.text else {
            print("\(className) > \(#function) > check Duplication Error > text is nil")
            self.alert(message: "닉네임을 입력해 주세요")
            return
        }
        
        UserInfoRepository.shared.validateNickname(name: inputNickname) { available in
            
            DispatchQueue.main.async {
                if available {
                    self.nextButton.isEnabled = true
                    self.alert(message: "사용가능한 닉네임입니다.", title: "닉네임 중복확인")
                } else {
                    self.alert(message: "사용중인 닉네임입니다.", title: "닉네임 중복확인")
                }
            }
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        print("\(className) > \(#function)")
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
            print("\(className) > \(#function) > withIdentifier : \(String(describing: segue.identifier))")
            
            guard let inputPhoneVC = segue.destination as? InsertPhoneViewController else {
                fatalError("\(className) > \(#function) > destination Error")
            }
            
            guard let username = self.username else {
                fatalError("\(className) > \(#function) > username is nil")
            }
            
            guard let password = self.password else {
                fatalError("\(className) > \(#function) > password is nil")
            }
            
            inputPhoneVC.username = username
            inputPhoneVC.password = password
            inputPhoneVC.gender = self.maleButton.isSelected ? "male" : "female"
            inputPhoneVC.birth = yearArray[self.birthPickerView.selectedRow(inComponent: 0)]
            inputPhoneVC.nickname = self.nicknameInputText.text
            
            let dataSource = UserInfoRepository.shared
            inputPhoneVC.viewModel = InsertPhoneViewModel(userDataSource: dataSource)
            inputPhoneVC.registerModel = RegisterUserModel()
            inputPhoneVC.loginModel = LoginViewModel(dataSource: dataSource)
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
    
    override func doneKeyboard(_ sender: Any) {
        self.view.endEditing(true)
    }
    
    // MARK: -UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChanged(_ textField: UITextField) {
        nextButton.isEnabled = false
        nicknameConfirmButton.isEnabled = textField.text!.count > 1
    }
}

// MARK: -UIPickerView

extension InputUserInfoViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func initPickerView() {
        
        let date = Date()
        let calendar = Calendar.current
        
        let thisYear = calendar.component(.year, from: date)
        let startYear = thisYear - 20
        
        print("\(className) > \(#function) > startYear : \(startYear)")
        
        for i in 1950...startYear {
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
