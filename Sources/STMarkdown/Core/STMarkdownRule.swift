//
//  STMarkdownRule.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public protocol STMarkdownRule: Sendable {
    var name: String { get }
    func shouldApply(to text: String) -> Bool
    func apply(to text: String, context: inout STMarkdownPreprocessContext) -> String
}

public struct STMarkdownPreprocessContext: Sendable {
    public let debugMode: STMarkdownDebugMode
    public private(set) var appliedRules: [String] = []

    public init(debugMode: STMarkdownDebugMode = .disabled) {
        self.debugMode = debugMode
    }

    public mutating func markApplied(_ rule: any STMarkdownRule) {
        self.markApplied(rule.name)
    }

    public mutating func markApplied(_ ruleName: String) {
        self.appliedRules.append(ruleName)
    }
}

/// Toggle for verbose diagnostics during markdown preprocessing.
public enum STMarkdownDebugMode: Sendable, Equatable {
    case enabled
    case disabled

    public var isEnabled: Bool { self == .enabled }
}

public enum STMarkdownRegexFactory {
    /// 编译一个**已知正确**的内置正则；失败视作开发期 bug，直接 trap。
    /// 仅供框架内部硬编码模式使用。
    public static func compile(pattern: String, options: NSRegularExpression.Options = [], owner: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern, options: options)
        } catch {
            fatalError("[STMarkdown] invalid regex for \(owner): \(pattern) — \(error)")
        }
    }

    /// 供动态/外部模式使用的安全编译入口。
    public static func tryCompile( pattern: String, options: NSRegularExpression.Options = []) throws -> NSRegularExpression {
        try NSRegularExpression(pattern: pattern, options: options)
    }
}

struct STMarkdownCodeFenceState {
    private var openFenceChar: Character?
    private var openFenceLength: Int = 0

    var isInside: Bool { self.openFenceChar != nil }

    mutating func ingest(trimmedLine: String) {
        guard let first = trimmedLine.first, first == "`" || first == "~" else { return }
        let runLength = trimmedLine.prefix { $0 == first }.count
        guard runLength >= 3 else { return }
        if self.openFenceChar == nil {
            self.openFenceChar = first
            self.openFenceLength = runLength
            return
        }
        guard first == self.openFenceChar, runLength >= self.openFenceLength else { return }
        let afterRun = trimmedLine.dropFirst(runLength)
        guard afterRun.allSatisfy({ $0 == " " || $0 == "\t" }) else { return }
        self.openFenceChar = nil
        self.openFenceLength = 0
    }
}
