//
//  UserInfoManager.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 6. 5..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

class UserInfoManager: NSObject {
    
    static let UpdatePointNotification = "com.entuition.wekend.Notification.UpdatePoint"
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
        return getUserInfo(userId: userId).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let result = task.result else {
                fatalError("UserInfoManager > getOwnedUserInfo Failed")
            }
            
            self.userInfo = result as? UserInfo
            return nil
        })
    }
    
    func getUserInfo(userId: String) -> AWSTask<AnyObject> {
        
        let getUserTask = AWSTaskCompletionSource<AnyObject>()
        
        self.mapper.load(UserInfo.self, hashKey: userId, rangeKey: nil).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let result = task.result else {
                fatalError("UserInfoManager > getUserInfo Failed")
            }
            
            getUserTask.set(result: result as? UserInfo)
            
            return nil
        })
        
        return getUserTask.task
    }
    
    func isUsernameAvailable(username: String) -> AWSTask<AnyObject> {
        let checkUsernameTask = AWSTaskCompletionSource<AnyObject>()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = UserInfo.Schema.INDEX_USERNAME
        queryExpression.keyConditionExpression = "\(UserInfo.Attribute.USERNAME) = :username"
        queryExpression.expressionAttributeValues = [":username" : username]
        
        mapper.query(UserInfo.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let results = task.result?.items else {
                fatalError("UserInfoManager > isUsernameAvailable > Error")
            }
            
            self.printLog("isUsernameAvailable > results.count : \(results.count)")
            
            if results.count == 0 {
                checkUsernameTask.set(result: true as AnyObject?)
            } else {
                checkUsernameTask.set(result: false as AnyObject?)
            }
            
            return nil
        })
        
        return checkUsernameTask.task
    }
    
    func isNicknameAvailable(nickname: String) -> AWSTask<AnyObject> {
        let nicknameTask = AWSTaskCompletionSource<AnyObject>()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = UserInfo.Schema.INDEX_NICKNAME
        queryExpression.keyConditionExpression = "\(UserInfo.Attribute.NICKNAME) = :nickname"
        queryExpression.expressionAttributeValues = [":nickname" : nickname]
        
        mapper.query(UserInfo.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let resultItems = task.result?.items else {
                fatalError("UserInfoManager > isNicknameAvailable Error")
            }
            
            if resultItems.count == 0 {
                nicknameTask.set(result: true as AnyObject?)
            } else {
                nicknameTask.set(result: false as AnyObject?)
            }
            
            return nil
        })
        
        return nicknameTask.task
    }
    
    func saveUserInfo(userInfo: UserInfo) -> AWSTask<AnyObject> {
        
        return mapper.save(userInfo).continueWith(block: {
            (task: AWSTask) -> Any? in
            
            if task.error == nil {
                
                self.userInfo = userInfo
                
                let imageName = userInfo.userid + "/" + Configuration.S3.PROFILE_IMAGE_NAME(0)
                let imageUrl  = Configuration.S3.PROFILE_IMAGE_URL + imageName
                
                UIImageView.removeObjectFromCache(forKey: imageUrl as AnyObject)
                NotificationCenter.default.post(name: Notification.Name(UserInfoManager.UpdateUserInfoNotification), object: nil)
            }
            return nil
        })
    }
    
    func deleteUserInfo(userInfo: UserInfo) -> AWSTask<AnyObject> {
        return mapper.remove(userInfo)
    }

    func chargePoint(point: Int) -> AWSTask<AnyObject> {
        
        printLog("chargePoint > point : \(point)")
        
        guard let userInfo = self.userInfo else {
            fatalError("UserInfoManager > could not load userInfo")
        }
        
        let oldPoint = userInfo.balloon as? Int ?? 0
        userInfo.balloon = oldPoint + point
        
        return mapper.save(userInfo).continueWith(block: {
            (task: AWSTask) -> Any! in
            
            if task.error != nil { return nil }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: UserInfoManager.UpdatePointNotification),
                                            object: nil,
                                            userInfo: [UserInfoManager.NotificationDataPoint : userInfo.balloon! as! Int])
            
            return nil
        })
    }
    
    func consumePoint() -> AWSTask<AnyObject> {
        
        guard let oldPoint = userInfo?.balloon as? Int else {
            fatalError("consumePoint > could not load point")
        }
        
        let newPoint = oldPoint - 500
        if newPoint < 0 {
            return AWSTask(error: PurchaseError.notEnoughPoint)
        }
        
        userInfo?.balloon = newPoint
        
        return mapper.save(userInfo!).continueWith(block: {
            (task: AWSTask) -> Any? in
            
            if task.error == nil {
                NotificationCenter.default.post(name: Notification.Name(rawValue: UserInfoManager.UpdatePointNotification),
                                                object: nil,
                                                userInfo: [UserInfoManager.NotificationDataPoint : newPoint])
            }
            
            return nil
        })
    }
    
    func clearNotificationCount(_ type: NavigationType) -> AWSTask<AnyObject> {
        
        guard let userInfo = self.userInfo else {
            printLog("clearNotification > userInfo is nil")
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
        
        printLog("registerARN")
        
        guard let deviceToken = UserDefaults.RemoteNotification.string(forKey: .deviceToken),
            let userId = userInfo?.userid else {
                printLog("registEndpointARN > deviceToken or userId is nil")
                return
        }
        
        let apiClient = WEKENDNotificationAPIClient.default()
        let requestModel = WEKENDCreateEndpointARNRequestModel()!
        requestModel.platform = Configuration.PLATFORM
        requestModel.snsToken = deviceToken
        requestModel.userId = userId
        
        apiClient.endpointarnPost(requestModel).continueWith(block: {
            task -> Any! in
            
            if task.error != nil || task.result == nil {
                self.printLog("registEndpointARN > Error")
            } else {
                guard let response = task.result as? WEKENDCreateEndpointARNResponseModel else {
                    self.printLog("registEndpointARN > response is nil")
                    return nil
                }
                
                self.userInfo?.EndpointARN = response.endpointARN
                UserDefaults.RemoteNotification.set(true, forKey: .isRegistered)
                
                self.printLog("registerARN > endpoint : \(String(describing: response.endpointARN))")
                
            }
            
            return nil
        })
    }
    
    func sendVerificationCode(phoneNumber: String) -> AWSTask<NSString> {
        
        let verificationTask = AWSTaskCompletionSource<NSString>()
        
        guard let verificaitonURL = URL(string: Configuration.ApiGateway.VERIFICATION_URL) else {
            fatalError("UserInfoManager > sendVerificationCode > make URL Error")
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
            printLog("sendVerificationCode > create JSON from body Error")
            return AWSTask(result: nil)
        }
        
        URLSession.shared.dataTask(with: verificationRequest) {
            (data, response, error) in
            
            guard let responseData = data else {
                self.printLog("sendVerificationCode > no response")
                return
            }
            
            do {
                
                guard let returnValue = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String : Any] else {
                    self.printLog("sendVerification > Could not get JSON from response as Dictionary")
                    return
                }
                
                guard let verificationCode = returnValue["verificationCode"] as? String else {
                    self.printLog("sendVerificationCode > verificationCode is nil")
                    return
                }
                
                self.printLog("verificationCode : \(verificationCode)")
                
                verificationTask.set(result: verificationCode as NSString)
                
            } catch {
                self.printLog("sendVerificationCode > URLSession Error")
                return
            }
            }.resume()
        
        return verificationTask.task
    }
}
