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
    @IBOutlet weak var mainEditImage: EditImageView!
    @IBOutlet weak var editImage1: EditImageView!
    @IBOutlet weak var editImage2: EditImageView!
    @IBOutlet weak var editImage3: EditImageView!
    @IBOutlet weak var editImage4: EditImageView!
    @IBOutlet weak var editImage5: EditImageView!
    
    @IBOutlet weak var nickname: UITextField!
    @IBOutlet weak var age: UITextField!
    @IBOutlet weak var company: UITextField!
    @IBOutlet weak var school: UITextField!
    @IBOutlet weak var introduce: UITextView!
    @IBOutlet weak var phone: UITextField!
    @IBOutlet weak var code: UITextField!
    
    var editImages: [EditImageView]!
    var viewModel: EditProfileViewModel?
    var activeTextView: UIView?
    
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
            guard let editImages = self?.editImages else { return }
            for editImage in editImages {
                guard let imageUrl = self?.getImageUrl(id: user.userid, index: editImage.index) else { return }
                editImage.image.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "default_profile"), options: .cacheMemoryOnly) {
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
    }
    
    private func initEditImages() {
        editImages = [mainEditImage, editImage1, editImage2, editImage3, editImage4, editImage5]
        
        for image in editImages {
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
        guard let editView = tapGestureRecognizer.view as? EditImageView else {
            print("\(className) > \(#function) > sender : \(tapGestureRecognizer)")
            return
        }
        print("\(className) > \(#function) > \(editView.index)")
    }
    
    /*
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { }
    */
}

extension EditProfileViewController: UITextFieldDelegate {
    
    func initTextFields() {
        company.delegate = self
        company.inputAccessoryView = getKeyboardToolbar()
        school.delegate = self
        school.inputAccessoryView = getKeyboardToolbar()
        phone.delegate = self
        phone.keyboardType = .numberPad
        phone.inputAccessoryView = getKeyboardToolbar()
        code.delegate = self
        code.keyboardType = .numberPad
        code.inputAccessoryView = getKeyboardToolbar()
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
}

