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
    @IBOutlet weak var introduce: UITextView!
    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var code: UITextField!
    
    @IBOutlet weak var requestCodeButton: WhiteRoundedButton!
    @IBOutlet weak var confirmCodeButton: WhiteRoundedButton!
    
    var editCells: [EditCell]!
    var viewModel: UserProfileViewModel?
    var activeTextView: UIView?
    var activeEditCell: EditCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        introduce.isScrollEnabled = false
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
            self?.alert(message: "프로필 이미지가 수정되었습니다")
        }
        
        self.viewModel?.onUploadFailed = { [weak self] _ in
            self?.endLoading()
            self?.alert(message: "프로필 이미지 수정에 실패하였습니다.\n다시 시도해 주세요")
        }
        
        self.viewModel?.onUpdateUser = { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
    }
    
    private func initEditImages() {
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
        guard let editView = tapGestureRecognizer.view as? EditCell else {
            print("\(className) > \(#function) > sender : \(tapGestureRecognizer)")
            return
        }
        print("\(className) > \(#function) > \(editView.index)")
        
        activeEditCell = editView
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func onRequestCodeButtonTapped(_ sender: Any) {
        
    }
    
    @IBAction func onConfirmCodeButtonTapped(_ sender: Any) {
        
    }
    
    @IBAction func onDoneButtonTapped(_ sender: Any) {
        viewModel?.updateUser()
    }
    /*
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { }
    */
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
        
        phone.delegate = self
        phone.inputAccessoryView = getKeyboardToolbar()
        phone.addTarget(self, action: #selector(self.phoneDidChanged(_:)), for: .editingChanged)
        
        code.delegate = self
        code.inputAccessoryView = getKeyboardToolbar()
        code.layer.addBorder(edge: .bottom, color: UIColor(netHex: 0x909090), thickness: 1.0)
        code.addTarget(self, action: #selector(self.codeDidChanged(_:)), for: .editingChanged)
        
        introduce.delegate = self
        introduce.inputAccessoryView = getKeyboardToolbar()
        
        confirmCodeButton.isEnabled = false
    }
    
    override func getFocusView() -> UIView? {
        return activeTextView
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextView = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        print("\(className) > \(#function)")
        activeTextView = textView
    }
    
    func phoneDidChanged(_ textField: UITextField) {
        requestCodeButton.isEnabled = textField.text!.count == 11
    }
    
    func codeDidChanged(_ textField: UITextField) {
        confirmCodeButton.isEnabled = textField.text!.count == 6
    }
}

