//
//  STMarkdownMathNormalizer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public struct STMarkdownMathNormalizationResult: Sendable {
    public let text: String
    public let blockMap: [Int: String]

    public init(text: String, blockMap: [Int: String]) {
        self.text = text
        self.blockMap = blockMap
    }
}

public enum STMarkdownMathNormalizer {
    private static let mathBlockEnvironmentRegex = STMarkdownRegexFactory.compile(
        pattern: #"^\\begin\{([^}]+)\}"#,
        owner: "STMarkdownMathNormalizer.environment"
    )

    public static func normalizeBlocks(in markdown: String) -> STMarkdownMathNormalizationResult {
        guard markdown.isEmpty == false else {
            return STMarkdownMathNormalizationResult(text: markdown, blockMap: [:])
        }

        let normalized = normalizeDelimiters(in: markdown)
        var mathMap: [Int: String] = [:]
        var output: [String] = []
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var index = 0
        var fenceState = STMarkdownCodeFenceState()

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            let wasInsideFence = fenceState.isInside
            fenceState.ingest(trimmedLine: trimmed)

            if wasInsideFence || fenceState.isInside {
                output.append(line)
                index += 1
                continue
            }

            if trimmed.hasPrefix("$$") {
                let indent = String(line.prefix(while: { $0 == " " || $0 == "\t" }))
                let result = consumeDollarMathBlock(from: lines, start: index)
                let currentIndex = mathMap.count
                let content = STMarkdownLatexSyntaxNormalizer.normalize(
                    result.content.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                mathMap[currentIndex] = content
                output.append("")
                output.append(indent + "{{ST_MATH_BLOCK:\(currentIndex)}}")
                output.append("")
                index = result.nextIndex
                continue
            }

            if trimmed.hasPrefix(#"\["#) {
                let indent = String(line.prefix(while: { $0 == " " || $0 == "\t" }))
                let result = consumeBracketMathBlock(from: lines, start: index)
                let currentIndex = mathMap.count
                let content = STMarkdownLatexSyntaxNormalizer.normalize(
                    result.content.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                mathMap[currentIndex] = content
                output.append("")
                output.append(indent + "{{ST_MATH_BLOCK:\(currentIndex)}}")
                output.append("")
                index = result.nextIndex
                continue
            }

            if let environment = environmentName(from: trimmed) {
                let indent = String(line.prefix(while: { $0 == " " || $0 == "\t" }))
                let result = consumeEnvironmentMathBlock(
                    from: lines,
                    start: index,
                    environment: environment
                )
                let currentIndex = mathMap.count
                let content = STMarkdownLatexSyntaxNormalizer.normalize(
                    result.content.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                mathMap[currentIndex] = content
                output.append("")
                output.append(indent + "{{ST_MATH_BLOCK:\(currentIndex)}}")
                output.append("")
                index = result.nextIndex
                continue
            }

            output.append(applyInlineSentinels(to: line))
            index += 1
        }

        return STMarkdownMathNormalizationResult(
            text: output.joined(separator: "\n"),
            blockMap: mathMap
        )
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
        result = result.replacingOccurrences(of: "⦅ST_MATH_LBRACKET⦆", with: "[")
        result = result.replacingOccurrences(of: "⦅ST_MATH_RBRACKET⦆", with: "]")
        result = result.replacingOccurrences(of: "⦅ST_MATH_ASTERISK⦆", with: "*")
        result = result.replacingOccurrences(of: "⦅ST_MATH_BACKTICK⦆", with: "`")
        return result
    }

    private static func applyInlineSentinels(to line: String) -> String {
        var result = line
        result = result.replacingOccurrences(of: #"\("#, with: "⦅ST_LATEX_PAREN_OPEN⦆")
        result = result.replacingOccurrences(of: #"\)"#, with: "⦅ST_LATEX_PAREN_CLOSE⦆")
        result = result.replacingOccurrences(of: #"\["#, with: "⦅ST_LATEX_BRACKET_OPEN⦆")
        result = result.replacingOccurrences(of: #"\]"#, with: "⦅ST_LATEX_BRACKET_CLOSE⦆")
        result = protectMarkdownCharsInsideMath(in: result)
        return result
    }

    /// 在 `applyInlineSentinels` 已经把 `\(...\)` / `\[...\]` 定界符替换成 sentinel 之后，
    /// 把 sentinel 包裹的数学区段内部仍为字面量的 `[`、`]`、`*`、`` ` `` 也换成 sentinel。
    ///
    /// 不处理这一步时，例如 `\(\sum_{k=1}^n k^3 = \left[\frac{n(n+1)}{2}\right]^2\)`，
    /// 数学内部的 `[\frac{n(n+1)}{2}\right]` 会被 swift-markdown 识别为
    /// shortcut reference link，从而拆掉 Text 节点 + 吃掉中括号，后续
    /// `splitInlineMath` 拿不到完整的 `\(...\)` 配对，整段公式退化为纯文本。
    ///
    /// `_` 不需要保护：LaTeX 中 `_` 多为 intraword (`k_n`) 或紧跟标点 (`_{...`)，
    /// 都不满足 CommonMark left-flanking 条件，无法打开 emphasis。
    private static func protectMarkdownCharsInsideMath(in text: String) -> String {
        let openParen = "⦅ST_LATEX_PAREN_OPEN⦆"
        let closeParen = "⦅ST_LATEX_PAREN_CLOSE⦆"
        let openBracket = "⦅ST_LATEX_BRACKET_OPEN⦆"
        let closeBracket = "⦅ST_LATEX_BRACKET_CLOSE⦆"

        var result = ""
        var cursor = text.startIndex

        while cursor < text.endIndex {
            let tail = text[cursor...]
            let parenOpen = tail.range(of: openParen)
            let bracketOpen = tail.range(of: openBracket)

            let nextOpen: (Range<String.Index>, String)?
            switch (parenOpen, bracketOpen) {
            case let (p?, b?):
                nextOpen = p.lowerBound < b.lowerBound ? (p, closeParen) : (b, closeBracket)
            case let (p?, nil):
                nextOpen = (p, closeParen)
            case let (nil, b?):
                nextOpen = (b, closeBracket)
            case (nil, nil):
                nextOpen = nil
            }

            guard let (openRange, closingSentinel) = nextOpen else {
                result += String(tail)
                break
            }

            result += String(text[cursor..<openRange.upperBound])
            cursor = openRange.upperBound

            guard let closeRange = text[cursor...].range(of: closingSentinel) else {
                // 未闭合的数学块（流式中段）：不强行保护，保持现有行为
                result += String(text[cursor...])
                break
            }

            let mathContent = text[cursor..<closeRange.lowerBound]
            let protected = String(mathContent)
                .replacingOccurrences(of: "[", with: "⦅ST_MATH_LBRACKET⦆")
                .replacingOccurrences(of: "]", with: "⦅ST_MATH_RBRACKET⦆")
                .replacingOccurrences(of: "*", with: "⦅ST_MATH_ASTERISK⦆")
                .replacingOccurrences(of: "`", with: "⦅ST_MATH_BACKTICK⦆")
            result += protected
            result += closingSentinel
            cursor = closeRange.upperBound
        }

        return result
    }

    public static func splitInlineMath(in rawText: String) -> [STMarkdownInlineNode] {
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
                let formula = STMarkdownLatexSyntaxNormalizer.normalize(
                    String(formulaText.dropFirst(2).dropLast(2))
                )
                result.append(.inlineMath(formula, isDisplayMode: false))
            } else if formulaText.hasPrefix(#"\["#), formulaText.hasSuffix(#"\]"#) {
                let formula = STMarkdownLatexSyntaxNormalizer.normalize(
                    String(formulaText.dropFirst(2).dropLast(2))
                )
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

    private static let inlineMathRegex = STMarkdownRegexFactory.compile(
        pattern: #"(\\\(.+?\\\))|(\\\[.+?\\\])"#,
        options: [.dotMatchesLineSeparators],
        owner: "STMarkdownMathNormalizer.inlineMath"
    )

    private static func inlineMathMatches(in text: String) -> [NSTextCheckingResult] {
        inlineMathRegex.matches(in: text, range: NSRange(location: 0, length: text.utf16.count))
    }

    private static let supportedMathEnvironments: Set<String> = [
        "align", "align*",
        "equation", "equation*",
        "gather", "gather*",
        "multline", "multline*",
        "aligned", "alignedat",
        "cases",
        "matrix", "pmatrix", "bmatrix", "Bmatrix", "vmatrix", "Vmatrix",
        "array",
        "split",
    ]

    private static func environmentName(from line: String) -> String? {
        let range = NSRange(location: 0, length: line.utf16.count)
        guard let match = mathBlockEnvironmentRegex.firstMatch(in: line, options: [], range: range),
              let envRange = Range(match.range(at: 1), in: line) else {
            return nil
        }
        let environment = String(line[envRange])
        return supportedMathEnvironments.contains(environment) ? environment : nil
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

// MARK: - LaTeX 语法降级

/// LaTeX 语法降级函数链。
///
/// 移植自 SwiftStreamingMarkdown 的 `filteringUnsupportedSyntaxes()`：
/// 对 LLM 输出中常见但 iosMath/KaTeX 不支持的 LaTeX 命令做降级替换，
/// 避免渲染空白或报错。
public enum STMarkdownLatexSyntaxNormalizer {

    /// 对 LaTeX 文本依次执行全部的降级转换（8 种）。
    ///
    /// ```swift
    /// let result = STMarkdownLatexSyntaxNormalizer.normalize("\\dfrac{a}{b}")
    /// // result == "\\frac{a}{b}"
    /// ```
    public static func normalize(_ latex: String) -> String {
        var result = latex
        result = strippingBoxedLatex(result)
        result = replacingFrac(result)
        result = replacingPrime(result)
        result = replacingVector(result)
        result = replacingImplies(result)
        result = replacingHarpoons(result)
        result = replacingDots(result)
        result = strippingBracketSizeCommands(result)
        return result
    }

    // MARK: - 各转换规则

    /// 移除 `\\boxed{...}`（不支持），保留括号内内容。
    public static func strippingBoxedLatex(_ text: String) -> String {
        text.replacingOccurrences(of: #"\boxed"#, with: "")
    }

    /// 将 `\\dfrac` 和 `\\tfrac` 降级为 `\\frac`。
    public static func replacingFrac(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"\dfrac"#, with: #"\frac"#)
            .replacingOccurrences(of: #"\tfrac"#, with: #"\frac"#)
    }

    /// 将 `'` 降级为 `^{\\prime}`（iosMath 不支持短撇号）。
    public static func replacingPrime(_ text: String) -> String {
        text.replacingOccurrences(of: "'", with: "^{\\prime}")
    }

    /// 将 `\\overrightarrow` 降级为 `\\vec`。
    public static func replacingVector(_ text: String) -> String {
        text.replacingOccurrences(of: #"\overrightarrow"#, with: #"\vec"#)
    }

    /// 将 `\\implies` 降级为 `\\Rightarrow`。
    public static func replacingImplies(_ text: String) -> String {
        text.replacingOccurrences(of: #"\implies"#, with: #"\Rightarrow"#)
    }

    /// 将 `\\rightleftharpoons` 降级为 `\\Leftrightarrow`。
    public static func replacingHarpoons(_ text: String) -> String {
        text.replacingOccurrences(of: #"\rightleftharpoons"#, with: #"\Leftrightarrow"#)
    }

    /// 将 `\\dots` 降级为 `\\ldots`。
    public static func replacingDots(_ text: String) -> String {
        text.replacingOccurrences(of: #"\dots"#, with: #"\ldots"#)
    }

    /// 移除支架尺寸命令（`\\bigl`、`\\biggl`、`\\Bigl`、`\\Biggl`、
    /// `\\bigr`、`\\biggr`、`\\Bigr`、`\\Biggr`、`\\big`）。
    public static func strippingBracketSizeCommands(_ text: String) -> String {
        let commands = [
            #"\biggl"#, #"\Biggl"#, #"\biggr"#, #"\Biggr"#,
            #"\bigl"#, #"\Bigl"#, #"\bigr"#, #"\Bigr"#,
            #"\big"#,
        ]
        var result = text
        for cmd in commands {
            result = result.replacingOccurrences(of: cmd, with: "")
        }
        return result
    }
}
