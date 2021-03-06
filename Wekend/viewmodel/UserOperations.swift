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

struct LoadUserOperation {
    
    let userId: String
    let dataSource: UserInfoDataSource
    
    init(userId: String, dataSource: UserInfoDataSource) {
        self.userId = userId
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (Result<UserInfo, FailureReason>) -> Void) {
        dataSource.getUserInfo(id: userId) { result in
            DispatchQueue.main.async {
                if case let Result.success(object: value) = result {
                    completion(.success(object: value))
                } else if case Result.failure(_) = result {
                    completion(.failure(.notAvailable))
                }
            }
        }
    }
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

struct SearchUserByUsernameOpration {
    
    let username: String
    let dataSource: UserInfoDataSource
    
    init(username: String, dataSource: UserInfoDataSource) {
        self.username = username
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (UserInfo?) -> Void) {
        dataSource.searchUser(username: username) { result in
            DispatchQueue.main.async {
                if case let Result.success(object: info) = result {
                    completion(info)
                } else {
                    completion(nil)
                }
            }
        }
    }
}

struct SearchUserByPhoneOperation {
    
    let phone: String
    let dataSource: UserInfoDataSource
    
    init(phone: String, dataSource: UserInfoDataSource) {
        self.phone = phone
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (UserInfo?) -> Void) {
        dataSource.searchUser(phone: phone) { result in
            if case let Result.success(object: info) = result {
                completion(info)
            } else {
                completion(nil)
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
            } else {
                var photos = Set<String>()
                photos.insert(key)
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
            
            let deleteThumbRequest = AWSS3DeleteObjectRequest()
            deleteThumbRequest?.bucket = Configuration.S3.PROFILE_THUMB_BUCKET
            deleteThumbRequest?.key = objectKey
            s3Client.deleteObject(deleteThumbRequest!).continueWith(executor: AWSExecutor.mainThread()) { task in return nil }
            
            guard var photos = self.userInfo.photos as? Set<String> else { return nil }
            if photos.contains(objectKey) {
                photos.remove(objectKey)
                
                print("\(#function) > photos : \(photos)")
                if photos.count == 0 {
                    self.userInfo.photos = nil
                } else {
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

struct ResetPasswordOperation {
    
    let userId: String
    let password: String
    
    init(userId: String, password: String) {
        self.userId = userId
        self.password = password
    }
    
    func execute(completion: @escaping (Result<String, FailureReason>) -> Void) {
        AmazonClientManager.shared.devIdentityProvider?.resetPassword(userId: userId, password: password).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            guard let userId = task.result as String? else {
                completion(.failure(.notAvailable))
                return nil
            }
            
            completion(.success(object: userId))
            
            return nil
        }
    }
    
}
