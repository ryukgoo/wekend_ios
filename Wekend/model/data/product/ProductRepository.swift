//
//  ProductInfoManager.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 6. 5..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation
import AWSDynamoDB

protocol ProductDataSource {
    
    var cachedData: [ProductInfo] { get set }
    var options: FilterOptions? { get set }
    var searchKey: String? { get set }
    
    var readStates: [ProductReadState] { get set }
    
    func destroy()
    
    func getProductInfo(id: Int, completion: @escaping (Result<ProductInfo, FailureReason>) -> Void)
    func getProductInfos(completion: @escaping (Result<Array<ProductInfo>, FailureReason>) -> Void)
    func getReadTimes(completion: @escaping (Result<Array<ProductReadState>, FailureReason>) -> Void)
}

class ProductRepository : NSObject, ProductDataSource {
    
    var cachedData: [ProductInfo]
    var options: FilterOptions?
    var searchKey: String?
    
    var readStates: [ProductReadState]
    
    func getProductInfo(id: Int, completion: @escaping (Result<ProductInfo, FailureReason>) -> Void) {
        mapper.load(ProductInfo.self, hashKey: id, rangeKey: nil)
            .continueOnSuccessWith(executor: AWSExecutor.mainThread()) { task in
                if let result = task.result as? ProductInfo {
                    completion(.success(object: result))
                } else {
                    completion(.failure(.notAvailable))
                }
                return nil
        }
    }
    
    func getProductInfos(completion: @escaping (Result<Array<ProductInfo>, FailureReason>) -> Void) {
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
            queryExpression.scanIndexForward = false
        }
        
        mapper.query(ProductInfo.self, expression: queryExpression).continueOnSuccessWith(executor: AWSExecutor.mainThread()) { task in
            
            self.cachedData = []
            
            if let result = task.result as AWSDynamoDBPaginatedOutput?,
               let items = result.items as? [ProductInfo] {
                for item in items { self.cachedData.append(item) }
                completion(.success(object: self.cachedData))
            } else {
                completion(.failure(.notAvailable))
            }
            return nil
        }
    }
    
    func getReadTimes(completion: @escaping (Result<Array<ProductReadState>, FailureReason>) -> Void) {
        
        mapper.scan(ProductReadState.self, expression: AWSDynamoDBScanExpression()).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            self.readStates = []
            
            if let result = task.result as AWSDynamoDBPaginatedOutput?,
                let items = result.items as? [ProductReadState] {
                for item in items { self.readStates.append(item) }
                completion(.success(object: self.readStates))
            } else {
                completion(.failure(.notAvailable))
            }
            return nil
        }
        
    }
    
    static let shared = ProductRepository()
    
    override init() {
        self.mapper = AWSDynamoDBObjectMapper.default()
        self.cachedData = []
        self.readStates = []
        self.options = FilterOptions()
        
        
        self.datas = []
        self.likeStates = []
        self.filterOptions = FilterOptions()
        super.init()
    }
    
    private let mapper : AWSDynamoDBObjectMapper
    
    var datas: Array<ProductInfo>?
    var filterOptions: FilterOptions?
    var searchKeyword: String?
    
    var likeStates: Array<ProductReadState>?
    
    func destroy() {
        
        cachedData = []
        readStates = []
        searchKey = nil
        options = FilterOptions()
        
        
        likeStates = []
        datas = []
        filterOptions = FilterOptions()
        searchKeyword = nil
        likeStates = []
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
    
    func queryData(startFromBeginning: Bool) -> AWSTask<AnyObject> {
        
        let queryTask = AWSTaskCompletionSource<AnyObject>()
        
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
            queryExpression.scanIndexForward = false
        }
        
        mapper.query(ProductInfo.self, expression: queryExpression).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            self.datas?.removeAll(keepingCapacity: true)
            
            if task.result != nil {
                let paginatedOutput = task.result! as AWSDynamoDBPaginatedOutput
                for item in paginatedOutput.items as! [ProductInfo] {
                    self.datas?.append(item)
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
