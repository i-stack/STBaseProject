//
//  STContactPermissionStatus.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import Contacts

public enum STContactPermissionStatus: Sendable {
    case notDetermined
    case restricted
    case denied
    case authorized
}

extension STContactPermissionStatus {
    init(_ rawStatus: CNAuthorizationStatus) {
        switch rawStatus {
        case .notDetermined: self = .notDetermined
        case .restricted:    self = .restricted
        case .denied:        self = .denied
        case .authorized:    self = .authorized
        @unknown default:    self = .notDetermined
        }
    }
}
