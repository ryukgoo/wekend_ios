//
//  LikeProtocol.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 17..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

protocol Likable {
    func likeProduct(user: UserInfo, product: ProductInfo)
}

protocol LikeLoadable {
    var like: Dynamic<LikeItem?> { get }
    func loadLike(userId: String, productId: Int)
}
