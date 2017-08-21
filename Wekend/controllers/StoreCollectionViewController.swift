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

    var priceArray: [String] = Array(Constants.Title.Price.toStrings())
    
    var products = [SKProduct]()
    
    @IBOutlet weak var pointLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reload()
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reload() {
        
        printLog("reload")
        
        startLoading()
        
        products = []
        
        collectionView?.reloadData()
        
        StoreProducts.store.requestProducts{
            success, products in
            
            self.printLog("reload > success: \(success), products: \(String(describing: products))")
            
            if success {
                self.products = products!
                self.collectionView?.reloadData()
                self.endLoading()
            }
        }
    }
    
    func handlePurchaseNotification(_ notification: Notification) {
        
        printLog("handlePurchaseNotification > notification : \(notification)")
        
        endLoading()
        
        guard let productId = notification.object as? String else { return }
        
        let point = BillingPoint(id: productId)
        
        UserInfoManager.sharedInstance.chargePoint(point: point.rawValue).continueWith(block: {
            (task: AWSTask) -> Any! in
            
            if task.error == nil {
                DispatchQueue.main.async {
                    self.alert(message: "상품을 구매하였습니다")
                }
            }
            
            return nil
        })
        
        
        // Handle purchase Non-Consumable Product
//        guard let productId = notification.object as? String else { return }
//        
//        for (index, product) in products.enumerated() {
//            
//            guard product.productIdentifier == productId else { continue }
//            
//            collectionView?.reloadItems(at: [IndexPath(row: index, section: 0)])
//        }
        
        
    }

    func handlePurchaseFailNotification(_ notification: Notification) {
        endLoading()
        alert(message: "상품구매에 실패하였습니다.\n다시 시도해주세요")
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension StoreCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return products.count
    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(for: indexPath) as StoreCollectionViewCell
        
        let product = products[indexPath.row]
        cell.product = product
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = products[indexPath.row]
        StoreProducts.store.buyProduct(product)
        startLoading()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: UIScreen.main.bounds.width/3, height: UIScreen.main.bounds.width/3 + 30.0)
        
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! StoreHeaderView
            
            guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
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

// MARK: -Observerable

extension StoreCollectionViewController: Observerable {
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(StoreCollectionViewController.handlePurchaseNotification(_:)),
                                               name: Notification.Name(rawValue: IAPHelper.IAPHelperPurchaseNotification),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(StoreCollectionViewController.handlePurchaseFailNotification(_:)),
                                               name: Notification.Name(rawValue: IAPHelper.IAPHelperFailNotification),
                                               object: nil)
    }
}
