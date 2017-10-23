
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
        static let PHONE = "phone"
        static let PHOTOS = "photos"
        static let BALLOON = "balloon"
        static let ENDPOINT_ARN = "EndpointARN"
        static let NEW_LIKE_COUNT = "NewLikeCount"
        static let NEW_SEND_COUNT = "NewSendCount"
        static let NEW_RECEIVE_COUNT = "NewReceiveCount"
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
    var phone: String?
    var photos: Any?
    var photosArr: [String] = []
    var balloon: Any?
    var EndpointARN: String?
    var NewLikeCount: Int = 0
    var NewSendCount: Int = 0
    var NewReceiveCount: Int = 0
    
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

enum BillingPoint: Int, EnumCollection {
    
    case price1 = 1000
    case price2 = 3500
    case price3 = 6000
    case price4 = 12500
    case price5 = 38500
    
    init(id: String) {
        switch id {
            case "com.entuition.wekend.purchase.point.1":
                self = .price1
            break
            case "com.entuition.wekend.purchase.point.2":
                self = .price2
            break
            case "com.entuition.wekend.purchase.point.3":
                self = .price3
            break
            case "com.entuition.wekend.purchase.point.4":
                self = .price4
            break
            case "com.entuition.wekend.purchase.point.5":
                self = .price5
            break
        default:
            self = .price1
            break
        }
    }
    
    var toString: String {
        switch self {
        case .price1:
            return "com.entuition.wekend.purchase.point.1"
        case .price2:
            return "com.entuition.wekend.purchase.point.2"
        case .price3:
            return "com.entuition.wekend.purchase.point.3"
        case .price4:
            return "com.entuition.wekend.purchase.point.4"
        case .price5:
            return "com.entuition.wekend.purchase.point.5"
        }
    }
    
    var id: String {
        return self.toString
    }
}
