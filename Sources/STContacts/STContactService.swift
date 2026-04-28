//
//  STContactService.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import Foundation
@preconcurrency import Contacts

public final class STContactService {

    public static let shared = STContactService()

    public init() {}

    public var permissionStatus: STContactPermissionStatus {
        STContactPermissionStatus(CNContactStore.authorizationStatus(for: .contacts))
    }

    public func requestPermissionAndFetch() async throws -> [STContact] {
        try await self.requestPermission()
        return try await self.fetchContacts()
    }

    private lazy var contactStore = CNContactStore()
    private lazy var keysToFetch: [CNKeyDescriptor] = [
        CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
        CNContactPhoneNumbersKey as CNKeyDescriptor
    ]
}

// MARK: - STContactServiceProtocol
extension STContactService: STContactServiceProtocol {}

// MARK: - Private
private extension STContactService {

    func requestPermission() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.contactStore.requestAccess(for: .contacts) { granted, _ in
                if granted {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: STContactError.permissionDenied)
                }
            }
        }
    }

    func fetchContacts() async throws -> [STContact] {
        let store = self.contactStore
        let keys = self.keysToFetch
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let containers = try store.containers(matching: nil)
                    var rawContacts: [CNContact] = []
                    for container in containers {
                        let predicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                        let batch = try store.unifiedContacts(matching: predicate, keysToFetch: keys)
                        rawContacts.append(contentsOf: batch)
                    }
                    let contacts = rawContacts.map { STContact(contact: $0) }
                    continuation.resume(returning: contacts)
                } catch {
                    continuation.resume(throwing: STContactError.fetchFailed(error))
                }
            }
        }
    }
}

// MARK: - CNContact Mapping
private extension STContact {
    init(contact: CNContact) {
        self.identifier = contact.identifier
        self.fullName = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
        self.phoneNumbers = contact.phoneNumbers.map { $0.value.stringValue }
    }
}
