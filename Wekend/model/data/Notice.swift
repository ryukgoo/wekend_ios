//
//  Notice.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 6. 14..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

class Notice: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    struct Schema {
        static let TABLE_NAME = "notice_db"
        static let NOTICE_TYPE_UPDATED_TIME_INDEX = "noticeType-updatedTime-index"
    }
    
    struct Attribute {
        static let NOTICE_ID = "noticeId"
        static let NOTICE_TYPE = "noticeType"
        static let UPDATED_TIME = "updatedTime"
        static let TITLE = "title"
        static let SUB_TITLE = "subTitle"
        static let CONTENT = "content"
    }
    
    var noticeId: String = ""
    var noticeType: String?
    var updatedTime: String = ""
    var title: String?
    var subTitle: String?
    var content: String?
    
    static func dynamoDBTableName() -> String {
        return Schema.TABLE_NAME
    }
    
    static func hashKeyAttribute() -> String {
        return Attribute.NOTICE_ID
    }
    
    static func ignoreAttributes() -> [String] {
        return []
    }
    
}
