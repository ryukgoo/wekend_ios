//
//  MailTableViewCell.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 19..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit
import KRWordWrapLabel

class MailTableViewCell: UITableViewCell {

    var viewModel: MailBoxCellViewModel? {
        didSet {
            bindViewModel()
        }
    }
    
    @IBOutlet weak var mailImage: UIImageView!
    @IBOutlet weak var mailTitle: KRWordWrapLabel!
    @IBOutlet weak var mailDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    private func bindViewModel() {
        guard let viewModel = viewModel else { return }
        guard let user = viewModel.user else { return }
        guard let mail = viewModel.mail else { return }
        
        let defaultImage: UIImage
        if user.gender != UserInfo.RawValue.GENDER_MALE {
            defaultImage = #imageLiteral(resourceName: "img_bg_thumb_s_default_male")
        } else {
            defaultImage = #imageLiteral(resourceName: "img_bg_thumb_s_default_Female")
        }
        
        let imageName = "\(mail.FriendId!)/\(Configuration.S3.PROFILE_IMAGE_NAME(0))"
        let imageUrl = Configuration.S3.PROFILE_THUMB_URL + imageName
        
        mailImage.sd_setImage(with: URL(string: imageUrl), placeholderImage: defaultImage, options: .cacheMemoryOnly) {
            (image, error, cacheType, imageURL) in
            
        }
        mailImage.toMask(mask: #imageLiteral(resourceName: "img_bg_thumb_s_2"))
        
        guard let status = ProposeStatus(rawValue: mail.ProposeStatus!) else { return }
        mailTitle.text = "\(mail.FriendNickname ?? "")\(getMailTitle(type: mail.mailType, status: status))"
        
        switch status {
        case .notMade:
            mailTitle.textColor = mail.highlightColor
        default:
            mailTitle.textColor = UIColor(netHex: Constants.ColorInfo.Text.Mail.DEFAULT)
        }
        
        mailDate.text = "\(Constants.Title.Cell.DATE) : \(Utilities.getDateFromTimeStamp(timestamp: mail.UpdatedTime))"
    }
    
    private func getMailTitle(type: MailType, status: ProposeStatus) -> String {
        switch status {
        case .notMade:
            if type == .send { return Constants.Title.Cell.SEND_NOT_MADE }
            else { return Constants.Title.Cell.RECEIVE_NOT_MADE }
        case .made, .alreadyMade:
            return Constants.Title.Cell.MADE
        case .reject:
            if type == .send { return Constants.Title.Cell.SEND_REJECT }
            else { return Constants.Title.Cell.RECEIVE_REJECT }
        default:
            return ""
        }
    }
}
