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

class MyProfileViewController: UIViewController {
    
    // MARK: IBOutlet
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var pagerView: PagerView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var nickname: UILabel!
    @IBOutlet weak var company: UILabel!
    @IBOutlet weak var school: UILabel!
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var introduce: UILabel!
    @IBOutlet weak var point: UILabel!
    @IBOutlet weak var pagerViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backViewOffsetY: NSLayoutConstraint!
    
    var viewModel: UserProfileViewModel?
    
    deinit {
        print("\(className) > \(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pagerView.delegate = self
        scrollView.delegate = self
        
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
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
            self?.nickname.text = "\(nickname), \((user.birth as! Int).toAge.description)"
            
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
            
            self?.phone.text = user.phone?.toPhoneFormat()
            self?.introduce.text = user.introduce
            
            if let point = user.balloon as? Int {
                self?.point.text = "보유포인트 \(point)P"
            } else {
                self?.point.text = "보유포인트 0P"
            }
            
            if let photos = user.photos as? Set<String> {
                self?.pagerView.pageCount = max(photos.count, 1)
            }
        }
    }
    
    @IBAction func onBackButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - PagerViewDelegate, UIScrollViewDelegate
extension MyProfileViewController: PagerViewDelegate, UIScrollViewDelegate {
    
    func loadPageViewItem(imageView: UIImageView, page: Int) {
        print("\(className) > \(#function)")
        
        guard let user = viewModel?.user.value else { return }
        
        let imageName = "\(user.userid)/\(Configuration.S3.PROFILE_IMAGE_NAME(page))"
        let imageUrl = Configuration.S3.PROFILE_IMAGE_URL + imageName
        
        imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "default_profile"), options: .cacheMemoryOnly) {
            (image, error, cacheType, imageURL) in
            print("\(self.className) > \(#function) > url: \(String(describing: imageURL))")
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
