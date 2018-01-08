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

/*
 *
 */
@available(iOS 9.0, *)
class MailProfileViewController: UIViewController {
    
    // MARK: IBOutlet
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var pagerView: PagerView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var messageStackView: UIStackView!
    @IBOutlet weak var nicknameStackView: UIStackView!
    @IBOutlet weak var ageStackView: UIStackView!
    @IBOutlet weak var phoneStackView: UIStackView!
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var descriptionLabel: KRWordWrapLabel!
    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var proposeButton: UIButton!
    
    @IBOutlet weak var containerViewHeight: NSLayoutConstraint!
    @IBOutlet weak var pagerViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var stackViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backViewOffsetY: NSLayoutConstraint!
    @IBOutlet weak var backgroundHeight: NSLayoutConstraint!
    
    var viewModel: MailProfileViewModel?
    
    deinit {
        removeNotificationObservers()
        print("\(className) > \(#function)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        navigationController?.isNavigationBarHidden = true
    }
    
    fileprivate func bindViewModel() {
        guard let viewModel = viewModel else { return }
        
        viewModel.user.bindAndFire { [weak self] user in
            if let point = user?.balloon as? Int {
                self?.pointLabel.text = "보유포인트 \(point)P"
            }
        }
        
        viewModel.friend.bindAndFire { [weak self] friend in
            
            guard let friend = friend else { return }
            guard let photos = friend.photos as? Set<String> else { return }
            
            self?.nicknameLabel.text = friend.nickname
            self?.ageLabel.text = (friend.birth as! Int).toAge.description
            self?.phoneLabel.text = friend.phone?.toPhoneFormat() ?? friend.phone
            self?.pagerView.pageCount = max(photos.count, 1)
        }
        
        viewModel.product.bindAndFire { [weak self] product in
            guard let product = product else { return }
            self?.descriptionLabel.text = product.toDescriptionForProfile
        }
        
        viewModel.mail.bindAndFire { [weak self] mail in
            if !(self?.isViewLoaded)! { return }
            
            if let mail = mail {
                guard let proposeStatus = mail.ProposeStatus else { return }
                guard let status = ProposeStatus(rawValue: proposeStatus) else { return }
                
                self?.messageStackView.isHidden = false
                self?.messageLabel.text = mail.Message
                self?.proposeButton.setTitle(status.message(), for: .normal)
                
                self?.buttonStackView.isHidden = true
                
                switch status {
                case .none: break
                case .notMade:
                    self?.phoneStackView.isHidden = true
                    self?.proposeButton.isUserInteractionEnabled = false
                    
                    if let _ = mail as? ReceiveMail {
                        print("\(String(describing: self?.className)) > \(#function) > mail is ReceiveMail")
                        self?.buttonStackView.isHidden = false
                    }
                    break
                case .made:
                    self?.phoneStackView.isHidden = false
                    self?.proposeButton.isUserInteractionEnabled = false
                    break
                case .alreadyMade:
                    self?.phoneStackView.isHidden = true
                    self?.proposeButton.isUserInteractionEnabled = false
                    break
                case .reject:
                    self?.phoneStackView.isHidden = true
                    self?.proposeButton.isUserInteractionEnabled = false
                    self?.proposeButton.setTitle("함께가기 거절", for: .normal)
                    break
                case .delete:
                    self?.phoneStackView.isHidden = true
                    self?.proposeButton.isUserInteractionEnabled = false
                    break
                }
                
                self?.proposeButton.setTitle(status.message(), for: .normal)
                
            } else {
                
                print("\(String(describing: self?.className)) > \(#function) > mail is nil")
                
                self?.messageStackView.isHidden = true
                self?.phoneStackView.isHidden = true
                self?.proposeButton.isUserInteractionEnabled = true
                self?.proposeButton.setTitle(ProposeStatus.none.message(), for: .normal)
                self?.proposeButton.addTarget(self,
                                              action: #selector(self?.proposeButtonTapped(_:)),
                                              for: .touchUpInside)
            }
            self?.refreshLayout()
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
    
    private func refreshLayout() {
        
        var scrollableHeight = pagerView.frame.height
        if (!messageStackView.isHidden) { scrollableHeight += messageStackView.frame.height }
        if (!nicknameStackView.isHidden) { scrollableHeight += nicknameStackView.frame.height }
        if (!ageStackView.isHidden) { scrollableHeight += ageStackView.frame.height }
        if (!phoneStackView.isHidden) { scrollableHeight += phoneStackView.frame.height }
        if (!descriptionLabel.isHidden) { scrollableHeight += descriptionLabel.frame.height }
        scrollableHeight += 27 // margin
        scrollableHeight += 20 // bottom margin
        
        let maxHeight = UIScreen.main.bounds.height - proposeButton.frame.height - pointLabel.frame.height + pagerView.frame.height - UIApplication.shared.statusBarFrame.height
        containerViewHeight.constant = max(scrollableHeight, maxHeight)
        
        backgroundHeight.constant = scrollableHeight - pagerView.frame.size.height
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

// MARK: - Delegates
extension MailProfileViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = scrollView.contentOffset.y
        let alpha = 1 - (yOffset / pagerView.frame.size.height)
        let halfOffsetY = yOffset * 0.5

        pagerView.alpha = alpha
        pagerViewOffsetY.constant = halfOffsetY
        backViewOffsetY.constant = -halfOffsetY
        stackViewOffsetY.constant = -halfOffsetY
    }
}

extension MailProfileViewController: PagerViewDelegate {
    func loadPageViewItem(imageView: UIImageView, page: Int) {
        print("\(className) > \(#function) > page : \(page)")
        guard let friend = viewModel?.friend.value else { return }
        
        let imageName = friend.userid + "/" + Configuration.S3.PROFILE_IMAGE_NAME(page)
        let imageUrl = Configuration.S3.PROFILE_IMAGE_URL + imageName
        imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "default_profile"), options: .cacheMemoryOnly) {
            (image, error, cachedType, url) in
        }
    }
    
    func onPageTapped(page: Int) {
        print("\(className) > \(#function) > page : \(page)")
    }
}

extension MailProfileViewController: Observerable {
    
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(MailProfileViewController.handleUpdatePointNotification(_:)),
                                               name: Notification.Name(rawValue: UserInfoManager.UpdateUserInfoNotification),
                                               object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: UserInfoManager.UpdateUserInfoNotification),
                                                  object: nil)
    }
    
    func handleUpdatePointNotification(_ notification: Notification) {
        guard let point = UserInfoManager.sharedInstance.userInfo?.balloon as? Int else { return }
        
        DispatchQueue.main.async {
            self.pointLabel.text = "보유포인트 \(point)P"
        }
    }
}
