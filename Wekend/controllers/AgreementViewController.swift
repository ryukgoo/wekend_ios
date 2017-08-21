//
//  AgreementViewController.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 7. 24..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class AgreementViewController: UIViewController {
    
    @IBOutlet weak var textViewTermsOfUse: UITextView!
    @IBOutlet weak var textViewPrivacy: UITextView!
    @IBOutlet weak var checkBoxTermsOfUse: UIButton!
    @IBOutlet weak var checkBoxPrivacy: UIButton!
    @IBOutlet weak var buttonConfirm: UIButton!
    
    // TODO : handle checkBox -> All checked -> button enabled
    
    var delegate: AgreementDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textViewTermsOfUse.isScrollEnabled = false
        textViewPrivacy.isScrollEnabled = false
        
        checkBoxTermsOfUse.setImage(#imageLiteral(resourceName: "btn_checkbox_check"), for: .selected)
        checkBoxPrivacy.setImage(#imageLiteral(resourceName: "btn_checkbox_check"), for: .selected)
        
        buttonConfirm.setBackgroundImage(UIImage(color: UIColor(netHex: 0xdadada)), for: .disabled)
        buttonConfirm.isEnabled = false

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        textViewTermsOfUse.isScrollEnabled = true
        textViewPrivacy.isScrollEnabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onTermsOfUseTapped(_ sender: Any) {
        checkBoxTermsOfUse.isSelected = !checkBoxTermsOfUse.isSelected
        buttonConfirm.isEnabled = checkBoxTermsOfUse.isSelected && checkBoxPrivacy.isSelected
    }
    
    @IBAction func onPrivacyTapped(_ sender: Any) {
        checkBoxPrivacy.isSelected = !checkBoxPrivacy.isSelected
        buttonConfirm.isEnabled = checkBoxTermsOfUse.isSelected && checkBoxPrivacy.isSelected
    }
    
    @IBAction func onAgreeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: {
            self.delegate?.onAgreementTapped()
        })
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

protocol AgreementDelegate {
    func onAgreementTapped()
}
