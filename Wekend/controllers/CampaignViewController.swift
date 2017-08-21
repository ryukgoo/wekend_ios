//
//  CampaignViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 12..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit
import GoogleMaps
import Social
import FBSDKShareKit

class CampaignViewController: UIViewController, UIScrollViewDelegate {
    
    let minimumAlpha: CGFloat = 0.1
    
    // MARK: Properties
    
    var productId: Int?
    var productInfo: ProductInfo?
    var isLoading: Bool = false
    
    // MARK: For Map
    
    var latitude: Double?
    var longitude: Double?
    
    // MARK: IBOutlet

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pagerView: PagerView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleEngLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var phoneTextView: UITextView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var containerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var pagerViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var stackViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!
    
    var gradientView: UIView!
    // MARK: UIViewController override functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn_icon_back_w"), style: .plain, target: self, action: #selector(self.backButtonTapped(_:)))
        navigationItem.leftBarButtonItem = backButton
        
        initShareButton()
        initMapView()
        
        // Data
        loadProductInfo()
        addNotificationObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.isStatusBarHidden = true
        
        var colors = [UIColor]()
        colors.append(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5))
        colors.append(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0))
        navigationController?.navigationBar.setGradientBackground(colors: colors)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.tintColor = .white
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isStatusBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    // Data
    private func loadProductInfo() {
        
        startLoading()
        
        isLoading = true
        self.containerView.alpha = 0.0
        
        ProductInfoManager.sharedInstance.getProductInfo(productId: productId!).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let info = task.result as? ProductInfo else {
                fatalError("CampaignViewController > error")
            }
            
            self.productInfo = info
            
            DispatchQueue.main.async {
                self.initViews()
                self.endLoading()
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.containerView.alpha = 1.0
                })
            }
            
            self.isLoading = false
            
            return nil
        })
    }
    
    // View
    // Scroll
    private func initViews() {
        
        pagerView.delegate = self
        pagerView.pageCount = productInfo!.ImageCount as! Int
        
        printLog("initView > productInfo.ImageCount : \(productInfo!.ImageCount!)")
        
        scrollView.delegate = self
        
        guard let productInfo = self.productInfo else {
            fatalError("CampaignViewController > no Data")
        }
        
        titleLabel.text = productInfo.TitleKor
        titleEngLabel.text = productInfo.TitleEng
        subTitleLabel.text = productInfo.SubTitle
        descriptionLabel.text = productInfo.Description?.htmlToString ?? productInfo.Description
        
        if let price = productInfo.Price {
            descriptionLabel.text! += "\n\n" + "\(ProductInfo.Title.PRICE) : " + price
        }
        
        if let parking = productInfo.Parking {
            descriptionLabel.text! += "\n\n" + "\(ProductInfo.Title.PARKING) : " + parking
        }
        
        if let operatingTime = productInfo.OperationTime {
            descriptionLabel.text! += "\n\n" + "\(ProductInfo.Title.OPERATING_TIME) : " + operatingTime
        }
        
        phoneTextView.text = productInfo.Telephone
        phoneTextView.tintColor = UIColor(netHex: 0x202020)
        
        let address = "\(productInfo.Address ?? "") \(productInfo.SubAddress ?? "")"
        locationButton.setTitle(address, for: .normal)
        
        subTitleLabel.sizeToFit()
        descriptionLabel.sizeToFit()
        
        loadMap()
        loadButton()
    }
    
    private func loadButton() {
        
        likeButton.loadingIndicator(true)
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
            fatalError("CampaignViewController > getUserInfo Failed")
        }
        
        guard let productInfo = self.productInfo else {
            fatalError("CampaignViewController > no Data")
        }
        
        LikeDBManager.sharedInstance.getLikeItem(userId: userInfo.userid, productId: productInfo.ProductId).continueWith(executor: AWSExecutor.mainThread(), block: {
            (task: AWSTask) -> Any! in
            
            guard let _ = task.result else {
                
                DispatchQueue.main.async {
                    self.likeButton.setTitle(Constants.Title.Button.LIKE, for: .normal)
                    self.likeButton.addTarget(self, action: #selector(self.likeButtonTapped(_:)), for: .touchUpInside)
                    
                    self.likeButton.loadingIndicator(false)
                    
                    self.refreshLayout()
                }
                
                return nil
            }
            
            LikeDBManager.sharedInstance.getFriendCount(productId: productInfo.ProductId, gender: userInfo.gender!).continueWith(executor: AWSExecutor.mainThread(), block: {
                (getFriendTask) -> Any! in
                
                guard let friendCount = getFriendTask.result else {
                    fatalError("CampaignViewController > getFriendCount > Error")
                }
                
                DispatchQueue.main.async {
                    self.likeButton.setTitle("\(Constants.Title.Button.FRIEND_RECOMMEND) : \(friendCount)", for: .normal)
                    self.likeButton.addTarget(self, action: #selector(self.recommendButtonTapped(_:)), for: .touchUpInside)
                    
                    self.likeButton.loadingIndicator(false)
                    
                    self.refreshLayout()
                }
                return nil
            })
            return nil
        })
        
    }
    
    // Scroll
    private func refreshLayout() {
        
        printLog("refreshLayout")
        
        // 673 => scrolled height
        var scrollableHeight = pagerView.frame.height
        scrollableHeight += 20
        scrollableHeight += titleLabel.frame.height
        scrollableHeight += titleEngLabel.frame.height
        scrollableHeight += 20
        scrollableHeight += subTitleLabel.frame.height
        scrollableHeight += 20
        scrollableHeight += descriptionLabel.frame.height
        scrollableHeight += 31
        scrollableHeight += phoneTextView.frame.height
        scrollableHeight += 23
        scrollableHeight += locationButton.frame.height
        scrollableHeight += 32
        scrollableHeight += mapView.frame.height
        scrollableHeight += 20
        
        containerViewHeight.constant = scrollableHeight
        backgroundHeight.constant = scrollableHeight - self.pagerView.frame.size.height
    }
    
    // Scroll
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setNavigationBarAlpha()
    }
    
    // Scroll
    func setNavigationBarAlpha() {
        let yOffset = self.scrollView.contentOffset.y
        let alpha = 1 - (yOffset / self.pagerView.frame.size.height)
        let halfOffsetY = yOffset * 0.5
        
        pagerView.alpha = alpha
        pagerViewOffsetY.constant = halfOffsetY
        backViewOffsetY.constant = -halfOffsetY
        stackViewOffsetY.constant = -halfOffsetY + 20
    }
    
    // MARK: addTarget functions
    
    // View
    func likeButtonTapped(_ sender: Any) {
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else {
            fatalError("CampaignViewController > get UserInfo Error")
        }
        
        guard let productInfo = self.productInfo else {
            fatalError("CampaignViewController > get ProductInfo Error")
        }
        
        likeButton.loadingIndicator(true)
        
        LikeDBManager.sharedInstance.addLikeAtDetail(userInfo: userInfo, productInfo: productInfo)
        
    }
    
    func recommendButtonTapped(_ sender: Any) {
        
        printLog("recommendButtonTapped")
        
        performSegue(withIdentifier: LikeCollectionViewController.className, sender: self)
    }
    
    // MARK: IBAction
    
    @IBAction func phoneIconTapped(_ sender: Any) {
        printLog("phoneIconTapped")
//        callPhone()
    }
    
    @IBAction func phoneNumberTapped(_ sender: Any) {
        printLog("phoneNumberTapped")
//        callPhone()
    }
    
    @IBAction func locationIconTapped(_ sender: Any) {
        printLog("locationIconTapped")
        showMap()
    }
    
    @IBAction func addressTapped(_ sender: Any) {
        printLog("addressTapped")
        showMap()
    }
    
    func callPhone() {
        
        printLog("callPhone")
        
        guard let productInfo = self.productInfo else {
            fatalError("CampaignViewController > callPhone > productInfo Error")
        }
        
        if let phone = productInfo.Telephone {
            let phoneNumber = "tel://\(phone)"
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(URL(string: phoneNumber)!, options: [:], completionHandler: nil)
            } else {
                // Fallback on earlier versions
                UIApplication.shared.openURL(URL(string: phoneNumber)!)
            }
        }
//        let phoneNumber = "tel://\("01092382541")"
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        printLog("identity : \(String(describing: segue.identifier))")
        
        if segue.identifier == LikeCollectionViewController.className {
            
            guard let destController = segue.destination as? LikeCollectionViewController else {
                fatalError("CampaignViewController > prepare > destination Error")
            }
            
            destController.productId = productInfo?.ProductId
            
        } else if segue.identifier == MapViewController.className {
            
            guard let destController = segue.destination as? MapViewController else {
                fatalError("CampaignViewController > prepare > MapView destination Error")
            }
            
            guard let productInfo = self.productInfo else {
                fatalError("CampaignViewController > prepare > productInfo is nil")
            }
            
            guard let latitude = self.latitude, let longitude = self.longitude else {
                fatalError("CampaignViewController > prepare > latitude or longitude is nil")
            }
            
            destController.latitude = latitude
            destController.longitude = longitude
            destController.productTitle = productInfo.TitleKor
            
        }
    }
}

// MARK: Observerable

extension CampaignViewController: Observerable {
    
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(CampaignViewController.handleLikeAddNotification(_:)),
                                               name: Notification.Name(rawValue: LikeDBManager.AddNotification),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(CampaignViewController.handleLikeDeleteNotification(_:)),
                                               name: Notification.Name(rawValue: LikeDBManager.DeleteNotification),
                                               object: nil)
    }
    
    func handleLikeAddNotification(_ notification: Notification) {
        
        likeButton.loadingIndicator(false)
        
        guard let productId = notification.userInfo![LikeDBManager.NotificationDataProductId] as? Int else {
            return
        }
        
        if let index = ProductInfoManager.sharedInstance.datas?.index(where: { $0.ProductId == productId }) {
            
            guard let friendCount = ProductInfoManager.sharedInstance.datas?[index].realLikeCount else {
                return
            }
            
            DispatchQueue.main.async {
                self.likeButton.setTitle("\(Constants.Title.Button.FRIEND_RECOMMEND) : \(friendCount)", for: .normal)
                self.likeButton.removeTarget(self, action: #selector(self.likeButtonTapped(_:)), for: .touchUpInside)
                self.likeButton.addTarget(self, action: #selector(self.recommendButtonTapped(_:)), for: .touchUpInside)
            }
            
        }
    }
    
    func handleLikeDeleteNotification(_ notification: Notification) {
        
        DispatchQueue.main.async {
            self.likeButton.loadingIndicator(false)
            self.likeButton.setTitle(Constants.Title.Button.LIKE, for: .normal)
            self.likeButton.addTarget(self, action: #selector(self.likeButtonTapped(_:)), for: .touchUpInside)
            self.likeButton.removeTarget(self, action: #selector(self.recommendButtonTapped(_:)), for: .touchUpInside)
        }
    }
    
}

// MARK: PagerView Delegate

extension CampaignViewController: PagerViewDelegate {
    
    func loadPageViewItem(imageView: UIImageView, page: Int) {
        
        guard let productInfo = self.productInfo else {
            imageView.image = #imageLiteral(resourceName: "bg_default_logo_gray")
            return
        }
        
        let imageName = String(productInfo.ProductId) + "/" + Configuration.S3.PRODUCT_IMAGE_NAME(page)
        let imageUrl = Configuration.S3.PRODUCT_IMAGE_URL + imageName
        
        imageView.tag = page
        imageView.downloadedFrom(link: imageUrl, defaultImage: #imageLiteral(resourceName: "bg_default_logo_gray"), index: page)
    }
    
    func onPageTapped(page: Int) {
        printLog("onPageTapped > page : \(page)")
    }
    
}

// MARK: For Map

extension CampaignViewController: GMSMapViewDelegate {
    
    func initMapView() {
        mapView.settings.setAllGesturesEnabled(false)
        mapView.delegate = self
    }
    
    func loadMap() {
        printLog("loadGoogleMap")
        
        guard let productInfo = self.productInfo else {
            printLog("loadGoogleMap > product Info not loaded")
            return
        }
        
        Utilities.geocodeAddress(address: productInfo.Address!, completion: {
            (latitude: Double, longitude: Double) -> Void in
            
            DispatchQueue.main.async {
                
                self.latitude = latitude
                self.longitude = longitude
                
                self.printLog("loadGoogleMap > latitude : \(latitude), longitude : \(longitude)")
                let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0)
                
                self.mapView.camera = camera
                
                let marker = GMSMarker()
                marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                marker.title = productInfo.TitleKor
                marker.map = self.mapView
                
                self.mapView.selectedMarker = marker
            }
        })
    }
    
    // MARK: MapView Delegate
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        showMap()
    }
    
    func showMap() {
        if let _ = self.latitude, let _ = self.longitude {
            performSegue(withIdentifier: MapViewController.className, sender: self)
        } else {
            printLog("can not show map")
        }
    }
}

// MARK: For Share

extension CampaignViewController: FBSDKSharingDelegate {
    
    func initShareButton() {
        let shareButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn_icon_share"), style: .plain, target: self, action: #selector(self.shareButtonTapped(_:)))
        navigationItem.rightBarButtonItem = shareButton
    }
    
    func shareButtonTapped(_ sender: Any) {
        
        let attributedString = NSAttributedString(string: "공유\n\n\n\n\n\n", attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 20),
                                                                                             NSForegroundColorAttributeName : UIColor(netHex: 0x4b4b4b)])
        
        let alertController = UIAlertController(title: "공유\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        alertController.setValue(attributedString, forKey: "attributedTitle")
        
        let scrollView = UIScrollView(frame: CGRect(x: 10, y: 50, width: alertController.view.bounds.size.width - 40, height: 110))
        
        printLog("sharedButtonTapped > self.view.width : \(self.view.frame.width)")
        printLog("sharedButtonTapped > scrollView.width : \(scrollView.frame.width)")
        
        let kakaoImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: scrollView.frame.width / 2, height: 70))
        kakaoImageView.image = #imageLiteral(resourceName: "img_share_kakao")
        kakaoImageView.contentMode = .scaleAspectFit
        scrollView.addSubview(kakaoImageView)
        
        let kakaoLabel = UILabel(frame: CGRect(x: 0, y: 80, width: scrollView.frame.width / 2, height: 30))
        kakaoLabel.text = "카카오톡"
        kakaoLabel.textAlignment = .center
        scrollView.addSubview(kakaoLabel)
        
        let kakaoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.shareKakaoTapped(_:)))
        kakaoImageView.isUserInteractionEnabled = true
        kakaoImageView.addGestureRecognizer(kakaoTapGestureRecognizer)
        
        let fbImageView = UIImageView(frame: CGRect(x: scrollView.frame.width / 2, y: 0, width: scrollView.frame.width / 2, height: 70))
        fbImageView.image = #imageLiteral(resourceName: "img_share_facebook")
        fbImageView.contentMode = .scaleAspectFit
        scrollView.addSubview(fbImageView)
        
        let fbLabel = UILabel(frame: CGRect(x: scrollView.frame.width / 2, y: 80, width: scrollView.frame.width / 2, height: 30))
        fbLabel.text = "페이스북"
        fbLabel.textAlignment = .center
        scrollView.addSubview(fbLabel)
        
        let fbTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.shareFacebookTapped(_:)))
        fbImageView.isUserInteractionEnabled = true
        fbImageView.addGestureRecognizer(fbTapGestureRecognizer)
        
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: 110)
        scrollView.bounces = false
        
        alertController.view.addSubview(scrollView)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Share Kakao
    func shareKakaoTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        printLog("shareKakoTapped")
        
        guard let productInfo = self.productInfo else {
            printLog("shareKakaoTapped > get productInfo Error")
            return
        }
        
        let imageName = String(productInfo.ProductId) + "/" + Configuration.S3.PRODUCT_IMAGE_NAME(0)
        let imageUrl = Configuration.S3.PRODUCT_IMAGE_URL + imageName
        
        // Feed 타입 템플릿 오브젝트 생성
        let template = KLKFeedTemplate.init { (feedTemplateBuilder) in
            
            // 컨텐츠
            feedTemplateBuilder.content = KLKContentObject.init(builderBlock: { (contentBuilder) in
                contentBuilder.title = productInfo.TitleKor!
                contentBuilder.desc = productInfo.Description
                contentBuilder.imageURL = URL.init(string: imageUrl)!
                contentBuilder.link = KLKLinkObject.init(builderBlock: { (linkBuilder) in
                    linkBuilder.mobileWebURL = URL.init(string: "https://fb.me/673785809486815")
                })
            })
            
            // 소셜
            feedTemplateBuilder.social = KLKSocialObject.init(builderBlock: { (socialBuilder) in
                socialBuilder.likeCount = productInfo.realLikeCount as NSNumber
            })
            
            feedTemplateBuilder.addButton(KLKButtonObject.init(builderBlock: { (buttonBuilder) in
                buttonBuilder.title = "앱으로 보기"
                buttonBuilder.link = KLKLinkObject.init(builderBlock: { (linkBuilder) in
                    linkBuilder.iosExecutionParams = "param1=value1&param2=value2"
                    linkBuilder.androidExecutionParams = "param1=value1&param2=value2"
                })
            }))
        }
        
        // 카카오링크 실행
        self.view.startLoading()
        KLKTalkLinkCenter.shared().sendDefault(with: template, success: { (warningMsg, argumentMsg) in
            
            // 성공
            self.view.stopLoading()
            self.printLog("warning message: \(String(describing: warningMsg))")
            self.printLog("argument message: \(String(describing: argumentMsg))")
            
        }, failure: { (error) in
            
            // 실패
            self.view.stopLoading()
//            self.alert(error.localizedDescription)
            self.printLog("error \(error)")
            
        })
    }
    
    // MARK: Share Facebook
    func shareFacebookTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        
        printLog("shareFacebookTapped")
        
        guard let productInfo = self.productInfo else {
            return
        }
        
        let imageName = String(productInfo.ProductId) + "/" + Configuration.S3.PRODUCT_IMAGE_NAME(0)
        let imageUrl = Configuration.S3.PRODUCT_IMAGE_URL + imageName
        
        let properties = [
            "fb:app_id": "553669081498489",
            "og:type": "article",
            "og:title": "Wekend",
            "og:description": "This is a test game to test Fb share functionality",
            "og:image" : imageUrl,
            "og:url" : "https://fb.me/673785809486815"
        ]
        
        let object: FBSDKShareOpenGraphObject = FBSDKShareOpenGraphObject.init(properties: properties)
        
        let action: FBSDKShareOpenGraphAction = FBSDKShareOpenGraphAction()
        action.actionType = "news.publishes"
        action.setObject(object, forKey: "article")
        
        let content: FBSDKShareOpenGraphContent = FBSDKShareOpenGraphContent()
        content.action = action
        content.previewPropertyName = "article"
        
        if presentedViewController != nil {
            dismiss(animated: true, completion: nil)
        }
        
        let dialog = FBSDKShareDialog()
        dialog.fromViewController = self
        dialog.delegate = self
        dialog.shareContent = content
        dialog.mode = .automatic
        if dialog.canShow() {
            printLog("dialog can show")
            dialog.show()
        }
        
//        let content: FBSDKShareOpenGraphObject
        
//        let content: FBSDKShareLinkContent = FBSDKShareLinkContent()
//        content.contentURL = URL(string: "https://fb.me/673369249528471")
//        content.contentTitle = "Wekend"
//        content.quote = "game"
//        content.contentDescription = "Test Facebook sharing"
//        content.imageURL = URL(string: imageUrl)
        
        /*
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook) {
            
            printLog("shareFacebookTapped > SLCompseViewController is Available")
            
            let post = SLComposeViewController(forServiceType: SLServiceTypeFacebook)!
            
            post.setInitialText("Wekend")
            post.add(URL(string: "https://fb.me/673369249528471"))
            
            if let image = pagerView.getPageItem(0)?.image {
                post.add(image)
            }
            
            if presentedViewController != nil {
                dismiss(animated: true, completion: nil)
            }
            
            present(post, animated: true, completion: nil)
            
        } else {
            let alert = UIAlertController(title: "Error", message: "You are not connected Facebook", preferredStyle: .alert)
            let action = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            
            alert.addAction(action)
            
            if presentedViewController != nil {
                dismiss(animated: true, completion: nil)
            }
            
            present(alert, animated: true, completion: nil)
        }
        */
    }
    
    func sharer(_ sharer: FBSDKSharing!, didCompleteWithResults results: [AnyHashable : Any]!) {
        print(results)
    }
    
    func sharer(_ sharer: FBSDKSharing!, didFailWithError error: Error!) {
        print("sharer Error")
        print(error)
    }
    
    func sharerDidCancel(_ sharer: FBSDKSharing!) {
        print("shareDidCancel")
    }
}
