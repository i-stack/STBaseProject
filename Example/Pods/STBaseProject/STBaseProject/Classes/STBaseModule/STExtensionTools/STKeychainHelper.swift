//
//  STKeychainHelper.swift
//  STBaseProject
//
//  Created by song on 2022/1/15.
//

import UIKit
import Security

public class STKeychainHelper {
    
    private static let service = Bundle.main.bundleIdentifier ?? "com.STBaseProject.app"
    
    public static func st_save(_ key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    public static func st_load(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == noErr,
           let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
