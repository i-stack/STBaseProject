//
//  STMarkdownDefaultMathRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public struct STMarkdownDefaultMathRenderer: STMarkdownInlineMathRendering, STMarkdownBlockMathRendering {
    public init() {}

    public func renderInlineMath(
        formula: String,
        style: STMarkdownStyle,
        baseFont: UIFont,
        textColor: UIColor
    ) -> NSAttributedString? {
        self.renderMath(
            formula: formula,
            style: style,
            baseFont: baseFont,
            textColor: textColor,
            displayMode: false
        )
    }

    public func renderBlockMath(
        formula: String,
        style: STMarkdownStyle
    ) -> NSAttributedString? {
        // 早期使用 `st_monospacedSystemFont`，但等宽字体在 iOS 上对希腊字母 / 数学符号
        // 的 glyph 覆盖差，常出现 fallback 字形阶跃。改为以正文 font 为基线，
        // 既保持视觉一致，也利用系统字体更全的数学符号子集。
        let baseFont = UIFont(descriptor: style.font.fontDescriptor, size: max(style.font.pointSize, 16))
        return self.renderMath(
            formula: formula,
            style: style,
            baseFont: baseFont,
            textColor: style.textColor,
            displayMode: true
        )
    }
}

private extension STMarkdownDefaultMathRenderer {
    static let commandMap: [String: String] = [
        #"\\alpha"#: "α",
        #"\\beta"#: "β",
        #"\\gamma"#: "γ",
        #"\\delta"#: "δ",
        #"\\theta"#: "θ",
        #"\\lambda"#: "λ",
        #"\\mu"#: "μ",
        #"\\pi"#: "π",
        #"\\sigma"#: "σ",
        #"\\phi"#: "φ",
        #"\\omega"#: "ω",
        #"\\Delta"#: "Δ",
        #"\\Gamma"#: "Γ",
        #"\\Pi"#: "Π",
        #"\\Sigma"#: "Σ",
        #"\\Phi"#: "Φ",
        #"\\Omega"#: "Ω",
        #"\\cdot"#: "·",
        #"\\times"#: "×",
        #"\\pm"#: "±",
        #"\\neq"#: "≠",
        #"\\le"#: "≤",
        #"\\ge"#: "≥",
        #"\\approx"#: "≈",
        #"\\infty"#: "∞",
        #"\\to"#: "→",
        #"\\leftarrow"#: "←",
        #"\\Rightarrow"#: "⇒",
        #"\\sum"#: "∑",
        #"\\prod"#: "∏",
        #"\\int"#: "∫",
        #"\\partial"#: "∂",
        #"\\nabla"#: "∇",
        #"\\sqrt"#: "√",
    ]

    func renderMath(
        formula: String,
        style: STMarkdownStyle,
        baseFont: UIFont,
        textColor: UIColor,
        displayMode: Bool
    ) -> NSAttributedString {
        let paragraphStyle = self.makeParagraphStyle(style: style, displayMode: displayMode)
        let normalized = self.normalize(formula)
        let result = NSMutableAttributedString()
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        var index = normalized.startIndex
        while index < normalized.endIndex {
            let character = normalized[index]

            if character == "^" || character == "_" {
                let isSuperscript = character == "^"
                let nextIndex = normalized.index(after: index)
                let extraction = self.extractScriptContent(in: normalized, startingAt: nextIndex)
                let content = extraction.content.isEmpty ? String(character) : extraction.content
                result.append(
                    self.makeScriptAttributedString(
                        content: content,
                        baseFont: baseFont,
                        textColor: textColor,
                        paragraphStyle: paragraphStyle,
                        isSuperscript: isSuperscript
                    )
                )
                index = extraction.nextIndex
                continue
            }

            result.append(NSAttributedString(string: String(character), attributes: baseAttributes))
            index = normalized.index(after: index)
        }

        if displayMode {
            let wrapped = NSMutableAttributedString(string: "\n", attributes: baseAttributes)
            wrapped.append(result)
            wrapped.append(NSAttributedString(string: "\n", attributes: baseAttributes))
            return wrapped
        }

        return result
    }

    func normalize(_ formula: String) -> String {
        var result = formula.trimmingCharacters(in: .whitespacesAndNewlines)
        result = result.replacingOccurrences(of: "\r\n", with: " ")
        result = result.replacingOccurrences(of: "\n", with: " ")
        result = result.replacingOccurrences(of: "\r", with: " ")
        // Raw-string 字面 `#"\("#` 里反斜杠是单字面字符；之前的 `#"\\("#`
        // 实际去匹配两个反斜杠+括号，对真实输入永远不会命中。
        result = result.replacingOccurrences(of: #"\("#, with: "")
        result = result.replacingOccurrences(of: #"\)"#, with: "")
        result = result.replacingOccurrences(of: #"\["#, with: "")
        result = result.replacingOccurrences(of: #"\]"#, with: "")

        for (command, replacement) in Self.commandMap {
            result = result.replacingOccurrences(of: command, with: replacement)
        }

        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }

        return result
    }

    func extractScriptContent(
        in text: String,
        startingAt index: String.Index
    ) -> (content: String, nextIndex: String.Index) {
        guard index < text.endIndex else {
            return ("", index)
        }

        if text[index] == "{" {
            var cursor = text.index(after: index)
            var depth = 1
            let start = cursor

            while cursor < text.endIndex {
                if text[cursor] == "{" {
                    depth += 1
                } else if text[cursor] == "}" {
                    depth -= 1
                    if depth == 0 {
                        return (String(text[start..<cursor]), text.index(after: cursor))
                    }
                }
                cursor = text.index(after: cursor)
            }

            return (String(text[start...]), text.endIndex)
        }

        let next = text.index(after: index)
        return (String(text[index..<next]), next)
    }

    func makeScriptAttributedString(
        content: String,
        baseFont: UIFont,
        textColor: UIColor,
        paragraphStyle: NSParagraphStyle,
        isSuperscript: Bool
    ) -> NSAttributedString {
        let scriptFont = UIFont(descriptor: baseFont.fontDescriptor, size: max(baseFont.pointSize * 0.72, 10))
        let offset = isSuperscript ? baseFont.pointSize * 0.32 : -baseFont.pointSize * 0.22
        return NSAttributedString(
            string: content,
            attributes: [
                .font: scriptFont,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle,
                .baselineOffset: offset,
            ]
        )
    }

    func makeParagraphStyle(style: STMarkdownStyle, displayMode: Bool) -> NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = style.lineHeight
        paragraphStyle.maximumLineHeight = style.lineHeight
        paragraphStyle.paragraphSpacing = displayMode ? style.paragraphSpacing : 0
        paragraphStyle.alignment = displayMode ? .center : .natural
        paragraphStyle.lineBreakMode = .byWordWrapping
        return paragraphStyle
    }
}
