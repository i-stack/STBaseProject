//
//  STMarkdownInputSanitizer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public struct STHtmlNormalizeRule: STMarkdownRule {

    public let name = "STHtmlNormalizeRule"

    private static let brTagRegex = STMarkdownRegexFactory.compile(
        pattern: #"<br\s*/?>"#,
        options: [.caseInsensitive],
        owner: "STHtmlNormalizeRule.brTag"
    )

    public init() {}

    public func shouldApply(to text: String) -> Bool {
        text.contains("<") || text.contains("\\\"") || text.contains("\\/") || text.contains("\\n") || text.contains("\\r")
    }

    public func apply(to text: String, context: inout STMarkdownPreprocessContext) -> String {
        var result = text
        result = result.replacingOccurrences(of: "</>", with: "</a>")
        result = Self.brTagRegex.stringByReplacingMatches(
            in: result,
            range: NSRange(location: 0, length: result.utf16.count),
            withTemplate: "  \n"
        )
        // HTML entity decoding intentionally omitted here. Unconditionally rewriting
        // `&lt;`/`&gt;`/`&amp;` to raw characters before the CommonMark parser runs turns
        // plain-text snippets like `Use &lt;T&gt;` into `Use <T>`, which swift-markdown then
        // tries to parse as HTML inline — and the downstream `inlineNodes(from:)` path has no
        // handling for raw HTML, so the content silently vanishes. Let CommonMark handle
        // entity decoding per spec (6.2); any `<a>`-specific decoding belongs inside
        // STHtmlLinkToMarkdownRule on the captured title.
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

    private static let regex = STMarkdownRegexFactory.compile(
        pattern: "<a\\s+[^>]*href=\"#([^\"]*)\"[^>]*>[^<]*</a>",
        options: .caseInsensitive,
        owner: "STAnchorCleanupRule.regex"
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
        return patterns.map { pattern in
            STMarkdownRegexFactory.compile(
                pattern: pattern,
                options: .caseInsensitive,
                owner: "STPageReferenceCleanupRule.\(pattern.prefix(24))"
            )
        }
    }()

    private static let maxCleanupIterations = 5

    public init() {}

    public func shouldApply(to text: String) -> Bool {
        text.contains("webpage") || text.contains("网页") || text.contains("第") || text.contains("页")
    }

    public func apply(to text: String, context: inout STMarkdownPreprocessContext) -> String {
        var result = text
        var previous = ""
        var iterations = 0
        while result != previous {
            previous = result
            for regex in Self.cleanupRegexes {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(location: 0, length: result.utf16.count),
                    withTemplate: ""
                )
            }
            iterations += 1
            if iterations >= Self.maxCleanupIterations { break }
        }
        return result
    }
}

public struct STDoubleNewlineRule: STMarkdownRule {
    public let name = "STDoubleNewlineRule"

    private static let regex = STMarkdownRegexFactory.compile(
        pattern: #"\n{3,}"#,
        owner: "STDoubleNewlineRule.collapse"
    )

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

public struct STTableBlankLineNormalizationRule: STMarkdownRule {
    public let name = "STTableBlankLineNormalizationRule"

    public init() {}

    public func shouldApply(to text: String) -> Bool {
        text.contains("|")
    }

    public func apply(to text: String, context: inout STMarkdownPreprocessContext) -> String {
        let lines = text.components(separatedBy: "\n")
        var result: [String] = []
        result.reserveCapacity(lines.count + 8)
        var fenceState = STMarkdownCodeFenceState()

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let wasInsideFence = fenceState.isInside
            fenceState.ingest(trimmedLine: trimmed)

            if wasInsideFence || fenceState.isInside {
                result.append(line)
                continue
            }

            let isTableRow = trimmed.hasPrefix("|")
            let prevTrimmed = result.last?.trimmingCharacters(in: .whitespaces) ?? ""
            let isPrevBlank = prevTrimmed.isEmpty
            let isPrevTableRow = prevTrimmed.hasPrefix("|")

            if isTableRow && !result.isEmpty && !isPrevBlank && !isPrevTableRow {
                result.append("")
            }

            result.append(line)

            let nextIndex = index + 1
            if isTableRow && nextIndex < lines.count {
                let nextTrimmed = lines[nextIndex].trimmingCharacters(in: .whitespaces)
                if !nextTrimmed.isEmpty && !nextTrimmed.hasPrefix("|") && !nextTrimmed.hasPrefix("```") && !nextTrimmed.hasPrefix("~~~") {
                    result.append("")
                }
            }
        }

        return result.joined(separator: "\n")
    }
}

public struct STTableDelimiterNormalizationRule: STMarkdownRule {

    public let name = "STTableDelimiterNormalizationRule"

    private static let delimiterPattern = STMarkdownRegexFactory.compile(
        pattern: #"^\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$"#,
        owner: "STTableDelimiterNormalizationRule.delimiter"
    )

    public init() {}

    public func shouldApply(to text: String) -> Bool {
        text.contains("|")
    }

    public func apply(to text: String, context: inout STMarkdownPreprocessContext) -> String {
        let lines = text.components(separatedBy: "\n")
        var result: [String] = []
        result.reserveCapacity(lines.count + 4)
        var fenceState = STMarkdownCodeFenceState()

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let wasInsideFence = fenceState.isInside
            fenceState.ingest(trimmedLine: trimmed)

            result.append(line)

            guard !(wasInsideFence || fenceState.isInside), trimmed.hasPrefix("|") else { continue }

            // Previous line is considered "safe to treat this as a new table header" when it's blank,
            // not itself a table row, and not a code fence. This accepts LLM output that omits the
            // blank line before a table while still refusing to treat mid-paragraph `|`-lines as tables.
            let prevTrimmed = result.count >= 2
                ? result[result.count - 2].trimmingCharacters(in: .whitespaces)
                : ""
            if prevTrimmed.hasPrefix("|") || prevTrimmed.hasPrefix("```") || prevTrimmed.hasPrefix("~~~") {
                continue
            }

            // Look ahead: next line starts with | but is NOT a delimiter row → insert one
            let nextIndex = index + 1
            guard nextIndex < lines.count else { continue }
            let nextTrimmed = lines[nextIndex].trimmingCharacters(in: .whitespaces)
            guard nextTrimmed.hasPrefix("|"),
                  !Self.isDelimiterRow(nextTrimmed) else { continue }

            // Only synthesize a delimiter when BOTH rows look like table rows: at least 2
            // cells each and their column counts match. Without this guard, any pair of
            // consecutive lines that merely start with `|` (e.g. quoted prose, code samples
            // with a leading pipe) is rewritten into a table.
            let columnCount = Self.countColumns(in: trimmed)
            let nextColumnCount = Self.countColumns(in: nextTrimmed)
            guard columnCount >= 2, columnCount == nextColumnCount else { continue }
            let cells = (0..<columnCount).map { _ in " --- " }.joined(separator: "|")
            result.append("|\(cells)|")
        }

        return result.joined(separator: "\n")
    }

    private static func isDelimiterRow(_ line: String) -> Bool {
        let nsLine = line as NSString
        return Self.delimiterPattern.firstMatch(
            in: line,
            options: [],
            range: NSRange(location: 0, length: nsLine.length)
        ) != nil
    }

    private static func countColumns(in tableRow: String) -> Int {
        var stripped = tableRow
        if stripped.hasPrefix("|") { stripped = String(stripped.dropFirst()) }
        if stripped.hasSuffix("|") { stripped = String(stripped.dropLast()) }
        // Keep empty cells: `| a |  | b |` → 3 columns, not 2.
        return stripped.components(separatedBy: "|").count
    }
}

public struct STMarkdownInputSanitizer {
    public static let defaultRules: [any STMarkdownRule] = [
        STHtmlNormalizeRule(),
        STPageReferenceCleanupRule(),
        STAnchorCleanupRule(),
        STHtmlLinkToMarkdownRule(),
        STTableBlankLineNormalizationRule(),
        STTableDelimiterNormalizationRule(),
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
