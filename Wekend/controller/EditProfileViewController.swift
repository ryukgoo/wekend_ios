//
//  EditProfileViewController.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 8..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController {

    // MARK: IBOutlet
    @IBOutlet weak var mainEditCell: EditCell!
    @IBOutlet weak var editCell1: EditCell!
    @IBOutlet weak var editCell2: EditCell!
    @IBOutlet weak var editCell3: EditCell!
    @IBOutlet weak var editCell4: EditCell!
    @IBOutlet weak var editCell5: EditCell!
    
    @IBOutlet weak var nickname: UITextField!
    @IBOutlet weak var age: UITextField!
    @IBOutlet weak var company: UITextField!
    @IBOutlet weak var school: UITextField!
    @IBOutlet weak var area: UITextField!
    @IBOutlet weak var introduce: UITextView!
    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var code: UITextField!
    
    @IBOutlet weak var phoneEditView: UIStackView!
    @IBOutlet weak var requestCodeButton: WhiteRoundedButton!
    @IBOutlet weak var confirmCodeButton: WhiteRoundedButton!
    
    var editCells: [EditCell]!
    var activeTextView: UIView?
    var activeEditCell: EditCell?
    var viewModel: UserProfileViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
//        phoneEditView.isHidden = true
        introduce.isScrollEnabled = false
        requestCodeButton.isEnabled = false
        
        let newBackButton = UIBarButtonItem(title: "완료", style: .plain, target: self, action: #selector(self.onDoneButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = newBackButton
        
        initTextFields()
        initEditImages()
        bindViewModel()
        
        viewModel?.loadUser()
    }
    
    deinit {
        print("\(className) > \(#function)")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
        addKeyboardObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /*
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { }
    */
}

extension EditProfileViewController {
    
    fileprivate func bindViewModel() {
        print("\(className) > \(#function)")
        guard let viewModel = viewModel else { return }
        viewModel.user.bindAndFire { [weak self] user in
            guard let user = user else { return }
            guard let editImages = self?.editCells else { return }
            for editImage in editImages {
                guard let imageUrl = self?.getImageUrl(id: user.userid, index: editImage.index) else { return }
                editImage.imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "default_profile"), options: .cacheMemoryOnly) {
                    (image, error, cachedType, url) in
                }
            }
            
            self?.nickname.text = user.nickname
            self?.age.text = (user.birth as! Int).toAge.description
            self?.company.text = user.company
            self?.school.text = user.school
            self?.area.text = user.area
            self?.introduce.text = user.introduce
            self?.phone.text = user.phone
        }
        
        self.viewModel?.onUploadPrepare = { [weak self] image in
            self?.activeEditCell?.imageView.image = image
            self?.activeEditCell = nil
            self?.startLoading(message: "저장중...")
        }
        
        self.viewModel?.onUploadComplete = { [weak self] _ in
            self?.endLoading()
            
            let alert = ButtonAlert(title: nil,
                                    message: "프로필 이미지가 변경되었습니다",
                                    actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.onUploadFailed = { [weak self] _ in
            self?.endLoading()
            
            let alert = ButtonAlert(title: nil,
                                    message: "이미지 변경에 실패하였습니다\n다시 시도해 주십시오",
                                    actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.onUpdateUser = { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        
        self.viewModel?.onUpdateUserFailed = { [weak self] _ in
            let alert = ButtonAlert(title: nil, message: "사용자 정보수정에 실패하였습니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.onDeletePrepare = { [weak self] _ in
            self?.startLoading(message: "삭제중...")
        }
        
        self.viewModel?.onDeleteComplete = { [weak self] _ in
            self?.activeEditCell?.imageView.image = #imageLiteral(resourceName: "default_profile")
            self?.activeEditCell = nil
            self?.endLoading()
            
            let alert = ButtonAlert(title: nil,
                                    message: "프로필 이미지가 삭제되었습니다",
                                    actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.onDeleteFailed = { [weak self] _ in
            self?.endLoading()
            
            let alert = ButtonAlert(title: nil,
                                    message: "이미지 삭제에 실패하였습니다\n다시 시도해 주십시오",
                                    actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.onRequestCodeStart = { [weak self] _ in
            self?.startLoading(message: "인증번호 발송중입니다..")
        }
        
        self.viewModel?.onRequestComplete = { [weak self] _ in
            self?.endLoading()
            let alert = ButtonAlert(title: nil,
                                    message: "인증번호가 발송되었습니다\n잠시만 기다려 주세요",
                                    actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.onRequestCodeFailed = { [weak self] _ in
            self?.endLoading()
            let alert = ButtonAlert(title: nil,
                                    message: "인증번호 발송에 실패하였습니다\n다시 시도해 주십시오",
                                    actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.notAvailablePhone = { [weak self] _ in
            let alert = ButtonAlert(title: "전화번호 입력오류", message: "전화번호를 정확히 입력해주세요", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.notAvailableCode = { [weak self] _ in
            let alert = ButtonAlert(title: "인증번호 입력오류", message: "인증번호를 입력해 주세요", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.onConfirmCodeComplete = { [weak self] _ in
            let alert = ButtonAlert(title: nil, message: "휴대폰 정보가 수정되었습니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
        self.viewModel?.onConfirmCodeFailed = { [weak self] _ in
            let alert = ButtonAlert(title: nil, message: "인증번호가 일치하지 않습니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
        
    }
    
    fileprivate func initEditImages() {
        editCells = [mainEditCell, editCell1, editCell2, editCell3, editCell4, editCell5]
        
        for image in editCells {
            image.addGestureRecognizer(getTapGestureRecognizer())
        }
    }
    
    private func getImageUrl(id: String, index: Int) -> String {
        let imageName = "\(id)/\(Configuration.S3.PROFILE_IMAGE_NAME(index))"
        return Configuration.S3.PROFILE_IMAGE_URL + imageName
    }
    
    private func getTapGestureRecognizer() -> UITapGestureRecognizer {
        return UITapGestureRecognizer(target: self, action: #selector(self.editImageTapped(_:)))
    }
    
    func editImageTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        guard let editCell = tapGestureRecognizer.view as? EditCell else { return }
        activeEditCell = editCell
        
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let editAction = UIAlertAction(title: "이미지 변경", style: .default, handler: { _ in
            self.editImage(editCell.index)
        })
        let deleteAction = UIAlertAction(title: "이미지 삭제", style: .default, handler: { _ in
            self.deleteImage(editCell.index)
        })
        let cancelACtion = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        sheet.addAction(editAction)
        sheet.addAction(deleteAction)
        sheet.addAction(cancelACtion)
        
        present(sheet, animated: true, completion: nil)
    }
    
    private func editImage(_ index: Int) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    private func deleteImage(_ index: Int) {
        viewModel?.deleteImage(index: index)
    }
    
    @IBAction func onRequestCodeButtonTapped(_ sender: Any) {
        viewModel?.requestVerificationCode(phone: phone.text)
    }
    
    @IBAction func onConfirmCodeButtonTapped(_ sender: Any) {
        guard let code = self.code.text, let phone = phone.text else { return }
        viewModel?.confirmVerificationCode(code: code, phone: phone)
    }
    
    @IBAction func onDoneButtonTapped(_ sender: Any) {
        viewModel?.updateUser(company: company.text, school: school.text, area: area.text, introduce: introduce.text)
    }
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let viewModel = self.viewModel else { return }
        guard let editView = self.activeEditCell else { return }
        dismiss(animated: true) { viewModel.uploadImage(info: info, index: editView.index) }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}

extension EditProfileViewController: UITextFieldDelegate, UITextViewDelegate {
    
    func initTextFields() {
        company.delegate = self
        company.inputAccessoryView = getKeyboardToolbar()
        
        school.delegate = self
        school.inputAccessoryView = getKeyboardToolbar()
        
        area.delegate = self
        area.inputAccessoryView = getKeyboardToolbar()
        
        introduce.delegate = self
        introduce.inputAccessoryView = getKeyboardToolbar()
        
//        phone.tag = 2341543
        phone.delegate = self
        phone.inputAccessoryView = getKeyboardToolbar()
        phone.addTarget(self, action: #selector(self.phoneDidChanged(_:)), for: .editingChanged)
        
        code.delegate = self
        code.inputAccessoryView = getKeyboardToolbar()
        code.layer.addBorder(edge: .bottom, color: UIColor(netHex: 0x909090), thickness: 1.0)
        code.addTarget(self, action: #selector(self.codeDidChanged(_:)), for: .editingChanged)
        
        confirmCodeButton.isEnabled = false
    }
    
    override func getFocusView() -> UIView? {
        return activeTextView
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        print("\(className) > \(#function)")
        activeTextView = textField
        
//        if textField.tag == 2341543 {
//            phoneEditView.isHidden = false
//        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        print("\(className) > \(#function)")
        activeTextView = textView
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        print("\(className) > \(#function)")
    }
    
    func phoneDidChanged(_ textField: UITextField) {
        requestCodeButton.isEnabled = textField.text!.count == 11
    }
    
    func codeDidChanged(_ textField: UITextField) {
        confirmCodeButton.isEnabled = textField.text!.count == 6
    }
}

