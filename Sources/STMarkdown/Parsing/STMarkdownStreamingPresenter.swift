//
//  STMarkdownSemanticNormalizer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public enum STMarkdownStreamingBlockKind {
    case paragraph
    case heading
    case list
    case table
    case quote
    case fencedCode
    case thematicBreak
}

public enum STMarkdownStreamingPresenter {
    
    private static let streamingPartialOrderedListMarkerRegex = try! NSRegularExpression(
        pattern: #"^\d+\.?$"#,
        options: []
    )
    private static let headingLineRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{0,3})#{1,6}[ \t]+(.+)$"#,
        options: []
    )
    private static let headingStrongLineRegex = try! NSRegularExpression(
        pattern: #"^[ \t]{0,3}#{1,6}[ \t]+\*\*.+$"#,
        options: []
    )
    private static let blockquoteLineRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{0,3})>[ \t]?(.*)$"#,
        options: []
    )
    private static let danglingListMarkerSuffixRegex = try! NSRegularExpression(
        pattern: #"\n[ \t]*([-*+][ \t]*)?$"#,
        options: []
    )
    private static let listLineContentCaptureRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{0,3}(?:[-+*]|\d+\.)[ \t]+)(.*)$"#,
        options: []
    )
    /// 全角/中文标点紧跟 `*` 的 CJK 边界修正，补插 ZWNJ（U+200C）。
    private static let streamingActiveCjkEmphasisBoundaryRegex = try! NSRegularExpression(
        pattern: #"([）】」』》”’，。！？；：…—])(?=\*)"#,
        options: []
    )

    private struct StreamingBlockRange {
        let start: Int
        let endExclusive: Int
        let kind: STMarkdownStreamingBlockKind
    }

    public static func splitStableStreamingPrefixAndActiveBlock(in text: String) -> (stable: String, active: String?) {
        guard !text.isEmpty else { return ("", nil) }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let blockRanges = Self.streamingTopLevelBlockRanges(in: lines)
        guard let activeRange = blockRanges.last else {
            return (text, nil)
        }

        var effectiveActiveStart = activeRange.start
        if activeRange.kind == .paragraph {
            var index = blockRanges.count - 1
            while index > 0 {
                let previous = blockRanges[index - 1]
                guard previous.kind == .paragraph else { break }
                effectiveActiveStart = previous.start
                index -= 1
            }
        }

        let stableLines = Array(lines[..<effectiveActiveStart])
        let activeLines = Array(lines[effectiveActiveStart..<activeRange.endExclusive])
        let stable = stableLines.joined(separator: "\n")
        let active = activeLines.joined(separator: "\n")
        return active.isEmpty ? (stable, nil) : (stable, active)
    }

    public static func splitStableStreamingPrefixAndActiveBlockForReply(in text: String) -> (stable: String, active: String?) {
        guard !text.isEmpty else { return ("", nil) }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let blockRanges = Self.streamingTopLevelBlockRanges(in: lines)
        guard let activeRange = blockRanges.last else {
            return (text, nil)
        }

        if activeRange.kind == .list {
            let stableLines = Array(lines[..<activeRange.start])
            let activeLines = Array(lines[activeRange.start..<activeRange.endExclusive])
            let stable = stableLines.joined(separator: "\n")
            let active = activeLines.joined(separator: "\n")
            return active.isEmpty ? (stable, nil) : (stable, active)
        }

        if let listAttachedRange = Self.trailingListAttachedParagraphRangeForReply(in: lines, blockRanges: blockRanges) {
            let stableLines = Array(lines[..<listAttachedRange.start])
            let activeLines = Array(lines[listAttachedRange.start..<listAttachedRange.endExclusive])
            let stable = stableLines.joined(separator: "\n")
            let active = activeLines.joined(separator: "\n")
            return active.isEmpty ? (stable, nil) : (stable, active)
        }

        return Self.splitStableStreamingPrefixAndActiveBlock(in: text)
    }

    public static func inferStreamingActiveBlockKind(from activeText: String, committedPrefix: String) -> STMarkdownStreamingBlockKind {
        let inferred = Self.inferStreamingBlockKind(from: activeText)
        guard inferred == .paragraph else { return inferred }
        guard Self.isStreamingPartialListMarkerBlock(activeText) else { return inferred }
        guard Self.trailingCommittedBlockKind(in: committedPrefix) == .list else { return inferred }
        return .list
    }

    public static func makeStableStreamingPrefixPresentation(from text: String) -> String {
        guard !text.isEmpty else { return "" }
        let citationTrimmed = STMarkdownStreamingTransforms.trimTrailingIncompleteCitationTags(in: text)
        let tableClean = STMarkdownStreamingTransforms.transformTableBlocksForStreaming(in: citationTrimmed)
        return STMarkdownStreamingTransforms.sanitizeStreamingCitationTagsForPresentation(in: tableClean)
    }

    public static func makeActiveStreamingBlockPresentation(from text: String) -> String {
        guard !text.isEmpty else { return "" }
        let citationTrimmed = STMarkdownStreamingTransforms.trimTrailingIncompleteCitationTags(in: text)
        let markdownSyntaxTrimmed = STMarkdownStreamingTransforms.trimIncompleteTrailingMarkdownSyntax(in: citationTrimmed)
        let tablePresentation = Self.makeStreamingTablePresentation(from: citationTrimmed)
        if !tablePresentation.isEmpty {
            return STMarkdownStreamingTransforms.sanitizeStreamingCitationTagsForPresentation(in: tablePresentation)
        }
        if Self.isLikelyStreamingTableBlockCandidate(markdownSyntaxTrimmed) {
            return ""
        }

        let tableTrimmed = Self.trimTrailingIncompleteTableConstruction(in: markdownSyntaxTrimmed)
        if tableTrimmed.isEmpty {
            return ""
        }

        let standaloneStrongClosed = Self.autoCloseTrailingStandaloneStrongLine(in: tableTrimmed)
        let listItemLineClosed = Self.autoCloseDanglingEmphasisInTrailingListItem(in: standaloneStrongClosed)
        let emphasisClean = STMarkdownStreamingTransforms.trimIncompleteTrailingEmphasis(in: listItemLineClosed)
        let inlineCodeClosed = STMarkdownStreamingTransforms.autoCloseTrailingInlineCode(in: emphasisClean)
        let listLeadingEmphasisSoftened = STMarkdownStreamingTransforms.softenTrailingListLeadingDanglingEmphasis(in: inlineCodeClosed)
        let setextSafe = STMarkdownStreamingTransforms.trimTrailingSetextHeadingAmbiguity(in: listLeadingEmphasisSoftened)
        let escapedMathSafe = STMarkdownStreamingTransforms.trimTrailingDanglingEscapedMathDelimiter(in: setextSafe)
        let listDanglingEmphasisTrimmed = STMarkdownStreamingTransforms.trimTrailingListMarkerWithDanglingEmphasis(in: escapedMathSafe)
        let finalBareListTrimmed = STMarkdownStreamingTransforms.trimTrailingBareListMarker(in: listDanglingEmphasisTrimmed)
        let finalBareBlockTrimmed = STMarkdownStreamingTransforms.trimTrailingBareBlockMarker(in: finalBareListTrimmed)
        let htmlSafe = STMarkdownStreamingTransforms.trimTrailingIncompleteHtmlTag(in: finalBareBlockTrimmed)
        let stabilized = STMarkdownStreamingTransforms.stabilizeStreamingPresentationTail(in: htmlSafe)
        let thematicBreakSuppressed = Self.suppressTrailingThematicBreakLine(in: stabilized)
        guard thematicBreakSuppressed.contains("*"), thematicBreakSuppressed.count > 2 else {
            return thematicBreakSuppressed
        }
        return Self.streamingActiveCjkEmphasisBoundaryRegex.stringByReplacingMatches(
            in: thematicBreakSuppressed,
            range: NSRange(thematicBreakSuppressed.startIndex..., in: thematicBreakSuppressed),
            withTemplate: "$1\u{200C}"
        )
    }

    public static func makeLiveReplyStreamingActivePresentation(from text: String, kind: STMarkdownStreamingBlockKind) -> String {
        guard !text.isEmpty else { return "" }
        switch kind {
        case .paragraph:
            return Self.makeActiveStreamingBlockPresentation(from: text)
        case .quote:
            return Self.makeActiveStreamingBlockPresentation(from: text)
        case .list:
            return Self.makeActiveStreamingBlockPresentation(from: text)
        case .heading:
            return Self.makeActiveStreamingBlockPresentation(from: text)
        case .table:
            return Self.makeStreamingTablePresentation(from: text)
        case .fencedCode:
            return text.hasSuffix("```") || text.hasSuffix("~~~") ? text : ""
        case .thematicBreak:
            return ""
        }
    }

    public static func makeCompletedReplyStreamingActivePresentation(from text: String, kind: STMarkdownStreamingBlockKind) -> String {
        guard !text.isEmpty else { return "" }
        switch kind {
        case .paragraph:
            return Self.makeActiveStreamingBlockPresentation(from: text)
        case .list:
            return Self.makeActiveStreamingBlockPresentation(from: text)
        case .heading:
            return Self.makeActiveStreamingBlockPresentation(from: text)
        case .quote:
            return Self.makeActiveStreamingBlockPresentation(from: text)
        case .table:
            return Self.makeStreamingTablePresentation(from: text)
        case .fencedCode:
            return text.hasSuffix("```") || text.hasSuffix("~~~") ? text : ""
        case .thematicBreak:
            return text.hasSuffix("\n") ? text.trimmingCharacters(in: .newlines) : ""
        }
    }

    public static func joinStreamingPresentationSegments(_ lhs: String, _ rhs: String) -> String {
        if lhs.isEmpty { return rhs }
        if rhs.isEmpty { return lhs }
        if lhs.hasSuffix("\n\n") {
            return lhs + rhs
        }
        if lhs.hasSuffix("\n") {
            return lhs + "\n" + rhs
        }
        return lhs + "\n\n" + rhs
    }

    public static func replyPreferredCommittedMarkdown(
        proposedCommitted: String,
        semanticSnapshot: STMarkdownStreamingStateMachine.Snapshot,
        preparedMarkdown: String,
        previousCommitted: String,
        citationURLMapping: [String: Int] = [:]
    ) -> String {
        var candidates: [String] = []
        if !proposedCommitted.isEmpty, preparedMarkdown.hasPrefix(proposedCommitted) {
            candidates.append(proposedCommitted)
        }
        if !semanticSnapshot.stablePrefix.isEmpty,
           preparedMarkdown.hasPrefix(semanticSnapshot.stablePrefix) {
            candidates.append(semanticSnapshot.stablePrefix)
        }
        if !previousCommitted.isEmpty {
            let safePrevious = Self.trimDanglingListMarkerSuffix(previousCommitted)
            if preparedMarkdown.hasPrefix(safePrevious) {
                candidates.append(safePrevious)
            } else if !citationURLMapping.isEmpty {
                let translated = Self.replaceMarkdownLinksWithCitations(
                    in: safePrevious,
                    citationURLMapping: citationURLMapping
                )
                if translated != safePrevious, preparedMarkdown.hasPrefix(translated) {
                    candidates.append(translated)
                }
            }
        }

        guard let best = candidates.max(by: { $0.count < $1.count }) else {
            return proposedCommitted
        }
        return Self.trimDanglingListMarkerSuffix(best)
    }

    public static func preferredReplySemanticSnapshot(
        primary: STMarkdownStreamingStateMachine.Snapshot,
        fallback: STMarkdownStreamingStateMachine.Snapshot,
        preparedMarkdown: String
    ) -> STMarkdownStreamingStateMachine.Snapshot {
        let primaryValid = preparedMarkdown.hasPrefix(primary.stablePrefix)
        let fallbackValid = preparedMarkdown.hasPrefix(fallback.stablePrefix)

        switch (primaryValid, fallbackValid) {
        case (true, true):
            return fallback.stablePrefix.count > primary.stablePrefix.count
                ? fallback
                : primary
        case (false, true):
            return fallback
        default:
            return primary
        }
    }

    public static func replyActiveText(from preparedMarkdown: String, committedMarkdown: String) -> String {
        guard !preparedMarkdown.isEmpty else { return "" }
        guard !committedMarkdown.isEmpty else { return preparedMarkdown }
        guard preparedMarkdown.hasPrefix(committedMarkdown) else { return preparedMarkdown }
        return String(preparedMarkdown.dropFirst(committedMarkdown.count))
    }

    public static func trimUnstableTrailingTableSuffixForReply(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let normalizedLines = lines.map(Self.normalizeStreamingTableDelimiters(in:))
        let nonEmptyIndices = normalizedLines.indices.filter {
            !normalizedLines[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard let suffixStart = Self.unstableTrailingTableSuffixStart(
            in: normalizedLines,
            nonEmptyIndices: nonEmptyIndices
        ) else {
            return text
        }

        var stableLines = Array(lines[..<suffixStart])
        while let last = stableLines.last,
              last.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            stableLines.removeLast()
        }
        return stableLines.joined(separator: "\n")
    }

    private static func streamingTopLevelBlockRanges(in lines: [String]) -> [StreamingBlockRange] {
        guard !lines.isEmpty else { return [] }
        var ranges: [StreamingBlockRange] = []
        var index = 0
        while index < lines.count {
            if lines[index].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                index += 1
                continue
            }
            let start = index
            let block = Self.streamingBlock(in: lines, start: start)
            ranges.append(block)
            index = max(block.endExclusive, start + 1)
        }
        return ranges
    }

    private static func streamingBlock(in lines: [String], start: Int) -> StreamingBlockRange {
        let line = lines[start]
        if Self.isFencedCodeFenceLine(line) {
            return StreamingBlockRange(
                start: start,
                endExclusive: Self.endIndexOfFencedCodeBlock(in: lines, start: start),
                kind: .fencedCode
            )
        }
        if Self.isStreamingTableBlockStart(in: lines, index: start) {
            return StreamingBlockRange(
                start: start,
                endExclusive: Self.endIndexOfStreamingTableBlock(in: lines, start: start),
                kind: .table
            )
        }
        if STMarkdownStreamingTransforms.isStreamingListLine(line) {
            return StreamingBlockRange(
                start: start,
                endExclusive: Self.endIndexOfStreamingListBlock(in: lines, start: start),
                kind: .list
            )
        }
        if Self.isStreamingQuoteLine(line) {
            return StreamingBlockRange(
                start: start,
                endExclusive: Self.endIndexOfStreamingQuoteBlock(in: lines, start: start),
                kind: .quote
            )
        }
        if Self.isStreamingSingleLineBlock(line) {
            let kind: STMarkdownStreamingBlockKind = Self.headingLineRegex.firstMatch(
                in: line.trimmingCharacters(in: .whitespaces),
                options: [],
                range: NSRange(location: 0, length: line.trimmingCharacters(in: .whitespaces).utf16.count)
            ) != nil ? .heading : .thematicBreak
            return StreamingBlockRange(start: start, endExclusive: start + 1, kind: kind)
        }
        return StreamingBlockRange(
            start: start,
            endExclusive: Self.endIndexOfStreamingParagraphBlock(in: lines, start: start),
            kind: .paragraph
        )
    }

    private static func endIndexOfFencedCodeBlock(in lines: [String], start: Int) -> Int {
        let opening = lines[start].trimmingCharacters(in: .whitespaces)
        let fenceToken = String(opening.prefix(3))
        var index = start + 1
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix(fenceToken) {
                return index + 1
            }
            index += 1
        }
        return lines.count
    }

    private static func endIndexOfStreamingTableBlock(in lines: [String], start: Int) -> Int {
        var index = start + 2
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || !Self.isStreamingTableCandidateLine(lines[index]) {
                break
            }
            index += 1
        }
        return index
    }

    private static func endIndexOfStreamingListBlock(in lines: [String], start: Int) -> Int {
        var index = start + 1
        while index < lines.count {
            let rawLine = lines[index]
            let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                break
            }
            let indent = rawLine.prefix { $0 == " " || $0 == "\t" }.count
            if STMarkdownStreamingTransforms.isStreamingListLine(rawLine)
                || Self.isStreamingPartialListMarkerLine(rawLine)
                || indent >= 2 {
                index += 1
                continue
            }
            break
        }
        return index
    }

    private static func endIndexOfStreamingQuoteBlock(in lines: [String], start: Int) -> Int {
        var index = start + 1
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || !Self.isStreamingQuoteLine(lines[index]) {
                break
            }
            index += 1
        }
        return index
    }

    private static func endIndexOfStreamingParagraphBlock(in lines: [String], start: Int) -> Int {
        var index = start + 1
        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || Self.isStreamingExplicitBlockStart(in: lines, index: index) {
                break
            }
            index += 1
        }
        return index
    }

    private static func isStreamingExplicitBlockStart(in lines: [String], index: Int) -> Bool {
        let line = lines[index]
        return Self.isFencedCodeFenceLine(line)
            || Self.isStreamingTableBlockStart(in: lines, index: index)
            || STMarkdownStreamingTransforms.isLikelyStreamingTableHeaderCandidate(line)
            || STMarkdownStreamingTransforms.isStreamingListLine(line)
            || Self.isStreamingQuoteLine(line)
            || Self.isStreamingSingleLineBlock(line)
    }

    private static func isStreamingSingleLineBlock(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let lineRange = NSRange(location: 0, length: trimmed.utf16.count)
        if Self.headingLineRegex.firstMatch(in: trimmed, options: [], range: lineRange) != nil {
            return true
        }
        return Self.isThematicBreakLine(trimmed)
    }

    private static func isFencedCodeFenceLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~")
    }

    private static func isStreamingTableBlockStart(in lines: [String], index: Int) -> Bool {
        guard index + 1 < lines.count else { return false }
        let header = lines[index].trimmingCharacters(in: .whitespaces)
        let separator = lines[index + 1].trimmingCharacters(in: .whitespaces)
        guard STMarkdownStreamingTransforms.isLikelyStreamingTableHeaderCandidate(header) else { return false }
        let separatorCharsOnly = separator.allSatisfy { ch in
            ch == "|" || ch == "-" || ch == ":" || ch == " " || ch == "\t"
        }
        return separatorCharsOnly && separator.contains("-")
    }

    private static func isStreamingPartialListMarkerLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        if ["-", "+", "*"].contains(trimmed) { return true }
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        return Self.streamingPartialOrderedListMarkerRegex.firstMatch(in: trimmed, options: [], range: range) != nil
    }

    private static func isStreamingQuoteLine(_ line: String) -> Bool {
        let range = NSRange(location: 0, length: line.utf16.count)
        return Self.blockquoteLineRegex.firstMatch(in: line, options: [], range: range) != nil
    }

    private static func isThematicBreakLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else { return false }
        let chars = trimmed.filter { !$0.isWhitespace }
        guard let first = chars.first, first == "-" || first == "*" || first == "_" else {
            return false
        }
        return chars.allSatisfy { $0 == first }
    }

    private static func inferStreamingBlockKind(from text: String) -> STMarkdownStreamingBlockKind {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let firstNonEmpty = lines.first(where: {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else {
            return .paragraph
        }
        if Self.isFencedCodeFenceLine(firstNonEmpty) { return .fencedCode }
        if Self.isStreamingTableBlockStart(in: lines, index: 0) || Self.isLikelyStreamingTableBlockCandidate(text) {
            return .table
        }
        if STMarkdownStreamingTransforms.isStreamingListLine(firstNonEmpty) { return .list }
        if Self.isStreamingQuoteLine(firstNonEmpty) { return .quote }
        if Self.isStreamingSingleLineBlock(firstNonEmpty) {
            let trimmed = firstNonEmpty.trimmingCharacters(in: .whitespaces)
            let range = NSRange(location: 0, length: trimmed.utf16.count)
            return Self.headingLineRegex.firstMatch(in: trimmed, options: [], range: range) != nil
                ? .heading
                : .thematicBreak
        }
        return .paragraph
    }

    private static func trailingCommittedBlockKind(in text: String) -> STMarkdownStreamingBlockKind? {
        guard !text.isEmpty else { return nil }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let ranges = Self.streamingTopLevelBlockRanges(in: lines)
        return ranges.last?.kind
    }

    private static func isStreamingPartialListMarkerBlock(_ text: String) -> Bool {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard nonEmptyLines.count == 1, let line = nonEmptyLines.first else { return false }
        return Self.isStreamingPartialListMarkerLine(line)
    }

    private static func trailingListAttachedParagraphRangeForReply(in lines: [String], blockRanges: [StreamingBlockRange]) -> StreamingBlockRange? {
        guard blockRanges.count >= 2 else { return nil }
        let activeRange = blockRanges[blockRanges.count - 1]
        let previousRange = blockRanges[blockRanges.count - 2]
        guard activeRange.kind == .paragraph, previousRange.kind == .list else { return nil }
        guard previousRange.endExclusive == activeRange.start else { return nil }
        let activeLines = Array(lines[activeRange.start..<activeRange.endExclusive])
        guard activeLines.contains(where: {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else {
            return nil
        }
        return StreamingBlockRange(start: previousRange.start, endExclusive: activeRange.endExclusive, kind: .list)
    }

    private static func lastStreamingListItemStartOffset(in lines: [String]) -> Int? {
        guard !lines.isEmpty else { return nil }
        var markerIndices: [Int] = []
        for (index, line) in lines.enumerated() {
            if STMarkdownStreamingTransforms.isStreamingListLine(line) || Self.isStreamingPartialListMarkerLine(line) {
                markerIndices.append(index)
            }
        }
        guard markerIndices.count >= 2 else { return nil }
        return markerIndices.last
    }

    private static func shouldSplitActiveListItem(in listBlockLines: [String], lastItemStartOffset: Int) -> Bool {
        guard lastItemStartOffset > 0, lastItemStartOffset < listBlockLines.count else { return false }
        let candidateLines = Array(listBlockLines[lastItemStartOffset...])
        let candidateText = candidateLines.joined(separator: "\n")
        let candidatePresentation = Self.makeActiveStreamingBlockPresentation(from: candidateText)
        guard !candidatePresentation.isEmpty else { return false }
        let visibleLines = candidatePresentation
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        guard let firstVisibleLine = visibleLines.first else { return false }

        let firstLineRange = NSRange(location: 0, length: firstVisibleLine.utf16.count)
        if let match = Self.listLineContentCaptureRegex.firstMatch(
            in: firstVisibleLine,
            options: [],
            range: firstLineRange
        ), match.numberOfRanges == 3,
           let contentRange = Range(match.range(at: 2), in: firstVisibleLine) {
            let body = firstVisibleLine[contentRange].trimmingCharacters(in: .whitespacesAndNewlines)
            return !body.isEmpty
        }

        return !Self.isStreamingPartialListMarkerLine(firstVisibleLine)
    }

    private static func suppressTrailingThematicBreakLine(in text: String) -> String {
        guard !text.isEmpty else { return text }
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let lastNonEmptyIndex = lines.lastIndex(where: {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else {
            return text
        }
        guard Self.isThematicBreakLine(lines[lastNonEmptyIndex]) else { return text }
        lines = Array(lines[..<lastNonEmptyIndex])
        var result = lines.joined(separator: "\n")
        while result.hasSuffix("\n") {
            result.removeLast()
        }
        return result
    }

    private static func autoCloseDanglingEmphasisInTrailingListItem(in text: String) -> String {
        // SSE 流式阶段列表项 marker 行尾部 emphasis 未闭合，后续 token 未知，不补闭合。
        // trimIncompleteTrailingEmphasis 会在后续步骤将孤立 marker trim 掉。
        return text
    }

    private static func autoCloseTrailingStandaloneStrongLine(in text: String) -> String {
        guard !text.isEmpty else { return text }
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let lastNonEmptyIndex = lines.lastIndex(where: {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else {
            return text
        }
        let line = lines[lastNonEmptyIndex]
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return text }
        guard !trimmed.contains("|") else { return text }
        let nsRange = NSRange(location: 0, length: trimmed.utf16.count)
        let isStandaloneStrongLine = trimmed.hasPrefix("**")
        let isHeadingStrongLine = Self.headingStrongLineRegex.firstMatch(in: trimmed, options: [], range: nsRange) != nil
        guard isStandaloneStrongLine || isHeadingStrongLine else { return text }
        guard !trimmed.hasSuffix("**") else { return text }
        guard Self.countUnescapedOccurrences(of: "**", in: trimmed) == 1 else { return text }
        // SSE 流式阶段尾部 ** 未闭合，后续 token 未知，不能补闭合。
        // 将包含孤立 ** 的尾行移除，待闭合符到达后再渲染。
        lines.removeSubrange(lastNonEmptyIndex...)
        while let last = lines.last, last.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.removeLast()
        }
        return lines.joined(separator: "\n")
    }

    private static func countUnescapedOccurrences(of token: String, in text: String) -> Int {
        guard !token.isEmpty else { return 0 }
        var count = 0
        var searchStart = text.startIndex
        while let range = text.range(of: token, range: searchStart..<text.endIndex) {
            let escaped = range.lowerBound > text.startIndex
                && text[text.index(before: range.lowerBound)] == "\\"
            if !escaped {
                count += 1
            }
            searchStart = range.upperBound
        }
        return count
    }

    private static func processStreamingNonTableMarkdownPreservingTables(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard !lines.isEmpty else { return text }

        var fenceState = [Bool](repeating: false, count: lines.count)
        var fenceFlag = false
        for i in 0..<lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                fenceFlag.toggle()
            }
            fenceState[i] = fenceFlag
        }

        var outputSegments: [String] = []
        var pendingNonTableLines: [String] = []

        func flushNonTable() {
            guard !pendingNonTableLines.isEmpty else { return }
            let joined = pendingNonTableLines.joined(separator: "\n")
            let standaloneStrongClosed = Self.autoCloseTrailingStandaloneStrongLine(in: joined)
            let emphasisClean = STMarkdownStreamingTransforms.trimIncompleteTrailingEmphasis(in: standaloneStrongClosed)
            let setextSafe = STMarkdownStreamingTransforms.trimTrailingSetextHeadingAmbiguity(in: emphasisClean)
            let escapedMathSafe = STMarkdownStreamingTransforms.trimTrailingDanglingEscapedMathDelimiter(in: setextSafe)
            let finalBareListTrimmed = STMarkdownStreamingTransforms.trimTrailingBareListMarker(in: escapedMathSafe)
            let finalBareBlockTrimmed = STMarkdownStreamingTransforms.trimTrailingBareBlockMarker(in: finalBareListTrimmed)
            outputSegments.append(finalBareBlockTrimmed)
            pendingNonTableLines.removeAll(keepingCapacity: true)
        }

        var i = 0
        while i < lines.count {
            if fenceState[i] {
                pendingNonTableLines.append(lines[i])
                i += 1
                continue
            }

            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            let pipeCount = trimmed.filter { $0 == "|" }.count
            if !trimmed.isEmpty && pipeCount >= 2 {
                let blockStart = i
                while i < lines.count {
                    if fenceState[i] { break }
                    let t = lines[i].trimmingCharacters(in: .whitespaces)
                    if t.isEmpty { break }
                    let pc = t.filter { $0 == "|" }.count
                    if pc >= 2 || t.hasPrefix("|") {
                        i += 1
                    } else {
                        break
                    }
                }
                let blockLines = Array(lines[blockStart..<i])
                let hasValidSeparator: Bool = {
                    guard blockLines.count >= 2 else { return false }
                    let sep = blockLines[1].trimmingCharacters(in: .whitespaces)
                    let nonSepChars = sep.filter { $0 != "|" && $0 != "-" && $0 != ":" && $0 != " " && $0 != "\t" }
                    return nonSepChars.isEmpty && sep.contains("--")
                }()
                if hasValidSeparator {
                    flushNonTable()
                    var validTableLines: [String] = []
                    validTableLines.append(blockLines[0])
                    validTableLines.append(blockLines[1])
                    for rowIdx in 2..<blockLines.count {
                        let rowTrimmed = blockLines[rowIdx].trimmingCharacters(in: .whitespaces)
                        let rowPipeCount = rowTrimmed.filter { $0 == "|" }.count
                        if rowPipeCount >= 2 {
                            validTableLines.append(blockLines[rowIdx])
                        }
                    }
                    if validTableLines.count >= 2 {
                        outputSegments.append(validTableLines.joined(separator: "\n"))
                    }
                    continue
                }
                pendingNonTableLines.append(contentsOf: blockLines)
                continue
            }

            pendingNonTableLines.append(lines[i])
            i += 1
        }

        flushNonTable()
        return outputSegments.joined(separator: "\n")
    }

    // MARK: - Private helpers: table

    private static func makeStreamingTablePresentation(from text: String) -> String {
        guard !text.isEmpty else { return "" }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.count >= 2 else { return "" }
        let separator = lines[1].trimmingCharacters(in: .whitespaces)
        let nonSepChars = separator.filter { $0 != "|" && $0 != "-" && $0 != ":" && $0 != " " && $0 != "\t" }
        guard nonSepChars.isEmpty, separator.contains("--") else { return "" }

        var validLines: [String] = []
        validLines.append(lines[0])
        validLines.append(lines[1])
        for row in lines.dropFirst(2) {
            let trimmed = row.trimmingCharacters(in: .whitespaces)
            let pipeCount = trimmed.filter { $0 == "|" }.count
            if pipeCount >= 2 {
                validLines.append(row)
            }
        }
        guard validLines.count >= 2 else { return "" }

        if validLines.count == 2 {
            let colCount = max(lines[0].filter({ $0 == "|" }).count - 1, 1)
            let emptyCells = Array(repeating: " ", count: colCount)
            validLines.append("| " + emptyCells.joined(separator: " | ") + " |")
        }

        let lastIdx = validLines.count - 1
        if lastIdx >= 2 {
            validLines[lastIdx] = Self.autoCloseEmphasisInTableRow(validLines[lastIdx])
        }

        return validLines.joined(separator: "\n")
    }

    private static func autoCloseEmphasisInTableRow(_ row: String) -> String {
        let parts = row.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count >= 3 else { return row }
        var result: [String] = []
        for (index, part) in parts.enumerated() {
            if index == 0 || index == parts.count - 1 {
                result.append(part)
                continue
            }
            result.append(Self.autoCloseEmphasisInCellContent(part))
        }
        return result.joined(separator: "|")
    }

    private static func autoCloseEmphasisInCellContent(_ cell: String) -> String {
        var text = cell
        let markers: [(String, Int)] = [("~~", 2), ("**", 2), ("__", 2), ("*", 1), ("_", 1)]
        for (marker, _) in markers {
            var count = 0
            var searchRange = text.startIndex..<text.endIndex
            while let range = text.range(of: marker, range: searchRange) {
                count += 1
                searchRange = range.upperBound..<text.endIndex
            }
            if count % 2 != 0 {
                text = text + marker
            }
        }
        return STMarkdownStreamingTransforms.trimTrailingMarkerOnlyEmphasisRun(in: text)
    }

    private static func isStreamingTableCandidateLine(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let pipeCount = trimmed.filter { $0 == "|" }.count
        if pipeCount >= 2 { return true }
        if trimmed.hasPrefix("|") { return true }
        let separatorCharsOnly = trimmed.allSatisfy { ch in
            ch == "|" || ch == "-" || ch == ":" || ch == " " || ch == "\t"
        }
        return separatorCharsOnly && trimmed.contains("-")
    }

    private static func isLikelyStreamingTableBlockCandidate(_ text: String) -> Bool {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let meaningfulLines = lines.filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !meaningfulLines.isEmpty else { return false }
        if meaningfulLines.count == 1 {
            return STMarkdownStreamingTransforms.isLikelyStreamingTableHeaderCandidate(meaningfulLines[0])
        }
        if meaningfulLines.count >= 2 {
            let first = meaningfulLines[0]
            let second = meaningfulLines[1]
            if STMarkdownStreamingTransforms.isLikelyStreamingTableHeaderCandidate(first) {
                let trimmedSecond = second.trimmingCharacters(in: .whitespaces)
                let separatorCharsOnly = trimmedSecond.allSatisfy { ch in
                    ch == "|" || ch == "-" || ch == ":" || ch == " " || ch == "\t"
                }
                if separatorCharsOnly || trimmedSecond.hasPrefix("|") {
                    return true
                }
            }
        }
        return false
    }

    private static func trimTrailingIncompleteTableConstruction(in text: String) -> String {
        guard !text.isEmpty else { return text }
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.count >= 1 else { return text }

        let normalizedLines = lines.map(Self.normalizeStreamingTableDelimiters(in:))
        let nonEmptyIndices = normalizedLines.indices.filter {
            !normalizedLines[$0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard let lastIdx = nonEmptyIndices.last else { return text }
        let lastLine = normalizedLines[lastIdx].trimmingCharacters(in: .whitespaces)

        if let unstableSuffixStart = Self.unstableTrailingTableSuffixStart(in: normalizedLines, nonEmptyIndices: nonEmptyIndices) {
            lines = Array(lines[..<unstableSuffixStart])
            var result = lines.joined(separator: "\n")
            while result.hasSuffix("\n\n") {
                result.removeLast()
            }
            return result
        }

        var suffixStart = lastIdx
        while suffixStart > 0 {
            let previous = normalizedLines[suffixStart - 1].trimmingCharacters(in: .whitespacesAndNewlines)
            if previous.isEmpty || !Self.isStreamingPotentialTableConstructionLine(previous) {
                break
            }
            suffixStart -= 1
        }
        let trailingConstructionLines = normalizedLines[suffixStart...lastIdx]
        let hasMultiLineConstruction = trailingConstructionLines.count >= 2
        let startsAtBlockBoundary: Bool = {
            guard suffixStart > 0 else { return true }
            let previous = normalizedLines[suffixStart - 1].trimmingCharacters(in: .whitespacesAndNewlines)
            if previous.isEmpty { return true }
            let range = NSRange(location: 0, length: previous.utf16.count)
            return Self.headingLineRegex.firstMatch(in: previous, options: [], range: range) != nil
                || Self.blockquoteLineRegex.firstMatch(in: previous, options: [], range: range) != nil
        }()
        if hasMultiLineConstruction, startsAtBlockBoundary,
           trailingConstructionLines.contains(where: { Self.isStreamingPotentialTableConstructionLine($0) }) {
            lines = Array(lines[..<suffixStart])
            var result = lines.joined(separator: "\n")
            while result.hasSuffix("\n\n") {
                result.removeLast()
            }
            return result
        }

        let previousLineIsBlockBoundary: Bool = {
            guard lastIdx > 0 else { return true }
            let previous = normalizedLines[lastIdx - 1].trimmingCharacters(in: .whitespacesAndNewlines)
            if previous.isEmpty { return true }
            let range = NSRange(location: 0, length: previous.utf16.count)
            return Self.headingLineRegex.firstMatch(in: previous, options: [], range: range) != nil
                || Self.blockquoteLineRegex.firstMatch(in: previous, options: [], range: range) != nil
        }()
        let lastPipeCount = lastLine.filter { $0 == "|" }.count
        if previousLineIsBlockBoundary, lastLine.hasPrefix("|"), lastPipeCount < 2 {
            lines = Array(lines[..<lastIdx])
            var result = lines.joined(separator: "\n")
            while result.hasSuffix("\n\n") {
                result.removeLast()
            }
            return result
        }

        let isSeparatorCharsOnly = !lastLine.isEmpty && lastLine.allSatisfy { ch in
            ch == "|" || ch == "-" || ch == ":" || ch == " " || ch == "\t"
        }
        if isSeparatorCharsOnly, lastLine.contains("|") || lastLine.contains("-") {
            let headerIdx = lastIdx - 1
            if headerIdx >= 0 {
                let headerLine = lines[headerIdx].trimmingCharacters(in: .whitespaces)
                if STMarkdownStreamingTransforms.isLikelyStreamingTableHeaderCandidate(headerLine) {
                    lines = Array(lines[..<headerIdx])
                    var result = lines.joined(separator: "\n")
                    while result.hasSuffix("\n\n") {
                        result.removeLast()
                    }
                    return result
                }
            }
        }

        if STMarkdownStreamingTransforms.isLikelyStreamingTableHeaderCandidate(lastLine) {
            lines = Array(lines[..<lastIdx])
            var result = lines.joined(separator: "\n")
            while result.hasSuffix("\n\n") {
                result.removeLast()
            }
            return result
        }

        return text
    }

    private static func isStreamingPotentialTableConstructionLine(_ line: String) -> Bool {
        let trimmed = Self.normalizeStreamingTableDelimiters(in: line).trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let pipeCount = trimmed.filter { $0 == "|" }.count
        if trimmed.hasPrefix("|") { return true }
        if pipeCount >= 2 { return true }
        let isSeparatorCharsOnly = trimmed.allSatisfy { ch in
            ch == "|" || ch == "-" || ch == ":" || ch == " " || ch == "\t"
        }
        return isSeparatorCharsOnly && (trimmed.contains("|") || trimmed.contains("-"))
    }

    private static func isStreamingPotentialTableSeparatorLine(_ line: String) -> Bool {
        let trimmed = Self.normalizeStreamingTableDelimiters(in: line).trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let isSeparatorCharsOnly = trimmed.allSatisfy { ch in
            ch == "|" || ch == "-" || ch == ":" || ch == " " || ch == "\t"
        }
        return isSeparatorCharsOnly && trimmed.contains("-")
    }

    private static func unstableTrailingTableSuffixStart(in normalizedLines: [String], nonEmptyIndices: [Int]) -> Int? {
        guard !nonEmptyIndices.isEmpty else { return nil }
        let recent = Array(nonEmptyIndices.suffix(4))
        guard let separatorIndex = recent.last(where: {
            Self.isStreamingPotentialTableSeparatorLine(normalizedLines[$0].trimmingCharacters(in: .whitespaces))
        }) else {
            return nil
        }
        let separatorPosition = recent.firstIndex(of: separatorIndex) ?? 0
        let prefixCandidates = recent.prefix(through: separatorPosition)
        guard let suffixStartNonEmptyIndex = prefixCandidates.first(where: {
            Self.isStreamingPotentialTableConstructionLine(normalizedLines[$0])
        }) else {
            return nil
        }
        let nextNonEmptyAfterSeparator = recent.dropFirst(separatorPosition + 1).first
        let nextLine: String? = nextNonEmptyAfterSeparator.map {
            normalizedLines[$0].trimmingCharacters(in: .whitespaces)
        }
        let dataRowIsStable: Bool = {
            guard let nextLine else { return false }
            let pipeCount = nextLine.filter { $0 == "|" }.count
            return nextLine.hasPrefix("|") && pipeCount >= 2
        }()
        guard !dataRowIsStable else { return nil }
        return suffixStartNonEmptyIndex
    }

    private static func trimDanglingListMarkerSuffix(_ committed: String) -> String {
        guard !committed.isEmpty else { return committed }
        let range = NSRange(committed.startIndex..., in: committed)
        guard let match = danglingListMarkerSuffixRegex.firstMatch(in: committed, range: range),
              let swiftRange = Range(match.range, in: committed) else {
            return committed
        }
        let keepEnd = committed.index(after: swiftRange.lowerBound)
        return String(committed[committed.startIndex..<keepEnd])
    }

    private static func replaceMarkdownLinksWithCitations(in text: String, citationURLMapping: [String: Int]) -> String {
        STMarkdownCitationURLMatcher(citationURLMapping: citationURLMapping).replaceMarkdownLinksWithCitations(in: text)
    }

    private static func normalizeStreamingTableDelimiters(in text: String) -> String {
        guard text.contains("｜") else { return text }
        return text.replacingOccurrences(of: "｜", with: "|")
    }
}
