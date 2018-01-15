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

protocol UserInfoDataSource {
    
    var userId: String? { get }
    var userInfo: UserInfo? { get }
    
    func destroy()
    
    func getUserInfo(id: String, completion: @escaping (Result<UserInfo, FailureReason>) -> Void)
    func validateUsername(name: String, completion: @escaping (Bool) -> Void)
    func validateNickname(name: String, completion: @escaping (Bool) -> Void)
    func updateUser(info: UserInfo, completion: @escaping (Result<UserInfo, FailureReason>) -> Void)
    func deleteUser(info: UserInfo, completion: @escaping (Bool) -> Void)
    func chargePoint(point: Int, completion: @escaping (Result<UserInfo, FailureReason>) -> Void)
    func consumePoint(point: Int, completion: @escaping (Result<UserInfo, PurchaseError>) -> Void)
    func registerEndpoint()
    func requestVerificationCode(phone: String, completion: @escaping (Result<String, FailureReason>) -> Void)
    func confirmVerificationCode(code: String) -> Bool
}

struct UserNotification {
    static let Update = "com.entution.wekend.user.Update"
}

class UserInfoRepository: NSObject, UserInfoDataSource {
    
    static let shared = UserInfoRepository()
    private let mapper: AWSDynamoDBObjectMapper
    
    var userDictionary: [String: UserInfo]
    var userId: String? { return UserDefaults.Account.string(forKey: .userId) }
    var userInfo: UserInfo? {
        guard let id = userId else { return nil }
        return userDictionary[id]
    }
    
    fileprivate var verificationCode: String?
    
    override init() {
        mapper = AWSDynamoDBObjectMapper.default()
        userDictionary = [String: UserInfo]()
        super.init()
    }
    
    func destroy() {
        userDictionary = [String: UserInfo]()
    }
    
    func getUserInfo(id: String, completion: @escaping (Result<UserInfo, FailureReason>) -> Void) {
        mapper.load(UserInfo.self, hashKey: id, rangeKey: nil)
            .continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if let result = task.result as? UserInfo {
                if let photos = result.photos as? Set<String> {
                    result.photosArr = photos.sorted(by: <)
                }
                self.userDictionary[result.userid] = result
                completion(.success(object: result))
                return nil
            }
            
            completion(.failure(.notAvailable))
            
            return nil
        }
    }
    
    func validateUsername(name: String, completion: @escaping (Bool) -> Void) {
        
        print("\(className) > \(#function) > name : \(name)")
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = UserInfo.Schema.INDEX_USERNAME
        queryExpression.keyConditionExpression = "\(UserInfo.Attribute.USERNAME) = :username"
        queryExpression.expressionAttributeValues = [":username" : name]
        
        mapper.query(UserInfo.self, expression: queryExpression)
            .continueWith(executor: AWSExecutor.mainThread()) { task in
                
            if let results = task.result?.items {
                if results.count > 0 {
                    print("\(self.className) > \(#function) > count : \(results.count)")
                    completion(false)
                    return nil
                }
            }
            
            completion(true)
            return nil
        }
    }
    
    func validateNickname(name: String, completion: @escaping (Bool) -> Void) {
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = UserInfo.Schema.INDEX_NICKNAME
        queryExpression.keyConditionExpression = "\(UserInfo.Attribute.NICKNAME) = :nickname"
        queryExpression.expressionAttributeValues = [":nickname" : name]
        
        mapper.query(UserInfo.self, expression: queryExpression)
            .continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if let results = task.result?.items {
                if results.count > 0 {
                    completion(false)
                    return nil
                }
            }
            
            completion(true)
            return nil
        }
    }
    
    func updateUser(info: UserInfo, completion: @escaping (Result<UserInfo, FailureReason>) -> Void) {
        mapper.save(info).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if let _ = task.error {
                completion(.failure(.notAvailable))
                return nil
            }
            
            self.userDictionary[info.userid] = info
            completion(.success(object: info))
            return nil
        }
    }
    
    func deleteUser(info: UserInfo, completion: @escaping (Bool) -> Void) {
        mapper.remove(info).continueWith(executor: AWSExecutor.mainThread()) { task in
            if let _ = task.error {
                completion(false)
                return nil
            }
            
            if let index = self.userDictionary.index(forKey: info.userid) {
                self.userDictionary.remove(at: index)
            }
            completion(true)
            return nil
        }
    }
    
    func chargePoint(point: Int, completion: @escaping (Result<UserInfo, FailureReason>) -> Void) {
        guard let userInfo = userInfo else {
            completion(.failure(.notAvailable))
            return
        }
        let oldPoint = userInfo.balloon as? Int ?? 0
        userInfo.balloon = oldPoint + point
        
        updateUser(info: userInfo) { result in
            if case let Result.success(object: value) = result {
                completion(.success(object: value))
            } else {
                completion(.failure(.notAvailable))
            }
        }
    }
    
    func consumePoint(point: Int, completion: @escaping (Result<UserInfo, PurchaseError>) -> Void) {
        guard let userInfo = userInfo, let oldPoint = userInfo.balloon as? Int else {
            completion(.failure(.notEnoughPoint))
            return
        }
        
        if oldPoint < 500 {
            completion(.failure(.notEnoughPoint))
            return
        }
        
        userInfo.balloon = oldPoint - 500
        
        updateUser(info: userInfo) { result in
            if case let Result.success(object: value) = result {
                completion(.success(object: value))
            } else {
                completion(.failure(.notAvailable))
            }
        }
    }
    
    func registerEndpoint() {
        guard let deviceToken = UserDefaults.RemoteNotification.string(forKey: .deviceToken) else { return }
        guard let id = userId, let userInfo = userInfo else { return }
        
        let apiClient = WEKENDNotificationAPIClient.default()
        let requestModel = WEKENDCreateEndpointARNRequestModel()!
        requestModel.platform = Configuration.PLATFORM
        requestModel.snsToken = deviceToken
        requestModel.userId = id
        
        apiClient.endpointarnPost(requestModel).continueWith(executor: AWSExecutor.mainThread()) { task in
            guard let response = task.result as? WEKENDCreateEndpointARNResponseModel else { return nil }
            userInfo.EndpointARN = response.endpointARN
            self.userDictionary[id] = userInfo
            return nil
        }
    }
    
    func requestVerificationCode(phone: String, completion: @escaping (Result<String, FailureReason>) -> Void) {
        guard let requestURL = URL(string: Configuration.ApiGateway.VERIFICATION_URL) else { return }
        
        var urlRequest = URLRequest(url: requestURL)
        urlRequest.httpMethod = "POST"
        var body: [String: Any] = [String: Any]()
        body["phone"] = phone
        
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            urlRequest.httpBody = jsonData
        } catch {
            print("\(className) > \(#function) > create JSON from body Error")
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            
            guard let responseData = data else {
                print("\(self.className) > \(#function) > no response")
                completion(.failure(.notAvailable))
                return
            }
            
            do {
                guard let returnValue =
                    try JSONSerialization.jsonObject(with: responseData, options: []) as? [String : Any] else {
                    print("\(self.className) > \(#function) > Could not get JSON from response as Dictionary")
                    completion(.failure(.notAvailable))
                    return
                }
                guard let verificationCode = returnValue["verificationCode"] as? String else {
                    print("\(self.className) > \(#function) > verificationCode is nil")
                    completion(.failure(.notAvailable))
                    return
                }
                self.verificationCode = verificationCode
                completion(.success(object: verificationCode))
            } catch {
                print("\(self.className) > \(#function) > URLSession Error")
                completion(.failure(.notAvailable))
                return
            }
        }.resume()
    }
    
    func confirmVerificationCode(code: String) -> Bool {
        if let verificationCode = verificationCode {
            return verificationCode == code
        }
        return false
    }
}
