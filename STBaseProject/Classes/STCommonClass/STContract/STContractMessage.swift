//
//  STContractMessage.swift
//  STBaseProject
//
//  Created by song on 2018/7/24.
//  Copyright © 2019 song. All rights reserved.
//

import UIKit

class STContractMessage: NSObject {
    
    var note: String? // 备注
    var phone: String? // 电话
    var email: String? // email
    var address: String? // 地址
    var service: String? // 即时通讯(IM)
    var birthday: String? // 生日
    var jobTitle: String? // 职位
    var nickName: String? // 昵称
    var department: String? // 部门
    var contractName: String? // 姓名
    var organization: String? // 公司（组织）

    @objc var name: String {
        get {
            var newName: String = ""
            if let contract = contractName, contract.count > 0 {
                newName = contract
            } else if let nick = nickName, nick.count > 0 {
                newName = nick
            } else if let org = organization, org.count > 0 {
                newName = org
            }
            return newName
        }
    }
    
    override init() {
        super.init()
    }
}
