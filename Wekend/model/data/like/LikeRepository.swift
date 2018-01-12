//
//  LikeDBManager.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 6. 5..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

struct LikeNotification {
    static let Add = "com.entuition.wekend.Like.Add"
    static let Delete = "com.entuition.wekend.Like.Delete"
    static let Read = "com.entution.wekend.Like.Read"
    static let New = "com.entuition.wekend.Like.New"
    static let Friend = "com.entuition.wekend.Like.Friend"
    static let Refresh = "com.entuition.wekend.Like.Refresh"
    
    struct Data {
        static let UserId = "com.entuition.wekend.Like.Data.UserId"
        static let ProductId = "com.entuition.wekend.Like.Data.ProductId"
        static let Count = "com.entuition.wekend.Like.Data.Count"
    }
}

class LikeRepository : NSObject {
    
    static let shared = LikeRepository()
    
    override init() {
        self.mapper = AWSDynamoDBObjectMapper.default()
        self.datas = []
        
        super.init()
    }
    
    private var mapper: AWSDynamoDBObjectMapper
    
    var datas: Array<LikeItem>?
    
    func destroy() {
        datas = []
    }
    
    func comeNewNotification(id: Int) {
        
        print("\(className) > \(#function) > id : \(id)")
        
        if let removeIndex = datas?.index(where: { $0.ProductId == id }) {
            if let element = datas?.remove(at: removeIndex) {
                element.ReadTime = nil
                element.isRead = false
                datas?.insert(element, at: 0)
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: LikeNotification.New),
                                        object: nil,
                                        userInfo: [LikeNotification.Data.ProductId : id])
        
    }
    
    func getLikeItem(userId: String, productId: Int) -> AWSTask<AnyObject> {
        
        print("\(className) > \(#function) > userId : \(userId), productId : \(productId)")
        
        let getItemTask = AWSTaskCompletionSource<AnyObject>()
        
        mapper.load(LikeItem.self, hashKey: userId, rangeKey: productId)
            .continueWith(executor: AWSExecutor.mainThread()) { task in
            
            guard let result = task.result else {
                getItemTask.set(result: nil)
                return nil
            }
            
            getItemTask.set(result: result)
            
            return nil
        }
        
        return getItemTask.task
    }
    
    func addLike(userInfo: UserInfo, productInfo: ProductInfo) {
        
        print("\(className) > \(#function) > userInfo : \(String(describing: userInfo.username))")
        
        guard let likeItem = LikeItem() else {
            fatalError("LikeItemManager > LikeItem initialize Error")
        }
        
        likeItem.UserId = userInfo.userid
        likeItem.Nickname = userInfo.nickname!
        likeItem.ProductId = productInfo.ProductId
        likeItem.Gender = userInfo.gender!
        likeItem.ProductTitle = productInfo.TitleKor
        likeItem.UpdatedTime = Date().iso8601
        likeItem.LikeId = UUID().uuidString.lowercased()
        likeItem.isRead = false
        
        if productInfo.SubTitle == nil || productInfo.SubTitle!.isEmpty {
            likeItem.ProductDesc = productInfo.Description
        } else {
            likeItem.ProductDesc = productInfo.SubTitle
        }
        
        mapper.save(likeItem).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if task.error != nil { return nil }
            
            LikeRepository.shared.getLikeCount(productId: likeItem.ProductId)
                .continueWith(executor: AWSExecutor.mainThread()) { getCountTask in
                
                guard let likeCount = getCountTask.result as? Int else {
                    print("\(self.className) > \(#function) > getCount from Server Error")
                    return nil
                }
                
                if let index = ProductRepository.shared.datas?.index(where: { $0.ProductId == productInfo.ProductId }) {
                    guard let newProductInfo = ProductRepository.shared.datas?[index] else {
                        print("\(self.className) > \(#function) > get ProductInfo from ProductInfoManager Error")
                        return nil
                    }
                    
                    newProductInfo.isLike = false
                    newProductInfo.realLikeCount = likeCount
                    
                    self.datas?.insert(likeItem, at: 0)
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: LikeNotification.Add),
                                                    object: nil,
                                                    userInfo: [LikeNotification.Data.ProductId : likeItem.ProductId])
                }
                
                return nil
            }
            
            return nil
        }
    }
    
    /*
    func addLikeAtDetail(userInfo: UserInfo, productInfo: ProductInfo) {
        
        guard let likeItem = LikeItem() else {
            fatalError("LikeItemManager > LikeItem initialize Error")
        }
        
        likeItem.UserId = userInfo.userid
        likeItem.Nickname = userInfo.nickname!
        likeItem.ProductId = productInfo.ProductId
        likeItem.Gender = userInfo.gender!
        likeItem.ProductTitle = productInfo.TitleKor
        likeItem.UpdatedTime = Date().iso8601
        likeItem.LikeId = UUID().uuidString.lowercased()
        likeItem.isRead = false
        
        if productInfo.SubTitle == nil || productInfo.SubTitle!.isEmpty {
            likeItem.ProductDesc = productInfo.Description
        } else {
            likeItem.ProductDesc = productInfo.SubTitle
        }
        
        mapper.save(likeItem).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            if task.error != nil { return nil }
            
            LikeDBManager.sharedInstance.getFriendCount(productId: likeItem.ProductId, gender: likeItem.Gender).continueWith(block: {
                (getCountTask: AWSTask) -> Any! in
                
                guard let likeCount = getCountTask.result as? Int else {
                    self.printLog("addLike > getCount from Server Error")
                    return nil
                }
                
                if let index = ProductInfoManager.sharedInstance.datas?.index(where: { $0.ProductId == productInfo.ProductId }) {
                    guard let newProductInfo = ProductInfoManager.sharedInstance.datas?[index] else {
                        self.printLog("addLike > get ProductInfo from ProductInfoManager Error")
                        return nil
                    }
                    
                    newProductInfo.isLike = false
                    newProductInfo.realLikeCount = likeCount
                    
                    self.datas?.insert(likeItem, at: 0)
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: LikeDBManager.AddNotification),
                                                    object: nil,
                                                    userInfo: [LikeDBManager.NotificationDataProductId : likeItem.ProductId])
                }
                
                return nil
            })
            
            return nil
        })
    }
 */
    
    func deleteLike(item : LikeItem) -> AWSTask<AnyObject> {
        
        return mapper.remove(item).continueWith(block: {
            (task: AWSTask) -> Any! in
            
            if task.error != nil { return nil }
            
            LikeRepository.shared.getLikeCount(productId: item.ProductId).continueWith(block: {
                (getCountTask: AWSTask) -> Any! in
                
                if task.error != nil {
                    print("\(self.className) > \(#function) > AWSTask > Error")
                    // TODO: Error notification
                }
                
                guard let likeCount = getCountTask.result as? Int else {
                    print("\(self.className) > \(#function) > getCount from Server Error")
                    return nil
                }
                
                if let index = ProductRepository.shared.datas?.index(where: { $0.ProductId == item.ProductId }) {
                    guard let newProductInfo = ProductRepository.shared.datas?[index] else {
                        print("\(self.className) > \(#function) > get productInfo from ProductInfoManager Error")
                        return nil
                    }
                    
                    newProductInfo.isLike = false
                    newProductInfo.realLikeCount = likeCount
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: LikeNotification.Delete),
                                                    object: nil,
                                                    userInfo: [LikeNotification.Data.ProductId : item.ProductId])
                    
                    self.datas?.remove(object: item)
                    
                }
                
                return nil
            })
            
            return nil
        })
    }
    
    func getDatas(userId : String) -> AWSTask<AnyObject> {
        
        print("\(className) > \(#function) > userId : \(userId)")
        
        let getDataTask = AWSTaskCompletionSource<AnyObject>()
        
//        if (datas?.count)! > 0 {
//            getDataTask.set(result: self.datas as AnyObject?)
//            return getDataTask.task
//        }
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = LikeItem.Schema.INDEX_USERID_UPDATEDTIME
        queryExpression.keyConditionExpression = "\(LikeItem.Attribute.USER_ID) = :userId"
        queryExpression.expressionAttributeValues = [":userId" : userId]
        queryExpression.scanIndexForward = false
        
        mapper.query(LikeItem.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if task.error != nil {
                print("\(self.className) > \(#function) > Error : \(String(describing: task.error))")
                return nil
            }
            
            guard let result = task.result else {
                fatalError("\(self.className) > \(#function) > Error !!!!")
            }
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            
            print("\(self.className) > \(#function) > complete And getReadTimes start")
            
            ProductRepository.shared.getReadTimes()
                .continueWith(executor: AWSExecutor.mainThread()) { readTask in
                
                print("\(self.className) > \(#function) > getReadTimes in continue")
                
                self.datas = []
                
                if readTask.error != nil {
                    for item in paginatedOutput.items as! [LikeItem] {
                        self.datas?.append(item)
                    }
                    
                    getDataTask.set(result: self.datas as AnyObject?)
                }
                
                guard let productReadTimes = ProductRepository.shared.likeStates else {
                    print("\(self.className) > \(#function) > likeStates is nil")
                    return nil
                }
                
                for item in paginatedOutput.items as! [LikeItem] {
                    for readItem in productReadTimes {
                        if item.ProductId == readItem.ProductId {
                            
                            item.isRead = self.compareLikeTimeAndReadTime(like: item, read: readItem)
                            print("\(self.className) > \(#function) > compareLikeTimeAndReadTime > ProductId : \(item.ProductId), isRead : \(item.isRead)")
                            
                            if item.Gender == UserInfo.RawValue.GENDER_MALE {
                                item.productLikedTime = readItem.FemaleLikeTime ?? ""
                            } else {
                                item.productLikedTime = readItem.MaleLikeTime ?? ""
                            }
                            
                            if let updatedTime = item.UpdatedTime {
                                if (updatedTime > item.productLikedTime) {
                                    item.productLikedTime = updatedTime
                                }
                            }
                            
                            break
                        }
                    }
                    
                    self.datas?.append(item)
                    
                }
                
                self.datas?.sort(by: { $0.productLikedTime > $1.productLikedTime })
                
                getDataTask.set(result: self.datas as AnyObject?)
                
                return nil
            }
            
            return nil
        }
        
        return getDataTask.task
    }
    
    private func compareLikeTimeAndReadTime(like: LikeItem, read: ProductReadState) -> Bool {
        
        print("\(className) > \(#function) > productId : \(read.ProductId)")
        print("\(className) > \(#function) > maleTime : \(String(describing: read.MaleLikeTime))")
        print("\(className) > \(#function) > femaleTime : \(String(describing: read.FemaleLikeTime))")
        print("\(className) > \(#function) > likeReadTime : \(String(describing: like.ReadTime))")
        
        if let likeReadTime = like.ReadTime?.dateFromISO8601 {
            if like.Gender == UserInfo.RawValue.GENDER_MALE {
                if let productLikeTime = read.FemaleLikeTime?.dateFromISO8601 {
                    return likeReadTime > productLikeTime
                } else {
                    return true
                }
            } else {
                if let productLikeTime = read.MaleLikeTime?.dateFromISO8601 {
                    return likeReadTime > productLikeTime
                } else {
                    return true
                }
            }
        } else {
            if like.Gender == UserInfo.RawValue.GENDER_MALE {
                if let _ = read.FemaleLikeTime?.dateFromISO8601 {
                    return false
                } else {
                    return true
                }
            } else {
                if let _ = read.MaleLikeTime?.dateFromISO8601 {
                    return false
                } else {
                    return true
                }
            }
        }
    }
    
    func getLikeCount(productId : Int) -> AWSTask<AnyObject> {
        
        print("\(className) > \(#function) > productId : \(productId)")
        
        let getLikeCountTask = AWSTaskCompletionSource<AnyObject>()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = LikeItem.Schema.INDEX_PRODUCTID_UPDATEDTIME
        queryExpression.keyConditionExpression = "\(LikeItem.Attribute.PRODUCT_ID) = :productId"
        queryExpression.expressionAttributeValues = [":productId" : productId]
        
        mapper.query(LikeItem.self, expression: queryExpression)
            .continueWith(executor: AWSExecutor.mainThread()) { task in
            
            guard let result = task.result else {
                fatalError("\(self.className) > \(#function) > Error !!!!")
            }
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            
            getLikeCountTask.set(result: paginatedOutput.items.count as AnyObject)
            
            return nil
        }
        
        return getLikeCountTask.task
    }
    
    func getFriends(productId: Int, userId: String, gender: String) -> AWSTask<AnyObject> {
        
        print("\(className) > \(#function) > productId : \(productId), userId : \(userId), gender : \(gender)")
        
        let getFriendsTask = AWSTaskCompletionSource<AnyObject>()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = LikeItem.Schema.INDEX_PRODUCTID_UPDATEDTIME
        queryExpression.keyConditionExpression = "\(LikeItem.Attribute.PRODUCT_ID) = :productId"
        queryExpression.filterExpression = "\(LikeItem.Attribute.GENDER) <> :gender"
        queryExpression.expressionAttributeValues = [":productId" : productId, ":gender" : gender]
        queryExpression.scanIndexForward = false
        
        mapper.query(LikeItem.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            guard let result = task.result else {
                fatalError("\(self.className) > \(#function) > Error")
            }
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            
            var arrResult: Array<LikeItem> = []
            for item in paginatedOutput.items as! [LikeItem] {
                arrResult.append(item)
            }
            
            let readStateExpression = AWSDynamoDBQueryExpression()
            readStateExpression.indexName = LikeReadState.Schema.INDEX_PRODUCTID_USERID
            readStateExpression.keyConditionExpression = "\(LikeReadState.Attribute.PRODUCT_ID) = :productId and \(LikeReadState.Attribute.USER_ID) = :userId"
            readStateExpression.expressionAttributeValues = [":productId" : productId, ":userId" : userId]
            
            self.mapper.query(LikeReadState.self, expression: readStateExpression)
                .continueWith(executor: AWSExecutor.mainThread()) { readStateTask in
                
                guard let readStateResult = readStateTask.result else {
                    print("\(self.className) > \(#function) > get readStateResult Error")
                    getFriendsTask.set(result: arrResult as AnyObject)
                    return nil
                }
                
                let readStateOutput = readStateResult as AWSDynamoDBPaginatedOutput
                
                for item in arrResult {
                    
                    print("\(self.className) > \(#function) > item.userId : \(item.UserId)")
                    
                    for readState in readStateOutput.items as! [LikeReadState] {
                        
                        print("\(self.className) > \(#function) > readState.LikeUserId : \(readState.LikeUserId)")
                        
                        if item.UserId == readState.LikeUserId {
                            item.isRead = true
                            continue
                        }
                    }
                }
                
                getFriendsTask.set(result: arrResult as AnyObject)
                
                return nil
            }
            
            return nil
        }
        
        return getFriendsTask.task
    }
    
    func getFriendCount(productId : Int, gender : String) -> AWSTask<AnyObject> {
        
        let getFriendTask = AWSTaskCompletionSource<AnyObject>()
        
        let queryExpression = AWSDynamoDBQueryExpression()
        queryExpression.indexName = LikeItem.Schema.INDEX_PRODUCTID_UPDATEDTIME
        queryExpression.keyConditionExpression = "\(LikeItem.Attribute.PRODUCT_ID) = :productId"
        queryExpression.filterExpression = "\(LikeItem.Attribute.GENDER) <> :gender"
        queryExpression.expressionAttributeValues = [":productId" : productId, ":gender" : gender]
        
        mapper.query(LikeItem.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let result = task.result else {
                fatalError("LikeDBManager > getFriendCount > Failed")
            }
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            
            getFriendTask.set(result: paginatedOutput.items.count as AnyObject)
            
            return nil
        })
        
        return getFriendTask.task
    }
    
    func hasLike(productId : Int) -> Bool {
        
        guard let datas = self.datas else { return false }
        
        for item in datas {
            
            if item.ProductId == productId {
                return true
            }
        }
        
        return false
    }
    
    func updateReadTime(likeItem: LikeItem) {
        likeItem.ReadTime = Utilities.getTimestamp()
        mapper.save(likeItem).continueWith(block: {
            (task: AWSTask) -> Any! in
            
            if task.error != nil { return nil }
            
            likeItem.isRead = true
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: LikeNotification.Read),
                                            object: nil,
                                            userInfo: [LikeNotification.Data.ProductId : likeItem.ProductId])
            
            return nil
        })
    }
    
    func updateReadState(id: String, userId: String, productId: Int, likeUserId: String) {
        
        let readState = LikeReadState()
        
        readState?.LikeId = id
        readState?.UserId = userId
        readState?.ProductId = productId
        readState?.LikeUserId = likeUserId
        readState?.ReadTime = Utilities.getTimestamp()
        
        mapper.save(readState!).continueWith(block: {
            (task: AWSTask) -> Any! in
            
            if task.error == nil {
                NotificationCenter.default.post(name: Notification.Name(rawValue: LikeNotification.Friend),
                                                object: nil,
                                                userInfo: [LikeNotification.Data.UserId : likeUserId])
            }
            
            return nil
        })
    }
    
    private func clearDatas() {
        self.datas = []
    }
}
