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
                
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let mainViewController = storyboard.instantiateViewController(withIdentifier: MainViewController.className)
                
                self.present(mainViewController, animated: true, completion: nil)
            }
            return
        }
        
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
            fatalError("SelectPhotoViewController > resize image > error!!!!")
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
        
        transferManager.upload(uploadRequest).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            if let error = task.error {
                self.printLog("upload > error : \(error)")
            }
            
            guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
                fatalError("SelectPhotoViewController > upload get UserInfo Failed")
            }
            
            self.printLog("userInfo.userid : \(userInfo.userid)")
            
            let photos: Set = [uploadRequest.key!]
            userInfo.photos = photos
            
            UserInfoManager.sharedInstance.saveUserInfo(userInfo: userInfo).continueWith(executor: AWSExecutor.mainThread(), block: {
                (saveTask: AWSTask) -> Any! in
                
                if saveTask.error != nil {
                    self.printLog("upload error : \(String(describing: saveTask.error))")
                } else {
                    
                    UserInfoManager.sharedInstance.getOwnedUserInfo(userId: userInfo.userid).continueWith(executor: AWSExecutor.mainThread(), block: {
                        getUserTask -> Any! in
                        
                        DispatchQueue.main.async {
                            self.endLoading()
                            
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let mainViewController = storyboard.instantiateViewController(withIdentifier: MainViewController.className)
                            
                            self.present(mainViewController, animated: true, completion: nil)
                        }
                        
                        return nil
                    })
                    
                }
                
                return nil
            })
            
            return nil
        })
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
