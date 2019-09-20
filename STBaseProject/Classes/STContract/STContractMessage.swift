//
//  STContractMessage.swift
//  STBaseProject
//
//  Created by song on 2018/7/24.
//  Copyright © 2018 song. All rights reserved.
//

import UIKit

open class STContractMessage: NSObject {
    
    open var note: String? // 备注
    open var phone: String? // 电话
    open var email: String? // email
    open var address: String? // 地址
    open var service: String? // 即时通讯(IM)
    open var birthday: String? // 生日
    open var jobTitle: String? // 职位
    open var nickName: String? // 昵称
    open var department: String? // 部门
    open var contractName: String? // 姓名
    open var organization: String? // 公司（组织）

    @objc open var name: String {
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
}
