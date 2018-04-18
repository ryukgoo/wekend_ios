//
//  FindAccountViewController.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 3. 2..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import UIKit

class FindAccountViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var button: RoundedButton!

    var viewModel: UserSearchViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        button.isEnabled = true

        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        navigationController?.isNavigationBarHidden = false
    }
    
    override func viewWillLayoutSubviews() {
        emailTextField.layer.addBorder(edge: .bottom, color: .white, thickness: 1.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func bindViewModel() {
        viewModel?.onSearchUsernameComplete = { [weak self] info in
            if let username = info.username {
                self?.gotoConfirmPhoneView(username: username)
            }
        }
        
        viewModel?.onSearchUsernameFailed = { [weak self] _ in
            let alert = ButtonAlert(title: "계정정보 찾기 실패", message: "입력하신 계정 정보를 찾을 수 없습니다", actions: [AlertAction.done])
            self?.showButtonAlert(alert)
        }
    }
    
    @IBAction func onButtonTapped(_ sender: Any) {
        print("\(className) > \(#function)")
        
        viewModel?.searchUser(username: emailTextField.text)
    }
    
    func gotoConfirmPhoneView(username: String) {
        guard let phoneVC = ConfirmPhoneViewController.storyboardInstance(from: "Login") as? ConfirmPhoneViewController else {
            return
        }
        phoneVC.viewModel = InsertPhoneViewModel(userDataSource: UserInfoRepository.shared)
        phoneVC.confirmPhoneModel = UserSearchViewModel(userDataSource: UserInfoRepository.shared)
        phoneVC.registedUsername = username
        navigationController?.pushViewController(phoneVC, animated: true)
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
