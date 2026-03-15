//
//  STMarkdownMathNormalizer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public struct STMarkdownMathNormalizationResult {
    public let text: String
    public let blockMap: [Int: String]

    public init(text: String, blockMap: [Int: String]) {
        self.text = text
        self.blockMap = blockMap
    }
}

enum STMarkdownMathNormalizer {
    private static let mathBlockEnvironmentRegex = try! NSRegularExpression(
        pattern: #"^\\begin\{([^}]+)\}"#,
        options: []
    )

    static func normalizeBlocks(in markdown: String) -> STMarkdownMathNormalizationResult {
        var normalized = normalizeDelimiters(in: markdown)
        var mathMap: [Int: String] = [:]
        var output: [String] = []
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var index = 0
        var inCodeBlock = false
        var codeFence = ""

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                output.append(line)
                if inCodeBlock == false {
                    inCodeBlock = true
                    codeFence = String(trimmed.prefix(3))
                } else if trimmed.hasPrefix(codeFence) {
                    inCodeBlock = false
                }
                index += 1
                continue
            }

            if inCodeBlock {
                output.append(line)
                index += 1
                continue
            }

            if trimmed.hasPrefix("$$") {
                let result = consumeDollarMathBlock(from: lines, start: index)
                let currentIndex = mathMap.count
                mathMap[currentIndex] = result.content.trimmingCharacters(in: .whitespacesAndNewlines)
                output.append("")
                output.append("{{ST_MATH_BLOCK:\(currentIndex)}}")
                output.append("")
                index = result.nextIndex
                continue
            }

            if trimmed.hasPrefix(#"\["#) {
                let result = consumeBracketMathBlock(from: lines, start: index)
                let currentIndex = mathMap.count
                mathMap[currentIndex] = result.content.trimmingCharacters(in: .whitespacesAndNewlines)
                output.append("")
                output.append("{{ST_MATH_BLOCK:\(currentIndex)}}")
                output.append("")
                index = result.nextIndex
                continue
            }

            if let environment = environmentName(from: trimmed) {
                let result = consumeEnvironmentMathBlock(
                    from: lines,
                    start: index,
                    environment: environment
                )
                let currentIndex = mathMap.count
                mathMap[currentIndex] = result.content.trimmingCharacters(in: .whitespacesAndNewlines)
                output.append("")
                output.append("{{ST_MATH_BLOCK:\(currentIndex)}}")
                output.append("")
                index = result.nextIndex
                continue
            }

            output.append(line)
            index += 1
        }

        normalized = output.joined(separator: "\n")
        normalized = normalized.replacingOccurrences(of: #"\("#, with: "⦅ST_LATEX_PAREN_OPEN⦆")
        normalized = normalized.replacingOccurrences(of: #"\)"#, with: "⦅ST_LATEX_PAREN_CLOSE⦆")
        normalized = normalized.replacingOccurrences(of: #"\["#, with: "⦅ST_LATEX_BRACKET_OPEN⦆")
        normalized = normalized.replacingOccurrences(of: #"\]"#, with: "⦅ST_LATEX_BRACKET_CLOSE⦆")

        return STMarkdownMathNormalizationResult(text: normalized, blockMap: mathMap)
    }

    static func normalizeDelimiters(in text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: #"\\("#, with: #"\("#)
        result = result.replacingOccurrences(of: #"\\)"#, with: #"\)"#)
        result = result.replacingOccurrences(of: #"\\["#, with: #"\["#)
        result = result.replacingOccurrences(of: #"\\]"#, with: #"\]"#)
        return result
    }

    static func restoreInlineDelimiters(in text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "⦅ST_LATEX_PAREN_OPEN⦆", with: #"\("#)
        result = result.replacingOccurrences(of: "⦅ST_LATEX_PAREN_CLOSE⦆", with: #"\)"#)
        result = result.replacingOccurrences(of: "⦅ST_LATEX_BRACKET_OPEN⦆", with: #"\["#)
        result = result.replacingOccurrences(of: "⦅ST_LATEX_BRACKET_CLOSE⦆", with: #"\]"#)
        return result
    }

    static func splitInlineMath(in rawText: String) -> [STMarkdownInlineNode] {
        let restored = restoreInlineDelimiters(in: rawText)
        let normalized = normalizeDelimiters(in: restored)
        let matches = inlineMathMatches(in: normalized)
        guard matches.isEmpty == false else {
            return normalized.isEmpty ? [] : [.text(normalized)]
        }

        let text = normalized as NSString
        var result: [STMarkdownInlineNode] = []
        var cursor = 0

        for match in matches {
            if match.range.location > cursor {
                let prefix = text.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
                if prefix.isEmpty == false {
                    result.append(.text(prefix))
                }
            }

            let formulaText = text.substring(with: match.range)
            if formulaText.hasPrefix(#"\("#), formulaText.hasSuffix(#"\)"#) {
                let formula = String(formulaText.dropFirst(2).dropLast(2))
                result.append(.inlineMath(formula, isDisplayMode: false))
            } else if formulaText.hasPrefix(#"\["#), formulaText.hasSuffix(#"\]"#) {
                let formula = String(formulaText.dropFirst(2).dropLast(2))
                result.append(.inlineMath(formula, isDisplayMode: true))
            }

            cursor = match.range.location + match.range.length
        }

        if cursor < text.length {
            let suffix = text.substring(with: NSRange(location: cursor, length: text.length - cursor))
            if suffix.isEmpty == false {
                result.append(.text(suffix))
            }
        }

        return result
    }

    private static func inlineMathMatches(in text: String) -> [NSTextCheckingResult] {
        let pattern = #"(\\\(.+?\\\))|(\\\[.+?\\\])"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        return regex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
    }

    private static func environmentName(from line: String) -> String? {
        let range = NSRange(location: 0, length: line.utf16.count)
        guard let match = mathBlockEnvironmentRegex.firstMatch(in: line, options: [], range: range),
              let envRange = Range(match.range(at: 1), in: line) else {
            return nil
        }
        let environment = String(line[envRange])
        let supported = ["align", "align*", "equation", "equation*", "gather", "gather*", "multline", "multline*"]
        return supported.contains(environment) ? environment : nil
    }

    private static func consumeDollarMathBlock(
        from lines: [String],
        start: Int
    ) -> (content: String, nextIndex: Int) {
        let trimmed = lines[start].trimmingCharacters(in: .whitespaces)
        var content = ""
        var index = start

        if trimmed.count > 2 {
            let inner = String(trimmed.dropFirst(2))
            if inner.hasSuffix("$$") {
                content = String(inner.dropLast(2))
                return (content, start + 1)
            }
            content = inner
            index += 1
            while index < lines.count {
                let current = lines[index].trimmingCharacters(in: .whitespaces)
                if current.hasPrefix("$$") {
                    if current.count > 2, current.hasSuffix("$$") {
                        content += "\n" + String(current.dropFirst(2).dropLast(2))
                    }
                    return (content, index + 1)
                }
                content += "\n" + lines[index]
                index += 1
            }
            return (content, index)
        }

        index += 1
        while index < lines.count {
            let current = lines[index].trimmingCharacters(in: .whitespaces)
            if current.hasPrefix("$$") {
                if current.count > 2 {
                    content += (content.isEmpty ? "" : "\n") + String(current.dropFirst(2))
                }
                return (content, index + 1)
            }
            content += (content.isEmpty ? "" : "\n") + lines[index]
            index += 1
        }
        return (content, index)
    }

    private static func consumeBracketMathBlock(
        from lines: [String],
        start: Int
    ) -> (content: String, nextIndex: Int) {
        let trimmed = lines[start].trimmingCharacters(in: .whitespaces)
        let afterOpen = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        var content = ""
        var index = start

        if afterOpen.hasSuffix(#"\]"#) {
            content = String(afterOpen.dropLast(2))
            return (content, start + 1)
        }

        if afterOpen.isEmpty == false {
            content = afterOpen
        }

        index += 1
        while index < lines.count {
            let current = lines[index].trimmingCharacters(in: .whitespaces)
            if current.hasPrefix(#"\]"#) {
                return (content, index + 1)
            }
            if current.hasSuffix(#"\]"#) {
                content += (content.isEmpty ? "" : "\n") + String(current.dropLast(2))
                return (content, index + 1)
            }
            content += (content.isEmpty ? "" : "\n") + lines[index]
            index += 1
        }
        return (content, index)
    }

    private static func consumeEnvironmentMathBlock(
        from lines: [String],
        start: Int,
        environment: String
    ) -> (content: String, nextIndex: Int) {
        let closingToken = #"\\end{\#(environment)}"#
        var content = lines[start]
        var index = start + 1
        while index < lines.count {
            content += "\n" + lines[index]
            if lines[index].trimmingCharacters(in: .whitespaces).contains(closingToken) {
                return (content, index + 1)
            }
            index += 1
        }
        return (content, index)
    }
}
