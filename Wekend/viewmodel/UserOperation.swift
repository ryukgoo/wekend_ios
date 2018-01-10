//
//  ProfileOperation.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 10..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSS3
import SDWebImage

struct UserOperation {
    
}

struct UpdateUserOperation {
    
}

struct UploadImageOperation {
    
    let userInfo: UserInfo
    let image: UIImage
    let index: Int
    let dataSource: UserInfoManager
    
    init(userInfo: UserInfo, image: UIImage, index: Int, dataSource: UserInfoManager) {
        self.userInfo = userInfo
        self.image = image
        self.index = index
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (Result<UserInfo, FailureReason>) -> Void) {
        let uploadRequest = AWSS3TransferManagerUploadRequest()
        
        let filename = ProcessInfo.processInfo.globallyUniqueString.appending(".jpg")
        let fileURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename)
        let imageData = UIImageJPEGRepresentation(image, 0.7)
        let objectKey = "\(userInfo.userid)/\(Configuration.S3.PROFILE_IMAGE_NAME(index))"
        
        do {
            try imageData?.write(to: fileURL!, options: .atomicWrite)
        } catch let error {
            print("\(#function) > error: \(error)")
        }
        
        uploadRequest?.bucket = Configuration.S3.PROFILE_IMAGE_BUCKET
        uploadRequest?.key = objectKey
        uploadRequest?.body = fileURL!
        uploadRequest?.contentType = "image/jpeg"
        
        let transferManager = AWSS3TransferManager.default()
        transferManager.upload(uploadRequest!).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if let _ = task.error {
                completion(.failure(.notAvailable))
                return nil
            }
            
            guard let key = uploadRequest?.key else { return nil }
            if var photos = self.userInfo.photos as? Set<String> {
                if !photos.contains(key) {
                    photos.insert(key)
                    self.userInfo.photos = photos
                }
            }
            
            let imageURL = Configuration.S3.PROFILE_IMAGE_URL + objectKey
            
            SDImageCache.shared().removeImage(forKey: imageURL, withCompletion: nil)
            self.dataSource.saveUserInfo(userInfo: self.userInfo) { isSuccess in
                DispatchQueue.main.async {
                    if isSuccess {
                        completion(.success(object: self.userInfo))
                    } else {
                        completion(.failure(.notAvailable))
                    }
                }
            }
            return nil
        }
        
    }
}
