//
//  CampaignTableViewCell.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 11. 22..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit

class CampaignTableViewCell: UITableViewCell {
    
    var viewModel: CampaignCellViewModel? {
        didSet {
            bindViewModel()
        }
    }
    
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
    
    private func bindViewModel() {
        
        guard let productInfo = viewModel?.productInfo else { return }
        
        if let productRegion = productInfo.ProductRegion,
            let regionEnum = ProductRegion(rawValue: productRegion as! Int) {
            campaignTitle.text = "[\(regionEnum.toString)] " + productInfo.TitleKor!
        } else {
            campaignTitle.text = "[지역정보없음] \(productInfo.TitleKor!)"
        }
        
        campaignDescription.text = productInfo.SubTitle
        
        let imageName = String(productInfo.ProductId) + "/" + Configuration.S3.PRODUCT_IMAGE_NAME(0)
        let imageUrl = Configuration.S3.PRODUCT_IMAGE_URL + imageName
        
        campaignImage.sd_setImage(with: URL(string: imageUrl), placeholderImage: #imageLiteral(resourceName: "bg_default_logo_gray"), options: .refreshCached) {
            (image, error, cacheType, imageURL) in
        }
        
        campaignHeart.isSelected = viewModel?.isSelected ?? false
        campaignHeart.setTitle(String(productInfo.realLikeCount), for: .normal)
        campaignHeart.addTarget(self, action: #selector(self.heartButtonTapped(_:)), for: .touchUpInside)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func heartButtonTapped(_ sender: Any) {
        guard let productInfo = viewModel?.productInfo else { return }
        viewModel?.listener?(productInfo)
    }
}
