//
//  ProductOperations.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 16..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct LoadProductOperation {
    let productId: Int
    let dataSource: ProductDataSource
    init(productId: Int, dataSource: ProductDataSource) {
        self.productId = productId
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (Result<ProductInfo, FailureReason>) -> Void) {
        dataSource.getProductInfo(id: productId) { result in
            DispatchQueue.main.async {
                if case let Result.success(object: value) = result {
                    completion(.success(object: value))
                } else {
                    completion(.failure(.notAvailable))
                }
            }
        }
    }
}

struct LoadProductListOperation {
    let userId: String
    let options: FilterOptions
    let productDataSource: ProductDataSource
    init(userId: String, options: FilterOptions, productDataSource: ProductDataSource) {
        self.userId = userId
        self.options = options
        self.productDataSource = productDataSource
    }
    
    func execute(completion: @escaping (Result<Array<ProductInfo>, FailureReason>) -> Void) {
        LikeRepository.shared.getDatas(userId: userId).continueWith(executor: AWSExecutor.mainThread()) { task in
            self.productDataSource.getProductInfos { result in
                DispatchQueue.main.async {
                    if case let Result.success(object: value) = result {
                        completion(.success(object: value))
                    } else {
                        completion(.failure(.notAvailable))
                    }
                }
            }
            return nil
        }
    }
}
