//
//  ProductProtocol.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 11..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

protocol ProductProtocol {}

protocol ProductLoadable {
    var product: Dynamic<ProductInfo?> { get }
    func loadProduct()
}

protocol ProductListLoadable {
    func loadProductList()
}
