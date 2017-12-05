//
//  UITableView+Reload.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 6. 5..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

extension UITableView {
    func reloadIndex(index: Int) {
        reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
}
