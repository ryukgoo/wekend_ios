//
//  LikeItem.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 16..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

class LikeItem: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    struct Schema {
        static let TABLE_NAME = "picnic_like_db"
        static let INDEX_PRODUCTID_UPDATEDTIME = "ProductId-UpdatedTime-index"
        static let INDEX_USERID_UPDATEDTIME = "UserId-UpdatedTime-index"
    }
    
    struct Attribute {
        static let USER_ID = "UserId"
        static let NICKNAME = "Nickname"
        static let GENDER = "Gender"
        static let PRODUCT_ID = "ProductId"
        static let PRODUCT_TITLE = "ProductTitle"
        static let PRODUCT_DESC = "ProductDesc"
        static let UPDATED_TIME = "UpdatedTime"
        static let READ_TIME = "ReadTime"
        static let LIKE_ID = "LikeId"
    }
    
    // MARK: Attributes // Add Nickname
    
    var UserId: String = ""
    var Nickname: String = ""
    var Gender: String = ""
    var ProductId: Int = -1
    var ProductTitle: String?
    var ProductDesc: String?
    var UpdatedTime: String?
    var ReadTime: String?
    var LikeId: String?
    var isRead: Bool = false
    var productLikedTime: String = ""
    
    // AWSDynamoDBModeling functions
    
    static func dynamoDBTableName() -> String {
        return Schema.TABLE_NAME
    }
    
    static func hashKeyAttribute() -> String {
        return Attribute.USER_ID
    }
    
    static func rangeKeyAttribute() -> String {
        return Attribute.PRODUCT_ID
    }
    
    static func ignoreAttributes() -> [String] {
        return ["isRead", "productLikedTime"]
    }
}

class LikeReadState: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    struct Schema {
        static let TABLE_NAME = "like_read_state"
        static let INDEX_PRODUCTID_USERID = "ProductId-UserId-index"
    }
    
    struct Attribute {
        static let LIKE_ID = "LikeId"
        static let USER_ID = "UserId"
        static let PRODUCT_ID = "ProductId"
        static let LIKE_USER_ID = "LikeUserId"
        static let READ_TIME = "ReadTime"
    }
    
    var LikeId: String = ""
    var UserId: String = ""
    var ProductId: Int = -1
    var LikeUserId: String = ""
    var ReadTime: String?
    
    static func dynamoDBTableName() -> String {
        return Schema.TABLE_NAME
    }
    
    static func hashKeyAttribute() -> String {
        return Attribute.LIKE_ID
    }
    
    static func rangeKeyAttribute() -> String {
        return Attribute.USER_ID
    }
    
    static func ignoreAttributes() -> [String] {
        return []
    }
}
