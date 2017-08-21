//
//  SettingViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 6. 14..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

class SettingViewModel: NSObject {
    
    static let sharedInstance = SettingViewModel()
    
    private let mapper: AWSDynamoDBObjectMapper
    var notices: Array<Notice>?
    var helps: Array<Notice>?
    
    override init() {
        self.mapper = AWSDynamoDBObjectMapper.default()
        
        super.init()
    }
    
    func loadNotices() -> AWSTask<AnyObject> {
        
        guard let datas = self.notices else {
            
            let queryExpression = AWSDynamoDBQueryExpression()
            queryExpression.indexName = Notice.Schema.NOTICE_TYPE_UPDATED_TIME_INDEX
            queryExpression.keyConditionExpression = "\(Notice.Attribute.NOTICE_TYPE) = :noticeType"
            queryExpression.expressionAttributeValues = [":noticeType" : "Notice"]
            queryExpression.scanIndexForward = true
            
            return mapper.query(Notice.self, expression: queryExpression).continueWith(block: {
                (task: AWSTask) -> Any? in
                
                guard let result = task.result else {
                    fatalError("SettingViewModel > loadNotices > Error")
                }
                
                self.notices = []
                
                let paginatedOutput = result as AWSDynamoDBPaginatedOutput
                
                for item in paginatedOutput.items as! [Notice] {
                    self.notices?.append(item)
                }
                
                return self.notices
            })
        }
        
        return AWSTask(result: datas as AnyObject)
    }
    
    func loadHelps() -> AWSTask<AnyObject> {
        
        guard let datas = self.helps else {
            
            let queryExpression = AWSDynamoDBQueryExpression()
            queryExpression.indexName = Notice.Schema.NOTICE_TYPE_UPDATED_TIME_INDEX
            queryExpression.keyConditionExpression = "\(Notice.Attribute.NOTICE_TYPE) = :noticeType"
            queryExpression.expressionAttributeValues = [":noticeType" : "Help"]
            queryExpression.scanIndexForward = true
            
            return mapper.query(Notice.self, expression: queryExpression).continueWith(block: {
                (task: AWSTask) -> Any? in
                
                guard let result = task.result else {
                    fatalError("SettingViewModel > loadNotices > Error")
                }
                
                self.helps = []
                
                let paginatedOutput = result as AWSDynamoDBPaginatedOutput
                
                for item in paginatedOutput.items as! [Notice] {
                    self.helps?.append(item)
                }
                
                return self.helps
            })
        }
        
        return AWSTask(result: datas as AnyObject)
    }
    
}
