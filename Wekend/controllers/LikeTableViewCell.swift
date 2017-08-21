//
//  LikeTableViewCell.swift
//  Wekend
//
//  Created by Kim Young-wook on 2016. 12. 16..
//  Copyright © 2016년 Kim Young-wook. All rights reserved.
//

import UIKit
import KRWordWrapLabel

class LikeTableViewCell: UITableViewCell {

    // MARK: Properties
    
    @IBOutlet weak var likeImage: UIImageView!
    @IBOutlet weak var likeTitleLabel: KRWordWrapLabel!
    @IBOutlet weak var likeSubTitleLabel: UILabel!
    @IBOutlet weak var likeNewIcon: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
