//
//  NoticeTableViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 17..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class NoticeTableViewController: UITableViewController {

    var noticeType: String?
    var datas: Array<Notice>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView?.contentInset = UIEdgeInsetsMake(12, 0, 0, 0)
        
        print("\(className) > \(#function) > noticeType : \(String(describing: noticeType))")
        
        if noticeType == "Notice" {
            
            self.title = "공지사항"
            
            SettingViewModel.sharedInstance.loadHelps().continueWith(block: {
                (task: AWSTask) -> Any? in
                
                guard let result = task.result else {
                    self.tableView.reloadData()
                    return nil
                }
                
                self.datas = result as? Array<Notice>
                self.tableView.reloadData()
                
                return nil
            })
        } else if noticeType == "Help" {
            
            self.title = "도움말"
            
            SettingViewModel.sharedInstance.loadHelps().continueWith(block: {
                (task: AWSTask) -> Any? in
                
                guard let result = task.result else {
                    self.tableView.reloadData()
                    return nil
                }
                
                self.datas = result as? Array<Notice>
                self.tableView.reloadData()
                
                return nil
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let count = datas?.count else {
            return 0
        }
        
        return count
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(for: indexPath) as NoticeTableViewCell
        
        guard let notice = datas?[indexPath.row] else {
            print("\(className) > \(#function) > notice is nil")
            return cell
        }
        
        cell.titleLabel.text = notice.title
        cell.subTitleLabel.text = notice.content

        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let noticeDetailViewController = segue.destination as? NoticeDetailViewController else {
            return
        }
        
        guard let selectedCell = sender as? NoticeTableViewCell else {
            return
        }
        
        guard let indexPath = tableView.indexPath(for: selectedCell) else {
            return
        }
        
        guard let selectedNotice = datas?[indexPath.row] else {
            return
        }
        
        noticeDetailViewController.notice = selectedNotice
    }

}
