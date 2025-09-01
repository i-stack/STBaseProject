//
//  STData.swift
//  STBaseProject
//
//  Created by song on 2019/1/21.
//

import Foundation

public extension Dictionary {
    func st_urlEncodedToString() -> String {
        self.map { key, value in
            let encodedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
            let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
            return "\(encodedKey)=\(encodedValue)"
        }
        .joined(separator: "&")
    }
    
    func st_urlEncodedToData() -> Data? {
        return st_urlEncodedToString().data(using: .utf8)
    }
}
