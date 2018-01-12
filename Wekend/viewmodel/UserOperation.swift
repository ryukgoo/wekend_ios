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
    
    let userInfo: UserInfo
    let dataSource: UserInfoDataSource
    
    init(userInfo: UserInfo, dataSource: UserInfoDataSource) {
        self.userInfo = userInfo
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (Bool) -> Void) {
        dataSource.updateUser(info: userInfo) { result in
            DispatchQueue.main.async {
                if case Result.success(object: _) = result {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
}

struct UploadImageOperation {
    
    let userInfo: UserInfo
    let image: UIImage
    let index: Int
    let dataSource: UserInfoDataSource
    
    init(userInfo: UserInfo, image: UIImage, index: Int, dataSource: UserInfoDataSource) {
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
            
            self.dataSource.updateUser(info: self.userInfo) { result in
                DispatchQueue.main.async {
                    if case let Result.success(object: value) = result {
                        completion(.success(object: value))
                    } else {
                        completion(.failure(.notAvailable))
                    }
                }
            }
            return nil
        }
    }
}

struct DeleteImageOperation {
    let userInfo: UserInfo
    let index: Int
    let dataSource: UserInfoDataSource
    
    init(userInfo: UserInfo, index: Int, dataSource: UserInfoDataSource) {
        self.userInfo = userInfo
        self.index = index
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (Result<UserInfo, FailureReason>) -> Void) {
        let s3Client = AWSS3.default()
        let deleteObjectRequest = AWSS3DeleteObjectRequest()
        
        let objectKey = "\(userInfo.userid)/\(Configuration.S3.PROFILE_IMAGE_NAME(index))"
        deleteObjectRequest?.bucket = Configuration.S3.PROFILE_IMAGE_BUCKET
        deleteObjectRequest?.key = objectKey
        s3Client.deleteObject(deleteObjectRequest!).continueWith(executor: AWSExecutor.mainThread()) { task in
            if let error = task.error {
                print("\(#function) > Error: \(error)")
                return nil
            }
            
            guard var photos = self.userInfo.photos as? Set<String> else { return nil }
            if photos.contains(objectKey) {
                photos.remove(objectKey)
                self.userInfo.photos = photos
            }
            
            let imageURL = Configuration.S3.PROFILE_IMAGE_URL + objectKey
            SDImageCache.shared().removeImage(forKey: imageURL, withCompletion: nil)
            
            self.dataSource.updateUser(info: self.userInfo) { result in
                DispatchQueue.main.async {
                    if case let Result.success(object: value) = result {
                        completion(.success(object: value))
                    } else {
                        completion(.failure(.notAvailable))
                    }
                }
            }
            return nil
        }
    }
}

struct RequestCodeOperation {
    
    let phone: String
    let dataSource: UserInfoDataSource
    
    init(phone: String, dataSource: UserInfoDataSource) {
        self.phone = phone
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (Result<String, FailureReason>) -> Void) {
        dataSource.requestVerificationCode(phone: phone) { result in
            DispatchQueue.main.async {
                if case let Result.success(object: code) = result {
                    completion(.success(object: code))
                } else {
                    completion(.failure(.notAvailable))
                }
            }
        }
    }
}
