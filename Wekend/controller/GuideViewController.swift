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
    var helpArray: [UIImage] = []
    
    @IBOutlet weak var pagerView: PagerView!
    @IBOutlet weak var checkBox: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var noMoreShowText: UIButton!
    @IBOutlet weak var overlayBackground: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(className) > \(#function)")
        
        helpArray = [#imageLiteral(resourceName: "Help_06"), #imageLiteral(resourceName: "Help_01"), #imageLiteral(resourceName: "Help_00"), #imageLiteral(resourceName: "Help_02"), #imageLiteral(resourceName: "Help_03"), #imageLiteral(resourceName: "Help_04"), #imageLiteral(resourceName: "Help_05")]
        
        checkBox.isHidden = !isShowButtons
        noMoreShowText.isHidden = !isShowButtons
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.overlayBackground.alpha = 0.5
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        initView()
    }
    
    private func initView() {
        print("\(className) > \(#function)")
        
        pagerView.delegate = self
        pagerView.pageCount = helpArray.count
    }
    
    @IBAction func onCheckBoxTapped(_ sender: Any) {
        UserDefaults.Account.set(true, forKey: .noMoreGuide)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onCloseButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension GuideViewController: PagerViewDelegate {
    func loadPageViewItem(imageView: UIImageView, page: Int) {
//        if let image = UIImage(named: "Help_0" + page.description) {
//            imageView.backgroundColor = UIColor.clear
//            imageView.contentMode = .scaleAspectFit
//            imageView.image = image
//        }
        
        imageView.backgroundColor = UIColor.clear
        imageView.contentMode = .scaleAspectFit
        imageView.image = helpArray[page]
    }
    
    func onPageTapped(page: Int) { }
}
