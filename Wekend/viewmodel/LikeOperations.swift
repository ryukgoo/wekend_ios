//
//  LikeOperations.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 18..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct LoadLikeOperation {
    let userId: String
    let productId: Int
    
    init(userId: String, productId: Int) {
        self.userId = userId
        self.productId = productId
    }
    
    func execute(completion: @escaping (Result<LikeItem, FailureReason>) -> Void) {
        LikeRepository.shared.getLikeItem(userId: userId, productId: productId).continueWith(executor: AWSExecutor.mainThread()) { task in
            DispatchQueue.main.async {
                guard let result = task.result as? LikeItem else {
                    completion(.failure(.notAvailable))
                    return
                }
                
                completion(.success(object: result))
            }
            return nil
        }
    }
}

struct LikeCountOperation {
    let productId: Int
    let gender: String
    init(productId: Int, gender: String) {
        self.productId = productId
        self.gender = gender
    }
    
    func execute(completion: @escaping (Int) -> Void) {
        LikeRepository.shared.getFriendCount(productId: productId, gender: gender).continueWith(executor: AWSExecutor.mainThread()) { task in
            
            DispatchQueue.main.async {
                guard let count = task.result as? Int else {
                    completion(0)
                    return
                }
                completion(count)
            }
            
            return nil
        }
    }
}
