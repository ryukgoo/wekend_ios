//
//  SendMailManager.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 6. 5..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

class SendMailManager: NSObject {
    
    static let AddNotification = "com.entuition.wekend.Notification.SendMail.Add"
    
    static let NewRemoteNotification = "com.entuition.wekend.Notification.Remote"
    static let NotificationDataCount = "com.entuition.wekend.Notification.Data.Count"
    
    // MARK : singlton instance
    
    static let sharedInstance = SendMailManager()
    
    // MARK : Initialize
    
    override init() {
        self.mapper = AWSDynamoDBObjectMapper.default()
        super.init()
    }
    
    // MARK : Properties
    
    private let mapper : AWSDynamoDBObjectMapper
    
    var datas: Array<SendMail> = [SendMail]()
    
    // MARK : DAO
    
    func destory() {
        datas = []
    }
    
    func comeNewNotification() {
        
        printLog("comeNewNotification")
        
        let newCount = UserDefaults.NotificationCount.integer(forKey: .sendMail)
//        newCount += 1
//        UserDefaults.NotificationCount.set(newCount, forKey: .sendMail)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: SendMailManager.NewRemoteNotification),
                                        object: nil,
                                        userInfo: [SendMailManager.NotificationDataCount : newCount])
        
    }
    
    func getSendMails() -> AWSTask<AnyObject> {
        
        let queryTask = AWSTaskCompletionSource<AnyObject>()
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
            fatalError("SendMailManager > getSendMails > get UserInfo Error")
        }
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = SendMail.Schema.INDEX_USERID_RESPONSETIME
        queryExpression.keyConditionExpression = "\(SendMail.Attribute.USER_ID) = :userId"
        queryExpression.filterExpression = "\(SendMail.Attribute.STATUS) <> :proposeStatus"
        queryExpression.expressionAttributeValues = [":userId" : userInfo.userid, ":proposeStatus" : ProposeStatus.delete.rawValue]
        queryExpression.scanIndexForward = false
        
        mapper.query(SendMail.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let result = task.result else {
                fatalError("SendMailManager > getSendMails > query Error")
            }
            
            self.datas = []
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            
            for item in paginatedOutput.items as! [SendMail] {
                self.datas.append(item)
            }
            
            if task.error != nil {
                self.printLog("getSendMails > Error : \(String(describing: task.error))")
            }
            
            queryTask.set(result: self.datas as AnyObject?)
            
            return nil
        })
        
        return queryTask.task
        
    }
    
    func getSendMail(senderId: String, receiverId: String, productId: Int) -> AWSTask<AnyObject> {
        
        printLog("getSendMail")
        
        let queryTask = AWSTaskCompletionSource<AnyObject>()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.keyConditionExpression = "\(SendMail.Attribute.USER_ID) = :userId"
        queryExpression.filterExpression = "\(SendMail.Attribute.RECEIVER_ID) = :receiverId and \(SendMail.Attribute.PRODUCT_ID) = :productId"
        queryExpression.expressionAttributeValues = [":userId" : senderId, ":receiverId" : receiverId, ":productId" : productId]
        queryExpression.scanIndexForward = false
        
        mapper.query(SendMail.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let result = task.result else {
                fatalError("SendMailManager > getSendMail > query Error")
            }
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            
            if paginatedOutput.items.count == 0 {
                queryTask.set(result: nil)
            } else {
                queryTask.set(result: paginatedOutput.items[0] as AnyObject)
            }
            
            self.printLog("getSendMail > paginatedOutput : \(paginatedOutput.items.count)")
            
            return nil
        })
        
        return queryTask.task
    }
    
    func updateSendMail(mail: SendMail) -> AWSTask<AnyObject> {
        return mapper.save(mail)
    }
    
    func deleteSendMail(mail: SendMail) -> AWSTask<AnyObject> {
        return mapper.remove(mail)
    }
    
}
