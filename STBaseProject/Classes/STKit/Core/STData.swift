//
//  STData.swift
//  STBaseProject
//
//  Created by song on 2019/1/21.
//

import Foundation

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
