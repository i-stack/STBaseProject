//
//  STContactServiceProtocol.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import Foundation

public protocol STContactServiceProtocol {
    var permissionStatus: STContactPermissionStatus { get }
    func requestPermissionAndFetch() async throws -> [STContact]
}
