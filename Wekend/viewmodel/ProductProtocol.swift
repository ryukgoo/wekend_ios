//
//  ProductProtocol.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 11..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation
import FBSDKShareKit

protocol ProductProtocol {}

protocol ProductLoadable {
    var product: Dynamic<ProductInfo?> { get }
    func loadProduct()
}

protocol ProductContactable {
    func callTo(phone: String)
}

protocol ProductListLoadable {
    var datas: Dynamic<Array<ProductInfo>?> { get }
    func loadProductList(options: FilterOptions?, keyword: String?)
}

protocol MapLoadable {
    var mapPosition: Dynamic<(Double, Double)?> { get }
    
    var onMapLoaded: ((Double, Double) -> Void)? { get set }
    func loadMap(address: String)
}

protocol SNSSharable {
    func shareToKakao(with product: ProductInfo, completion: @escaping (Bool) -> Void)
    func shareToFacebook(with product: ProductInfo) -> FBSDKShareOpenGraphContent
}
