//
//  ProfileViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 4..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import AWSCore
import KRWordWrapLabel

class MailProfileViewController: UIViewController {
    
    // MARK: IBOutlet
    @IBOutlet weak var pagerView: PagerView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var proposeButton: UIButton!
    
    @IBOutlet weak var message: UILabel!
    @IBOutlet weak var messageStackView: UIStackView!
    @IBOutlet weak var messageUnderline: UIView!
    @IBOutlet weak var nickname: UILabel!
    @IBOutlet weak var company: UILabel!
    @IBOutlet weak var school: UILabel!
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var introduce: UILabel!
    @IBOutlet weak var introductUnderline: UIView!
    @IBOutlet weak var productDesc: KRWordWrapLabel!
    @IBOutlet weak var point: UILabel!
    
    @IBOutlet weak var pagerViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backViewOffsetY: NSLayoutConstraint!
    
    var viewModel: MailProfileViewModel?
    
    deinit {
        removeNotificationObservers()
        print("\(className) > \(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        bindViewModel()
        
        viewModel?.loadUser()
        viewModel?.loadFriend()
        viewModel?.loadProduct()
        viewModel?.loadMail()
        
        pagerView.delegate = self
        scrollView.delegate = self
        
        addNotificationObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    private func initView() {
        productDesc.isUserInteractionEnabled = true
        productDesc.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.onDescTapped(_:))))
    }
    
    func onDescTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        print("\(className) > \(#function)")
        
        guard let detailVC: CampaignViewController = CampaignViewController.storyboardInstance(from: "SubItems") else {
            fatalError("\(className) > \(#function) > initialize CampaignViewcontroller Error")
        }
        
        guard let productId = viewModel?.product.value?.ProductId else { return }
        guard let user = viewModel?.user.value else { return }
        detailVC.viewModel = CampaignViewModel(id: productId,
                                               isLikeEnabled: true,
                                               dataSource: ProductRepository.shared)
        
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    fileprivate func bindViewModel() {
        guard let viewModel = viewModel else { return }
        
        viewModel.user.bindAndFire { [weak self] user in
            if let point = user?.balloon as? Int {
                self?.point.text = "보유포인트 \(point)P"
            }
        }
        
        viewModel.friend.bindAndFire { [weak self] friend in
            
            guard let friend = friend else { return }
            guard let nickname = friend.nickname else { return }
            self?.nickname.text = "\(nickname), \((friend.birth as! Int).toAge.description)세"
            
            if let company = friend.company {
                self?.company.isHidden = false
                self?.company.text = company
            } else {
                self?.company.isHidden = true
            }
            
            if let school = friend.school {
                self?.school.isHidden = false
                self?.school.text = school
            } else {
                self?.school.isHidden = true
            }
            
            self?.phone.text = friend.phone?.toPhoneFormat()
            if let introduce = friend.introduce {
                self?.introduce.isHidden = false
                self?.introductUnderline.isHidden = false
                self?.introduce.text = introduce
            } else {
                self?.introduce.isHidden = true
                self?.introductUnderline.isHidden = true
            }
            
            if let photos = friend.photos as? Set<String> {
                self?.pagerView.pageCount = max(photos.count, 1)
            }
        }
        
        viewModel.product.bindAndFire { [weak self] product in
            guard let product = product else { return }
            self?.productDesc.text = product.toDescriptionForProfile
        }
        
        viewModel.mail.bindAndFire { [weak self] mail in
            if !(self?.isViewLoaded)! { return }
            
            if let mail = mail {
                guard let proposeStatus = mail.ProposeStatus else { return }
                guard let status = ProposeStatus(rawValue: proposeStatus) else { return }
                
                self?.messageStackView.isHidden = false
                self?.messageUnderline.isHidden = false
                self?.message.text = mail.Message
                self?.proposeButton.setTitle(status.message(), for: .normal)
                
                self?.buttonStackView.isHidden = true
                
                switch status {
                case .none: break
                case .notMade:
                    self?.phone.isHidden = true
                    self?.proposeButton.isUserInteractionEnabled = false
                    
                    if let _ = mail as? ReceiveMail {
                        print("\(String(describing: self?.className)) > \(#function) > mail is ReceiveMail")
                        self?.buttonStackView.isHidden = false
                    }
                    break
                case .made:
                    self?.phone.isHidden = false
                    self?.proposeButton.isUserInteractionEnabled = false
                    break
                case .alreadyMade:
                    self?.phone.isHidden = true
                    self?.proposeButton.isUserInteractionEnabled = false
                    break
                case .reject:
                    self?.phone.isHidden = true
                    self?.proposeButton.isUserInteractionEnabled = false
                    self?.proposeButton.setTitle("함께가기 거절", for: .normal)
                    break
                case .delete:
                    self?.phone.isHidden = true
                    self?.proposeButton.isUserInteractionEnabled = false
                    break
                }
                
                self?.proposeButton.setTitle(status.message(), for: .normal)
                
            } else {
                
                print("\(String(describing: self?.className)) > \(#function) > mail is nil")
                
                self?.messageStackView.isHidden = true
                self?.messageUnderline.isHidden = true
                self?.phone.isHidden = true
                self?.proposeButton.isUserInteractionEnabled = true
                self?.proposeButton.setTitle(ProposeStatus.none.message(), for: .normal)
                self?.proposeButton.addTarget(self,
                                              action: #selector(self?.proposeButtonTapped(_:)),
                                              for: .touchUpInside)
            }
        }
        
        self.viewModel?.onShowAlert = { [weak self] alert in
            let alertController = UIAlertController(title: alert.title,
                                                    message: alert.message,
                                                    preferredStyle: .alert)
            for action in alert.actions {
                alertController.addAction(UIAlertAction(title: action.buttonTitle,
                                                        style: action.style,
                                                        handler: { _ in action.handler?() }))
            }
            self?.present(alertController, animated: true, completion: nil)
        }
        
        self.viewModel?.onShowMessage = { [weak self] _ in self?.sendMessage() }
    }
}

extension MailProfileViewController {
    
    @IBAction func onBackButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func proposeButtonTapped(_ sender: Any) {
        guard let viewModel = viewModel else { return }
        viewModel.proposeButtonTapped()
    }
    
    func sendMessage() {
        let alertController = UIAlertController(title: "상대방에게 한마디",
                                                message: "상대방에게 전하고 싶은 메시지을 보내주세요",
                                                preferredStyle: .alert)
        
        // for multiline textField -> addCustomView
        alertController.addTextField { (textField) in
            textField.placeholder = "200자 내로 적어주세요"
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "보내기", style: .default, handler: { (action) in
            let textField = alertController.textFields![0] as UITextField
            guard let viewModel = self.viewModel else { return }
            viewModel.propose(message: textField.text!)
        })
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func onAcceptButtonTapped(_ sender: Any) {
        viewModel?.accept()
    }
    
    @IBAction func onRejectButtonTapped(_ sender: Any) {
        viewModel?.reject()
    }
}

// MARK: - UIScrollViewDelegate
extension MailProfileViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = scrollView.contentOffset.y
        let alpha = 1 - (yOffset / pagerView.frame.size.height)
        let halfOffsetY = yOffset * 0.5

        pagerView.alpha = alpha
        pagerViewOffsetY.constant = halfOffsetY
        backViewOffsetY.constant = -halfOffsetY
    }
}

// MARK: - PagerViewDelegate
extension MailProfileViewController: PagerViewDelegate {
    func loadPageViewItem(imageView: UIImageView, page: Int) {
        guard let photos = viewModel?.friend.value?.photosArr else {
            imageView.image = #imageLiteral(resourceName: "default_profile")
            return
        }
        
        let imageUrl = Configuration.S3.PROFILE_IMAGE_URL + photos[page]
        imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "default_profile"), options: .cacheMemoryOnly) {
            (image, error, cachedType, url) in
        }
    }
    
    func onPageTapped(page: Int) {
        print("\(className) > \(#function) > page : \(page)")
    }
}

// MARK: -Notification Observers
extension MailProfileViewController {
    
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(MailProfileViewController.handleUpdatePointNotification(_:)),
                                               name: Notification.Name(rawValue: UserNotification.Update),
                                               object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: UserNotification.Update),
                                                  object: nil)
    }
    
    func handleUpdatePointNotification(_ notification: Notification) {
        guard let point = UserInfoRepository.shared.userInfo?.balloon as? Int else { return }
        
        DispatchQueue.main.async {
            self.point.text = "보유포인트 \(point)P"
        }
    }
}
