//
//  ProductInfoManager.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 6. 5..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

class ProductRepository : NSObject {
    
    static let shared = ProductRepository()
    
    override init() {
        self.mapper = AWSDynamoDBObjectMapper.default()
        self.datas = []
        self.likeStates = []
        self.filterOptions = FilterOptions()
        super.init()
    }
    
    private let mapper : AWSDynamoDBObjectMapper
    
    var datas: Array<ProductInfo>?
    var lastEvaluatedKey: [String : AWSDynamoDBAttributeValue]!
    var doneLoading = false
    var filterOptions: FilterOptions?
    var searchKeyword: String?
    
    var likeStates: Array<ProductReadState>?
    
    func destroy() {
        likeStates = []
        datas = []
        filterOptions = FilterOptions()
        lastEvaluatedKey = nil
        doneLoading = false
        searchKeyword = nil
        likeStates = []
    }
    
    func getProductInfo(productId: Int) -> AWSTask<AnyObject> {
        
        return mapper.load(ProductInfo.self, hashKey: productId, rangeKey: nil)
    }
    
    func loadData(startFromBeginning: Bool) -> AWSTask<AnyObject> {
        
        let loadTask = AWSTaskCompletionSource<AnyObject>()
        
        guard let userInfo = UserInfoRepository.shared.userInfo else {
            fatalError("\(className) > \(#function) > userInfo not loaded")
        }
        
        LikeRepository.shared.getDatas(userId: userInfo.userid).continueWith(executor: AWSExecutor.mainThread()) { likeTask in
            
            guard let _ = likeTask.result as! Array<LikeItem>? else {
                fatalError("\(self.className) > \(#function) > Failed Like > getDatas")
            }
            
            self.queryData(startFromBeginning: startFromBeginning).continueWith(executor: AWSExecutor.mainThread()) { task in
                guard let _ = task.result else {
                    print("\(self.className) > \(#function) > loadData > No Data")
                    return nil
                }
                
                loadTask.set(result: self.datas as AnyObject?)
                
                return nil
            }
            
            return nil
        }
        
        return loadTask.task
    }
    
    func scanData(startFromBeginning: Bool) -> AWSTask<AnyObject> {
        
        let scanTask = AWSTaskCompletionSource<AnyObject>()
        
        if startFromBeginning {
            self.lastEvaluatedKey = nil
            self.doneLoading = false
        }
        
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.exclusiveStartKey = self.lastEvaluatedKey
        scanExpression.limit = 20
        self.mapper.scan(ProductInfo.self, expression: scanExpression).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if self.lastEvaluatedKey == nil {
                self.datas?.removeAll(keepingCapacity: true)
            }
            
            if task.result != nil {
                let paginatedOutput = task.result! as AWSDynamoDBPaginatedOutput
                for item in paginatedOutput.items as! [ProductInfo] {
                    self.datas?.append(item)
                }
                
                self.lastEvaluatedKey = paginatedOutput.lastEvaluatedKey
                if paginatedOutput.lastEvaluatedKey == nil {
                    self.doneLoading = true
                }
            }
            
            if task.error != nil {
                print("\(self.className) > \(#function) > scan Error : \(String(describing: task.error))")
            }
            
            scanTask.set(result: self.datas as AnyObject?)
            
            return nil
        }
        
        return scanTask.task
    }
    
    func queryData(startFromBeginning: Bool) -> AWSTask<AnyObject> {
        
        let queryTask = AWSTaskCompletionSource<AnyObject>()
        
        if startFromBeginning {
            self.lastEvaluatedKey = nil
            self.doneLoading = false
        }
        
        let queryExpression = AWSDynamoDBQueryExpression()
        
        if let keyword = self.searchKeyword {
            queryExpression.indexName = ProductInfo.Schema.INDEX_STATUS_UPDATEDTIME
            queryExpression.keyConditionExpression = "\(ProductInfo.Attribute.PRODUCT_STATUS) = :productStatus"
            let filterExpression = "contains(" + ProductInfo.Attribute.TITLE_KOR + ", " + ":keyword" + ")"
                + " or " + "contains(" + ProductInfo.Attribute.ADDRESS + ", " + ":keyword" + ")"
                + " or " + "contains(" + ProductInfo.Attribute.DESCRIPTION + ", " + ":keyword" + ")"
            queryExpression.filterExpression = filterExpression
            var expressionAttributeValues: [String : Any] = [":productStatus" : ProductInfo.RawValue.STATUS_ENABLED]
            expressionAttributeValues[":keyword"] = keyword
            queryExpression.expressionAttributeValues = expressionAttributeValues
            queryExpression.scanIndexForward = false
        } else {
            queryExpression.indexName = getIndexName()
            queryExpression.keyConditionExpression = "\(ProductInfo.Attribute.PRODUCT_STATUS) = :productStatus"
            if let filterExpression = getFilterExpression() { queryExpression.filterExpression = filterExpression }
            queryExpression.expressionAttributeValues = getExpressionAttributeValues()
            queryExpression.exclusiveStartKey = self.lastEvaluatedKey
            //            queryExpression.limit = 50
            queryExpression.scanIndexForward = false
        }
        
        mapper.query(ProductInfo.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if self.lastEvaluatedKey == nil {
                self.datas?.removeAll(keepingCapacity: true)
            }
            
            if task.result != nil {
                let paginatedOutput = task.result! as AWSDynamoDBPaginatedOutput
                for item in paginatedOutput.items as! [ProductInfo] {
                    self.datas?.append(item)
                }
                
                self.lastEvaluatedKey = paginatedOutput.lastEvaluatedKey
                if paginatedOutput.lastEvaluatedKey == nil {
                    self.doneLoading = true
                }
            }
            
            if task.error != nil {
                print("\(self.className) > \(#function) > query Error : \(String(describing: task.error))")
            }
            
            queryTask.set(result: self.datas as AnyObject?)
            
            return nil
        }
        
        return queryTask.task
    }
    
    func getReadTimes() -> AWSTask<AnyObject> {
        
        print("\(className) > \(#function)")
        
        return mapper.scan(ProductReadState.self, expression: AWSDynamoDBScanExpression())
            .continueWith(executor: AWSExecutor.mainThread()) { task in
            
            if task.error != nil {
                print("\(self.className) > \(#function) > Error")
                return nil
            }
            
            guard let result = task.result else {
                print("\(self.className) > \(#function) > No result")
                return nil
            }
            
            self.likeStates = []
            
            let paginatedOutput = result as AWSDynamoDBPaginatedOutput
            
            for item in paginatedOutput.items as! [ProductReadState] {
                
                self.likeStates?.append(item)
            }
            
            return nil
        }
    }
    
    private func getIndexName() -> String {
        
        guard let filterOptions = self.filterOptions else {
            return ProductInfo.Schema.INDEX_STATUS_LIKECOUNT
        }
        
        if filterOptions.sortMode == .like {
            return ProductInfo.Schema.INDEX_STATUS_LIKECOUNT
        } else {
            return ProductInfo.Schema.INDEX_STATUS_UPDATEDTIME
        }
    }
    
    private func getFilterExpression() -> String? {
        
        var filterExpression: String = ""
        
        guard let filterOptions = self.filterOptions else {
            return nil
        }
        
        if filterOptions.category != .none && filterOptions.category != .category {
            filterExpression += "\(ProductInfo.Attribute.MAIN_CATEGORY) = :mainCategory"
        }
        
        if (filterOptions.food != nil && filterOptions.food != .none && filterOptions.food != .category) ||
            (filterOptions.concert != nil && filterOptions.concert != .none && filterOptions.concert != .category) ||
            (filterOptions.leisure != nil && filterOptions.leisure != .none && filterOptions.leisure != .category) {
            filterExpression += " and \(ProductInfo.Attribute.SUB_CATEGORY) = :subCategory"
        }
        
        if filterOptions.region != .none && filterOptions.region != .none {
            filterExpression += " and \(ProductInfo.Attribute.PRODUCT_REGION) = :productRegion"
        }
        
        print("\(className) > \(#function) > keyConditionExpression : \(filterExpression)")
        
        if filterExpression.isEmpty { return nil }
        
        return filterExpression
    }
    
    private func getExpressionAttributeValues() -> [String : Any]? {
        var expressionAttributeValues: [String : Any] = [":productStatus" : ProductInfo.RawValue.STATUS_ENABLED]
        
        guard let filterOptions = self.filterOptions else {
            return expressionAttributeValues
        }
        
        if filterOptions.category != .none && filterOptions.category != .category {
            expressionAttributeValues[":mainCategory"] = filterOptions.category.rawValue
        }
        
        if filterOptions.food != nil && filterOptions.food != .category {
            expressionAttributeValues[":subCategory"] = filterOptions.food?.rawValue
        }
        
        if filterOptions.concert != nil && filterOptions.concert != .category {
            expressionAttributeValues[":subCategory"] = filterOptions.concert?.rawValue
        }
        
        if filterOptions.leisure != nil && filterOptions.leisure != .category {
            expressionAttributeValues[":subCategory"] = filterOptions.leisure?.rawValue
        }
        
        if filterOptions.region != .none && filterOptions.region != .none {
            expressionAttributeValues[":productRegion"] = filterOptions.region.rawValue
        }
        
        print("\(className) > \(#function) > \(expressionAttributeValues)")
        
        return expressionAttributeValues
    }
    
}
