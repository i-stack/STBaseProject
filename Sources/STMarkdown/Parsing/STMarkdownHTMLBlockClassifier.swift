//
//  STMarkdownHTMLBlockClassifier.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

enum STMarkdownHTMLBlockClassifier {
    private static let detailsRegex = try! NSRegularExpression(
        pattern: #"(?is)<details\b[^>]*>(.*?)</details>"#,
        options: []
    )

    private static let summaryRegex = try! NSRegularExpression(
        pattern: #"(?is)<summary\b[^>]*>(.*?)</summary>"#,
        options: []
    )

    /// - Parameter parseFragment: 解析 `<details>` 内部 Markdown 正文（不应再次剥离脚注定义行，避免递归丢失）。
    static func classify(html: String, parseFragment: (String) -> STMarkdownDocument) -> STMarkdownBlockNode {
        let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return .rawHTML(html)
        }
        let ns = trimmed as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let detMatch = Self.detailsRegex.firstMatch(in: trimmed, range: range),
              let innerR = Range(detMatch.range(at: 1), in: trimmed)
        else {
            return .rawHTML(html)
        }
        let inner = String(trimmed[innerR])
        let innerNS = inner as NSString
        let innerFull = NSRange(location: 0, length: innerNS.length)
        guard let sumMatch = Self.summaryRegex.firstMatch(in: inner, range: innerFull),
              let sumR = Range(sumMatch.range(at: 1), in: inner)
        else {
            return .rawHTML(html)
        }
        let summaryRaw = String(inner[sumR])
        let summaryPlain = Self.stripHTMLTags(from: summaryRaw).trimmingCharacters(in: .whitespacesAndNewlines)
        let summaryEnd = sumMatch.range.location + sumMatch.range.length
        let bodyStart = (inner as NSString).length > summaryEnd ? summaryEnd : innerNS.length
        let bodyRaw = innerNS.substring(from: bodyStart).trimmingCharacters(in: .whitespacesAndNewlines)

        let summaryDoc = parseFragment(summaryPlain.isEmpty ? " " : summaryPlain)
        let summaryInlines: [STMarkdownInlineNode]
        if let first = summaryDoc.blocks.first, case .paragraph(let p) = first {
            summaryInlines = p
        } else {
            summaryInlines = summaryPlain.isEmpty ? [] : [.text(summaryPlain)]
        }

        let bodyDoc = parseFragment(bodyRaw.isEmpty ? " " : bodyRaw)
        return .details(summary: summaryInlines, body: bodyDoc.blocks)
    }

    private static func stripHTMLTags(from fragment: String) -> String {
        let pattern = #"<[^>]+>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return fragment
        }
        let ns = fragment as NSString
        return regex.stringByReplacingMatches(
            in: fragment,
            range: NSRange(location: 0, length: ns.length),
            withTemplate: ""
        )
    }
}
