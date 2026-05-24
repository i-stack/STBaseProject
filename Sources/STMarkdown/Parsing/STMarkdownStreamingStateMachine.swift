//
//  STMarkdownCitationURLMatcher.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

/// 逐字流式 markdown 的最小状态机骨架：
/// - 输入：全量 raw markdown（可由上游累积）
/// - 输出：稳定前缀 + 悬挂尾部（用于"只延迟不稳定尾部，不回退整段"）
///
/// 说明：
/// 1) 当前实现优先保证行为可解释与可测试，不引入侵入式渲染改动。
/// 2) 先覆盖最常见不稳定结构：fenced code、inline code、emphasis。
/// 3) link/list/table 等结构可在后续扩展到同一状态机内。
public final class STMarkdownStreamingStateMachine {

    public struct Snapshot: Equatable {
        /// 可以安全提交到渲染层的稳定前缀（单调增长目标）。
        public let stablePrefix: String
        /// 仍在构建中的尾部（建议走占位/延迟提交，而非整段回退）。
        public let danglingSuffix: String

        public var renderableText: String {
            stablePrefix + danglingSuffix
        }

        public init(stablePrefix: String, danglingSuffix: String) {
            self.stablePrefix = stablePrefix
            self.danglingSuffix = danglingSuffix
        }
    }

    public private(set) var lastSnapshot: Snapshot = .init(stablePrefix: "", danglingSuffix: "")

    public init() {}

    public func reset() {
        self.lastSnapshot = .init(stablePrefix: "", danglingSuffix: "")
    }

    @discardableResult
    public func ingest(fullMarkdown: String) -> Snapshot {
        let boundary = Self.lastStableBoundary(in: fullMarkdown)
        var stable = String(fullMarkdown.prefix(boundary))
        var suffix = String(fullMarkdown.dropFirst(boundary))

        // 流式阶段默认只追加文本，不允许已提交前缀回退。
        // 若本次计算出的 stable 更短，但旧 stable 仍然是当前 fullMarkdown 的前缀，
        // 则保留旧 stable，把新增部分继续留在 danglingSuffix。
        // 这样可以兜住 markdown 语义在尾部补全时对边界的短暂重算，
        // 避免上层已渲染正文被撤回后再提交，引发闪烁。
        let previousStable = self.lastSnapshot.stablePrefix
        if stable.count < previousStable.count,
           fullMarkdown.hasPrefix(previousStable) {
            stable = previousStable
            suffix = String(fullMarkdown.dropFirst(previousStable.count))
        }

        let snapshot = Snapshot(stablePrefix: stable, danglingSuffix: suffix)
        self.lastSnapshot = snapshot
        return snapshot
    }

    // MARK: - Stable boundary detection

    /// 返回"最后一个稳定边界"索引（字符偏移）。
    /// 边界之后属于 danglingSuffix，不应直接按最终语义提交。
    private static func lastStableBoundary(in text: String) -> Int {
        if text.isEmpty { return 0 }

        var inFencedCodeBlock = false
        var fenceToken: String?
        var inlineCodeOpenCount = 0
        var strongStarOpenCount = 0
        var strongUnderscoreOpenCount = 0
        var emStarOpenCount = 0
        var emUnderscoreOpenCount = 0

        var lastSafeBoundary = 0

        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var consumed = 0

        for (lineIndex, rawLine) in lines.enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("```") || line.hasPrefix("~~~") {
                let token = String(line.prefix(3))
                if !inFencedCodeBlock {
                    inFencedCodeBlock = true
                    fenceToken = token
                } else if token == fenceToken {
                    inFencedCodeBlock = false
                    fenceToken = nil
                }
            }

            if !inFencedCodeBlock {
                inlineCodeOpenCount += Self.countUnescaped("`", in: rawLine)
                strongStarOpenCount += Self.countUnescaped("**", in: rawLine)
                strongUnderscoreOpenCount += Self.countUnescaped("__", in: rawLine)
                emStarOpenCount += Self.countUnescapedSingle("*", in: rawLine)
                emUnderscoreOpenCount += Self.countUnescapedSingle("_", in: rawLine)
            }

            consumed += rawLine.count
            let hasLineBreak = lineIndex < lines.count - 1
            if hasLineBreak { consumed += 1 }

            let balanced =
                !inFencedCodeBlock
                && (inlineCodeOpenCount % 2 == 0)
                && (strongStarOpenCount % 2 == 0)
                && (strongUnderscoreOpenCount % 2 == 0)
                && (emStarOpenCount % 2 == 0)
                && (emUnderscoreOpenCount % 2 == 0)

            if balanced {
                lastSafeBoundary = consumed
            }
        }

        let syntaxAdjusted = Self.adjustBoundaryForDanglingLinkLikeSyntax(
            in: text,
            boundary: lastSafeBoundary
        )
        return max(0, min(syntaxAdjusted, text.count))
    }

    /// 在"已平衡边界"基础上，进一步回退到不暴露半截 link/citation 的位置。
    private static func adjustBoundaryForDanglingLinkLikeSyntax(in text: String, boundary: Int) -> Int {
        guard boundary > 0 else { return boundary }
        var adjusted = boundary
        let stable = String(text.prefix(boundary))

        // 0) markdown image：`![alt](url` / `![alt`
        if let imageOpen = stable.range(of: "![", options: .backwards) {
            let tail = stable[imageOpen.lowerBound...]
            let imageClosed = tail.contains("]") && tail.contains(")")
            if !imageClosed {
                adjusted = min(adjusted, stable.distance(from: stable.startIndex, to: imageOpen.lowerBound))
            }
        }

        // 1) `[[citation:...` / `[[webpage:...` 未闭合 `]]`
        if let open = stable.range(of: "[[", options: .backwards) {
            let tail = stable[open.lowerBound...]
            if !tail.contains("]]") {
                adjusted = min(adjusted, stable.distance(from: stable.startIndex, to: open.lowerBound))
            }
        }

        // 2) markdown link：`[text](url` 末尾未闭合 `)`
        if let linkOpen = stable.range(of: "](", options: .backwards) {
            let tail = stable[linkOpen.lowerBound...]
            if !tail.contains(")") {
                adjusted = min(adjusted, stable.distance(from: stable.startIndex, to: linkOpen.lowerBound))
            }
        }

        // 3) 裸 `[` 末尾未闭合，避免外露 `[xxx`
        if let bracketOpen = stable.range(of: "[", options: .backwards) {
            let tail = stable[bracketOpen.lowerBound...]
            if !tail.contains("]") {
                adjusted = min(adjusted, stable.distance(from: stable.startIndex, to: bracketOpen.lowerBound))
            }
        }

        return adjusted
    }

    private static func countUnescaped(_ token: String, in text: String) -> Int {
        if token.isEmpty || text.isEmpty { return 0 }
        let chars = Array(text)
        let tokenChars = Array(token)
        if chars.count < tokenChars.count { return 0 }

        var i = 0
        var count = 0
        while i <= chars.count - tokenChars.count {
            if i > 0, chars[i - 1] == "\\" {
                i += 1
                continue
            }
            var matched = true
            for j in 0..<tokenChars.count where chars[i + j] != tokenChars[j] {
                matched = false
                break
            }
            if matched {
                count += 1
                i += tokenChars.count
            } else {
                i += 1
            }
        }
        return count
    }

    /// 统计单字符 emphasis（排除 ** / __ 这类 strong token）。
    private static func countUnescapedSingle(_ token: String, in text: String) -> Int {
        guard token == "*" || token == "_" else { return 0 }
        guard !text.isEmpty else { return 0 }
        let chars = Array(text)
        var count = 0
        for idx in chars.indices {
            if chars[idx] != Character(token) { continue }
            if idx > 0, chars[idx - 1] == "\\" { continue }
            let prevSame = idx > 0 && chars[idx - 1] == Character(token)
            let nextSame = idx + 1 < chars.count && chars[idx + 1] == Character(token)
            if prevSame || nextSame { continue }
            count += 1
        }
        return count
    }
}
