//
//  MailBoxViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 11. 22..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit

class MailBoxViewController: UIViewController {

    // MARK : IBOutlet
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noResultLabel: UILabel!
    
    // MARK : Properties
    var isNeedRefreshSendMail: Bool = true
    var isNeedRefreshReceiveMail: Bool = true
    
    var isLoading: Bool = false
    
    let refreshControl = UIRefreshControl()
    
    var viewModels: Dictionary<Int, MailBoxViewModel>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTableView()
        initSegmentControl()
        
        viewModels = Dictionary<Int, MailBoxViewModel>()
        viewModels?[MailType.receive.rawValue] = MailBoxViewModel(dataSource: ReceiveMailRepository.shared)
        viewModels?[MailType.send.rawValue] = MailBoxViewModel(dataSource: SendMailRepository.shared)
        
        bindViewModel()
        loadDatas()
        
        addNotificationObservers()
    }
    
    deinit {
        removeNotificationObservers()
        print("\(className) > \(#function)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadDatas() {
        print("\(className) > \(#function)")
        
        isLoading = true
        self.tabBarController?.startLoading()
        
        guard let viewModel = viewModels?[segmentControl.selectedSegmentIndex] else { return }
        viewModel.loadMailList()
    }
    
    /*
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
    }
     */
}

// MARK: -Bind ViewModel
extension MailBoxViewController {
    
    fileprivate func bindViewModel() {
        guard let receiveViewModel = viewModels?[MailType.receive.rawValue] else { return }
        receiveViewModel.datas.bind { [weak self] datas in
            if (self?.isLoading)! {
                self?.tabBarController?.endLoading()
                self?.refreshControl.endRefreshing()
            }
            
            if datas?.count == 0 {
                self?.noResultLabel.text = "받은 메일이 없습니다"
                self?.noResultLabel.isHidden = false
            } else {
                self?.noResultLabel.isHidden = true
            }
            
            self?.tableView.reloadData()
            self?.isLoading = false
        }
        
        guard let sendViewModel = viewModels?[MailType.send.rawValue] else { return }
        sendViewModel.datas.bind { [weak self] datas in
            if (self?.isLoading)! {
                self?.tabBarController?.endLoading()
                self?.refreshControl.endRefreshing()
            }
            
            if datas?.count == 0 {
                self?.noResultLabel.text = "보낸 메일이 없습니다"
                self?.noResultLabel.isHidden = false
            } else {
                self?.noResultLabel.isHidden = true
            }
            
            self?.tableView.reloadData()
            self?.isLoading = false
        }
    }
    
    fileprivate func unbindViewModel() {
        guard let receiveViewModel = viewModels?[MailType.receive.rawValue] else { return }
        receiveViewModel.datas.unbind()
        guard let sendViewModel = viewModels?[MailType.send.rawValue] else { return }
        sendViewModel.datas.unbind()
    }
}

// MARK: SegmentControl
extension MailBoxViewController {
    
    func initTableView() {
        
        tableView.contentInset = UIEdgeInsetsMake(12, 0, 0, 0)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        refreshControl.attributedTitle = NSAttributedString(string: "업데이트중...")
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
        loadDatas()
    }
    
    func refresh(_ sender: Any) {
        
        print("\(className) > \(#function)")
        
        isNeedRefreshSendMail = true
        isNeedRefreshReceiveMail = true
        loadDatas()
    }
    
    func handleNoResultLabel() {
        print(#function)
        guard let viewModel = viewModels?[segmentControl.selectedSegmentIndex] else { return }
        guard let type = MailType(rawValue: segmentControl.selectedSegmentIndex) else { return }
        
        if viewModel.datas.value?.count == 0 {
            self.noResultLabel.text = type.emptyMessage()
            self.noResultLabel.isHidden = false
        } else {
            self.noResultLabel.isHidden = true
        }
    }
}

// MARK: TableView DataSource
extension MailBoxViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let viewModel = viewModels?[segmentControl.selectedSegmentIndex] else { return 0 }
        return viewModel.datas.value?.count ?? 0
    }
}

// MARK: TableView Delegate
extension MailBoxViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(for: indexPath) as MailTableViewCell
        guard let userInfo = UserInfoRepository.shared.userInfo else { return cell }
        
        guard let mail = viewModels?[segmentControl.selectedSegmentIndex]?.datas.value?[indexPath.row] else {
            return cell
        }
        
        cell.viewModel = MailBoxCellViewModel(user: userInfo, mail: mail)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let mailProfileViewController: MailProfileViewController =
            MailProfileViewController.storyboardInstance(from: "SubItems") else {
            return
        }
        
        guard let type = MailType(rawValue: segmentControl.selectedSegmentIndex) else { return }
        
        switch type {
        case .receive:
            let mail = ReceiveMailRepository.shared.datas[indexPath.row]
            mailProfileViewController.viewModel = MailProfileViewModel(productId: mail.ProductId as! Int,
                                                                       friendId: mail.FriendId!,
                                                                       mailDataSource: ReceiveMailRepository.shared,
                                                                       userDataSource: UserInfoRepository.shared,
                                                                       productDataSource: ProductRepository.shared)
            navigationController?.pushViewController(mailProfileViewController, animated: true)
            break
        case .send:
            let mail = SendMailRepository.shared.datas[indexPath.row]
            mailProfileViewController.viewModel = MailProfileViewModel(productId: mail.ProductId as! Int,
                                                                       friendId: mail.FriendId!,
                                                                       mailDataSource: SendMailRepository.shared,
                                                                       userDataSource: UserInfoRepository.shared,
                                                                       productDataSource: ProductRepository.shared)
            navigationController?.pushViewController(mailProfileViewController, animated: true)
            break
        default: return
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let whitespace = whitespaceString(width: tableView.rowHeight)
        let deleteAction = UITableViewRowAction(style: .normal, title: whitespace) {
            (rowAction, indexPath) in
            
            guard let viewModel = self.viewModels?[self.segmentControl.selectedSegmentIndex],
                let deleteMail = viewModel.datas.value?[indexPath.row] else { return }
         
            self.unbindViewModel()
            viewModel.delete(mail: deleteMail, index: indexPath.row) { success in
                if success {
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                    self.handleNoResultLabel()
                    self.bindViewModel()
                }
            }
        }
        deleteAction.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "img_bg_delete"))
        return [deleteAction]
 
        /*
        let deleteAction = UITableViewRowAction(style: .default, title: "삭제") {
            (rowAction, indexPath) in
            
            guard let viewModel = self.viewModels?[self.segmentControl.selectedSegmentIndex],
                let deleteMail = viewModel.datas.value?[indexPath.row] else { return }
            
            self.unbindViewModel()
            viewModel.delete(mail: deleteMail, index: indexPath.row) { isSuccess in
                if isSuccess {
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                    self.handleNoResultLabel()
                    self.bindViewModel()
                }
            }
        }
        deleteAction.backgroundColor = .red
        return [deleteAction]
        */
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
    
    func scrollToTop(animated: Bool) {
        let yOffset = -tableView.contentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: true)
    }
}

extension MailBoxViewController {
    
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
        print("\(className) > \(#function) > notification : \(notification.name)")
        isNeedRefreshReceiveMail = true
        if segmentControl.selectedSegmentIndex == MailType.receive.rawValue {
            viewModels?[MailType.receive.rawValue]?.loadMailList()
        }
    }
    
    func handleAddSendMailNotification(_ notification: Notification) {
        print("\(className) > \(#function) > notification: \(notification.name)")
        isNeedRefreshSendMail = true
        if segmentControl.selectedSegmentIndex == MailType.send.rawValue {
            viewModels?[MailType.send.rawValue]?.loadMailList()
        }
    }
    
}
