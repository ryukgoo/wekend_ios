//
//  UserInfoManager.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 6. 5..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB
import AWSCore

class UserInfoManager: NSObject {
    
    static let UpdateUserInfoNotification = "com.entution.wekend.Notification.UpdateUser"
    static let NotificationDataPoint = "com.entuition.wekend.Notification.Data.Point"
    
    static let sharedInstance = UserInfoManager()
    
    private let mapper: AWSDynamoDBObjectMapper
    var userInfo: UserInfo?
    
    override init() {
        mapper = AWSDynamoDBObjectMapper.default()
        super.init()
    }
    
    func destroy() {
        userInfo = nil
    }
    
    func getOwnedUserInfo(userId: String) -> AWSTask<AnyObject> {
        
        let getOwnedUserInfoTask = AWSTaskCompletionSource<AnyObject>()
        
        getUserInfo(userId: userId).continueWith(executor: AWSExecutor.mainThread()) {
            (task: AWSTask) -> Any! in
            
            if task.error != nil {
                getOwnedUserInfoTask.set(error: AuthenticateError.userNotFound)
                return nil
            }
            
            guard let userInfo = task.result as? UserInfo else {
                getOwnedUserInfoTask.set(error: AuthenticateError.userNotFound)
                return nil
            }
            
            self.userInfo = userInfo
            if let photoSet = userInfo.photos as? Set<String> {
                self.userInfo?.photosArr = photoSet.sorted(by: <)
            }
            
            UserDefaults.NotificationCount.set(userInfo.NewLikeCount, forKey: .like)
            UserDefaults.NotificationCount.set(userInfo.NewSendCount, forKey: .sendMail)
            UserDefaults.NotificationCount.set(userInfo.NewReceiveCount, forKey: .receiveMail)
            
            getOwnedUserInfoTask.set(result: userInfo)
            
            return nil
        }
        
        return getOwnedUserInfoTask.task
    }
    
    func getUserInfo(userId: String) -> AWSTask<AnyObject> {
        
        let getUserTask = AWSTaskCompletionSource<AnyObject>()
        
        mapper.load(UserInfo.self, hashKey: userId, rangeKey: nil).continueWith(executor: AWSExecutor.mainThread()) {
            (task: AWSTask) -> Any! in
            
            guard let result = task.result as? UserInfo else {
                getUserTask.set(error: AuthenticateError.userNotFound)
                return nil
            }
            
            if let photoSet = result.photos as? Set<String> {
                self.userInfo?.photosArr = photoSet.sorted(by: <)
            }
            
            getUserTask.set(result: result)
            
            return nil
        }
        
        return getUserTask.task
    }
    
    func isUsernameAvailable(username: String) -> AWSTask<AnyObject> {
        let checkUsernameTask = AWSTaskCompletionSource<AnyObject>()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = UserInfo.Schema.INDEX_USERNAME
        queryExpression.keyConditionExpression = "\(UserInfo.Attribute.USERNAME) = :username"
        queryExpression.expressionAttributeValues = [":username" : username]
        
        mapper.query(UserInfo.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread()) {
            (task: AWSTask) -> Any! in
            
            guard let results = task.result?.items else {
                checkUsernameTask.set(error: AuthenticateError.unknown)
                return nil
            }
            
            if results.count == 0 {
                checkUsernameTask.set(result: true as AnyObject?)
            } else {
                checkUsernameTask.set(result: false as AnyObject?)
            }
            
            return nil
        }
        
        return checkUsernameTask.task
    }
    
    func isNicknameAvailable(nickname: String) -> AWSTask<AnyObject> {
        let nicknameTask = AWSTaskCompletionSource<AnyObject>()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = UserInfo.Schema.INDEX_NICKNAME
        queryExpression.keyConditionExpression = "\(UserInfo.Attribute.NICKNAME) = :nickname"
        queryExpression.expressionAttributeValues = [":nickname" : nickname]
        
        mapper.query(UserInfo.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread()) {
            (task: AWSTask) -> Any! in
            
            guard let resultItems = task.result?.items else {
                nicknameTask.set(error: AuthenticateError.unknown)
                return nil
            }
            
            if resultItems.count == 0 {
                nicknameTask.set(result: true as AnyObject?)
            } else {
                nicknameTask.set(result: false as AnyObject?)
            }
            
            return nil
        }
        
        return nicknameTask.task
    }
    
    func saveUserInfo(userInfo: UserInfo, completion: @escaping (_:Bool) -> Void) {
        mapper.save(userInfo).continueWith(executor: AWSExecutor.mainThread()) {
            (task: AWSTask) -> Any? in
            if task.error == nil {
                self.userInfo = userInfo
                NotificationCenter.default.post(name: Notification.Name(UserInfoManager.UpdateUserInfoNotification),
                                                object: nil)
            }
            completion(task.error == nil)
            return nil
        }
    }
    
    func deleteUserInfo(userInfo: UserInfo) -> AWSTask<AnyObject> {
        return mapper.remove(userInfo)
    }

    func chargePoint(point: Int, completion: @escaping (_:Bool) -> Void) {
        print("\(className) > \(#function) > point : \(point)")
        guard let userInfo = self.userInfo else {
            print("\(className) > \(#function) > get userInfo Error")
            completion(false)
            return
        }
        
        let oldPoint = userInfo.balloon as? Int ?? 0
        userInfo.balloon = oldPoint + point
        
        saveUserInfo(userInfo: userInfo) { isSuccess in
            completion(isSuccess)
        }
    }
    
    func consumePoint(completion: @escaping (_:Bool) -> Void) throws {
        
        guard let userInfo = self.userInfo,
            let oldPoint = userInfo.balloon as? Int else {
                throw PurchaseError.notEnoughPoint
        }
        
        let newPoint = oldPoint - 500
        if newPoint < 0 { throw PurchaseError.notEnoughPoint }
        
        userInfo.balloon = newPoint
        
        saveUserInfo(userInfo: userInfo) { isSuccess in
            completion(isSuccess)
        }
    }
    
    func clearNotificationCount(_ type: NavigationType) -> AWSTask<AnyObject> {
        
        guard let userInfo = self.userInfo else {
            print("\(className) > \(#function) > userInfo is nil")
            return AWSTask(result: nil)
        }
        
        switch type {
        case .like:
            userInfo.NewLikeCount = 0
            break
        case .mail:
            userInfo.NewReceiveCount = 0
            userInfo.NewSendCount = 0
            break
        default:
            break
        }
        
        return mapper.save(userInfo)
    }
    
    func registEndpointARN() {
        
        print("\(className) > \(#function)")
        
        guard let deviceToken = UserDefaults.RemoteNotification.string(forKey: .deviceToken) else {
            print("\(self.className) > \(#function) > deviceToken is nil")
            return
        }
        
        guard let userId = userInfo?.userid else {
            print("\(self.className) > \(#function) > userId is nil")
            return
        }
        
        let apiClient = WEKENDNotificationAPIClient.default()
        let requestModel = WEKENDCreateEndpointARNRequestModel()!
        requestModel.platform = Configuration.PLATFORM
        requestModel.snsToken = deviceToken
        requestModel.userId = userId
        
        apiClient.endpointarnPost(requestModel).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if task.error != nil || task.result == nil {
                print("\(self.className) > \(#function) > Error")
            } else {
                guard let response = task.result as? WEKENDCreateEndpointARNResponseModel else {
                    print("\(self.className) > \(#function) > response is nil")
                    return nil
                }
                
                self.userInfo?.EndpointARN = response.endpointARN
                print("\(self.className) > \(#function) > endpoint : \(String(describing: response.endpointARN))")
                
            }
            
            return nil
        }
    }
    
    func sendVerificationCode(phoneNumber: String) -> AWSTask<NSString> {
        
        let verificationTask = AWSTaskCompletionSource<NSString>()
        
        guard let verificaitonURL = URL(string: Configuration.ApiGateway.VERIFICATION_URL) else {
            fatalError("\(className) > \(#function) > make URL Error")
        }
        
        var verificationRequest = URLRequest(url: verificaitonURL)
        verificationRequest.httpMethod = "POST"
        
        var body: [String: Any] = [String : Any]()
        body["phone"] = phoneNumber
        
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            verificationRequest.httpBody = jsonData
        } catch {
            print("\(className) > \(#function) > create JSON from body Error")
            return AWSTask(result: nil)
        }
        
        URLSession.shared.dataTask(with: verificationRequest) {
            (data, response, error) in
            
            guard let responseData = data else {
                print("\(self.className) > \(#function) > no response")
                return
            }
            
            do {
                
                guard let returnValue = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String : Any] else {
                    print("\(self.className) > \(#function) > Could not get JSON from response as Dictionary")
                    return
                }
                
                guard let verificationCode = returnValue["verificationCode"] as? String else {
                    print("\(self.className) > \(#function) > verificationCode is nil")
                    return
                }
                
                print("\(self.className) > \(#function) > verificationCode : \(verificationCode)")
                
                verificationTask.set(result: verificationCode as NSString)
                
            } catch {
                print("\(self.className) > \(#function) > URLSession Error")
                return
            }
            }.resume()
        
        return verificationTask.task
    }
}
