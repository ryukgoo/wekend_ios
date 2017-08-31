//
//  MyProfileViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 18..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import AWSS3

@available(iOS 9.0, *)
class MyProfileViewController: UIViewController {
    
    let minimumAlpha: CGFloat = 0.1
    
    // MARK: Properties
    
    var selectedPhoto: UIImage?
    var isLoading: Bool = false
    var verificationCode: String?
    var isEditingMode: Bool = false {
        didSet {
            
            print("MyProfileViewController > isEdigingMode didSet > isEditing : \(isEditingMode)")
            
            editLayoutStackView.isHidden = !isEditingMode
            editPhoneButton.isHidden = !isEditingMode
            editPhotoButton.isHidden = !isEditingMode
            
            requestCodeButton.isEnabled = !isEditingMode
            confirmCodeButton.isEnabled = !isEditingMode
            
            phoneTextField.isEnabled = isEditingMode
            codeTextField.isEnabled = isEditingMode
            
            guard let phoneNumber = UserInfoManager.sharedInstance.userInfo?.phone?.toPhoneFormat() else {
                fatalError("phoneNumber is nil")
            }
            
            phoneTextField.text = phoneNumber
            
//            editButton.isEnabled = !isEditingMode
            
            if isEditingMode {
//                editButton.setTitle("완료", for: .normal)
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                                    target: self,
                                                                    action: #selector(doneItemTapped(_:)))
            } else {
//                editButton.setTitle("프로필 수정", for: .normal)
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit,
                                                                    target: self,
                                                                    action: #selector(editItemTapped(_:)))
            }
            
            refreshLayout()
        }
    }
    
    var activeTextField: UITextField?
    
    // MARK: IBOutlet
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var pagerView: PagerView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var nicknameStackView: UIStackView!
    @IBOutlet weak var ageStackView: UIStackView!
    @IBOutlet weak var phoneStackView: UIStackView!
    
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var pointLabel: UILabel!
//    @IBOutlet weak var editButton: WhiteRoundedButton!
    @IBOutlet weak var pagerViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var stackViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backgroundViewHeight: NSLayoutConstraint!
    @IBOutlet weak var containerViewHeight: NSLayoutConstraint!

    @IBOutlet weak var editPhoneButton: WhiteRoundedButton!
    @IBOutlet weak var requestCodeButton: WhiteRoundedButton!
    @IBOutlet weak var confirmCodeButton: WhiteRoundedButton!
    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var editLayoutStackView: UIStackView!
    @IBOutlet weak var editPhotoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layoutIfNeeded()
        
        initViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.isStatusBarHidden = true
        
        var colors = [UIColor]()
        colors.append(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5))
        colors.append(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0))
        navigationController?.navigationBar.setGradientBackground(colors: colors)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.tintColor = .white
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)),
                                               name: .UIKeyboardWillShow,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(_:)),
                                               name: .UIKeyboardWillHide,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isStatusBarHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    private func initViews() {
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
            fatalError("MyProfileViewController > initViews > get UserInfo Error")
        }
        
        pagerView.delegate = self
        if let photos = userInfo.photos as? Set<String> {
            pagerView.pageCount = max(photos.count, 1)
        } else {
            pagerView.pageCount = 1
        }
        
        scrollView.delegate = self
        
        guard let birth = userInfo.birth as! Int! else {
            fatalError("MyProfileViewController > initViews > get birth Error")
        }
        
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date)
        let year = components.year
        
        nicknameLabel.text = userInfo.nickname
        ageLabel.text = String(year! - birth) + "세"

        if let point = userInfo.balloon as! Int! {
            self.pointLabel.text = "보유포인트 : \(point)P"
        } else {
            self.pointLabel.text = "보유포인트 : 0P"
        }
        
        phoneTextField.attributedPlaceholder =
            NSAttributedString(string: "'-'를 제외한 숫자만 입력해주세요",
                               attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 14.0)])
        
        initTextFields()
        
        isEditingMode = false
    }
    
    private func refreshLayout() {
        
        self.view.layoutIfNeeded()
        
        var scrollableHeight = pagerView.frame.size.height
        scrollableHeight += nicknameStackView.frame.height
        scrollableHeight += ageStackView.frame.height
        scrollableHeight += phoneStackView.frame.height
        scrollableHeight += 24
        scrollableHeight += pointLabel.frame.height
        scrollableHeight += 36
//        scrollableHeight += editButton.frame.height
//        scrollableHeight += 40
        
        printLog("pagerView.frame.size.height: \(pagerView.frame.size.height)")
        
        containerViewHeight.constant = scrollableHeight
        backgroundViewHeight.constant = scrollableHeight - pagerView.frame.size.height
        
    }
    
    func editItemTapped(_ sender: Any) {
        isEditingMode = true
    }
    
    func doneItemTapped(_ sender: Any) {
        isEditingMode = false
    }
    
    @IBAction func onEditPhoneButtonTapped(_ sender: Any) {
        printLog("onEditPhoneButtonTapped")
        
        phoneTextField.becomeFirstResponder()
    }
    
    // MARK: IBAction
    @IBAction func onEditButtonTapped(_ sender: Any) {
        
        printLog("onEditButtonTapped")
        
        if isEditingMode {
            
            let uploadRequest = AWSS3TransferManagerUploadRequest()
            
            if let selectedPhoto = self.selectedPhoto {
                let fileName = ProcessInfo.processInfo.globallyUniqueString.appending(".jpg")
                let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
                let imageData = UIImageJPEGRepresentation(selectedPhoto, 0.5)
                
                do {
                    try imageData?.write(to: fileURL!, options: .atomicWrite)
                } catch let error {
                    printLog("imageData write error : \(error)")
                }
                
                guard let userId = UserInfoManager.sharedInstance.userInfo?.userid else {
                    fatalError("SelectPhotoViewController > nextButtonTapped > userId Error")
                }
                
                uploadRequest?.bucket = Configuration.S3.PROFILE_IMAGE_BUCKET
                uploadRequest?.key = userId + "/" + Configuration.S3.PROFILE_IMAGE_NAME(0)
                uploadRequest?.body = fileURL!
                uploadRequest?.contentType = "image/jpeg"
            }
            
            if let newPhoneNumber = phoneTextField.text, let oldPhoneNumber = UserInfoManager.sharedInstance.userInfo?.phone {
                if newPhoneNumber.removedHyphen != oldPhoneNumber {
                    UserInfoManager.sharedInstance.userInfo?.phone = newPhoneNumber
                }
            }
            
            upload(uploadRequest: uploadRequest!)
        }
        
        isEditingMode = !isEditingMode
    }
    
    @IBAction func onRequestCodeButtonTapped(_ sender: Any) {
        printLog("onRequestCodeButtonTapped")
        
        phoneTextField.resignFirstResponder()
        
        guard let phoneNumber = phoneTextField.text else {
            self.alert(message: "전화번호를 정확히 입력해주세요", title: "전화번호 입력오류")
            return
        }
        
        UserInfoManager.sharedInstance.sendVerificationCode(phoneNumber: phoneNumber).continueWith(block: {
            (task: AWSTask) -> Any! in
            
            if task.error == nil {
                
                guard let result = task.result else {
                    DispatchQueue.main.async {
                        self.alert(message: "다시 시도해 주세요", title: "인증번호 발송오류")
                    }
                    self.printLog("getVerificationCode Failed")
                    return nil
                }
                
                DispatchQueue.main.async {
                    self.alert(message: "인증번호가 발송되었습니다", title: "인증번호 발송")
                }
                
                self.verificationCode = result as String
            }
            
            return nil
        })
    }
    
    @IBAction func onConfirmCodeButtonTapped(_ sender: Any) {
        printLog("onConfirmCodeButtonTapped")
        
        codeTextField.resignFirstResponder()
        
        startLoading()
        
        guard let confirmCode = codeTextField.text else {
            alert(message: "인증번호를 입력해주세요", title: "인증번호 입력오류")
            return
        }
        
        if confirmCode != verificationCode {
            alert(message: "인증번호가 맞지 않습니다", title: "인증번호 확인")
        } else {
            guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
                fatalError("MyProfileViewController > onConfirmCodeButtonTapped > userInfo is nil")
            }
            
            if let newPhoneNumber = phoneTextField.text {
                userInfo.phone = newPhoneNumber
                
                UserInfoManager.sharedInstance.saveUserInfo(userInfo: userInfo).continueWith(block: {
                    (task: AWSTask) -> Any? in
                    
                    if task.error != nil {
                        self.printLog("onConfirmCodeButtonTapped > error: \(task.error.debugDescription)")
                        return nil
                    }
                    
                    self.endLoading()
                    self.isEditingMode = false
                    
                    return nil
                })
            }
        }
        
    }
    
    @IBAction func onEditPhotoButtonTapped(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func onBackButtonTapped(_ sender: Any) {
        
        if isEditingMode {
            isEditingMode = false
            
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

}

// MARK: - PagerViewDelegate, UIScrollViewDelegate

@available(iOS 9.0, *)
extension MyProfileViewController: PagerViewDelegate, UIScrollViewDelegate {
    
    func loadPageViewItem(imageView: UIImageView, page: Int) {
        printLog("loadPageViewItem")
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
            fatalError("ProfileViewController > loadPageViewItem > userInfo Error")
        }
        
        let imageName = userInfo.userid + "/" + Configuration.S3.PROFILE_IMAGE_NAME(page)
        let imageUrl = Configuration.S3.PROFILE_IMAGE_URL + imageName
        
        imageView.downloadedFrom(link: imageUrl, defaultImage: #imageLiteral(resourceName: "default_profile")/*, contentMode: .scaleAspectFit*/)
    }
    
    func onPageTapped(page: Int) {
        
        if !isEditingMode { return }
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let yOffset = self.scrollView.contentOffset.y
        let alpha = 1 - (yOffset / self.pagerView.frame.size.height)
        
        pagerView.alpha = alpha
        pagerViewOffsetY.constant = yOffset * 0.5
        backViewOffsetY.constant = -(yOffset * 0.5)
        stackViewOffsetY.constant = -(yOffset * 0.5)
    }
}

// MARK: - UIImagePickerControllerDelegate

@available(iOS 9.0, *)
extension MyProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImage: UIImage!
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImage = image
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImage = image
        }
        
        guard let resizedImage = selectedImage.resize(targetSize: CGSize(width: 800, height: 800)) else {
            fatalError("SelectPhotoViewController > resize image > error!!!!")
        }
        
        selectedPhoto = resizedImage

        if let imageView = pagerView.getPageItem(0) {
            imageView.image = selectedPhoto
        }
        
        dismiss(animated: true, completion: { self.validateSelectedPhoto() })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func validateSelectedPhoto() {
        
        guard let selectedPhoto = self.selectedPhoto else {
            return
        }
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        let fileName = ProcessInfo.processInfo.globallyUniqueString.appending(".jpg")
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        let imageData = UIImageJPEGRepresentation(selectedPhoto, 0.7)
        
        do {
            try imageData?.write(to: fileURL!, options: .atomicWrite)
        } catch let error {
            printLog("imageData write error : \(error)")
        }
        
        guard let userId = UserInfoManager.sharedInstance.userInfo?.userid else {
            fatalError("SelectPhotoViewController > nextButtonTapped > userId Error")
        }
        
        uploadRequest?.bucket = Configuration.S3.PROFILE_IMAGE_BUCKET
        uploadRequest?.key = userId + "/" + Configuration.S3.PROFILE_IMAGE_NAME(0)
        uploadRequest?.body = fileURL!
        uploadRequest?.contentType = "image/jpeg"
        
        upload(uploadRequest: uploadRequest!)
    }
    
    func upload(uploadRequest: AWSS3TransferManagerUploadRequest) {
        
        startLoading(message: "저장중...")
        
        let transferManager = AWSS3TransferManager.default()
        
        transferManager.upload(uploadRequest).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            if let error = task.error {
                self.printLog("upload > error : \(error)")
            }
            
            guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
                fatalError("SelectPhotoViewController > upload get UserInfo Failed")
            }
            
            let photos: Set = [uploadRequest.key!]
            userInfo.photos = photos
            
            UserInfoManager.sharedInstance.saveUserInfo(userInfo: userInfo).continueWith(executor: AWSExecutor.mainThread(), block: {
                (saveTask: AWSTask) -> Any! in
                
                if saveTask.error != nil {
                    self.printLog("upload error : \(String(describing: saveTask.error))")
                } else {
                    self.endLoading()
                    
                }
                return nil
            })
            return nil
        })
    }
}

@available(iOS 9.0, *)
extension MyProfileViewController: UITextFieldDelegate {
    
    func initTextFields() {
        
        phoneTextField.keyboardType = .phonePad
        phoneTextField.delegate = self
        phoneTextField.addTarget(self, action: #selector(self.phoneDidChanged(_:)), for: .editingChanged)
        
        codeTextField.keyboardType = .numberPad
        codeTextField.delegate = self
        codeTextField.addTarget(self, action: #selector(self.codeDidChanged(_:)), for: .editingChanged)
        
        let toolbar = getToolbar()
        phoneTextField.inputAccessoryView = toolbar
        codeTextField.inputAccessoryView = toolbar
        
        codeTextField.layer.addBorder(edge: .bottom, color: UIColor(netHex: 0x909090), thickness: 1.0)
        
        phoneTextField.isEnabled = false
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
        view.endEditing(true)
        
        validateInputPhoneNumber()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
        activeTextField = textField
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        validateInputPhoneNumber()
        return true
    }
    
    func phoneDidChanged(_ textField: UITextField) {
        requestCodeButton.isEnabled = phoneTextField.text!.characters.count == 11
    }
    
    func codeDidChanged(_ textField: UITextField) {
        confirmCodeButton.isEnabled = codeTextField.text!.characters.count == 6
    }
    
    func keyboardWillShow(_ notification: Notification) {
        
        var info: Dictionary = notification.userInfo!
        
        if let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            
            guard let textField = self.activeTextField else {
                printLog("keyboardWillShow > activeTextField is nil")
                return
            }
            
            let point = textField.convert(textField.frame.origin, to: self.view)
            
            let textFieldBottomY = point.y + textField.frame.size.height
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
    
    func validateInputPhoneNumber() {
        
        if let inputPhoneNumber = phoneTextField.text {
            if inputPhoneNumber.characters.count == 11 {
                guard let newPhoneNumber = inputPhoneNumber.toPhoneFormat() else {
                    return
                }
                phoneTextField.text = newPhoneNumber
                return
            }
        }
        
        guard let oldPhoneNumber = UserInfoManager.sharedInstance.userInfo?.phone?.toPhoneFormat() else {
            return
        }
        phoneTextField.text = oldPhoneNumber
    }
}
