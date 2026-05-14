//
//  STMarkdownTOC.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation
import UIKit

// MARK: - Attributed string anchor (TextKit 1 滚动 / 宿主定位)

extension NSAttributedString.Key {
    /// 标题块在富文本上的稳定锚点 id（与 ``STMarkdownTOCItem/anchorId`` 一致）。
    public static let stMarkdownHeadingAnchor = NSAttributedString.Key("STMarkdown.headingAnchor")
    /// 脚注引用在富文本上的逻辑标签（与 `[^label]` 中 `label` 一致，不含 `^`）。
    public static let stMarkdownFootnoteLabel = NSAttributedString.Key("STMarkdown.footnoteLabel")
    /// 当前字符所属渲染块的稳定 id（例如 `b:3/li:1/b:0`）。
    public static let stMarkdownBlockID = NSAttributedString.Key("STMarkdown.blockID")
    /// 当前字符所属渲染块类型；值为 ``STMarkdownRenderBlockKind/rawValue``。
    public static let stMarkdownBlockKind = NSAttributedString.Key("STMarkdown.blockKind")
    /// 当前字符所属渲染块的 reveal 策略；值为 ``STMarkdownRevealPolicy/rawValue``。
    public static let stMarkdownRevealPolicy = NSAttributedString.Key("STMarkdown.revealPolicy")
}

// MARK: - TOC item

/// 从 ``STMarkdownRenderDocument`` 抽取的目录项，供宿主渲染侧栏目录或跳转。
public struct STMarkdownTOCItem: Sendable, Hashable, Equatable {
    public let level: Int
    /// 纯文本标题（用于展示）。
    public let title: String
    /// 与 ``NSAttributedString.Key.stMarkdownHeadingAnchor``、``STMarkdownBaseTextView.scrollToHeadingAnchor`` 一致。
    public let anchorId: String

    public init(level: Int, title: String, anchorId: String) {
        self.level = level
        self.title = title
        self.anchorId = anchorId
    }
}

// MARK: - Plain text for headings / TOC titles

extension STMarkdownInlineNode {
    /// 递归拼接行内节点为纯文本（软换行视为空格）。
    public func st_plainTextForTOC() -> String {
        switch self {
        case .text(let s):
            return s
        case .softBreak:
            return " "
        case .inlineMath(let s, _):
            return s
        case .emphasis(let c), .strong(let c), .strikethrough(let c):
            return c.map { $0.st_plainTextForTOC() }.joined()
        case .code(let s):
            return s
        case .link(_, let c):
            return c.map { $0.st_plainTextForTOC() }.joined()
        case .image(_, let alt, _):
            return alt
        case .footnoteReference(let label):
            return "[^\(label)]"
        case .inlineRawHTML(let raw):
            return raw
        }
    }
}

extension Array where Element == STMarkdownInlineNode {
    public func st_plainTextForTOC() -> String {
        self.map { $0.st_plainTextForTOC() }.joined()
    }
}

// MARK: - Slug + 去重（GitHub 风格简化）

struct STMarkdownAnchorSlugRegistry: Sendable {
    private var used: Set<String> = []

    mutating func uniqueAnchorId(forPlainTitle plain: String) -> String {
        let base = Self.slugify(plain)
        let root = base.isEmpty ? "heading" : base
        var candidate = root
        var n = 1
        while self.used.contains(candidate) {
            candidate = "\(root)-\(n)"
            n += 1
        }
        self.used.insert(candidate)
        return candidate
    }

    private static func slugify(_ text: String) -> String {
        let folded = text.folding(options: .diacriticInsensitive, locale: .current)
        var result = ""
        var lastWasHyphen = false
        for ch in folded.lowercased() {
            if ch.isLetter || ch.isNumber {
                result.append(ch)
                lastWasHyphen = false
            } else if result.isEmpty == false, !lastWasHyphen {
                result.append("-")
                lastWasHyphen = true
            }
        }
        while result.hasSuffix("-") {
            result.removeLast()
        }
        return result
    }
}

// MARK: - 从渲染 AST 抽取 TOC

enum STMarkdownTOCExtraction {
    static func items(from document: STMarkdownRenderDocument) -> [STMarkdownTOCItem] {
        var items: [STMarkdownTOCItem] = []
        for block in document.blocks {
            self.collect(from: block, into: &items)
        }
        return items
    }

    private static func collect(from block: STMarkdownRenderBlock, into items: inout [STMarkdownTOCItem]) {
        switch block {
        case .heading(_, level: let level, anchorId: let anchorId, content: let content):
            let title = content.st_plainTextForTOC()
            items.append(STMarkdownTOCItem(level: level, title: title, anchorId: anchorId))
        case .quote(_, let inner):
            for b in inner { self.collect(from: b, into: &items) }
        case .list(_, let listItems):
            for item in listItems {
                for b in item.blocks {
                    self.collect(from: b, into: &items)
                }
            }
        case .details(_, summary: _, body: let body):
            for b in body { self.collect(from: b, into: &items) }
        case .paragraph, .codeBlock, .table, .mathBlock, .image, .thematicBreak, .rawHTML:
            break
        }
    }
}
