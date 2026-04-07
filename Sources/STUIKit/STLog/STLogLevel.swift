//
//  STLogLevel.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/10/10.
//

import UIKit

public enum STLogLevel: String, CaseIterable, Codable, Sendable, Comparable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case fatal = "FATAL"

    public static func < (lhs: STLogLevel, rhs: STLogLevel) -> Bool {
        lhs.priority < rhs.priority
    }

    public var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .fatal: return 4
        }
    }

    public var color: UIColor {
        switch self {
        case .debug: return .systemBlue
        case .info: return .systemGreen
        case .warning: return .systemOrange
        case .error: return .systemRed
        case .fatal: return .systemPink
        }
    }

    public var icon: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fatal: return "💥"
        }
    }

    public var systemImageName: String {
        switch self {
        case .debug: return "ladybug"
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.octagon"
        case .fatal: return "bolt.trianglebadge.exclamationmark"
        }
    }
}
