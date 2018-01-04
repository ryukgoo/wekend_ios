//
//  CampaignTableViewCell.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 11. 22..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit

class CampaignTableViewCell: UITableViewCell {
    
    // MARK: Properties
    @IBOutlet weak var campaignTitle: UILabel!
    @IBOutlet weak var campaignDescription: UILabel!
    @IBOutlet weak var campaignImage: UIImageView!
    @IBOutlet weak var campaignImageProgress: UIActivityIndicatorView!
    @IBOutlet weak var campaignHeart: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        campaignHeart.setBackgroundImage(#imageLiteral(resourceName: "img_heart_n"), for: .normal)
        campaignHeart.setBackgroundImage(#imageLiteral(resourceName: "img_heart_s"), for: .selected)
        campaignHeart.setTitleColor(UIColor(netHex: Constants.ColorInfo.Text.Mail.DEFAULT), for: .normal)
        campaignHeart.setTitleColor(.white, for: .selected)
        campaignHeart.tintColor = .clear
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
