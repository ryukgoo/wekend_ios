//
//  StoreHeaderView.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 8. 16..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class StoreHeaderView: UICollectionReusableView {
    @IBOutlet weak var pointLabel: UILabel!
    
    deinit {
        print("\(className) > \(#function)")
        NotificationCenter.default.removeObserver(self, name: IAPHelper.SubcribeEnableNotification, object: nil)
    }
    
    override func awakeFromNib() {
        print("\(className) > \(#function)")
        NotificationCenter.default.addObserver(self, selector: #selector(StoreHeaderView.handleSubcribe(_:)),
                                               name: IAPHelper.SubcribeEnableNotification, object: nil)
    }
    
    public func handleSubcribe(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.pointLabel.text = "정기 구독중"
        }
    }
}
