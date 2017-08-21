//
//  StoreProducts.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 5. 31..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

class StoreProducts {
    
    public static let Price1 = "com.entuition.wekend.billing.price.1"
    public static let Price2 = "com.entuition.wekend.billing.price.2"
    public static let Price3 = "com.entuition.wekend.billing.price.3"
    public static let Price4 = "com.entuition.wekend.billing.price.4"
    public static let Price5 = "com.entuition.wekend.billing.price.5"
    
    fileprivate static let productIdentifiers: Set<ProductIdentifier> = [StoreProducts.Price1,
                                                                         StoreProducts.Price2,
                                                                         StoreProducts.Price3,
                                                                         StoreProducts.Price4,
                                                                         StoreProducts.Price5]
    
    public static let store = IAPHelper(productIds: StoreProducts.productIdentifiers)
}

func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
    return productIdentifier.components(separatedBy: ".").last
}
