//
//  STContact.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import Foundation

public struct STContact: Sendable, Hashable {
    public let identifier: String
    public let fullName: String
    public let phoneNumbers: [String]
}
