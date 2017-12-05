//
//  SendMail.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 19..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

class SendMail: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    struct Schema {
        static let TABLE_NAME = "send_mail_db"
        static let INDEX_USERID_RESPONSETIME = "UserId-ResponseTime-index"
    }
    
    struct Attribute {
        static let USER_ID = "UserId"
        static let UPDATED_TIME = "UpdatedTime"
        static let RESPONSE_TIME = "ResponseTime"
        static let PRODUCT_ID = "ProductId"
        static let PRODUCT_TITLE = "ProductTitle"
        static let RECEIVER_ID = "ReceiverId"
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
    var ReceiverId: String?
    var SenderNickname: String?
    var ReceiverNickname: String?
    var ProposeStatus: String?
    var IsRead: Any?
    
    // AWSDynamoDBModeling functions
    
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

enum ProposeStatus: String {
    
    case none = "none"
    case notMade = "notMade"
    case made = "Made"
    case reject = "reject"
    case delete = "delete"
    case alreadyMade = "alreadyMade"
    
    func message() -> String {
        
        switch self {
        case .none:
            return "함께 가기 신청"
        case .notMade :
            return "함께 가기 신청중"
        case .made :
            return "함께 가기 성공"
        case .alreadyMade :
            return "함께 가기 성공"
        case .delete :
            return "함께 가기 신청 삭제됨"
        case .reject :
            return "함께 가기 거절"
        }
    }
}
