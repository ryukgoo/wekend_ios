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

    @IBOutlet weak var mailImage: UIImageView!
    @IBOutlet weak var mailTitle: KRWordWrapLabel!
    @IBOutlet weak var mailDate: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
