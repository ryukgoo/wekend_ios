//
//  MailBoxViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 11. 22..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit

class MailBoxViewController: UIViewController {

    enum Mode: Int {
        case receive
        case send
        case all
    }
    
    deinit {
        removeNotificationObservers()
        printLog("deinit")
    }
    
    // MARK : Properties
    
    var isNeedRefreshSendMail: Bool = true
    var isNeedRefreshReceiveMail: Bool = true
    
    let refreshControl = UIRefreshControl()
    
    // MARK : IBOutlet
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noResultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        printLog("viewDidLoad")
        
        initTableView()
        initSegmentControl()
        
        self.tabBarController?.startLoading()
        loadMails()
        
        addNotificationObservers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
        navigationController?.navigationBar.tintColor = .black
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK : load datas
    
    func loadMails(mode: Mode? = nil) {
        
        printLog(#function)
        
        guard let inputMode = mode else {
            loadMails(mode: Mode(rawValue: segmentControl.selectedSegmentIndex)!)
            return
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        printLog("\(#function) > inputMode : \(inputMode.rawValue)")
        
        switch inputMode {
            
        case .receive:
            
            if !isNeedRefreshReceiveMail {
                tableView.reloadData()
                refreshControl.endRefreshing()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                handleNoResultLabel()
                return
            }
            
            ReceiveMailRepository.shared.loadMails { result in
                if case Result.success(object: _) = result {
                    DispatchQueue.main.async {
                        self.refreshControl.endRefreshing()
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        self.endLoading()
                        self.tableView.reloadData()
                        self.handleNoResultLabel()
                        self.isNeedRefreshReceiveMail = false
                    }
                }
            }
            break
            
        case .send:
            
            if !isNeedRefreshSendMail {
                tableView.reloadData()
                refreshControl.endRefreshing()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
                handleNoResultLabel()
                return
            }
            
            SendMailRepository.shared.loadMails { result in
                if case Result.success(object: _) = result {
                    DispatchQueue.main.async {
                        self.refreshControl.endRefreshing()
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        
                        self.tabBarController?.endLoading()
                        self.tableView.reloadData()
                        self.handleNoResultLabel()
                        self.isNeedRefreshSendMail = false
                    }
                }
            }
            break
            
        default:
            loadMails(mode: Mode(rawValue: segmentControl.selectedSegmentIndex)!)
            break
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

// MARK: Observserable

extension MailBoxViewController: Observerable {
    
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(MailBoxViewController.handleAddReceiveMailNotification(_:)),
                                               name: Notification.Name(rawValue: MailNotification.Receive.Add),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MailBoxViewController.handleAddReceiveMailNotification(_:)),
                                               name: Notification.Name(rawValue: MailNotification.Receive.New),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MailBoxViewController.handleAddSendMailNotification(_:)),
                                               name: Notification.Name(rawValue: MailNotification.Send.Add),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MailBoxViewController.handleAddSendMailNotification(_:)),
                                               name: Notification.Name(rawValue: MailNotification.Send.New),
                                               object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: MailNotification.Receive.Add),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: MailNotification.Receive.New),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: MailNotification.Send.Add),
                                                  object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: MailNotification.Send.New),
                                                  object: nil)
    }
    
    func handleAddReceiveMailNotification(_ notification: Notification) {
        printLog("handleAddReceiveMailNotification > notification : \(notification.name)")
        isNeedRefreshReceiveMail = true
        if segmentControl.selectedSegmentIndex == Mode.receive.rawValue {
            DispatchQueue.main.async {
                self.loadMails()
            }
        }
    }
    
    func handleChangeReceiveMailNotification(_ notification: Notification) {
        printLog("handleChangeReceiveMailNotification > notification : \(notification.name)")
        isNeedRefreshReceiveMail = true
        if segmentControl.selectedSegmentIndex == Mode.receive.rawValue {
            loadMails()
        }
        
    }
    
    func handleAddSendMailNotification(_ notification: Notification) {
        printLog("handleAddSendMailNotification > notification: \(notification.name)")
        isNeedRefreshSendMail = true
        if segmentControl.selectedSegmentIndex == Mode.send.rawValue {
            DispatchQueue.main.async {
                self.loadMails()
            }
        }
    }
    
    func handleChangeSendMailNotification(_ notification: Notification) {
        printLog("handleChangeSendMailNotification > notification: \(notification.name)")
        isNeedRefreshSendMail = true
        if segmentControl.selectedSegmentIndex == Mode.send.rawValue {
            loadMails()
        }
    }
    
}

// MARK: SegmentControl

extension MailBoxViewController {
    
    func initTableView() {
        // Do any additional setup after loading the view.
        tableView.contentInset = UIEdgeInsetsMake(12, 0, 0, 0)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to Refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
        noResultLabel.isHidden = true
    }
    
    func initSegmentControl() {
        segmentControl.removeBorders()
        segmentControl.customizeText()
        segmentControl.addTarget(self, action: #selector(self.mailBoxTabSelected(_:)), for: .valueChanged)
    }
    
    func mailBoxTabSelected(_ sender: UISegmentedControl) {
//        self.mailBoxTableView.reloadData()
        loadMails()
    }
    
    func refresh(_ sender: Any) {
        isNeedRefreshSendMail = true
        isNeedRefreshReceiveMail = true
        loadMails()
    }
    
    func handleNoResultLabel() {
        switch segmentControl.selectedSegmentIndex {
        case Mode.receive.rawValue:
            if ReceiveMailRepository.shared.datas.count == 0 {
                self.noResultLabel.text = "받은 메일이 없습니다"
                self.noResultLabel.isHidden = false
            } else {
                self.noResultLabel.isHidden = true
            }
            break
        case Mode.send.rawValue:
            if SendMailRepository.shared.datas.count == 0 {
                self.noResultLabel.text = "보낸 메일이 없습니다"
                self.noResultLabel.isHidden = false
            } else {
                self.noResultLabel.isHidden = true
            }
            break
        default:
            break
        }
    }
}

// MARK: TableView DataSource

extension MailBoxViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch segmentControl.selectedSegmentIndex {
        case Mode.receive.rawValue:
            return ReceiveMailRepository.shared.datas.count
        case Mode.send.rawValue:
            return SendMailRepository.shared.datas.count
        default:
            return 0
        }
    }
}

// MARK: TableView Delegate

extension MailBoxViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(for: indexPath) as MailTableViewCell
        
        guard let userInfo = UserInfoManager.sharedInstance.userInfo else { return cell }
        
        let defaultImage : UIImage
        if userInfo.gender != UserInfo.RawValue.GENDER_MALE {
            defaultImage = #imageLiteral(resourceName: "img_bg_thumb_s_default_male")
        } else {
            defaultImage = #imageLiteral(resourceName: "img_bg_thumb_s_default_Female")
        }
        
        printLog("\(#function) > segmentControl.selectedSegmentIndex : \(segmentControl.selectedSegmentIndex)")
        
        switch segmentControl.selectedSegmentIndex {
        case Mode.receive.rawValue:
            
            let mail = ReceiveMailRepository.shared.datas[indexPath.row]
            let imageName = mail.SenderId! + "/" + Configuration.S3.PROFILE_IMAGE_NAME(0)
            let imageUrl = Configuration.S3.PROFILE_IMAGE_URL + imageName
            
            cell.mailImage.sd_setImage(with: URL(string: imageUrl), placeholderImage: defaultImage, options: .cacheMemoryOnly) {
                (image, error, cacheType, imageURL) in
                
            }
            cell.mailImage.toMask(mask: #imageLiteral(resourceName: "img_bg_thumb_s_2"))
            
            guard let status = ProposeStatus(rawValue: mail.ProposeStatus!) else {
                fatalError("MailBoxViewController > receiveMail > ProposeStatus Error")
            }
            
            let mailTitle = mail.SenderNickname! + getMailTitle(status: status, mode: segmentControl.selectedSegmentIndex)
            
            cell.mailTitle.text = mailTitle
            
            switch status {
            case .notMade:
                cell.mailTitle.textColor = UIColor(netHex: Constants.ColorInfo.Text.Mail.RECEIVE)
            default:
                cell.mailTitle.textColor = UIColor(netHex: Constants.ColorInfo.Text.Mail.DEFAULT)
            }
            
            cell.mailDate.text = "\(Constants.Title.Cell.DATE) : " + Utilities.getDateFromTimeStamp(timestamp: mail.UpdatedTime)
            
            return cell
            
        case Mode.send.rawValue:
            
            let mail = SendMailRepository.shared.datas[indexPath.row]
            let imageName = mail.ReceiverId! + "/" + Configuration.S3.PROFILE_IMAGE_NAME(0)
            let imageUrl = Configuration.S3.PROFILE_IMAGE_URL + imageName
            
            cell.mailImage.sd_setImage(with: URL(string: imageUrl), placeholderImage: defaultImage, options: .cacheMemoryOnly) {
                (image, error, cacheType, imageURL) in
                
            }
            cell.mailImage.toMask(mask: #imageLiteral(resourceName: "img_bg_thumb_s_2"))
            
            guard let status = ProposeStatus(rawValue: mail.ProposeStatus!) else {
                fatalError("MailBoxViewController > sendMail > ProposeStatus Error")
            }
            
            let mailTitle = mail.ReceiverNickname! + getMailTitle(status: status, mode: segmentControl.selectedSegmentIndex)
            
            cell.mailTitle.text = mailTitle
            
            switch status {
            case .notMade:
                cell.mailTitle.textColor = UIColor(netHex: Constants.ColorInfo.Text.Mail.SEND)
            default:
                cell.mailTitle.textColor = UIColor(netHex: Constants.ColorInfo.Text.Mail.DEFAULT)
            }
            
            cell.mailDate.text = "\(Constants.Title.Cell.DATE) : " + Utilities.getDateFromTimeStamp(timestamp: mail.UpdatedTime)
            
            return cell
            
        default:
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    private func getMailTitle(status: ProposeStatus, mode: Int) -> String {
        
        printLog("\(#function) > getMailTitle > status : \(status), mode : \(mode)")
        
        switch status {
        case .notMade:
            if mode == Mode.send.rawValue { return Constants.Title.Cell.SEND_NOT_MADE }
            else if mode == Mode.receive.rawValue { return Constants.Title.Cell.RECEIVE_NOT_MADE }
        case .made, .alreadyMade:
            return Constants.Title.Cell.MADE
        case .reject:
            if mode == Mode.send.rawValue { return Constants.Title.Cell.SEND_REJECT }
            else if mode == Mode.receive.rawValue { return Constants.Title.Cell.RECEIVE_REJECT }
        default:
            return ""
        }
        
        return ""
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let mailProfileViewController = LikeProfileViewController.storyboardInstance(from: "SubItems") as? LikeProfileViewController else {
            fatalError()
        }
        
        switch segmentControl.selectedSegmentIndex {
        case Mode.receive.rawValue:
            let mail = ReceiveMailRepository.shared.datas[indexPath.row]
            mailProfileViewController.viewModel = MailProfileViewModel(productId: mail.ProductId as! Int, friendId: mail.FriendId!)
            navigationController?.pushViewController(mailProfileViewController, animated: true)
            break
        case Mode.send.rawValue:
            let mail = SendMailRepository.shared.datas[indexPath.row]
            mailProfileViewController.viewModel = MailProfileViewModel(productId: mail.ProductId as! Int, friendId: mail.FriendId!)
            navigationController?.pushViewController(mailProfileViewController, animated: true)
            break
        default: return
        }
    }
    
    fileprivate func whitespaceString(font: UIFont = UIFont.systemFont(ofSize: 15), width: CGFloat) -> String {
        let kPadding: CGFloat = 20
        let mutable = NSMutableString(string: "")
        let attribute = [NSFontAttributeName: font]
        while mutable.size(attributes: attribute).width < width - (2 * kPadding) {
            mutable.append(" ")
        }
        return mutable as String
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let whitespace = whitespaceString(width: tableView.rowHeight)
        let deleteAction = UITableViewRowAction(style: .normal, title: whitespace) {
            (rowAction, indexPath) in
            
            switch self.segmentControl.selectedSegmentIndex {
                
            case Mode.receive.rawValue:
                let deleteMail = ReceiveMailRepository.shared.datas[indexPath.row]
                
                ReceiveMailRepository.shared.updateMail(mail: deleteMail) { isSuccess in
                    if isSuccess {
                        ReceiveMailRepository.shared.datas.remove(at: indexPath.row)
                        DispatchQueue.main.async {
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                            self.handleNoResultLabel()
                        }
                    }
                }
                break
                
            case Mode.send.rawValue:
                let deleteMail = SendMailRepository.shared.datas[indexPath.row]
                
                SendMailRepository.shared.deleteMail(mail: deleteMail) { isSuccess in
                    if isSuccess {
                        SendMailRepository.shared.datas.remove(at: indexPath.row)
                        DispatchQueue.main.async {
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                            self.handleNoResultLabel()
                        }
                    }
                }
                break
                
            default:
                break
            }
            
        }
        
        deleteAction.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "img_bg_delete"))
        
        return [deleteAction]
    }
    
    func scrollToTop(animated: Bool) {
        let yOffset = -tableView.contentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: true)
    }
}
