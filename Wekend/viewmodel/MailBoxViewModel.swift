//
//  MailBoxViewModel.swift
//  Wekend
//
//  Created by Young-Wook Kim on 2018. 2. 2..
//  Copyright © 2018년 Kim Young-wook. All rights reserved.
//

import Foundation

struct MailBoxViewModel: MailListLoadable, MailDeletable {
    
    var datas: Dynamic<Array<Mail>?>
    var dataSource: MailDataSource
    
    init(dataSource: MailDataSource) {
        self.datas = Dynamic(nil)
        self.dataSource = dataSource
    }
    
    func loadMailList() {
        
        print(#function)
        
        dataSource.loadMails { result in
            if case let Result.success(object: value) = result {
                self.datas.value = value
            } else {
                self.datas.value = []
            }
        }
    }
    
    func delete(mail: Mail, index: Int, completion: @escaping (Bool) -> Void) {
        
        print(#function)
        
        dataSource.deleteMail(mail: mail) { success in
            if success {
                self.datas.value?.remove(at: index)
                DispatchQueue.main.async {
                    completion(true)
                }
            }
            completion(false)
        }
    }
}
