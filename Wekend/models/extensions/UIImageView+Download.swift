//
//  ViewExtension.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 4. 27..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

let imageCache = NSCache<AnyObject, UIImage>()

extension UIImageView {
    
    func downloadedFrom(url: URL, defaultImage: UIImage, contentMode mode: UIViewContentMode = .scaleAspectFill, reload: Bool = false) {
        
        contentMode = mode
        
        var urlRequest = URLRequest(url: url)
        if reload { urlRequest.cachePolicy = .reloadIgnoringCacheData }
        
        URLSession.shared.dataTask(with: urlRequest) {
            (data, response, error) in
            guard
                let HttpURLResponse = response as? HTTPURLResponse, HttpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let downloadedImage = UIImage(data: data)
                else {
                    DispatchQueue.main.async {
                        self.image = defaultImage
                    }
                    return
            }
            DispatchQueue.main.async {
                () -> Void in
                
                self.image = downloadedImage
                self.fadeIn()
                
                imageCache.setObject(downloadedImage, forKey: url.absoluteString as AnyObject)
            }
        }.resume()
    }
    
    func downloadedFrom(link: String, defaultImage: UIImage, contentMode mode: UIViewContentMode = .scaleAspectFill, reload: Bool = false) {
        printLog(#function)
        if let cachedImage = imageCache.object(forKey: link as AnyObject) {
            self.contentMode = mode
            self.image = cachedImage
        } else {
            guard let url = URL(string: link) else {
                self.image = defaultImage
                return
            }
            
            self.image = defaultImage
            downloadedFrom(url: url, defaultImage: defaultImage, contentMode: mode, reload: reload)
        }
    }
    
    func downloadedFrom(url: URL, defaultImage: UIImage, index: Int, contentMode mode: UIViewContentMode = .scaleAspectFill) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            guard
                let HttpURLResponse = response as? HTTPURLResponse, HttpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else {
                    DispatchQueue.main.async {
                        self.image = defaultImage
                    }
                    return
            }
            
            DispatchQueue.main.async {
                () -> Void in
                
                if self.tag == index {
                    self.image = image
                    self.fadeIn()
                }
                
                imageCache.setObject(image, forKey: url.absoluteString as AnyObject)
            }
        }.resume()
    }
    
    func downloadedFrom(link: String, defaultImage: UIImage, index: Int, contentMode mode: UIViewContentMode = .scaleAspectFill) {
        if let cachedImage = imageCache.object(forKey: link as AnyObject) {
            self.contentMode = mode
            self.image = cachedImage
        } else {
            guard let url = URL(string: link) else {
                self.image = defaultImage
                return
            }
            
            self.image = defaultImage
            downloadedFrom(url: url, defaultImage: defaultImage, index: index, contentMode: mode)
        }
    }
    
    static func removeObjectFromCache(forKey: AnyObject) {
        print("removeObjectFromCache > forKey : \(forKey)")
        imageCache.removeObject(forKey: forKey)
    }
}

// MARK: UIImageView + Mask

extension UIImageView {
    func toMask(mask: UIImage) {
        
        let maskView = UIImageView()
        maskView.image = mask
        
        self.mask = maskView
        maskView.frame = self.bounds
    }
    
    func toCircle() {
        self.layer.borderWidth = 0.0
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.cornerRadius = self.frame.size.width / 2.0
        self.clipsToBounds = true
    }
    
    func toCircle(size: CGSize) {
        self.layer.borderWidth = 0.0
        self.layer.masksToBounds = false
        self.layer.borderColor = UIColor.clear.cgColor
        self.layer.cornerRadius = size.width / 2
        self.clipsToBounds = true
    }
}
