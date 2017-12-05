//
//  ReceiveMail.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 19..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

class ReceiveMail: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    struct Schema {
        static let TABLE_NAME = "receive_mail_db"
        static let INDEX_USERID_RESPONSETIME = "UserId-ResponseTime-index"
    }
    
    struct Attribute {
        static let USER_ID = "UserId"
        static let UPDATED_TIME = "UpdatedTime"
        static let RESPONSE_TIME = "ResponseTime"
        static let PRODUCT_ID = "ProductId"
        static let PRODUCT_TITLE = "ProductTitle"
        static let SENDER_ID = "SenderId"
        static let SENDER_NICKNAME = "SenderNickname"
        static let RECEIVER_NICKNAME = "ReceiverNickname"
        static let STATUS = "ProposeStatus"
        static let ISREAD = "IsRead"
    }
    
    // MARK: Properties
    
    var UserId: String = ""
    var UpdatedTime: String = ""
    var ResponseTime: String = ""
    var ProductId: Any?
    var ProductTitle: String?
    var SenderId: String?
    var SenderNickname: String?
    var ReceiverNickname: String?
    var ProposeStatus: String?
    var IsRead: Any?
    
    // MARK: AWSDynamoDBModeling functions
    
    static func dynamoDBTableName() -> String {
        return Schema.TABLE_NAME
    }
    
    static func hashKeyAttribute() -> String {
        return Attribute.USER_ID
    }
    
    static func rangeKeyAttribute() -> String {
        return Attribute.UPDATED_TIME
    }
    
    static func ignoreAttributes() -> [String] {
        return []
    }
}
