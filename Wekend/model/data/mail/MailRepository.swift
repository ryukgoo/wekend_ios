//
//  MailRepository.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 12. 18..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

protocol MailDataSource {
    
    func destroy()
    
    func loadMails(completion: @escaping (Result<Array<Mail>, FailureReason>) -> ())
    func getMail(friendId: String, productId: Int, completion: @escaping (Result<Mail, FailureReason>) -> ())
    func updateMail(mail: Mail, completion: @escaping (Bool) -> ())
    func deleteMail(mail: Mail, completion: @escaping (Bool) -> ())
    func notifyChangedMail()
}

struct MailNotification {
    
    struct Receive {
        static let Add = "com.entuition.wekend.mail.receive.Add"
        static let New = "com.entuition.wekend.mail.receive.New"
    }
    
    struct Send {
        static let Add = "com.entuition.wekend.mail.send.Add"
        static let New = "com.entuition.wekend.mail.send.New"
    }
    
    static let Count = "com.entuition.wekend.mail.data.Count"
}

class ReceiveMailRepository: NSObject, MailDataSource {
    
    static let shared = ReceiveMailRepository()
    private let mapper: AWSDynamoDBObjectMapper
    
    var datas: [ReceiveMail] = []
    
    override init() {
        mapper = AWSDynamoDBObjectMapper.default()
        super.init()
    }
    
    func destroy() {
        datas = []
    }
    
    func loadMails(completion: @escaping (Result<Array<Mail>, FailureReason>) -> ()) {
        
        guard let user = UserInfoManager.sharedInstance.userInfo else { return }
        
        let expression = AWSDynamoDBQueryExpression()
        expression.indexName = ReceiveMail.Schema.INDEX_USERID_RESPONSETIME
        expression.keyConditionExpression = "\(ReceiveMail.Attribute.USER_ID) = :userId"
        expression.filterExpression = "\(ReceiveMail.Attribute.STATUS) <> :proposeStatus"
        expression.expressionAttributeValues = [":userId" : user.userid, ":proposeStatus" : ProposeStatus.delete.rawValue]
        expression.scanIndexForward = false
        
        mapper.query(ReceiveMail.self, expression: expression).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            guard let result = task.result else {
                completion(.failure(.notAvailable))
                return nil
            }
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            guard let items = paginatedOutput.items as? [ReceiveMail] else {
                completion(.failure(.notAvailable))
                return nil
            }
            
            self.datas = []
            for item in items { self.datas.append(item) }
            completion(.success(object: self.datas))
            
            return nil
        }
    }
    
    func getMail(friendId: String, productId: Int, completion: @escaping (Result<Mail, FailureReason>) -> ()) {
        
        guard let user = UserInfoManager.sharedInstance.userInfo else { return }
        
        let expression = AWSDynamoDBQueryExpression()
        expression.keyConditionExpression = "\(ReceiveMail.Attribute.USER_ID) = :userId"
        expression.filterExpression = "\(ReceiveMail.Attribute.SENDER_ID) = :senderId and \(ReceiveMail.Attribute.PRODUCT_ID) = :productId"
        expression.expressionAttributeValues = [":userId" : user.userid, ":senderId" : friendId, ":productId" : productId]
        expression.scanIndexForward = false
        
        mapper.query(ReceiveMail.self, expression: expression).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            guard let result = task.result else {
                completion(.failure(.notAvailable))
                return nil
            }
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            if paginatedOutput.items.count > 0 {
                if let mail = paginatedOutput.items[0] as? ReceiveMail {
                    completion(.success(object: mail))
                    return nil
                }
            }
            
            completion(.failure(.notFound))
            return nil
        }
    }
    
    func updateMail(mail: Mail, completion: @escaping (Bool) -> ()) {
        guard let receiveMail = mail as? ReceiveMail else { return }
        mapper.save(receiveMail).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if let error = task.error { print(error) }
            
            completion(task.error == nil)
            return nil
        }
    }
    
    func deleteMail(mail: Mail, completion: @escaping (Bool) -> ()) {
        guard let receiveMail = mail as? ReceiveMail else { return }
        mapper.remove(receiveMail).continueWith(executor: AWSExecutor.mainThread()) { task in
            completion(task.error == nil)
            return nil
        }
    }
    
    func notifyChangedMail() {
        printLog(#function)
        
        let newCount = UserDefaults.NotificationCount.integer(forKey: .receiveMail)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: MailNotification.Receive.New),
                                        object: nil,
                                        userInfo: [MailNotification.Count : newCount])
    }
}

class SendMailRepository: NSObject, MailDataSource {
    
    var datas: [SendMail] = []
    
    static let shared = SendMailRepository()
    private let mapper: AWSDynamoDBObjectMapper
    
    override init() {
        mapper = AWSDynamoDBObjectMapper.default()
        super.init()
    }
    
    func destroy() {
        datas = []
    }
    
    func loadMails(completion: @escaping (Result<Array<Mail>, FailureReason>) -> ()) {
        
        guard let user = UserInfoManager.sharedInstance.userInfo else { return }
        
        let expression = AWSDynamoDBQueryExpression()
        expression.indexName = SendMail.Schema.INDEX_USERID_RESPONSETIME
        expression.keyConditionExpression = "\(SendMail.Attribute.USER_ID) = :userId"
        expression.filterExpression = "\(SendMail.Attribute.STATUS) <> :proposeStatus"
        expression.expressionAttributeValues = [":userId" : user.userid, ":proposeStatus" : ProposeStatus.delete.rawValue]
        expression.scanIndexForward = false
        
        mapper.query(SendMail.self, expression: expression).continueWith(executor: AWSExecutor.mainThread()) { task in
            guard let result = task.result else {
                completion(.failure(.notAvailable))
                return nil
            }
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            guard let items = paginatedOutput.items as? [SendMail] else {
                completion(.failure(.notAvailable))
                return nil
            }
            
            self.datas = []
            for item in items { self.datas.append(item) }
            completion(.success(object: self.datas))
            
            return nil
        }
    }
    
    func getMail(friendId: String, productId: Int, completion: @escaping (Result<Mail, FailureReason>) -> ()) {
        
        guard let user = UserInfoManager.sharedInstance.userInfo else { return }
        
        let expression = AWSDynamoDBQueryExpression()
        expression.keyConditionExpression = "\(SendMail.Attribute.USER_ID) = :userId"
        expression.filterExpression = "\(SendMail.Attribute.RECEIVER_ID) = :receiverId and \(SendMail.Attribute.PRODUCT_ID) = :productId"
        expression.expressionAttributeValues = [":userId" : user.userid, ":receiverId" : friendId, ":productId" : productId]
        expression.scanIndexForward = false
        
        mapper.query(SendMail.self, expression: expression).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            guard let result = task.result else {
                completion(.failure(.notAvailable))
                return nil
            }
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            if paginatedOutput.items.count > 0 {
                if let mail = paginatedOutput.items[0] as? SendMail {
                    completion(.success(object: mail))
                    return nil
                }
            }
            
            completion(.failure(.notFound))
            return nil
        }
    }
    
    func updateMail(mail: Mail, completion: @escaping (Bool) -> ()) {
        guard let sendMail = mail as? SendMail else { return }
        mapper.save(sendMail).continueWith(executor: AWSExecutor.mainThread()) { task in
            completion(task.error == nil)
            return nil
        }
    }
    
    func deleteMail(mail: Mail, completion: @escaping (Bool) -> ()) {
        guard let sendMail = mail as? SendMail else { return }
        mapper.remove(sendMail).continueWith(executor: AWSExecutor.mainThread()) { task in
            completion(task.error == nil)
            return nil
        }
    }
    
    func notifyChangedMail() {
        let newCount = UserDefaults.NotificationCount.integer(forKey: .sendMail)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: MailNotification.Send.New),
                                        object: nil,
                                        userInfo: [MailNotification.Count : newCount])
    }
}
