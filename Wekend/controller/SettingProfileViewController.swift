//
//  MyProfileViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 18..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import AWSS3
import SDWebImage

class SettingProfileViewController: UIViewController {
    
    // MARK: IBOutlet
    
    @IBOutlet weak var pagerView: PagerView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var nickname: UILabel!
    @IBOutlet weak var company: UILabel!
    @IBOutlet weak var school: UILabel!
    @IBOutlet weak var area: UILabel!
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var introduce: UILabel!
    @IBOutlet weak var introductUnderline: UIView!
    @IBOutlet weak var point: UILabel!
    @IBOutlet weak var pagerViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backViewOffsetY: NSLayoutConstraint!
    
    var viewModel: UserProfileViewModel?
    
    deinit {
        print("\(className) > \(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let screenWidth = UIScreen.main.bounds.width
        pagerView.pageFrame = CGRect(x: 0.0, y: 0.0, width: screenWidth, height: screenWidth)
        pagerView.delegate = self
        scrollView.delegate = self
        
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
        
        viewModel?.loadUser()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("\(className) > \(#function)")
        guard let editViewController = segue.destination as? EditProfileViewController else { return }
        editViewController.viewModel = UserProfileViewModel(userDataSource: UserInfoRepository.shared)
    }
    
    fileprivate func bindViewModel() {
        print("\(className) > \(#function)")
        guard let viewModel = viewModel else { return }
        viewModel.user.bindAndFire { [weak self] user in
            guard let user = user else { return }
            guard let nickname = user.nickname else { return }
            self?.nickname.text = "\(nickname), \((user.birth as! Int).toAge.description)세"
            
            if let company = user.company {
                self?.company.isHidden = false
                self?.company.text = company
            } else {
                self?.company.isHidden = true
            }
            
            if let school = user.school {
                self?.school.isHidden = false
                self?.school.text = school
            } else {
                self?.school.isHidden = true
            }
            
            if let area = user.area {
                self?.area.isHidden = false
                self?.area.text = area
            } else {
                self?.area.isHidden = true
            }
            
            self?.phone.text = user.phone?.toPhoneFormat()
            if let introduce = user.introduce {
                self?.introduce.isHidden = false
                self?.introductUnderline.isHidden = false
                self?.introduce.text = introduce
            } else {
                self?.introduce.isHidden = true
                self?.introductUnderline.isHidden = true
            }
            
            if let point = user.balloon as? Int {
                self?.point.text = "보유포인트 \(point)P"
            } else {
                self?.point.text = "보유포인트 0P"
            }
            
            if let photos = user.photos as? Set<String> {
                self?.pagerView.pageCount = max(photos.count, 1)
            } else {
                self?.pagerView.pageCount = 1
            }
        }
    }
    
    @IBAction func onBackButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - PagerViewDelegate, UIScrollViewDelegate
extension SettingProfileViewController: PagerViewDelegate, UIScrollViewDelegate {
    
    func loadPageViewItem(imageView: UIImageView, page: Int) {
        
        guard let photos = viewModel?.user.value?.photosArr, photos.count > 0 else {
            imageView.image = #imageLiteral(resourceName: "default_profile")
            return
        }
        
        let imageUrl = Configuration.S3.PROFILE_IMAGE_URL + photos[page]
        
        imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "default_profile"), options: [.cacheMemoryOnly, .retryFailed]) {
            (image, error, cacheType, imageURL) in
        }
    }
    
    func onPageTapped(page: Int) {}
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let yOffset = self.scrollView.contentOffset.y
        let alpha = 1 - (yOffset / self.pagerView.frame.size.height)

        pagerView.alpha = alpha
        pagerViewOffsetY.constant = yOffset * 0.5
        backViewOffsetY.constant = -(yOffset * 0.5)
    }
}
