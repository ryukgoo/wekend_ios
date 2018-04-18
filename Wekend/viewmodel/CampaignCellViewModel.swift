//
//  CampaignCellViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 16..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

typealias ProductCompletionHandler = (ProductInfo) -> Void

protocol CampaignCellBindable {
    var productInfo: ProductInfo? { get }
    var isSelected: Bool { get }
    var listener: ProductCompletionHandler? { get }
}

struct CampaignCellViewModel: CampaignCellBindable {
    
    var productInfo: ProductInfo?
    var isSelected: Bool
    var listener: ProductCompletionHandler?
    
    init(info: ProductInfo, isSelected: Bool) {
        self.productInfo = info
        self.isSelected = isSelected
    }
}
