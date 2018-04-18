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
    
    // MARK: - IBOutlet
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var pointLabel: UILabel!
    
    static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        return formatter
    }()
    
    //    var buyHandler: ((_ product: SKProduct) -> ())?
    
    var product: SKProduct? {
        didSet {
            guard let product = product else { return }
            
            if IAPHelper.canMakePayments() {
                StoreCollectionViewCell.priceFormatter.locale = product.priceLocale
                priceLabel.text = StoreCollectionViewCell.priceFormatter.string(from: product.price)
                
                if let point = StoreProducts.productPoints[product.productIdentifier],
                    let bonus = StoreProducts.productBonuses[product.productIdentifier] {
                    if bonus == 0 {
                        pointLabel.text = "\(point)P"
                    } else {
                        pointLabel.text = "\(point)P + \(bonus)P"
                    }
                } else {
                    pointLabel.text = product.localizedTitle
                }
                
                pointLabel.isHidden = false
            } else {
                // Not Available
                priceLabel.text = "Not Available"
                self.isUserInteractionEnabled = false
                pointLabel.isHidden = true
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

