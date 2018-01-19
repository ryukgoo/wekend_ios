//
//  ProductViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 17..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation
import FBSDKShareKit

typealias CampaignViewModelProtocol = ProductLoadable & MapLoadable & LikeLoadable & LikeCountable & UserLoadable

struct CampaignViewModel: CampaignViewModelProtocol {
    
    let productId: Int
    let isLikeEnabled: Bool
    let dataSource: ProductDataSource
    
    var onMapLoaded: ((Double, Double) -> Void)?
    var onGetFriendCount: ((Int) -> Void)?
    
    var position: Dynamic<(Double, Double)?>
    
    var user: Dynamic<UserInfo?>
    var product: Dynamic<ProductInfo?>
    var like: Dynamic<LikeItem?>
    
    init(id: Int, isLikeEnabled: Bool, dataSource: ProductDataSource) {
        self.productId = id
        self.isLikeEnabled = isLikeEnabled
        self.dataSource = dataSource
        
        self.user = Dynamic(nil)
        self.product = Dynamic(nil)
        self.like = Dynamic(nil)
        
        self.position = Dynamic(nil)
    }
    
    func load() {
        loadUser()
    }
    
    func loadUser() {
        guard let userId = UserInfoRepository.shared.userId else { return }
        let operation = LoadUserOperation(userId: userId, dataSource: UserInfoRepository.shared)
        operation.execute { result in
            if case let Result.success(object: value) = result {
                self.user.value = value
                self.loadProduct()
            }
        }
    }
    
    func loadProduct() {
        print(#function)
        let operation = LoadProductOperation(productId: productId, dataSource: dataSource)
        operation.execute { result in
            if case let Result.success(object: value) = result {
                self.product.value = value
                if let userId = self.user.value?.userid { self.loadLike(userId: userId, productId: value.ProductId) }
                if let address = value.Address { self.loadMap(address: address) }
            }
        }
    }
    
    func loadMap(address: String) {
        let operation = LoadMapOperaion(address: address)
        operation.execute { result in
            if case let Result.success(object: (latitude, longitude)) = result {
                self.position.value = (latitude, longitude)
                self.onMapLoaded?(latitude, longitude)
            } else {
                self.onMapLoaded?(-1, -1)
            }
        }
    }
    
    func loadLike(userId: String, productId: Int) {
        let operation = LoadLikeOperation(userId: userId, productId: productId)
        operation.execute { result in
            if case let Result.success(object: value) = result {
                self.like.value = value
                if let gender = self.user.value?.gender { self.getFriendCount(productId: productId, gender: gender) }
            } else {
                self.like.value = nil
            }
        }
    }
    
    func getFriendCount(productId: Int, gender: String) {
        let operation = LikeCountOperation(productId: productId, gender: gender)
        operation.execute { count in self.onGetFriendCount?(count) }
    }
}

extension CampaignViewModel: Likable {
    func likeProduct() {
        
    }
}

extension CampaignViewModel: ProductContactable {
    func callTo(phone: String) {
        guard let callURL = URL(string: "tel://\(phone)") else { return }
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(callURL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(callURL)
        }
    }
}

extension CampaignViewModel: SNSSharable {
    
    func shareToKakao(with product: ProductInfo, completion: @escaping (Bool) -> Void) {
        print(#function)
        let imageName = String(product.ProductId) + "/" + Configuration.S3.PRODUCT_IMAGE_NAME(0)
        let imageUrl = Configuration.S3.PRODUCT_IMAGE_URL + imageName
        
        // Feed 타입 템플릿 오브젝트 생성
        let template = KLKFeedTemplate.init { (feedTemplateBuilder) in
            
            // 컨텐츠
            feedTemplateBuilder.content = KLKContentObject.init(builderBlock: { (contentBuilder) in
                contentBuilder.title = product.TitleKor!
                contentBuilder.desc = product.Description
                contentBuilder.imageURL = URL.init(string: imageUrl)!
                contentBuilder.link = KLKLinkObject.init(builderBlock: { (linkBuilder) in
                    linkBuilder.mobileWebURL = URL.init(string: "https://fb.me/673785809486815")
                })
            })
            
            // 소셜
            feedTemplateBuilder.social = KLKSocialObject.init(builderBlock: { (socialBuilder) in
                socialBuilder.likeCount = product.realLikeCount as NSNumber
            })
            
            feedTemplateBuilder.addButton(KLKButtonObject.init(builderBlock: { (buttonBuilder) in
                buttonBuilder.title = "앱으로 보기"
                buttonBuilder.link = KLKLinkObject.init(builderBlock: { (linkBuilder) in
                    linkBuilder.iosExecutionParams = "productId=\(product.ProductId)"
                    linkBuilder.androidExecutionParams = "productId=\(product.ProductId)"
                })
            }))
        }
        
        KLKTalkLinkCenter.shared().sendDefault(with: template, success: { (warningMsg, argumentMsg) in
            print("\(#function) > warning message: \(String(describing: warningMsg))")
            print("\(#function) > message: \(String(describing: argumentMsg))")
            completion(true)
        }, failure: { (error) in
            print("\(#function) > error \(error)")
            completion(false)
        })
    }
    
    func shareToFacebook(with product: ProductInfo) -> FBSDKShareOpenGraphContent {
        let imageName = String(product.ProductId) + "/" + Configuration.S3.PRODUCT_IMAGE_NAME(0)
        let imageUrl = Configuration.S3.PRODUCT_IMAGE_URL + imageName
        
        let properties: [AnyHashable : Any] = [
            "fb:app_id": "553669081498489",
            "og:type": "article",
            "og:title": product.TitleKor ?? "Wekend",
            "og:description": product.Description ?? "",
            "og:image" : imageUrl,
            "og:url" : "https://fb.me/673785809486815?productId=\(product.ProductId)"
        ]
        
        let object: FBSDKShareOpenGraphObject = FBSDKShareOpenGraphObject.init(properties: properties)
        
        let action: FBSDKShareOpenGraphAction = FBSDKShareOpenGraphAction()
        action.actionType = "news.publishes"
        action.setObject(object, forKey: "article")
        
        let content: FBSDKShareOpenGraphContent = FBSDKShareOpenGraphContent()
        content.action = action
        content.previewPropertyName = "article"
        
        return content
    }
}
