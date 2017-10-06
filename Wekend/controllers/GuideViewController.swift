//
//  GuideViewController.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 9. 14..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class GuideViewController: UIViewController {
    
    var isShowButtons = true
    
    @IBOutlet weak var pagerView: PagerView!
    @IBOutlet weak var checkBox: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var noMoreShowText: UIButton!
    @IBOutlet weak var overlayBackground: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        printLog("GuideViewController > viewDidLoad")
        initView()
        // Do any additional setup after loading the view.
        
        checkBox.isHidden = !isShowButtons
        noMoreShowText.isHidden = !isShowButtons
        
        UIView.animate(withDuration: 0.3, animations: {
            self.overlayBackground.alpha = 0.5
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func initView() {
        printLog(#function)
        
        pagerView.delegate = self
        pagerView.pageCount = 6
    }
    
    @IBAction func onCheckBoxTapped(_ sender: Any) {
        UserDefaults.Account.set(true, forKey: .isNoMoreGuide)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onCloseButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension GuideViewController: PagerViewDelegate {
    func loadPageViewItem(imageView: UIImageView, page: Int) {
        if let image = UIImage(named: "Help_0" + page.description) {
            imageView.image = image
            imageView.backgroundColor = UIColor.clear
            imageView.contentMode = .scaleAspectFit
        }
    }
    
    func onPageTapped(page: Int) {
        
    }
}
