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
    public let isDebug: Bool
    public private(set) var appliedRules: [String] = []

    public init(isDebug: Bool = false) {
        self.isDebug = isDebug
    }

    public mutating func markApplied(_ rule: any STMarkdownRule) {
        self.markApplied(rule.name)
    }

    public mutating func markApplied(_ ruleName: String) {
        self.appliedRules.append(ruleName)
    }
}

enum STMarkdownRegexFactory {
    /// 编译一个**已知正确**的内置正则；失败视作开发期 bug，直接 trap。
    /// 仅供框架内部硬编码模式使用。
    static func compile(
        pattern: String,
        options: NSRegularExpression.Options = [],
        owner: String
    ) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern, options: options)
        } catch {
            fatalError("[STMarkdown] invalid regex for \(owner): \(pattern) — \(error)")
        }
    }

    /// 供动态/外部模式使用的安全编译入口。
    static func tryCompile(
        pattern: String,
        options: NSRegularExpression.Options = []
    ) throws -> NSRegularExpression {
        try NSRegularExpression(pattern: pattern, options: options)
    }
}

enum STMarkdownRegex {
    /// 匹配 `<a href="..."` / `<a href='...'`（含被 JSON 反斜线转义的 `\"`）形式的链接。
    /// - 容忍 `href` 之外的属性（如 `title`、`class`）。
    /// - 内容部分使用非贪婪 `.*?`，避免被嵌套标签吞掉边界；同时启用 `dotMatchesLineSeparators`
    ///   以支持跨行 anchor。
    static let htmlLink = STMarkdownRegexFactory.compile(
        pattern: #"<a\s+[^>]*?href\s*=\s*\\?["']([^"']+)\\?["'][^>]*>(.*?)</a>"#,
        options: [.caseInsensitive, .dotMatchesLineSeparators],
        owner: "STMarkdownRegex.htmlLink"
    )

    static let escaped2CRLF = STMarkdownRegexFactory.compile(pattern: #"\\\\r\\\\n"#, owner: "STMarkdownRegex.escaped2CRLF")
    static let escaped2LF = STMarkdownRegexFactory.compile(pattern: #"\\\\n(?![A-Za-z])"#, owner: "STMarkdownRegex.escaped2LF")
    static let escaped2CR = STMarkdownRegexFactory.compile(pattern: #"\\\\r(?![A-Za-z])"#, owner: "STMarkdownRegex.escaped2CR")
    static let escapedCRLF = STMarkdownRegexFactory.compile(pattern: #"\\r\\n"#, owner: "STMarkdownRegex.escapedCRLF")
    static let escapedLF = STMarkdownRegexFactory.compile(pattern: #"\\n(?![A-Za-z])"#, owner: "STMarkdownRegex.escapedLF")
    static let escapedCR = STMarkdownRegexFactory.compile(pattern: #"\\r(?![A-Za-z])"#, owner: "STMarkdownRegex.escapedCR")
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
            // 开启围栏：允许后续紧跟 info string（如 ```swift），不做校验。
            self.openFenceChar = first
            self.openFenceLength = runLength
            return
        }

        guard first == self.openFenceChar, runLength >= self.openFenceLength else { return }

        // 关闭围栏（CommonMark §4.5）：fence 字符之后只能是空白字符。
        let afterRun = trimmedLine.dropFirst(runLength)
        guard afterRun.allSatisfy({ $0 == " " || $0 == "\t" }) else { return }

        self.openFenceChar = nil
        self.openFenceLength = 0
    }
}
