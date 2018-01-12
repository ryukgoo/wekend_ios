//
//  ViewModelProtocol.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 1. 12..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

protocol Alertable {
    var onShowAlert: ((ButtonAlert) -> Void)? { get set }
    var onShowMessage: (() -> Void)? { get set }
}

struct AlertAction {
    let buttonTitle: String
    let style: UIAlertActionStyle
    let handler: (() -> Void)?
    
    static let done = AlertAction(buttonTitle: "확인", style: .default, handler: nil)
    static let cancel = AlertAction(buttonTitle: "취소", style: .cancel, handler: nil)
}

struct ButtonAlert {
    let title: String?
    let message: String?
    let actions: [AlertAction]
}
