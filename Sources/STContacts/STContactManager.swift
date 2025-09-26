//
//  STContactManager.swift
//  STBaseProject
//
//  Created by song on 2025/1/19.
//

import Foundation
import Contacts

/// 联系人管理器 - 可选模块
public class STContactManager {
    
    /// 单例实例
    public static let shared = STContactManager()
    
    private init() {}
    
    /// 请求联系人权限
    /// - Parameter completion: 权限请求完成回调 (是否授权, 联系人列表, 错误信息)
    public func st_requestContactPermission(completion: @escaping (Bool, [CNContact], String) -> Void) {
        CNContactStore().requestAccess(for: .contacts) { (granted, error) in
            if granted {
                self.st_fetchContactInfo(completion: completion)
            } else {
                completion(false, [], "Access denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    /// 获取联系人信息
    /// - Parameter completion: 获取完成回调 (是否成功, 联系人列表, 错误信息)
    public func st_fetchContactInfo(completion: @escaping (Bool, [CNContact], String) -> Void) {
        let contactStore = CNContactStore()
        let keysDescriptor = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]
        
        do {
            let containers = try contactStore.containers(matching: nil)
            var allContacts: [CNContact] = []
            
            for container in containers {
                let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                let contacts = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysDescriptor)
                allContacts.append(contentsOf: contacts)
            }
            
            completion(true, allContacts, "")
        } catch {
            completion(false, [], "Failed to fetch contacts: \(error.localizedDescription)")
        }
    }
    
    /// 检查联系人权限状态
    /// - Returns: 权限状态
    public func st_checkContactPermission() -> CNAuthorizationStatus {
        return CNContactStore.authorizationStatus(for: .contacts)
    }
}
