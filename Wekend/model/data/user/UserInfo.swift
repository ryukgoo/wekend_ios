
//
//  UserInfoManager.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 20..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

class UserInfo: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    struct Schema {
        static let TABLE_NAME = "picnic_users"
        static let INDEX_USERNAME = "username-index"
        static let INDEX_NICKNAME = "nickname-index"
        static let INDEX_PHONE_TIME = "phone-registered_time-index"
    }
    
    struct Attribute {
        static let USERNAME = "username"
        static let HASHED_PASSWORD = "hashed_password"
        static let STATUS = "status"
        static let USERID = "userid"
        static let REGISTERED_TIME = "registered_time"
        static let NICKNAME = "nickname"
        static let GENDER = "gender"
        static let BIRTH = "birth"
        static let COMPANY = "company"
        static let SCHOOL = "school"
        static let AREA = "area"
        static let INTRODUCE = "introduce"
        static let PHONE = "phone"
        static let PHOTOS = "photos"
        static let BALLOON = "balloon"
        static let ENDPOINT_ARN = "EndpointARN"
        static let NEW_LIKE_COUNT = "NewLikeCount"
        static let NEW_SEND_COUNT = "NewSendCount"
        static let NEW_RECEIVE_COUNT = "NewReceiveCount"
        
        static let PURCHASE_TIME = "PurchaseTime"
        static let EXPIRES_TIME = "ExpiresTime"
    }
    
    struct RawValue {
        static let STATUS_ACTIVE = "ACTIVE"
        static let GENDER_MALE = "male"
        static let GENDER_FEMALE = "female"
    }
    
    // MARK: Attributes
    
    var userid: String = ""
    var username: String?
    var hashed_password: String = ""
    var status: String?
    var registered_time: String?
    var nickname: String?
    var gender: String?
    var birth: Any?
    var company: String?
    var school: String?
    var area: String?
    var introduce: String?
    var phone: String?
    var balloon: Any?
    var EndpointARN: String?
    var NewLikeCount: Int = 0
    var NewSendCount: Int = 0
    var NewReceiveCount: Int = 0
    
    var PurchaseTime: String?
    var ExpiresTime: String?
    
    var photos: Any? {
        didSet {
            guard let photos = photos as? Set<String> else { return }
            photosArr = photos.sorted(by: <)
        }
    }
    var photosArr: [String] = []
    
    static func dynamoDBTableName() -> String {
        return Schema.TABLE_NAME
    }
    
    static func hashKeyAttribute() -> String {
        return Attribute.USERID
    }
    
    static func ignoreAttributes() -> [String] {
        return ["photosArr"]
    }
}
