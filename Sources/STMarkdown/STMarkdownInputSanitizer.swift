//
//  STMarkdownInputSanitizer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public struct STHtmlNormalizeRule: STMarkdownRule {
    
    public let name = "STHtmlNormalizeRule"

    public init() {}

    public func shouldApply(to text: String) -> Bool {
        text.contains("<") || text.contains("\\\"") || text.contains("\\/") || text.contains("\\n") || text.contains("\\r")
    }

    public func apply(to text: String, context: inout STMarkdownPreprocessContext) -> String {
        var result = text
        result = result.replacingOccurrences(of: "</>", with: "</a>")
        result = result.replacingOccurrences(of: "<br>", with: "")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = STMarkdownRegex.escaped2CRLF.stringByReplacingMatches(
            in: result,
            range: NSRange(location: 0, length: result.utf16.count),
            withTemplate: "\n"
        )
        result = STMarkdownRegex.escaped2LF.stringByReplacingMatches(
            in: result,
            range: NSRange(location: 0, length: result.utf16.count),
            withTemplate: "\n"
        )
        result = STMarkdownRegex.escaped2CR.stringByReplacingMatches(
            in: result,
            range: NSRange(location: 0, length: result.utf16.count),
            withTemplate: "\n"
        )
        result = STMarkdownRegex.escapedCRLF.stringByReplacingMatches(
            in: result,
            range: NSRange(location: 0, length: result.utf16.count),
            withTemplate: "\n"
        )
        result = STMarkdownRegex.escapedLF.stringByReplacingMatches(
            in: result,
            range: NSRange(location: 0, length: result.utf16.count),
            withTemplate: "\n"
        )
        result = STMarkdownRegex.escapedCR.stringByReplacingMatches(
            in: result,
            range: NSRange(location: 0, length: result.utf16.count),
            withTemplate: "\n"
        )
        result = result.replacingOccurrences(of: "\\\"", with: "\"")
        result = result.replacingOccurrences(of: "\\'", with: "'")
        result = result.replacingOccurrences(of: "\\/", with: "/")
        return result
    }
}

public struct STHtmlLinkToMarkdownRule: STMarkdownRule {
    public let name = "STHtmlLinkToMarkdownRule"

    public init() {}

    public func shouldApply(to text: String) -> Bool {
        text.contains("<a ")
    }

    public func apply(to text: String, context: inout STMarkdownPreprocessContext) -> String {
        var result = text
        let matches = STMarkdownRegex.htmlLink.matches(
            in: result,
            range: NSRange(location: 0, length: result.utf16.count)
        )

        for match in matches.reversed() {
            guard match.numberOfRanges == 3,
                  let urlRange = Range(match.range(at: 1), in: result),
                  let titleRange = Range(match.range(at: 2), in: result) else {
                continue
            }

            let url = String(result[urlRange])
            let title = String(result[titleRange])

            guard let parsedURL = URL(string: url),
                  let scheme = parsedURL.scheme?.lowercased(),
                  ["http", "https"].contains(scheme),
                  parsedURL.host != nil else {
                result = (result as NSString).replacingCharacters(in: match.range, with: title)
                continue
            }

            result = (result as NSString).replacingCharacters(
                in: match.range,
                with: "[\(title)](\(url))"
            )
        }

        return result
    }
}

public struct STAnchorCleanupRule: STMarkdownRule {
    public let name = "STAnchorCleanupRule"

    private static let regex = try! NSRegularExpression(
        pattern: "<a\\s+[^>]*href=\"#([^\"]*)\"[^>]*>[^<]*</a>",
        options: .caseInsensitive
    )

    public init() {}

    public func shouldApply(to text: String) -> Bool {
        text.contains("href=\"#")
    }

    public func apply(to text: String, context: inout STMarkdownPreprocessContext) -> String {
        var result = text
        let nsText = result as NSString
        let matches = Self.regex.matches(
            in: result,
            options: [],
            range: NSRange(location: 0, length: nsText.length)
        )

        for match in matches.reversed() {
            let full = nsText.substring(with: match.range)
            guard let hashIndex = full.firstIndex(of: "#") else { continue }
            let suffix = String(full[hashIndex...])
            if suffix.lowercased().contains("http") == false {
                result = (result as NSString).replacingCharacters(in: match.range, with: "")
            }
        }

        return result
    }
}

public struct STPageReferenceCleanupRule: STMarkdownRule {
    public let name = "STPageReferenceCleanupRule"

    private static let cleanupRegexes: [NSRegularExpression] = {
        let patterns: [String] = [
            #"[（(]\s*\[(?:第\d+页|页面\d+|\d+页|P\d+|引用网页\d+|参考\d+|见\d+页|网页\d+|webpage\s+\d+)\]\(#[^)]*\)\s*[）)]"#,
            #"\[\s*\[(?:第\d+页|页面\d+|\d+页|P\d+|引用网页\d+|参考\d+|见\d+页|网页\d+|webpage\s+\d+)\]\(#[^)]*\)\s*\]"#,
            #"[【《「『]\s*\[(?:第\d+页|页面\d+|\d+页|P\d+|引用网页\d+|参考\d+|见\d+页|网页\d+|webpage\s+\d+)\]\(#[^)]*\)\s*[】》」』]"#,
            #"\[(?:第\d+页|页面\d+|\d+页|P\d+|引用网页\d+|参考\d+|见\d+页|网页\d+|webpage\s+\d+)\]\(#[^)]*\)"#,
            #"\[webpage\s+\d+\]"#,
            #"[（(]\s*\[webpage\s+\d+\]\s*[）)]"#,
            #"\[\s*\[webpage\s+\d+\]\s*\]"#,
            #"[【《「『]\s*\[webpage\s+\d+\]\s*[】》」』]"#,
        ]
        return patterns.compactMap { try? NSRegularExpression(pattern: $0, options: .caseInsensitive) }
    }()

    public init() {}

    public func shouldApply(to text: String) -> Bool {
        text.contains("webpage") || text.contains("网页") || text.contains("第") || text.contains("页")
    }

    public func apply(to text: String, context: inout STMarkdownPreprocessContext) -> String {
        var result = text
        var previous = ""
        while result != previous {
            previous = result
            for regex in Self.cleanupRegexes {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(location: 0, length: result.utf16.count),
                    withTemplate: ""
                )
            }
        }
        return result
    }
}

public struct STDoubleNewlineRule: STMarkdownRule {
    public let name = "STDoubleNewlineRule"

    private static let regex = try! NSRegularExpression(pattern: #"\n{3,}"#, options: [])

    public init() {}

    public func shouldApply(to text: String) -> Bool {
        text.contains("\n\n\n")
    }

    public func apply(to text: String, context: inout STMarkdownPreprocessContext) -> String {
        Self.regex.stringByReplacingMatches(
            in: text,
            range: NSRange(location: 0, length: text.utf16.count),
            withTemplate: "\n\n"
        )
    }
}

public struct STMarkdownInputSanitizer {
    public static let defaultRules: [any STMarkdownRule] = [
        STHtmlNormalizeRule(),
        STPageReferenceCleanupRule(),
        STAnchorCleanupRule(),
        STHtmlLinkToMarkdownRule(),
        STDoubleNewlineRule(),
    ]

    public let rules: [any STMarkdownRule]

    public init(rules: [any STMarkdownRule] = Self.defaultRules) {
        self.rules = rules
    }

    public func sanitize(
        _ text: String,
        debug: Bool = false
    ) -> STMarkdownSanitizationResult {
        guard text.isEmpty == false else {
            return STMarkdownSanitizationResult(
                originalText: text,
                sanitizedText: text,
                appliedRules: []
            )
        }

        var context = STMarkdownPreprocessContext(isDebug: debug)
        var result = text
        for rule in self.rules {
            guard rule.shouldApply(to: result) else { continue }
            let updated = rule.apply(to: result, context: &context)
            if updated != result {
                context.markApplied(rule)
                result = updated
            }
        }

        return STMarkdownSanitizationResult(
            originalText: text,
            sanitizedText: result,
            appliedRules: context.appliedRules
        )
    }
}

public struct STMarkdownSanitizationResult: Sendable {
    public let originalText: String
    public let sanitizedText: String
    public let appliedRules: [String]

    public init(
        originalText: String,
        sanitizedText: String,
        appliedRules: [String]
    ) {
        self.originalText = originalText
        self.sanitizedText = sanitizedText
        self.appliedRules = appliedRules
    }
}
