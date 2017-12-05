//
//  Utilities.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 11. 28..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import Foundation

class Utilities {
    
    static func getDeviceUUID() -> String {
//        if let identifier = UIDevice.current.identifierForVendor?.uuidString.lowercased() {
//            print("identifier : \(identifier)")
//            return identifier
//        }
        return UUID().uuidString.lowercased()
    }
    
    static func getTimestamp() -> String {
        return Date().iso8601
    }
    
    static func getDateFromTimeStamp(timestamp: String) -> String {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = timestamp.dateFromISO8601 {
            return formatter.string(from: date)
        }
        
        return timestamp
    }
    
    static func getSignature(dateToSign: String, key: String) -> String {
        return dateToSign.hmac(algorithm: .SHA256, key: key)
    }
    
    static func dictionaryToString(map: NSDictionary) -> String {
        var result = ""
        for item in map {
            if (!result.isEmpty) {
                result.append("&")
            }
            
            let key = (item.key as! String).addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            let value = (item.value as! String).addingPercentEncoding(withAllowedCharacters: .alphanumerics)
            
            if (key != nil) { result.append(key!) }
            result.append("=")
            if (value != nil) { result.append(value!) }
            
        }
        
        print("Utilities > dictionaryToString: \(result)")
        
        return result
    }
    
    static func geocodeAddress(address: String!, completion: @escaping (_ latitude: Double, _ longitude: Double) -> Void) {
        
        print("Utitlies > geocoderAddress start > address : \(address)")
        
        let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"
        
        if let lookupAddress = address {
            
            var geocodeURLString = baseURLGeocode + "address=" + lookupAddress + "&region=kr"
            geocodeURLString = geocodeURLString.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
            let geocodeURL = URL(string: geocodeURLString)
            
            print("Utitlies > geocodeURLString : \(geocodeURLString)")
            
            URLSession.shared.dataTask(with: geocodeURL!) {
                (data, response, error) in
                
                if let error = error {
                    print("Utitlies > URLSession error : \(error)")
                    completion(-1, -1)
                } else {
                    
                    print("Utitlies > URLSession data : \(String(describing: data))")
                    
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
                            
                            print("Utitlies > geocoderAddress > address : \(address)")
                            print("Utitlies > geocoderAddress > latitude : \(latitude)")
                            print("Utitlies > geocoderAddress > longitude : \(longitude)")
                            
                            completion(latitude, longitude)
                        }
                        
                    } catch {
                        
                        print("Utitlies > catch > error : \(error)")
                        
                        completion(-1, -1)
                    }
                }
                
            }.resume()
            
        }
        
    }
    
}

enum CryptoAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    var HMACAlgorithm: CCHmacAlgorithm {
        var result: Int = 0
        switch self {
        case .MD5:      result = kCCHmacAlgMD5
        case .SHA1:     result = kCCHmacAlgSHA1
        case .SHA224:   result = kCCHmacAlgSHA224
        case .SHA256:   result = kCCHmacAlgSHA256
        case .SHA384:   result = kCCHmacAlgSHA384
        case .SHA512:   result = kCCHmacAlgSHA512
        }
        return CCHmacAlgorithm(result)
    }
    
    var digestLenght: Int {
        var result: Int32 = 0
        switch self {
        case .MD5:      result = CC_MD5_DIGEST_LENGTH
        case .SHA1:     result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:   result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:   result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:   result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}
