//
//  CampaignListViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 19..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct CampaignListViewModel: ProductListLoadable {
    
    var datas: Dynamic<Array<ProductInfo>?>
    var dataSource: ProductDataSource
    
    init(dataSource: ProductDataSource) {
        self.dataSource = dataSource
        self.datas = Dynamic(nil)
    }
    
    func loadProductList(options: FilterOptions?, keyword: String?) {
        guard let userId = UserInfoRepository.shared.userId else { return }
        let operation = LoadProductListOperation(userId: userId, options: options, keyword: keyword, productDataSource: dataSource)
        operation.execute { result in
            DispatchQueue.main.async {
                if case let Result.success(object: datas) = result {
                    self.datas.value = datas
                } else {
                    self.datas.value = []
                }
            }
        }
    }
}
