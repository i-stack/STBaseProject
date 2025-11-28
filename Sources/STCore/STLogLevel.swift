//
//  STLogLevel.swift
//  STBaseProject
//
//  定义统一的日志级别，在 Core 层即可复用。
//

import UIKit

public enum STLogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case fatal = "FATAL"
    
    public var color: UIColor {
        switch self {
        case .debug: return .systemBlue
        case .info: return .systemGreen
        case .warning: return .systemOrange
        case .error: return .systemRed
        case .fatal: return .systemPurple
        }
    }
    
    public var icon: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fatal: return "💀"
        }
    }
}