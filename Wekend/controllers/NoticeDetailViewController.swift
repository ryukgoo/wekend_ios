//
//  NoticeDetailViewController.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 17..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit
import KRWordWrapLabel

class NoticeDetailViewController: UIViewController {

    // MARK: -Properties
    var notice: Notice?
    
    // MARK: IBOutlet
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var beforeButton: UIButton!
    @IBOutlet weak var detailTitleLabel: KRWordWrapLabel!
    @IBOutlet weak var descriptionLabel: KRWordWrapLabel!
    @IBOutlet weak var containerViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        refreshViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func refreshViews() {
        
        guard let notice = self.notice else {
            return
        }
        
        detailTitleLabel.text = notice.title
        descriptionLabel.text = notice.content
        
        detailTitleLabel.sizeToFit()
        descriptionLabel.sizeToFit()
        
        var scrollableHeight = beforeButton.frame.height
        scrollableHeight += 28
        scrollableHeight += detailTitleLabel.frame.height
        scrollableHeight += 17
        scrollableHeight += descriptionLabel.frame.height
        scrollableHeight += 20
        
        containerViewHeight.constant = scrollableHeight
    }
    
    // MARK: IBAction
    
    @IBAction func onBeforeButtonTapped(_ sender: Any) {
        
        guard let _ = self.navigationController?.popViewController(animated: true) else {
            fatalError("NoticeDetailViewController > onBeforeButtonTapped > popViewController Error")
        }
    }
}
