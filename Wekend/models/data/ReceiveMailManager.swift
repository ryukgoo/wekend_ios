//
//  ReceiveMailManager.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 6. 5..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

class ReceiveMailManager: NSObject {
    
    static let AddNotification = "com.entuition.wekend.ReceiveMail.Add"
    
    static let NewRemoteNotification = "com.entuition.wekend.ReceiveMail.Remote"
    static let NotificationDataCount = "com.entuition.wekend.ReceiveMail.Data.Count"
    
    // MARK : singlton instance
    
    static let sharedInstance = ReceiveMailManager()
    
    // MARK : initialize
    
    override init() {
        self.mapper = AWSDynamoDBObjectMapper.default()
        super.init()
    }
    
    // MARK : Properties
    
    private let mapper: AWSDynamoDBObjectMapper
    
    var datas: Array<ReceiveMail> = [ReceiveMail]()
    
    // MARK : Functions
    
    func destory() {
        datas = []
    }
    
    func comeNewNotification() {
        
        printLog("comeNewNotification")
        
        var newCount = UserDefaults.NotificationCount.integer(forKey: .receiveMail)
        newCount += 1
        UserDefaults.NotificationCount.set(newCount, forKey: .receiveMail)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: ReceiveMailManager.NewRemoteNotification),
                                        object: nil,
                                        userInfo: [ReceiveMailManager.NotificationDataCount : newCount])
        
    }
    
    func getReceiveMails() -> AWSTask<AnyObject> {
        
        let queryTask = AWSTaskCompletionSource<AnyObject>()
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
            fatalError("ReceiveMailManager > getReceiveMails > get UserInfo Error")
        }
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = ReceiveMail.Schema.INDEX_USERID_RESPONSETIME
        queryExpression.keyConditionExpression = "\(ReceiveMail.Attribute.USER_ID) = :userId"
        queryExpression.filterExpression = "\(ReceiveMail.Attribute.STATUS) <> :proposeStatus"
        queryExpression.expressionAttributeValues = [":userId" : userInfo.userid, ":proposeStatus" : ProposeStatus.delete.rawValue]
        queryExpression.scanIndexForward = false
        
        mapper.query(ReceiveMail.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let result = task.result else {
                fatalError("ReceiveMailManager > getReceiveMails > query Error")
            }
            
            self.datas = []
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            
            for item in paginatedOutput.items as! [ReceiveMail] {
                self.datas.append(item)
            }
            
            if task.error != nil {
                self.printLog("getReceiveMails > Error : \(String(describing: task.error))")
            }
            
            queryTask.set(result: self.datas as AnyObject?)
            
            return nil
        })
        
        return queryTask.task
    }
    
    func getReceiveMail(senderId: String, receiverId: String, productId: Int) -> AWSTask<AnyObject> {
        
        let queryTask = AWSTaskCompletionSource<AnyObject>()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.keyConditionExpression = "\(ReceiveMail.Attribute.USER_ID) = :userId"
        queryExpression.filterExpression = "\(ReceiveMail.Attribute.SENDER_ID) = :senderId and \(ReceiveMail.Attribute.PRODUCT_ID) = :productId"
        queryExpression.expressionAttributeValues = [":userId" : receiverId, ":senderId" : senderId, ":productId" : productId]
        queryExpression.scanIndexForward = false
        
        mapper.query(ReceiveMail.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let result = task.result else {
                fatalError("ReceiveMailManager > getReceiveMail > query Error")
            }
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            
            if paginatedOutput.items.count == 0 {
                queryTask.set(result: nil)
            } else {
                queryTask.set(result: paginatedOutput.items[0] as AnyObject)
            }
            
            return nil
        })
        
        return queryTask.task
    }
    
    func updateReceiveMail(mail: ReceiveMail) -> AWSTask<AnyObject> {
        return mapper.save(mail)
        
    }
    
    func deleteReceiveMail(mail: ReceiveMail) -> AWSTask<AnyObject> {
        return mapper.remove(mail)
    }
}
