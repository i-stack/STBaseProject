//
//  STMarkdownIncrementalParse.swift
//  STBaseProject
//
//  元素级增量解析入口：回溯窗口子串 parse + ``replaceTailCount``（语义对齐 Vendor ``estimateReplaceCount`` / ``replaceCount``）。
//

import Foundation

// MARK: - 参数与结果

/// 增量解析输入。
///
/// **偏移约定**：`lastCommittedExclusiveEnd` / `currentSafeExclusiveEnd` 与 ``STMarkdownStreamBuffer``
/// 使用的 **Character 偏移**（`String.index(_:offsetBy:limitedBy:)` 从 `startIndex` 起算）一致，且作用于
/// 本参数中的 ``canonicalMarkdown`` 整串。
///
/// - Important: 本路径**不执行**输入规整器（`STMarkdownInputSanitizer`）。若管线启用 sanitizer，
///   请自行对全文做规整后再把结果作为 ``canonicalMarkdown`` 传入，并保证偏移与之一致；否则请关闭
///   sanitizer 后使缓冲串与 canonical 为同一字符串（常见流式场景）。
public struct STMarkdownIncrementalParameters: Sendable, Hashable {
    /// 当前帧完整 Markdown（已与缓冲 / 规整结果对齐）。
    public var canonicalMarkdown: String
    /// 上一帧已冻结、本帧仍视为不可变的前缀上界（不包含该下标）。
    public var lastCommittedExclusiveEnd: Int
    /// 本帧安全解析上界（不包含该下标），通常来自缓冲器的 `lastSafeUpperBoundOffset`。
    public var currentSafeExclusiveEnd: Int
    /// 向前回溯字符数，对齐 Vendor ``contextWindowSize``（默认 200）。
    public var contextWindowSize: Int
    /// 上一帧合并后 **渲染块总数**（对齐 Vendor ``previousElementCount``）。
    public var previousTotalRenderBlockCount: Int

    public init(
        canonicalMarkdown: String,
        lastCommittedExclusiveEnd: Int,
        currentSafeExclusiveEnd: Int,
        contextWindowSize: Int = 200,
        previousTotalRenderBlockCount: Int
    ) {
        self.canonicalMarkdown = canonicalMarkdown
        self.lastCommittedExclusiveEnd = lastCommittedExclusiveEnd
        self.currentSafeExclusiveEnd = currentSafeExclusiveEnd
        self.contextWindowSize = max(0, contextWindowSize)
        self.previousTotalRenderBlockCount = max(0, previousTotalRenderBlockCount)
    }
}

/// 单帧增量解析产物（对齐 Vendor ``IncrementalParseResult`` 的核心字段子集）。
public struct STMarkdownIncrementalParseResult: Sendable, Hashable {
    /// 与 Vendor ``replaceCount`` 对应：应从上一帧 **渲染块列表尾部** 丢弃的块数，再拼接 ``windowRenderDocument/blocks``。
    public let replaceTailCount: Int
    public let parseStartOffset: Int
    public let parseEndOffset: Int
    /// 实际参与 parse 的子串（`canonicalMarkdown[parseStart..<parseEnd]` 的字符视图）。
    public let windowFragment: String
    public let windowRenderDocument: STMarkdownRenderDocument
    public let windowTableOfContents: [STMarkdownTOCItem]

    public init(
        replaceTailCount: Int,
        parseStartOffset: Int,
        parseEndOffset: Int,
        windowFragment: String,
        windowRenderDocument: STMarkdownRenderDocument,
        windowTableOfContents: [STMarkdownTOCItem]
    ) {
        self.replaceTailCount = replaceTailCount
        self.parseStartOffset = parseStartOffset
        self.parseEndOffset = parseEndOffset
        self.windowFragment = windowFragment
        self.windowRenderDocument = windowRenderDocument
        self.windowTableOfContents = windowTableOfContents
    }

    /// 将上一帧渲染块与本轮窗口块按 ``replaceTailCount`` 做尾部替换合并。
    ///
    /// - Warning: 合并块若直接用于富文本，**标题 ``anchorId`` 可能需全文重算**；生产路径可在合并后
    ///   对 **全文 canonical** 再调用 ``STMarkdownPipeline/process``，或仅将本 API 用于中间态 diff。
    public func mergedRenderDocument(previous: STMarkdownRenderDocument) -> STMarkdownRenderDocument {
        let merged = Self.mergedRenderBlocks(
            previous: previous.blocks,
            replaceTailCount: self.replaceTailCount,
            newTailBlocks: self.windowRenderDocument.blocks
        )
        return STMarkdownRenderDocument(blocks: merged)
    }

    public static func mergedRenderBlocks(
        previous: [STMarkdownRenderBlock],
        replaceTailCount: Int,
        newTailBlocks: [STMarkdownRenderBlock]
    ) -> [STMarkdownRenderBlock] {
        let k = max(0, previous.count - replaceTailCount)
        return Array(previous.prefix(k)) + newTailBlocks
    }
}

// MARK: - replaceCount 估算（对齐 Vendor ``estimateReplaceCount``）

enum STMarkdownIncrementalReplaceCountEstimator {
    /// Vendor：`parseStart < lastSafePosition` 时 `max(1, backtrackChars/100)` 再 `min(previousElementCount, …)`。
    static func estimateReplaceTailCount(
        previousTotalRenderBlockCount: Int,
        parseStart: Int,
        lastCommittedExclusiveEnd: Int
    ) -> Int {
        guard parseStart < lastCommittedExclusiveEnd else { return 0 }
        let backtrackChars = lastCommittedExclusiveEnd - parseStart
        let estimated = max(1, backtrackChars / 100)
        return min(estimated, previousTotalRenderBlockCount)
    }
}

// MARK: - 子串（Character 偏移）

enum STMarkdownIncrementalSubstring {
    /// 使用与 ``STMarkdownStreamBuffer`` 相同的 Character 偏移语义。
    static func fragment(in text: String, startOffset: Int, endOffset: Int) -> String {
        guard text.isEmpty == false, startOffset < endOffset, startOffset >= 0 else { return "" }
        let endClamped = min(endOffset, text.count)
        guard let sIdx = text.index(text.startIndex, offsetBy: startOffset, limitedBy: text.endIndex),
              let eIdx = text.index(text.startIndex, offsetBy: endClamped, limitedBy: text.endIndex),
              sIdx < eIdx else {
            return ""
        }
        return String(text[sIdx..<eIdx])
    }
}
