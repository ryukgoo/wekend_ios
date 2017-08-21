//
//  StoreCollectionViewCell.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 20..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit
import StoreKit

class StoreCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    
    static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        
        return formatter
    }()
    
    var buyHandler: ((_ product: SKProduct) -> ())?
    
    var product: SKProduct? {
        didSet {
            guard let product = product else { return }
            
            /*if StoreProducts.store.isProductPurchased(product.productIdentifier) {
                // purchase product
            } else*/ if IAPHelper.canMakePayments() {
                StoreCollectionViewCell.priceFormatter.locale = product.priceLocale
                priceLabel.text = StoreCollectionViewCell.priceFormatter.string(from: product.price)
            } else {
                // Not Available
            }
            
        }
        
    }
    
    override func awakeFromNib() {
        bgImage.layer.shadowColor = UIColor.black.cgColor
        bgImage.layer.shadowOffset = CGSize(width: 0, height: 2)
        bgImage.layer.shadowRadius = 2
        bgImage.layer.shadowOpacity = 0.3
    }
}
