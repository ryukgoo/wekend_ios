//
//  IntExtension.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2017. 12. 12..
//  Copyright © 2017년 Kim Young-wook. All rights reserved.
//

import Foundation

extension Int {
    var toAge: Int {
        let date = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date)
        let year = components.year!
        return year - self
    }
}
