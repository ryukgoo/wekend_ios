//
//  StoreCollectionViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 20..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit
import StoreKit

class StoreCollectionViewController: UICollectionViewController {
    
    deinit {
        removeNotificationObservers()
        print("\(className) > \(#function)")
    }
    
    var products: [SKProduct]?
    
    @IBOutlet weak var pointLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let products = StoreProducts.store.subscriptions else {
            tabBarController?.startLoading()
            StoreProducts.store.requestProducts()
            return
        }
        self.products = products
        
        addNotificationObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.tintColor = .black
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        collectionView?.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension StoreCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return products?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(for: indexPath) as StoreCollectionViewCell
        guard let product = products?[indexPath.row] else { return cell }
        
        cell.product = product
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let product = products?[indexPath.row] else { return }
        guard let userId = UserInfoRepository.shared.userId else { return }
        
        StoreProducts.store.buyProduct(product, with: userId)
        self.tabBarController?.startLoading()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width/3, height: UIScreen.main.bounds.width/3 + 35.0)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! StoreHeaderView
            
            guard let userInfo = UserInfoRepository.shared.userInfo else {
                return headerView
            }
            
            headerView.pointLabel.text = "보유포인트 \(userInfo.balloon!)P"
            
            return headerView
        default:
            fatalError("UnexpectedElementkind")
            break
        }
    }
    
}

// MARK: -Notification Observers
extension StoreCollectionViewController {
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(StoreCollectionViewController.handlePurchaseSuccess(_:)),
                                               name: IAPHelper.PurchaseSuccessNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(StoreCollectionViewController.handlePurchaseFailed(_:)),
                                               name: IAPHelper.PurchaseFailedNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(StoreCollectionViewController.handleProductLoaded(_:)),
                                               name: IAPHelper.ProductLoadedNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(StoreCollectionViewController.handleSubcribeEnable(_:)),
                                               name: IAPHelper.SubcribeEnableNotification, object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: IAPHelper.PurchaseSuccessNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: IAPHelper.PurchaseFailedNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: IAPHelper.ProductLoadedNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: IAPHelper.SubcribeEnableNotification, object: nil)
    }
    
    func handleProductLoaded(_ notification: Notification) {
        
        print("\(className) > \(#function)")
        
        DispatchQueue.main.async { [weak self] in
            self?.tabBarController?.endLoading()
            self?.products = StoreProducts.store.subscriptions
            self?.collectionView?.reloadData()
        }
    }
    
    func handlePurchaseSuccess(_ notification: Notification) {
        
        print("\(className) > \(#function) > notification : \(notification)")
        
        self.tabBarController?.endLoading()
        
        guard let productId = notification.object as? String else { return }
        
        guard let point = StoreProducts.productPoints[productId],
            let bonus = StoreProducts.productBonuses[productId]  else { return }
        
        let totalPoint = point + bonus
        
        UserInfoRepository.shared.chargePoint(point: totalPoint) { [weak self] result in
            DispatchQueue.main.async {
                if case Result.success(object: _) = result {
                    self?.alert(message: "상품을 구매하였습니다")
                    self?.collectionView?.reloadData()
                }
            }
        }
        
    }
    
    func handlePurchaseFailed(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.tabBarController?.endLoading()
            self?.alert(message: "상품구매에 실패하였습니다.\n다시 시도해주세요")
        }
    }
    
    func handleSubcribeEnable(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.tabBarController?.endLoading()
            self?.alert(message: "상품을 구매하였습니다")
            self?.collectionView?.reloadData()
        }
    }
}

