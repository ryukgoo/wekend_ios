//
//  MapViewController.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 5. 11..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController {

    var latitude: Double?
    var longitude: Double?
    var productTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let latitude = self.latitude, let longitude = self.longitude else {
            fatalError("MapViewController > viewDidLoad > latitude or longitude is nil")
        }
        
        guard let productTitle = self.productTitle else {
            fatalError("MapViewController > viewDidLoad > productTitle is nil")
        }
        
        let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        view = mapView
        
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        marker.title = productTitle
        marker.map = mapView
        
        mapView.selectedMarker = marker
        
        title = productTitle
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        printLog("viewWillAppear")
        
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
