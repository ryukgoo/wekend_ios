//
//  CampaignListViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 19..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct CampaignListViewModel: ProductListLoadable {
    
    var options: Dynamic<FilterOptions?>
    var keyword: Dynamic<String?>
    var datas: Dynamic<Array<ProductInfo>?>
    var dataSource: ProductDataSource
    
    init(dataSource: ProductDataSource) {
        self.options = Dynamic(nil)
        self.keyword = Dynamic(nil)
        self.dataSource = dataSource
        self.datas = Dynamic(nil)
    }
    
    func loadProductList(options: FilterOptions?, keyword: String?) {
        guard let userId = UserInfoRepository.shared.userId else { return }
        let operation = LoadProductListOperation(userId: userId, options: options, keyword: keyword, productDataSource: dataSource)
        operation.execute { result in
            DispatchQueue.main.async {
                if case let Result.success(object: datas) = result {
                    self.options.value = options
                    self.keyword.value = keyword
                    self.datas.value = datas
                } else {
                    self.datas.value = []
                }
            }
        }
    }
    
    func getTitleText() -> String {
        var titleText = "전체보기"
        if let options = options.value {
            if options.category.rawValue == Category.category.rawValue {
                if options.region.rawValue != ProductRegion.none.rawValue {
                    titleText = options.region.toString
                }
            } else {
                titleText = options.category.toString
                
                if (options.food != nil) && (options.food?.rawValue != Food.category.rawValue) {
                    titleText = titleText + "+" + (options.food?.toString ?? "")
                } else if (options.concert != nil) && (options.concert?.rawValue != Concert.category.rawValue) {
                    titleText = titleText + "+" + (options.concert?.toString ?? "")
                } else if (options.leisure != nil) && (options.leisure?.rawValue != Leisure.category.rawValue) {
                    titleText = titleText + "+" + (options.leisure?.toString ?? "")
                }
                
                if options.region.rawValue != ProductRegion.none.rawValue {
                    titleText = titleText + "+" + options.region.toString
                }
            }
        } else if let keyword = keyword.value {
            return "\"\(keyword)\"(으)로 검색"
        }
        
        return titleText
    }
}
