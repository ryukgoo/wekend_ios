//
//  DrawerMenuTableViewCell.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 16..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class DrawerMenuTableViewCell: UITableViewCell {

    // MARK: IBOutlet
    
    @IBOutlet weak var menuImageView: UIImageView!
    @IBOutlet weak var menuLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
