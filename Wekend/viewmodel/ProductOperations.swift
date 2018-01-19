//
//  ProductOperations.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 16..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct LoadProductOperation {
    let productId: Int
    let dataSource: ProductDataSource
    init(productId: Int, dataSource: ProductDataSource) {
        self.productId = productId
        self.dataSource = dataSource
    }
    
    func execute(completion: @escaping (Result<ProductInfo, FailureReason>) -> Void) {
        dataSource.getProductInfo(id: productId) { result in
            DispatchQueue.main.async {
                if case let Result.success(object: value) = result {
                    completion(.success(object: value))
                } else {
                    completion(.failure(.notAvailable))
                }
            }
        }
    }
}

struct LoadProductListOperation {
    let userId: String
    let options: FilterOptions?
    let keyword: String?
    let productDataSource: ProductDataSource
    init(userId: String, options: FilterOptions?, keyword: String?, productDataSource: ProductDataSource) {
        self.userId = userId
        self.options = options
        self.keyword = keyword
        self.productDataSource = productDataSource
    }
    
    func execute(completion: @escaping (Result<Array<ProductInfo>, FailureReason>) -> Void) {
        LikeRepository.shared.getDatas(userId: userId).continueWith(executor: AWSExecutor.mainThread()) { task in
            self.productDataSource.getProductInfos(options: self.options, keyword: self.keyword) { result in
                DispatchQueue.main.async {
                    if case let Result.success(object: value) = result {
                        completion(.success(object: value))
                    } else {
                        completion(.failure(.notAvailable))
                    }
                }
            }
            return nil
        }
    }
}

struct LoadMapOperaion {
    
    let address: String
    init(address: String) {
        self.address = address
    }
    
    func execute(completion: @escaping (Result<(Double, Double), FailureReason>) -> Void) {
        
        print("LoadMapOperaion > execute > address : \(self.address)")
        
        let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"
        var geocodeURLString = baseURLGeocode + "address=" + address + "&region=kr"
        
        geocodeURLString = geocodeURLString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        guard let geocodeURL = URL(string: geocodeURLString) else { return }
        
        URLSession.shared.dataTask(with: geocodeURL) { (data, response, error) in
            if let error = error {
                print("LoadMapOperaion > URLSession error : \(error)")
                DispatchQueue.main.async { completion(.failure(.notAvailable)) }
            } else {
                print("LoadMapOperaion > URLSession data : \(String(describing: data))")
                do {
                    let parsedData = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! [String : Any]
                    
                    let status = parsedData["status"] as! String
                    
                    if status == "OK" {
                        let allResults = parsedData["results"] as! Array<[String : Any]>
                        let lookupAddressResults = allResults[0]
                        let geometry = lookupAddressResults["geometry"] as! [String : Any]
                        let location = geometry["location"] as! [String : Any]
                        let latitude = location["lat"] as! Double
                        let longitude = location["lng"] as! Double
                        
                        print("LoadMapOperaion > geocoderAddress > latitude : \(latitude)")
                        print("LoadMapOperaion > geocoderAddress > longitude : \(longitude)")
                        
                        DispatchQueue.main.async { completion(.success(object: (latitude, longitude))) }
                    }
                } catch {
                    DispatchQueue.main.async { completion(.failure(.notAvailable)) }
                }
            }
        }.resume()
    }
}
