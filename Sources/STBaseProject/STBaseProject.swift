//
//  STBaseProject.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import Foundation

// MARK: - 导出所有模块
@_exported import STBaseModule
@_exported import STKitLocation
@_exported import STKitScan
@_exported import STKitMedia
@_exported import STKitDialog

// MARK: - 版本信息
public struct STBaseProjectInfo {
    public static let version = "2.0.0"
    public static let name = "STBaseProject"
    public static let description = "A powerful iOS base project with modular architecture and rich UI components."
}

// MARK: - 便捷访问
public extension STBaseProjectInfo {
    /// 获取所有可用模块
    static var availableModules: [String] {
        return [
            "STBaseModule",
            "STKitLocation", 
            "STKitScan",
            "STKitMedia",
            "STKitDialog"
        ]
    }
}
