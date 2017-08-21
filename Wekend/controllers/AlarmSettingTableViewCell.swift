//
//  AlarmSettingTableViewCell.swift
//  Wekend
//
//  Created by Kim Young-wook on 2017. 1. 19..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import UIKit

class AlarmSettingTableViewCell: UITableViewCell {

    // MARK: IBOutlet
    @IBOutlet weak var alarmTitle: UILabel!
    @IBOutlet weak var alarmSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
