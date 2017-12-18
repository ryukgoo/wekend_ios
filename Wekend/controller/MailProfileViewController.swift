//
//  MailProfileViewController.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 12. 6..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import KRWordWrapLabel

class MailProfileViewController: UIViewController {

    var proposeButton: UIButton!
    var pointLabel: UILabel!
    
    var buttons: UIStackView!
    var acceptButton: UIButton!
    var rejectButton: UIButton!
    var scrollView: UIScrollView!
    var containter: UIView!
    var pagerView: PagerView!
    var messageStackView: UIStackView!
    var message: UILabel!
    var nicknameStackView: UIStackView!
    var nickname: UILabel!
    var ageStackView: UIStackView!
    var age: UILabel!
    var phoneStackView: UIStackView!
    var phone: UILabel!
    var campaignStackView: UIStackView!
    var campaign: KRWordWrapLabel!
    
    var viewModel: MailProfileViewModel? {
        didSet {
            fillUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.automaticallyAdjustsScrollViewInsets = true
        self.edgesForExtendedLayout = [.top, .bottom]
        
        initView()
        
        viewModel?.loadProduct()
        viewModel?.loadFriend()
        viewModel?.loadMail()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        navigationController?.navigationBar.viewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.viewDidAppear()
        refreshLayout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isStatusBarHidden = false
    }
    
    func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    func proposeButtonTapped(_ sender: Any) {
        printLog(#function)
    }
    
    func acceptButtonTapped(_ sender: Any) {
        printLog(#function)
    }
    
    func rejectButtonTapped(_ sender: Any) {
        printLog(#function)
    }
    
    fileprivate func fillUI() {
        guard let viewModel = viewModel else {
            return
        }
        
        viewModel.friend.bindAndFire { friend in
            guard let photos = friend?.photos as? Set<String> else {
                return
            }
            self.nickname.text = friend?.nickname
            self.age.text = (friend?.birth as! Int).toAge.description
            self.phone.text = friend?.phone?.toPhoneFormat()
            self.pagerView.pageCount = photos.count
            self.printLog("\(#function) > pageCount : \(photos.count)")
        }
        
        viewModel.product.bindAndFire { product in
            if let product = product {
                self.campaign.text = product.toDescriptionForProfile
            }
        }
        
        viewModel.mail.bindAndFire { mail in
            guard let mail = mail else { return }
            self.printLog("\(String(describing: mail.FriendNickname))")
            self.refreshLayout()
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MailProfileViewController: PagerViewDelegate {
    func loadPageViewItem(imageView: UIImageView, page: Int) {
        printLog("\(#function) > page : \(page)")
        
        guard let friend = viewModel?.friend.value else {
            return
        }
        
        let imageName = friend.userid + "/" + Configuration.S3.PROFILE_IMAGE_NAME(page)
        let imageUrl = Configuration.S3.PROFILE_IMAGE_URL + imageName
        
        imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "default_profile"), options: .cacheMemoryOnly) {
            (image, error, cachedType, url) in
        }
    }
    
    func onPageTapped(page: Int) {
        printLog("\(#function) > page : \(page)")
    }
}

extension MailProfileViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = scrollView.contentOffset.y
        let alpha = 1 - (yOffset / pagerView.frame.size.height)
//        let halfOffsetY = yOffset * 0.5
        
        pagerView.alpha = alpha
    }
}

extension MailProfileViewController {
    
    func initView() {
        
        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "btn_icon_back_w"), style: .plain, target: self, action: #selector(self.backButtonTapped(_:)))
        navigationItem.leftBarButtonItem = backButton
        
        proposeButton = UIButton()
        self.view.addSubview(proposeButton)
        proposeButton.backgroundColor = UIColor(netHex: 0xf2797c)
        proposeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0)
        proposeButton.setTitle("함께가기 신청", for: .normal)
        proposeButton.setTitleColor(.white, for: .normal)
        proposeButton.titleLabel?.textAlignment = .center
        
        proposeButton.translatesAutoresizingMaskIntoConstraints = false
        proposeButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        proposeButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        proposeButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        proposeButton.heightAnchor.constraint(equalToConstant: 49.0).isActive = true
        proposeButton.addTarget(self, action: #selector(self.proposeButtonTapped), for: .touchUpInside)
        
        pointLabel = UILabel()
        self.view.addSubview(pointLabel)
        pointLabel.backgroundColor = UIColor(netHex: 0xeeadae)
        pointLabel.font = UIFont.systemFont(ofSize: 15.0)
        pointLabel.text = "보유포인트"
        pointLabel.textColor = .white
        pointLabel.textAlignment = .center
        
        pointLabel.translatesAutoresizingMaskIntoConstraints = false
        pointLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        pointLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        pointLabel.bottomAnchor.constraint(equalTo: proposeButton.topAnchor).isActive = true
        pointLabel.heightAnchor.constraint(equalToConstant: 25.0).isActive = true
        
        acceptButton = UIButton()
        acceptButton.backgroundColor = UIColor(netHex: 0xf2797c)
        acceptButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0)
        acceptButton.setTitle("수락", for: .normal)
        acceptButton.setTitleColor(.white, for: .normal)
        acceptButton.titleLabel?.textAlignment = .center
        acceptButton.heightAnchor.constraint(equalToConstant: 49.0).isActive = true
        acceptButton.addTarget(self, action: #selector(self.acceptButtonTapped), for: .touchUpInside)

        rejectButton = UIButton()
        rejectButton.backgroundColor = UIColor(netHex: 0xe8e8e8)
        rejectButton.titleLabel?.font = UIFont.systemFont(ofSize: 18.0)
        rejectButton.setTitle("거절", for: .normal)
        rejectButton.setTitleColor(UIColor(netHex: 0x43434a), for: .normal)
        rejectButton.titleLabel?.textAlignment = .center
        rejectButton.heightAnchor.constraint(equalToConstant: 49.0).isActive = true
        rejectButton.addTarget(self, action: #selector(self.rejectButtonTapped), for: .touchUpInside)

        buttons = UIStackView()
        self.view.addSubview(buttons)
        buttons.addArrangedSubview(acceptButton)
        buttons.addArrangedSubview(rejectButton)
        buttons.distribution = .fillEqually
        buttons.alignment = .center
        buttons.spacing = 0.0
        buttons.isHidden = true // Buttons Hide
        
        buttons.translatesAutoresizingMaskIntoConstraints = false
        buttons.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        buttons.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        buttons.heightAnchor.constraint(equalTo: acceptButton.heightAnchor, multiplier: 1.0).isActive = true
        buttons.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
        scrollView = UIScrollView(frame: view.frame)
        self.view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.backgroundColor = .white
        scrollView.bounces = false
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: pointLabel.topAnchor).isActive = true
        
        containter = UIView(frame: view.frame)
        scrollView.addSubview(containter)
        
        pagerView = PagerView()
        containter.addSubview(pagerView)

        pagerView.delegate = self
        pagerView.isUserInteractionEnabled = true
        pagerView.translatesAutoresizingMaskIntoConstraints = false
        pagerView.leadingAnchor.constraint(equalTo: containter.leadingAnchor).isActive = true
        pagerView.trailingAnchor.constraint(equalTo: containter.trailingAnchor).isActive = true
        pagerView.topAnchor.constraint(equalTo: containter.topAnchor).isActive = true
        pagerView.heightAnchor.constraint(equalTo: containter.widthAnchor, multiplier: 1.0).isActive = true
        
        let infoStackView = UIStackView()
        containter.addSubview(infoStackView)
        infoStackView.axis = .vertical
        infoStackView.distribution = .fill
        infoStackView.spacing = 0.0
        infoStackView.backgroundColor = .yellow
        
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.leadingAnchor.constraint(equalTo: containter.leadingAnchor, constant: 15.0).isActive = true
        infoStackView.trailingAnchor.constraint(equalTo: containter.trailingAnchor, constant: -15.0).isActive = true
        infoStackView.topAnchor.constraint(equalTo: pagerView.bottomAnchor).isActive = true

        messageStackView = getMessageStackView(infoStackView)
        nicknameStackView = getNicknameStackView(infoStackView)
        ageStackView = getAgeStackView(infoStackView)
        phoneStackView = getPhoneStackView(infoStackView)
        campaignStackView = getCampaignStackView(containter)
        
        messageStackView.isHidden = true
        phoneStackView.isHidden = true
    }
    
    func refreshLayout() {
        
        var scrollableHeight = pagerView.frame.height
        if (!messageStackView.isHidden) { scrollableHeight += messageStackView.frame.height }
        if (!nicknameStackView.isHidden) { scrollableHeight += nicknameStackView.frame.height }
        if (!ageStackView.isHidden) { scrollableHeight += ageStackView.frame.height }
        if (!phoneStackView.isHidden) { scrollableHeight += phoneStackView.frame.height }
        if (!campaignStackView.isHidden) { scrollableHeight += campaignStackView.frame.height }
        
        printLog("\(#function) > scrollableHeight : \(scrollableHeight)")
        scrollableHeight = max(scrollableHeight, UIScreen.main.bounds.height - proposeButton.frame.height
            - pointLabel.frame.height + pagerView.frame.height)
        
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: scrollableHeight)
    }
    
    private func getMessageStackView(_ parentView: UIStackView) -> UIStackView {
        
        let stackView = UIStackView()
        parentView.addArrangedSubview(stackView)
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0.0
        
        let nestedStackView = UIStackView()
        stackView.addArrangedSubview(nestedStackView)
        nestedStackView.axis = .horizontal
        nestedStackView.distribution = .fill
        nestedStackView.alignment = .center
        nestedStackView.spacing = 20.0
        
        let messageLabel = UILabel()
        nestedStackView.addArrangedSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.widthAnchor.constraint(equalToConstant: 54.0).isActive = true
        messageLabel.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
        
        messageLabel.text = "메시지"
        messageLabel.font = UIFont.systemFont(ofSize: 16.0)
        messageLabel.textColor = UIColor(netHex: 0x4b4b4b)
        messageLabel.textAlignment = .center
        
        message = UILabel()
        nestedStackView.addArrangedSubview(message)
        message.translatesAutoresizingMaskIntoConstraints = false
        message.heightAnchor.constraint(equalTo: messageLabel.heightAnchor, multiplier: 1.0).isActive = true
        
        message.text = "메시지"
        message.font = UIFont.systemFont(ofSize: 16.0)
        message.textColor = UIColor(netHex: 0x4b4b4b)
        message.textAlignment = .left
        
        let lineView = UIView()
        stackView.addArrangedSubview(lineView)
        lineView.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        lineView.backgroundColor = UIColor(netHex: 0xdadada)
        
        return stackView
    }
    
    private func getNicknameStackView(_ parentView: UIStackView) -> UIStackView {
        
        let stackView = UIStackView()
        parentView.addArrangedSubview(stackView)
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0.0
        
        let nestedStackView = UIStackView()
        stackView.addArrangedSubview(nestedStackView)
        nestedStackView.axis = .horizontal
        nestedStackView.distribution = .fill
        nestedStackView.alignment = .center
        nestedStackView.spacing = 0.0
        
        let nicknameLabel = UILabel()
        nestedStackView.addArrangedSubview(nicknameLabel)
        nicknameLabel.translatesAutoresizingMaskIntoConstraints = false
        nicknameLabel.widthAnchor.constraint(equalToConstant: 54.0).isActive = true
        nicknameLabel.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
        
        nicknameLabel.text = "닉네임"
        nicknameLabel.font = UIFont.systemFont(ofSize: 16.0)
        nicknameLabel.textColor = UIColor(netHex: 0x4b4b4b)
        nicknameLabel.textAlignment = .center
        
        nickname = UILabel()
        nestedStackView.addArrangedSubview(nickname)
        nickname.heightAnchor.constraint(equalTo: nicknameLabel.heightAnchor, multiplier: 1.0).isActive = true
        
        nickname.text = "닉네임"
        nickname.font = UIFont.systemFont(ofSize: 20.0)
        nickname.textColor = UIColor(netHex: 0x4b4b4b)
        nickname.textAlignment = .center
        
        let lineView = UIView()
        stackView.addArrangedSubview(lineView)
        lineView.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        lineView.backgroundColor = UIColor(netHex: 0xdadada)

        return stackView
    }
    
    private func getAgeStackView(_ parentView: UIStackView) -> UIStackView {
        
        let stackView = UIStackView()
        parentView.addArrangedSubview(stackView)
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0.0
        
        let nestedStackView = UIStackView()
        stackView.addArrangedSubview(nestedStackView)
        nestedStackView.axis = .horizontal
        nestedStackView.distribution = .fill
        nestedStackView.alignment = .center
        nestedStackView.spacing = 0.0
        
        let ageLabel = UILabel()
        nestedStackView.addArrangedSubview(ageLabel)
        ageLabel.translatesAutoresizingMaskIntoConstraints = false
        ageLabel.widthAnchor.constraint(equalToConstant: 54.0).isActive = true
        ageLabel.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
        
        ageLabel.text = "나이"
        ageLabel.font = UIFont.systemFont(ofSize: 16.0)
        ageLabel.textColor = UIColor(netHex: 0x4b4b4b)
        ageLabel.textAlignment = .center
        
        age = UILabel()
        nestedStackView.addArrangedSubview(age)
        age.heightAnchor.constraint(equalTo: ageLabel.heightAnchor, multiplier: 1.0).isActive = true
        
        age.text = "나이"
        age.font = UIFont.systemFont(ofSize: 20.0)
        age.textColor = UIColor(netHex: 0x4b4b4b)
        age.textAlignment = .center
        
        let lineView = UIView()
        stackView.addArrangedSubview(lineView)
        lineView.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        lineView.backgroundColor = UIColor(netHex: 0xdadada)
        
        return stackView
    }
    
    private func getPhoneStackView(_ parentView: UIStackView) -> UIStackView {
        
        let stackView = UIStackView()
        parentView.addArrangedSubview(stackView)
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 0.0
        
        let nestedStackView = UIStackView()
        stackView.addArrangedSubview(nestedStackView)
        nestedStackView.axis = .horizontal
        nestedStackView.distribution = .fill
        nestedStackView.alignment = .center
        nestedStackView.spacing = 0.0
        
        let phoneLabel = UILabel()
        nestedStackView.addArrangedSubview(phoneLabel)
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false
        phoneLabel.widthAnchor.constraint(equalToConstant: 54.0).isActive = true
        phoneLabel.heightAnchor.constraint(equalToConstant: 80.0).isActive = true
        
        phoneLabel.text = "휴대폰"
        phoneLabel.font = UIFont.systemFont(ofSize: 16.0)
        phoneLabel.textColor = UIColor(netHex: 0x4b4b4b)
        phoneLabel.textAlignment = .center
        
        phone = UILabel()
        nestedStackView.addArrangedSubview(phone)
        phone.heightAnchor.constraint(equalTo: phoneLabel.heightAnchor, multiplier: 1.0).isActive = true
        
        phone.text = "휴대폰"
        phone.font = UIFont.systemFont(ofSize: 20.0)
        phone.textColor = UIColor(netHex: 0x4b4b4b)
        phone.textAlignment = .center
        
        let lineView = UIView()
        stackView.addArrangedSubview(lineView)
        lineView.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        lineView.backgroundColor = UIColor(netHex: 0xdadada)
        
        return stackView
    }
    
    private func getCampaignStackView(_ parentView: UIView) -> UIStackView {
        
        let stackView = UIStackView()
        parentView.addSubview(stackView)
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .top
        stackView.spacing = 20.0
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: containter.leadingAnchor, constant: 15.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: containter.trailingAnchor, constant: -15.0).isActive = true
        stackView.topAnchor.constraint(equalTo: ageStackView.bottomAnchor, constant: 27.0).isActive = true
        
        let campaignLabel = UILabel()
        stackView.addArrangedSubview(campaignLabel)
        campaignLabel.translatesAutoresizingMaskIntoConstraints = false
        campaignLabel.widthAnchor.constraint(equalToConstant: 54.0).isActive = true
        
        campaignLabel.text = "캠페인"
        campaignLabel.font = UIFont.systemFont(ofSize: 16.0)
        campaignLabel.textColor = UIColor(netHex: 0x4b4b4b)
        campaignLabel.baselineAdjustment = .alignBaselines
        
        campaign = KRWordWrapLabel()
        stackView.addArrangedSubview(campaign)
        
        campaign.text = "캠페인"
        campaign.font = UIFont.systemFont(ofSize: 16.0)
        campaign.textColor = UIColor(netHex: 0x4b4b4b)
        campaign.lineBreakMode = .byTruncatingTail
        campaign.numberOfLines = 0
        
        return stackView
    }
}
