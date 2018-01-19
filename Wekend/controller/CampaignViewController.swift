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
import AWSCore

class CampaignViewController: UIViewController {
    
    // MARK: IBOutlet
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pagerView: PagerView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleEngLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var phoneTextButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
    
    @IBOutlet weak var pagerViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var stackViewOffsetY: NSLayoutConstraint!
    
    var viewModel: CampaignViewModel?
    
    deinit {
        removeNotificationObservers()
        print("\(className) > \(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initMapView()
        
        // Data
        bindViewModel()
        
        pagerView.delegate = self
        scrollView.delegate = self
        
        loadProduct()
        addNotificationObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func loadProduct() {
        print("\(className) > \(#function)")
        containerView.alpha = 0.0
        likeButton.loadingIndicator(true)
        viewModel?.load()
    }
    
    // MARK: IBAction
    @IBAction func onBackButtonTapped(_ sender: Any) {
        if let views = navigationController?.viewControllers {
            if views.count > 1 {
                navigationController?.popViewController(animated: true)
                return
            }
        }
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onShareButtonTapped(_ sender: Any) { shareButtonTapped(sender) }
    
    @IBAction func phoneIconTapped(_ sender: Any) { callPhone() }
    
    @IBAction func phoneNumberTapped(_ sender: Any) { callPhone() }
    
    @IBAction func locationIconTapped(_ sender: Any) { showMap() }
    
    @IBAction func addressTapped(_ sender: Any) { showMap() }
    
    func callPhone() {
        guard let phone = viewModel?.product.value?.Telephone else { return }
        viewModel?.callTo(phone: phone)
    }
    
    func likeButtonTapped(_ sender: Any) {
        guard let userInfo = viewModel?.user.value, let product = viewModel?.product.value else { return }
        likeButton.loadingIndicator(true)
        LikeRepository.shared.addLike(userInfo: userInfo, productInfo: product)
    }
    
    func recommendButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: LikeCollectionViewController.className, sender: self)
    }
    
    // MARK: - Navigation > prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        print("\(className) > \(#function) > identity : \(String(describing: segue.identifier))")
        
        if segue.identifier == LikeCollectionViewController.className {
            
            guard let destController = segue.destination as? LikeCollectionViewController else {
                fatalError("\(className) > \(#function) > destination Error")
            }
            
            destController.productId = viewModel?.product.value?.ProductId
            
        } else if segue.identifier == MapViewController.className {
            
            guard let destController = segue.destination as? MapViewController else {
                fatalError("\(className) > \(#function) > MapView destination Error")
            }
            
            guard let productInfo = viewModel?.product.value else {
                fatalError("\(className) > \(#function) > productInfo is nil")
            }
            
            guard let latitude = self.viewModel?.position.value?.0, let longitude = self.viewModel?.position.value?.1 else {
                fatalError("\(className) > \(#function) > latitude or longitude is nil")
            }
            
            destController.latitude = latitude
            destController.longitude = longitude
            destController.productTitle = productInfo.TitleKor
            
        }
    }
}

extension CampaignViewController {
    fileprivate func bindViewModel() {
        guard let viewModel = viewModel else { return }
        likeButton.isHidden = !viewModel.isLikeEnabled
        
        viewModel.product.bind { [weak self] product in
            guard let product = product else { return }
            self?.titleLabel.text = product.TitleKor
            self?.titleEngLabel.text = product.TitleEng
            self?.subTitleLabel.text = product.SubTitle
            self?.descriptionLabel.text = product.toDescriptionForDetail
            
            self?.phoneTextButton.setTitle(product.Telephone, for: .normal)
            
            let address = "\(product.Address ?? "") \(product.SubAddress ?? "")"
            self?.locationButton.setTitle(address, for: .normal)
            
            self?.pagerView.pageCount = product.ImageCount as? Int ?? 1
            self?.containerView.fadeIn()
        }
        
        viewModel.like.bind { [weak self] like in
            
            if like != nil {
                self?.likeButton.setTitle("\(Constants.Title.Button.FRIEND_RECOMMEND)", for: .normal)
                self?.likeButton.addTarget(self, action: #selector(self?.recommendButtonTapped(_:)), for: .touchUpInside)
            } else {
                self?.likeButton.setTitle(Constants.Title.Button.LIKE, for: .normal)
                self?.likeButton.addTarget(self, action: #selector(self?.likeButtonTapped(_:)), for: .touchUpInside)
            }
            self?.likeButton.loadingIndicator(false)
        }
        
        self.viewModel?.onMapLoaded = { [weak self] (latitude: Double, longitude: Double) in
            
            print("\(String(describing: self?.className)) > \(#function)")
            
            let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 16.0)
            self?.mapView.camera = camera
            
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            marker.title = self?.viewModel?.product.value?.TitleKor ?? ""
            marker.map = self?.mapView
            self?.mapView.selectedMarker = marker
        }
        
        self.viewModel?.onGetFriendCount = { [weak self] count in
            self?.likeButton.setTitle("\(Constants.Title.Button.FRIEND_RECOMMEND) : \(count)", for: .normal)
        }
    }
}

// MARK: -UIScrollViewDelegate
extension CampaignViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = self.scrollView.contentOffset.y
        let alpha = 1 - (yOffset / self.pagerView.frame.size.height)
        let halfOffsetY = yOffset * 0.5
        
        pagerView.alpha = alpha
        pagerViewOffsetY.constant = halfOffsetY
        backViewOffsetY.constant = -halfOffsetY
        stackViewOffsetY.constant = -halfOffsetY + 20
    }
}

// MARK: -PagerViewDelegate
extension CampaignViewController: PagerViewDelegate {
    
    func loadPageViewItem(imageView: UIImageView, page: Int) {
        
        guard let productInfo = viewModel?.product.value else {
            imageView.image = #imageLiteral(resourceName: "bg_default_logo_gray")
            return
        }

        let imageName = String(productInfo.ProductId) + "/" + Configuration.S3.PRODUCT_IMAGE_NAME(page)
        let imageUrl = Configuration.S3.PRODUCT_IMAGE_URL + imageName

        imageView.tag = page
        
        imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "bg_default_logo_gray"), options: .refreshCached, completed: {
            (image, error, cacheType, imageURL) in
        })
    }
    
    func onPageTapped(page: Int) { }
}

// MARK: -GMSMapViewDelegate
extension CampaignViewController: GMSMapViewDelegate {
    
    func initMapView() {
        mapView.settings.setAllGesturesEnabled(false)
        mapView.delegate = self
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        showMap()
    }
    
    func showMap() {
        if let _ = viewModel?.position.value {
            performSegue(withIdentifier: MapViewController.className, sender: self)
        } else {
            print("\(className) > \(#function) > can not show map")
        }
    }
}

// MARK: -Notification Observers
extension CampaignViewController {
    
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(CampaignViewController.handleLikeAddNotification(_:)),
                                               name: Notification.Name(rawValue: LikeNotification.Add),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(CampaignViewController.handleLikeDeleteNotification(_:)),
                                               name: Notification.Name(rawValue: LikeNotification.Delete),
                                               object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name(rawValue: LikeNotification.Add),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: Notification.Name(rawValue: LikeNotification.Delete),
                                                  object: nil)
    }
    
    func handleLikeAddNotification(_ notification: Notification) {
        DispatchQueue.main.async {
            self.likeButton.loadingIndicator(false)
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

// MARK: -Share -FBSDKSharingDelegate
extension CampaignViewController: FBSDKSharingDelegate {
    
    func shareButtonTapped(_ sender: Any) {
        
        let attributedString = NSAttributedString(string: "공유\n\n\n\n\n\n", attributes: [NSFontAttributeName : UIFont.systemFont(ofSize: 20),
                                                                                             NSForegroundColorAttributeName : UIColor(netHex: 0x4b4b4b)])
        
        let alertController = UIAlertController(title: "공유\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        alertController.setValue(attributedString, forKey: "attributedTitle")

        let alertScrollView = UIScrollView(frame: CGRect(x: 10, y: 50, width: alertController.view.bounds.size.width - 40, height: 110))
        
        let kakaoImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: alertScrollView.frame.width / 2, height: 70))
        kakaoImageView.image = #imageLiteral(resourceName: "img_share_kakao")
        kakaoImageView.contentMode = .scaleAspectFit
        alertScrollView.addSubview(kakaoImageView)
        
        let kakaoLabel = UILabel(frame: CGRect(x: 0, y: 80, width: alertScrollView.frame.width / 2, height: 30))
        kakaoLabel.text = "카카오톡"
        kakaoLabel.textAlignment = .center
        alertScrollView.addSubview(kakaoLabel)
        
        let kakaoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.shareKakaoTapped(_:)))
        kakaoImageView.isUserInteractionEnabled = true
        kakaoImageView.addGestureRecognizer(kakaoTapGestureRecognizer)
        
        let fbImageView = UIImageView(frame: CGRect(x: alertScrollView.frame.width / 2, y: 0, width: alertScrollView.frame.width / 2, height: 70))
        fbImageView.image = #imageLiteral(resourceName: "img_share_facebook")
        fbImageView.contentMode = .scaleAspectFit
        alertScrollView.addSubview(fbImageView)
        
        let fbLabel = UILabel(frame: CGRect(x: alertScrollView.frame.width / 2, y: 80, width: alertScrollView.frame.width / 2, height: 30))
        fbLabel.text = "페이스북"
        fbLabel.textAlignment = .center
        alertScrollView.addSubview(fbLabel)
        
        let fbTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.shareFacebookTapped(_:)))
        fbImageView.isUserInteractionEnabled = true
        fbImageView.addGestureRecognizer(fbTapGestureRecognizer)
        
        alertScrollView.contentSize = CGSize(width: alertScrollView.frame.width, height: 110)
        alertScrollView.bounces = false
        alertController.view.addSubview(alertScrollView)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Share Kakao
    func shareKakaoTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        guard let productInfo = viewModel?.product.value else { return }
        self.view.startLoading()
        viewModel?.shareToKakao(with: productInfo) { isSuccess in
            self.view.stopLoading()
        }
    }
    
    // MARK: Share Facebook
    func shareFacebookTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        guard let productInfo = viewModel?.product.value else { return }
        guard let content = viewModel?.shareToFacebook(with: productInfo) else { return }
        
        if presentedViewController != nil {
            dismiss(animated: true, completion: nil)
        }
        
        let dialog = FBSDKShareDialog()
        dialog.fromViewController = self
        dialog.delegate = self
        dialog.shareContent = content
        dialog.mode = .automatic
        if dialog.canShow() {
            print("\(className) > \(#function) > dialog can show")
            dialog.show()
        }
    }
    
    func sharer(_ sharer: FBSDKSharing!, didCompleteWithResults results: [AnyHashable : Any]!) {
        print("\(className) > \(#function) > results : \(results)")
    }
    
    func sharer(_ sharer: FBSDKSharing!, didFailWithError error: Error!) {
        print("\(className) > \(#function) > sharer Error")
        print(error)
    }
    
    func sharerDidCancel(_ sharer: FBSDKSharing!) {
        print("\(className) > \(#function)")
    }
}
