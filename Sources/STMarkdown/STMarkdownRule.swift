//
//  STMarkdownRule.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public protocol STMarkdownRule {
    var name: String { get }

    func shouldApply(to text: String) -> Bool

    func apply(to text: String, context: inout STMarkdownPreprocessContext) -> String
}

public struct STMarkdownPreprocessContext {
    public let isDebug: Bool
    public private(set) var appliedRules: [String] = []

    public init(isDebug: Bool = false) {
        self.isDebug = isDebug
    }

    public mutating func markApplied(_ rule: any STMarkdownRule) {
        self.appliedRules.append(rule.name)
    }
}

enum STMarkdownRegex {
    static let htmlLink = try! NSRegularExpression(
        pattern: #"<a\s+[^>]*href=\\?["']([^"']+)\\?["'][^>]*>([^<]+)</a>"#,
        options: .caseInsensitive
    )

    static let escaped2CRLF = try! NSRegularExpression(pattern: #"\\\\r\\\\n"#)
    static let escaped2LF = try! NSRegularExpression(pattern: #"\\\\n(?![A-Za-z])"#)
    static let escaped2CR = try! NSRegularExpression(pattern: #"\\\\r(?![A-Za-z])"#)
    static let escapedCRLF = try! NSRegularExpression(pattern: #"\\r\\n"#)
    static let escapedLF = try! NSRegularExpression(pattern: #"\\n(?![A-Za-z])"#)
    static let escapedCR = try! NSRegularExpression(pattern: #"\\r(?![A-Za-z])"#)
}
