//
//  MyProfileViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 18..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import AWSS3
import SDWebImage

@available(iOS 9.0, *)
class MyProfileViewController: UIViewController {
    
    // MARK: IBOutlet
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var pagerView: PagerView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var nickname: UILabel!
    @IBOutlet weak var company: UILabel!
    @IBOutlet weak var school: UILabel!
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var introduce: UILabel!
    @IBOutlet weak var point: UILabel!
    @IBOutlet weak var pagerViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backViewOffsetY: NSLayoutConstraint!
    
    var viewModel: UserProfileViewModel?
    
    deinit {
        print("\(className) > \(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pagerView.delegate = self
        scrollView.delegate = self
        
        bindViewModel()
        viewModel?.loadUser()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        navigationController?.isNavigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("\(className) > \(#function)")
        guard let editViewController = segue.destination as? EditProfileViewController else { return }
        editViewController.viewModel = UserProfileViewModel()
    }
    
    fileprivate func bindViewModel() {
        print("\(className) > \(#function)")
        guard let viewModel = viewModel else { return }
        viewModel.user.bindAndFire { [weak self] user in
            guard let user = user else { return }
            guard let nickname = user.nickname else { return }
            self?.nickname.text = "\(nickname), \((user.birth as! Int).toAge.description)"
            
            if let company = user.company {
                self?.company.isHidden = false
                self?.company.text = company
            } else {
                self?.company.isHidden = true
            }
            
            if let school = user.school {
                self?.school.isHidden = false
                self?.school.text = school
            } else {
                self?.school.isHidden = true
            }
            
            self?.phone.text = user.phone?.toPhoneFormat()
            self?.introduce.text = user.introduce
            
            guard let point = user.balloon as? Int else { return }
            self?.point.text = "보유포인트 \(point)P"
            
            if let photos = user.photos as? Set<String> {
                self?.pagerView.pageCount = max(photos.count, 1)
            }
        }
    }
    
    /*
     
     private func initViews() {
     
     guard let userInfo = UserInfoManager.shared.userInfo else {
     fatalError("\(className) > \(#function) > get UserInfo Error")
     }
     
     pagerView.delegate = self
     if let photos = userInfo.photos as? Set<String> {
     pagerView.pageCount = max(photos.count, 1)
     } else {
     pagerView.pageCount = 1
     }
     
     scrollView.delegate = self
     
     guard let birth = userInfo.birth as! Int! else {
     fatalError("\(className) > \(#function) > get birth Error")
     }
     
     nicknameTextField.text = userInfo.nickname
     ageLabel.text = "\(birth.toAge)세"
     
     if let point = userInfo.balloon as! Int! {
     self.pointLabel.text = "보유포인트 : \(point)P"
     } else {
     self.pointLabel.text = "보유포인트 : 0P"
     }
     }
     
    @IBAction func onEditNicknameButtonTapped(_ sender: Any) {
        print("\(className) > \(#function)")
//        nicknameTextField.becomeFirstResponder()
        
        view.endEditing(true)
        
        guard let userInfo = UserInfoManager.shared.userInfo else { return }
        
        if let inputNickname = nicknameTextField.text {
            if !inputNickname.isEmpty && userInfo.nickname != inputNickname {
                startLoading(message: "수정중..")
                
                UserInfoManager.shared.isNicknameAvailable(nickname: inputNickname).continueWith(executor: AWSExecutor.mainThread()) { task in
                    
                    guard let isAvailable = task.result as? Bool else {
                        DispatchQueue.main.async {
                            self.alert(message: "사용중인 닉네임입니다.", title: "닉네임 중복확인")
                        }
                        return nil
                    }
                    
                    if isAvailable {
                        
                        userInfo.nickname = inputNickname
                        
                        UserInfoManager.shared.saveUserInfo(userInfo: userInfo) { isSuccess in
                            DispatchQueue.main.async { self.endLoading() }
                            if isSuccess {
                                self.alert(message: "닉네임이 변경되었습니다")
                            } else {
                                self.alert(message: "닉네임 변경에 실패하였습니다")
                            }
                        }
                    }
                    
                    return nil
                }
                
            }
        }
    }
    
    @IBAction func onEditButtonTapped(_ sender: Any) {
        
        print("\(className) > \(#function)")
        
        if isEditingMode {
            
            let uploadRequest = AWSS3TransferManagerUploadRequest()
            
            if let selectedPhoto = self.selectedPhoto {
                let fileName = ProcessInfo.processInfo.globallyUniqueString.appending(".jpg")
                let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
                let imageData = UIImageJPEGRepresentation(selectedPhoto, 0.5)
                
                do {
                    try imageData?.write(to: fileURL!, options: .atomicWrite)
                } catch let error {
                    print("\(className) > \(#function) > imageData write error : \(error)")
                }
                
                guard let userId = UserInfoManager.shared.userInfo?.userid else {
                    fatalError("\(className) > \(#function) > userId Error")
                }
                
                uploadRequest?.bucket = Configuration.S3.PROFILE_IMAGE_BUCKET
                uploadRequest?.key = userId + "/" + Configuration.S3.PROFILE_IMAGE_NAME(0)
                uploadRequest?.body = fileURL!
                uploadRequest?.contentType = "image/jpeg"
            }
            
            if let newPhoneNumber = phoneTextField.text, let oldPhoneNumber = UserInfoManager.shared.userInfo?.phone {
                if newPhoneNumber.removedHyphen != oldPhoneNumber {
                    UserInfoManager.shared.userInfo?.phone = newPhoneNumber
                }
            }
            
            upload(uploadRequest: uploadRequest!)
        }
        
        isEditingMode = !isEditingMode
    }
    
    @IBAction func onRequestCodeButtonTapped(_ sender: Any) {
        print("\(className) > \(#function)")
        
        phoneTextField.resignFirstResponder()
        
        guard let phoneNumber = phoneTextField.text else {
            self.alert(message: "전화번호를 정확히 입력해주세요", title: "전화번호 입력오류")
            return
        }
        
        print("\(className) > \(#function) > phoneNumber : \(phoneNumber)")
        
        UserInfoManager.shared.sendVerificationCode(phoneNumber: phoneNumber).continueWith(block: {
            (task: AWSTask) -> Any! in
            
            if task.error == nil {
                
                guard let result = task.result else {
                    DispatchQueue.main.async {
                        self.alert(message: "다시 시도해 주세요", title: "인증번호 발송오류")
                    }
                    print("\(self.className) > \(#function) > getVerificationCode Failed")
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
        print("\(className) > \(#function)")
        
        codeTextField.resignFirstResponder()
        
        startLoading()
        
        guard let confirmCode = codeTextField.text else {
            alert(message: "인증번호를 입력해주세요", title: "인증번호 입력오류")
            return
        }
        
        if confirmCode != verificationCode {
            alert(message: "인증번호가 맞지 않습니다", title: "인증번호 확인")
        } else {
            guard let userInfo = UserInfoManager.shared.userInfo else {
                fatalError("\(className) > \(#function) > userInfo is nil")
            }
            
            if let newPhoneNumber = phoneTextField.text {
                userInfo.phone = newPhoneNumber
                
                UserInfoManager.shared.saveUserInfo(userInfo: userInfo) { (isSuccess) in
                    
                    DispatchQueue.main.async { self.endLoading() }
                    
                    if isSuccess {
                        self.alert(message: "전화번호가 변경되었습니다.")
                    } else {
                        self.alert(message: "전화번호 수정에 실패하였습니다.\n다시 시도해 주세요.")
                    }
                }
            }
        }
        
    }
    */
    
    @IBAction func onBackButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: - PagerViewDelegate, UIScrollViewDelegate
extension MyProfileViewController: PagerViewDelegate, UIScrollViewDelegate {
    
    func loadPageViewItem(imageView: UIImageView, page: Int) {
        print("\(className) > \(#function)")
        
        guard let user = viewModel?.user.value else { return }
        
        let imageName = "\(user.userid)/\(Configuration.S3.PROFILE_IMAGE_NAME(page))"
        let imageUrl = Configuration.S3.PROFILE_IMAGE_URL + imageName
        
        imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "default_profile"), options: .cacheMemoryOnly) {
            (image, error, cacheType, imageURL) in
            print("\(self.className) > \(#function) > url: \(String(describing: imageURL))")
        }
        
    }
    
    func onPageTapped(page: Int) {}
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let yOffset = self.scrollView.contentOffset.y
        let alpha = 1 - (yOffset / self.pagerView.frame.size.height)

        pagerView.alpha = alpha
        pagerViewOffsetY.constant = yOffset * 0.5
        backViewOffsetY.constant = -(yOffset * 0.5)
    }
}
