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
        self.appliedRules.append(rule.name)
    }
}

enum STMarkdownRegexFactory {
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
}

enum STMarkdownRegex {
    static let htmlLink = STMarkdownRegexFactory.compile(
        pattern: #"<a\s+[^>]*href=\\?["']([^"']+)\\?["'][^>]*>([^<]+)</a>"#,
        options: .caseInsensitive,
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
