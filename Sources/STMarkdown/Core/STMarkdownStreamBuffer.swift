//
//  STMarkdownStreamBuffer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

// MARK: - Stream buffer

/// 流式场景下用于累积 chunk、检测可独立渲染的 Markdown 模块的缓冲器。
///
/// - Note: 使用 Swift 字符串的 `Index` 与 `offsetBy(_:limitedBy:)` 做边界截取，避免流式 Unicode 截断问题。
/// - SeeAlso: 与 ``STMarkdownStreamBuffer/lastSafeUpperBoundOffset`` 同语义的 **Character 偏移** 可传入
///   ``STMarkdownIncrementalParameters``，由 ``STMarkdownPipeline/processIncremental(_:)`` 做回溯窗口子串解析与
///   ``STMarkdownIncrementalParseResult/replaceTailCount`` 估算（见对比文档第 7.2.5 节）。
public final class STMarkdownStreamBuffer {

    public struct ModuleDetectionResult: Sendable {
        public let completeModules: [String]
        public let pendingText: String
        public let hasPendingStructure: Bool
        public let pendingType: PendingStructureType?
    }

    public enum PendingStructureType: String, Sendable {
        case codeBlock
        case latexBlock
        case table
    }

    private(set) public var accumulatedText: String = ""

    /// 已确认可安全参与「模块级」渲染的前缀在 ``accumulatedText`` 中的上界，用**字符偏移**表示，
    /// 避免 `accumulatedText += chunk` 后旧的 `String.Index` 跨变异失效。
    private var lastSafeUpperBoundOffset: Int

    private var minModuleLength: Int

    /// 本帧检测到一个或多个完整模块时的回调（对照 vendor ``onModuleReady`` 的**字符串子集**：不预解析 AST）。
    public var onCompleteModules: (([String]) -> Void)?

    public init(minModuleLength: Int = 20) {
        self.minModuleLength = max(1, minModuleLength)
        self.accumulatedText = ""
        self.lastSafeUpperBoundOffset = 0
    }

    public func reset() {
        accumulatedText = ""
        lastSafeUpperBoundOffset = 0
    }

    public func updateMinModuleLength(_ length: Int) {
        self.minModuleLength = max(1, length)
    }

    /// 当前累积的完整原文（含尚未提交到安全前缀的尾部）。
    public var fullAccumulatedText: String {
        accumulatedText
    }

    /// 已通过模块检测、可交给渲染管线的前缀子串（不含仍缓冲中的尾部）。
    public var committedSafePrefix: String {
        guard lastSafeUpperBoundOffset > 0 else { return "" }
        let text = accumulatedText
        guard let endIdx = text.index(
            text.startIndex,
            offsetBy: lastSafeUpperBoundOffset,
            limitedBy: text.endIndex
        ) else { return "" }
        return String(text[..<endIdx])
    }

    /// 追加一段网络/模型 chunk，返回本帧检测到的完整模块。
    @discardableResult
    public func append(_ text: String) -> ModuleDetectionResult {
        accumulatedText += text
        let result = detectCompleteModules()
        if result.completeModules.isEmpty == false {
            self.onCompleteModules?(result.completeModules)
        }
        return result
    }

    /// 流结束时将剩余内容全部标为已提交，返回此前未纳入安全前缀的尾部字符串。
    @discardableResult
    public func flush() -> String {
        let text = accumulatedText
        let tailStart = indexInCurrentText(offset: lastSafeUpperBoundOffset)
        let remaining = tailStart < text.endIndex ? String(text[tailStart...]) : ""
        lastSafeUpperBoundOffset = text.distance(from: text.startIndex, to: text.endIndex)
        return remaining
    }

    // MARK: - Detection

    private func detectCompleteModules() -> ModuleDetectionResult {
        let textToAnalyze = accumulatedText
        let startPosition = indexInCurrentText(offset: lastSafeUpperBoundOffset)

        if let pending = detectPendingStructure(in: textToAnalyze) {
            if pending == .table, hasTableSeparatorRow(in: textToAnalyze) {
                let newSlice = startPosition < textToAnalyze.endIndex
                    ? String(textToAnalyze[startPosition...])
                    : ""
                let trimmed = newSlice.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    lastSafeUpperBoundOffset = textToAnalyze.distance(
                        from: textToAnalyze.startIndex, to: textToAnalyze.endIndex)
                    return ModuleDetectionResult(
                        completeModules: [trimmed],
                        pendingText: "",
                        hasPendingStructure: false,
                        pendingType: nil
                    )
                }
            }
            let pendingSlice = startPosition < textToAnalyze.endIndex
                ? String(textToAnalyze[startPosition...])
                : ""
            return ModuleDetectionResult(
                completeModules: [],
                pendingText: pendingSlice,
                hasPendingStructure: true,
                pendingType: pending
            )
        }

        let boundaries = findModuleBoundaries(in: textToAnalyze, from: startPosition)
        if boundaries.isEmpty {
            let remainingText = startPosition < textToAnalyze.endIndex
                ? String(textToAnalyze[startPosition...])
                : ""
            let utf16Count = remainingText.utf16.count
            if (utf16Count > minModuleLength * 3 && remainingText.hasSuffix("\n\n")
                || (isPlainText(remainingText) && utf16Count > minModuleLength && remainingText.hasSuffix("\n"))),
                !shouldDeferCommitAwaitingPossibleSecondTopLevelHeading(in: textToAnalyze) {
                let completeText = remainingText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !completeText.isEmpty {
                    lastSafeUpperBoundOffset = textToAnalyze.distance(from: textToAnalyze.startIndex, to: textToAnalyze.endIndex)
                    return ModuleDetectionResult(
                        completeModules: [completeText],
                        pendingText: "",
                        hasPendingStructure: false,
                        pendingType: nil
                    )
                }
            }
            return ModuleDetectionResult(
                completeModules: [],
                pendingText: remainingText,
                hasPendingStructure: false,
                pendingType: nil
            )
        }

        var completeModules: [String] = []
        var lastBoundary = startPosition

        for boundary in boundaries where boundary > textToAnalyze.startIndex {
            if boundary > lastBoundary {
                let moduleText = extractModule(from: textToAnalyze, start: lastBoundary, end: boundary)
                if !moduleText.isEmpty {
                    completeModules.append(moduleText)
                }
            }
            lastBoundary = boundary
        }

        // 首 chunk 已把 `lastSafeUpperBoundOffset` 顶到「第二个 # 」行首时，`startPosition` 与该 H1 边界重合，`>` 分支不会切片，但仍需在本帧产出上一模块供渲染。
        if completeModules.isEmpty,
           let firstBoundary = boundaries.first,
           firstBoundary == startPosition,
           startPosition > textToAnalyze.startIndex {
            let moduleText = extractModule(from: textToAnalyze, start: textToAnalyze.startIndex, end: firstBoundary)
            if !moduleText.isEmpty {
                completeModules.append(moduleText)
            }
        }

        lastSafeUpperBoundOffset = textToAnalyze.distance(from: textToAnalyze.startIndex, to: lastBoundary)
        let pendingText = lastBoundary < textToAnalyze.endIndex
            ? String(textToAnalyze[lastBoundary...])
            : ""
        return ModuleDetectionResult(
            completeModules: completeModules,
            pendingText: pendingText,
            hasPendingStructure: false,
            pendingType: nil
        )
    }

    private func detectPendingStructure(in text: String) -> PendingStructureType? {
        let trimmedEnd = text.suffix(10)
        if trimmedEnd.contains("`") {
            let backtickSuffix = String(text.suffix(5))
            if backtickSuffix.hasSuffix("`"), !backtickSuffix.hasSuffix("```") {
                let run = backtickSuffix.reversed().prefix(while: { $0 == "`" })
                if run.count == 1 || run.count == 2 {
                    return .codeBlock
                }
            }
        }

        let nsText = text as NSString
        let fence = "```"
        var codeBlockCount = 0
        var searchRange = NSRange(location: 0, length: nsText.length)
        while searchRange.location < nsText.length {
            let foundRange = nsText.range(of: fence, options: [], range: searchRange)
            if foundRange.location == NSNotFound { break }
            codeBlockCount += 1
            searchRange.location = foundRange.location + foundRange.length
            searchRange.length = nsText.length - searchRange.location
        }
        if codeBlockCount % 2 != 0 { return .codeBlock }

        let latexFence = "$$"
        var latexCount = 0
        searchRange = NSRange(location: 0, length: nsText.length)
        while searchRange.location < nsText.length {
            let foundRange = nsText.range(of: latexFence, options: [], range: searchRange)
            if foundRange.location == NSNotFound { break }
            latexCount += 1
            searchRange.location = foundRange.location + foundRange.length
            searchRange.length = nsText.length - searchRange.location
        }
        if latexCount % 2 != 0 { return .latexBlock }

        let trimmed = lastNonEmptyLineTrimmed(in: text)
        if trimmed.hasPrefix("|"), trimmed.contains("|"), !text.hasSuffix("\n\n") {
            return .table
        }

        return nil
    }

    private func isPlainText(_ text: String) -> Bool {
        let markers = ["#", "> ", "```", "---", "***", "- ", "* ", "+ ", "| ", "1. ", "2. ", "3. ", "![", "[$"]
        for marker in markers where text.contains(marker) { return false }
        if text.contains("**") || text.contains("__") || text.contains("`") || text.contains("$$") {
            return false
        }
        return true
    }

    /// 返回每个边界对应的 ``accumulatedText`` 中的 `Index`（边界为模块结束位置，即下一模块起点）。
    private func findModuleBoundaries(in text: String, from startPosition: String.Index) -> [String.Index] {
        var h1Positions: [String.Index] = []
        var h2Positions: [String.Index] = []
        var paragraphBoundaries: [String.Index] = []

        var isInsideCodeBlock = false
        var paragraphStart = startPosition
        var hasRenderableSinceParagraphStart = false

        var lineStart = text.startIndex
        while lineStart < text.endIndex {
            let lineEnd: String.Index
            let afterLine: String.Index
            if let nl = text.range(of: "\n", range: lineStart..<text.endIndex) {
                lineEnd = nl.lowerBound
                afterLine = nl.upperBound
            } else {
                lineEnd = text.endIndex
                afterLine = text.endIndex
            }

            let line = String(text[lineStart..<lineEnd])
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isFenceMarker = trimmed.hasPrefix("```")
            let isOutsideCodeBlock = !isInsideCodeBlock

            let isWithinSearchRange = lineStart >= startPosition
            // 标题位置必须基于全文收集：流式提交第一段后 `startPosition` 会前移，否则只剩「第二个 # 」无法触发多 H1 切分。
            let isH1 = isOutsideCodeBlock
                && trimmed.hasPrefix("# ") && !trimmed.hasPrefix("## ")
            let isH2 = isOutsideCodeBlock
                && trimmed.hasPrefix("## ") && !trimmed.hasPrefix("### ")

            if isH1 {
                h1Positions.append(lineStart)
            } else if isH2 {
                h2Positions.append(lineStart)
            }

            if isWithinSearchRange {
                if !trimmed.isEmpty && !isH1 && !isH2 {
                    hasRenderableSinceParagraphStart = true
                }
                if isOutsideCodeBlock && trimmed.isEmpty && hasRenderableSinceParagraphStart {
                    let moduleLength = text.distance(from: paragraphStart, to: afterLine)
                    if moduleLength >= minModuleLength {
                        paragraphBoundaries.append(afterLine)
                        paragraphStart = afterLine
                        hasRenderableSinceParagraphStart = false
                    }
                }
            }

            if isFenceMarker {
                let wasInsideFence = isInsideCodeBlock
                isInsideCodeBlock.toggle()
                // 闭合围栏：在此处一切分点结束「标题/前文 + 完整代码块」模块，避免无空行时把后续正文与代码块粘成一块。
                if wasInsideFence, isInsideCodeBlock == false, lineStart >= startPosition {
                    if paragraphBoundaries.last != afterLine {
                        paragraphBoundaries.append(afterLine)
                    }
                    paragraphStart = afterLine
                    hasRenderableSinceParagraphStart = false
                }
            }

            if afterLine >= text.endIndex {
                break
            }
            lineStart = afterLine
        }

        var boundaries: [String.Index] = []

        if h1Positions.count >= 2 {
            for boundary in h1Positions.dropFirst() where boundary >= startPosition {
                boundaries.append(boundary)
            }
        } else if h2Positions.count >= 2 {
            for boundary in h2Positions.dropFirst() where boundary >= startPosition {
                boundaries.append(boundary)
            }
        } else {
            var pb = paragraphBoundaries
            // 与常见流式 Markdown 组件一致：最后一个正文段后若无收尾空行，仍按 EOF 提交（不在未闭合围栏内时）。
            if isInsideCodeBlock == false,
               hasRenderableSinceParagraphStart,
               paragraphStart >= startPosition,
               paragraphStart < text.endIndex {
                let tailUTF16 = text[paragraphStart...].utf16.count
                if tailUTF16 >= minModuleLength, pb.last != text.endIndex,
                   !shouldDeferCommitAwaitingPossibleSecondTopLevelHeading(in: text) {
                    pb.append(text.endIndex)
                }
            }
            boundaries = pb
        }

        return boundaries
    }

    private func extractModule(from text: String, start: String.Index, end: String.Index) -> String {
        guard start < end, end <= text.endIndex else { return "" }
        return String(text[start..<end])
    }

    /// 当前全文恰有 1 个一级 `# ` 标题且以 `\n\n` 结尾时，流式上很可能继续追加下一个顶级标题；避免把前缀一次性标为已提交，否则下一 chunk 的切分点会与 `startPosition` 重合而被 `>` 条件丢弃。
    private func shouldDeferCommitAwaitingPossibleSecondTopLevelHeading(in text: String) -> Bool {
        guard text.hasSuffix("\n\n") else { return false }
        var h1Count = 0
        var isInsideCodeBlock = false
        var lineStart = text.startIndex
        while lineStart < text.endIndex {
            let lineEnd: String.Index
            let afterLine: String.Index
            if let nl = text.range(of: "\n", range: lineStart..<text.endIndex) {
                lineEnd = nl.lowerBound
                afterLine = nl.upperBound
            } else {
                lineEnd = text.endIndex
                afterLine = text.endIndex
            }
            let line = String(text[lineStart..<lineEnd])
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isFenceMarker = trimmed.hasPrefix("```")
            if isFenceMarker {
                isInsideCodeBlock.toggle()
            } else if !isInsideCodeBlock, trimmed.hasPrefix("# "), !trimmed.hasPrefix("## ") {
                h1Count += 1
            }
            if afterLine >= text.endIndex { break }
            lineStart = afterLine
        }
        return h1Count == 1
    }

    private func indexInCurrentText(offset: Int) -> String.Index {
        let text = accumulatedText
        guard offset > 0 else { return text.startIndex }
        return text.index(text.startIndex, offsetBy: offset, limitedBy: text.endIndex) ?? text.endIndex
    }

    /// 与 `lines.last { !$0.trimmingCharacters(in: .whitespaces).isEmpty }` 语义一致，但不分配整份按行数组，
    /// 长文流式场景下避免 O(n) 额外内存与一次全量扫描。
    private func lastNonEmptyLineTrimmed(in text: String) -> String {
        guard text.isEmpty == false else { return "" }
        var endExclusive = text.endIndex
        while endExclusive > text.startIndex {
            let lineStart: String.Index
            if let r = text.range(of: "\n", options: .backwards, range: text.startIndex..<endExclusive) {
                lineStart = r.upperBound
            } else {
                lineStart = text.startIndex
            }
            let trimmed = text[lineStart..<endExclusive].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                if lineStart == text.startIndex {
                    return ""
                }
                endExclusive = text.index(before: lineStart)
                continue
            }
            return trimmed
        }
        return ""
    }

    private func hasTableSeparatorRow(in text: String) -> Bool {
        for line in text.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            guard t.hasPrefix("|") && t.contains("-") else { continue }
            let cells = t.components(separatedBy: "|").filter { !$0.isEmpty }
            if !cells.isEmpty && cells.allSatisfy({
                $0.trimmingCharacters(in: .whitespaces).allSatisfy({ $0 == "-" || $0 == ":" || $0 == " " })
            }) {
                return true
            }
        }
        return false
    }
}
