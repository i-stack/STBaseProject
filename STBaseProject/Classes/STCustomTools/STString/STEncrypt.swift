//
//  STEncrypt.swift
//  STBaseProject
//
//  Created by stack on 2018/12/22.
//

import Foundation
import CryptoKit

public extension String {
    static func st_sha256Hash(for input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
