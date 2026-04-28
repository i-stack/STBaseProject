//
//  STContactError.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import Foundation

public enum STContactError: Error {
    case permissionDenied
    case fetchFailed(Error)
}

extension STContactError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return NSLocalizedString("st_contacts.error.permission_denied", comment: "")
        case .fetchFailed(let underlying):
            return underlying.localizedDescription
        }
    }
}
