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
    case limited
    case authorized
}

extension STContactPermissionStatus {
    public init(_ rawStatus: CNAuthorizationStatus) {
        switch rawStatus {
        case .notDetermined: self = .notDetermined
        case .restricted:    self = .restricted
        case .denied:        self = .denied
        case .limited:       self = .limited
        case .authorized:    self = .authorized
        @unknown default:    self = .denied
        }
    }
}
