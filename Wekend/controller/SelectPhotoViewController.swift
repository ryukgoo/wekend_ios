//
//  SelectPhotoViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 2. 2..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import AWSS3

class SelectPhotoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: Properties
    
    var selectedPhoto: UIImage?
    
    // MARK: IBOutlet
    
    @IBOutlet weak var photoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        photoImageView.isUserInteractionEnabled = true
        navigationItem.setHidesBackButton(true, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: IBAction
    
    @IBAction func selectImageFromPhotoLibrary(_ sender: UITapGestureRecognizer) {
        
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        
        guard let selectedPhoto = self.selectedPhoto else {
            DispatchQueue.main.async {
                self.endLoading()
                
                guard let mainVC = MainViewController.storyboardInstance(from: "Main") as? MainViewController else { return }
                self.present(mainVC, animated: true, completion: nil)
            }
            return
        }
        
        let fileName = ProcessInfo.processInfo.globallyUniqueString.appending(".jpg")
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        let imageData = UIImageJPEGRepresentation(selectedPhoto, 0.7)
        
        do {
            try imageData?.write(to: fileURL!, options: .atomicWrite)
        } catch let error {
            print("\(className) > \(#function) > imageData write error : \(error)")
        }
        
        guard let userId = UserInfoManager.shared.userInfo?.userid else {
            fatalError("\(className) > \(#function) > userId Error")
        }
        
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        uploadRequest?.bucket = Configuration.S3.PROFILE_IMAGE_BUCKET
        uploadRequest?.key = userId + "/" + Configuration.S3.PROFILE_IMAGE_NAME(0)
        uploadRequest?.body = fileURL!
        uploadRequest?.contentType = "image/jpeg"
        
        upload(uploadRequest: uploadRequest!)
        
    }
    
    // UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImage: UIImage!
        
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectedImage = image
        } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectedImage = image
        }
        
        guard let resizedImage = selectedImage.resize(targetSize: CGSize(width: 800, height: 800)) else {
            fatalError("\(className) > \(#function) > resize image > error!!!!")
        }
        
        selectedPhoto = resizedImage
        
        photoImageView.image = resizedImage
        photoImageView.toMask(mask: #imageLiteral(resourceName: "img_profile_thumb_b_circle_mask"))
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func upload(uploadRequest: AWSS3TransferManagerUploadRequest) {
        
        startLoading()
        
        let transferManager = AWSS3TransferManager.default()
        
        transferManager.upload(uploadRequest).continueWith(executor: AWSExecutor.mainThread()) {
            (task: AWSTask) -> Any! in
            
            if let error = task.error {
                print("\(self.className) > \(#function) > upload > error : \(error)")
                self.alert(message: "다시 시도해 주세요", title: "사진 업로드 실패")
                return nil
            }
            
            guard let userInfo = UserInfoManager.shared.userInfo else {
                fatalError("\(self.className) > \(#function) > upload get UserInfo Failed")
            }
            
            let photos: Set = [uploadRequest.key!]
            userInfo.photos = photos
            
            UserInfoManager.shared.saveUserInfo(userInfo: userInfo) { isSuccess in
                self.endLoading()
                if isSuccess {
                    DispatchQueue.main.async {
                        guard let mainVC = MainViewController.storyboardInstance(from: "Main") as? MainViewController else { return }
                        self.present(mainVC, animated: true, completion: nil)
                    }
                } else {
                    // user save error
                    self.alert(message: "프로필 이미지 저장에 실패하였습니다.\n다시 시도해 주세요")
                }
            }
            
            return nil
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
