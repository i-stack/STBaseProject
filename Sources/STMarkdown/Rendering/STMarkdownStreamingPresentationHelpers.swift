import Foundation

/// Generic stateless text-stabilization helpers for streaming markdown rendering.
/// Contains pure text-transformation utilities that have no app-specific state or
/// business logic. Depends only on other STMarkdown types.
public enum STMarkdownStreamingTextStabilizer {

    // MARK: - List structure detection

    public static func isListLine(_ trimmedLine: String) -> Bool {
        if trimmedLine.hasPrefix("- ")
            || trimmedLine.hasPrefix("+ ")
            || trimmedLine.hasPrefix("* ")
            || trimmedLine.hasPrefix("• ")
            || trimmedLine.hasPrefix("◦ ")
            || trimmedLine.hasPrefix("▪ ") {
            return true
        }
        return trimmedLine.range(of: #"^\d+(?:\.|）)\s+"#, options: .regularExpression) != nil
    }

    public static func endsWithOrderedListLine(_ text: String) -> Bool {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let lastNonEmpty = lines.last(where: {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else {
            return false
        }
        let trimmed = lastNonEmpty.trimmingCharacters(in: .whitespaces)
        guard let dotIndex = trimmed.firstIndex(of: "."),
              dotIndex > trimmed.startIndex else {
            return false
        }
        let digits = trimmed[..<dotIndex]
        guard !digits.isEmpty, digits.allSatisfy(\.isNumber) else {
            return false
        }
        let suffix = trimmed[trimmed.index(after: dotIndex)...]
        return suffix.first?.isWhitespace == true
    }

    public static func autoCloseTrailingListLineEmphasis(in line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, Self.isListLine(trimmed) else { return line }
        let markers = ["~~", "**", "__"]
        var updated = line
        for marker in markers {
            if Self.countUnescapedOccurrences(of: marker, in: updated) % 2 != 0 {
                if updated.hasSuffix(marker) {
                    updated = String(updated.dropLast(marker.count))
                } else if marker.count > 1 {
                    let unit = String(marker.prefix(1))
                    if updated.hasSuffix(unit) {
                        updated = String(updated.dropLast(unit.count))
                    }
                }
            }
        }
        return updated
    }

    // MARK: - Stable preview helpers

    public static func committedLinePrefix(in text: String) -> String {
        guard let lastNewline = text.lastIndex(of: "\n") else { return "" }
        return String(text[..<lastNewline])
    }

    public static func lastSentenceBoundary(in text: String) -> String.Index? {
        let closingCharacters = CharacterSet(charactersIn: "\"\u{2018}\u{2019}\u{201C}\u{201D}\u{FF09})]】」』 ")
        var index = text.endIndex
        while index > text.startIndex {
            let previous = text.index(before: index)
            let character = text[previous]
            if "。！？!?；;：:\n".contains(character) {
                var boundary = text.index(after: previous)
                while boundary < text.endIndex,
                      let scalar = text[boundary].unicodeScalars.first,
                      closingCharacters.contains(scalar) {
                    boundary = text.index(after: boundary)
                }
                return boundary
            }
            index = previous
        }
        return nil
    }

    public static func containsPotentiallyUnstableMarkdownSyntax(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        if text.contains("[") || text.contains("|") || text.contains("`") {
            return true
        }
        if text.contains("**") || text.contains("__") || text.contains("~~") {
            return true
        }
        if text.hasPrefix("#") || text.hasPrefix(">") {
            return true
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if ["*", "-", "+"].contains(trimmed) {
            return true
        }
        let orderedRange = NSRange(location: 0, length: trimmed.utf16.count)
        if STMarkdownStreamingRegex.streamingPartialOrderedListMarker.firstMatch(
            in: trimmed, options: [], range: orderedRange
        ) != nil {
            return true
        }
        return false
    }

    public static func makeStableParagraphPreview(from text: String) -> String {
        guard !text.isEmpty else { return "" }
        let stabilized = STMarkdownStreamingTransforms.stabilizeStreamingPresentationTail(in: text)
        if Self.containsPotentiallyUnstableMarkdownSyntax(stabilized) {
            if let boundary = Self.lastSentenceBoundary(in: stabilized) {
                return String(stabilized[..<boundary])
            }
            return ""
        }
        return stabilized
    }

    public static func makeStableListPreview(from text: String) -> String {
        guard !text.isEmpty else { return "" }
        let stabilized = STMarkdownStreamingTransforms.stabilizeStreamingPresentationTail(in: text)
        if !Self.containsPotentiallyUnstableMarkdownSyntax(stabilized) {
            return stabilized
        }
        return Self.committedLinePrefix(in: stabilized)
    }

    public static func makeStableQuotedPreview(from text: String) -> String {
        guard !text.isEmpty else { return "" }
        let stabilized = STMarkdownStreamingTransforms.stabilizeStreamingPresentationTail(in: text)
        if !Self.containsPotentiallyUnstableMarkdownSyntax(stabilized) {
            return stabilized
        }
        return Self.committedLinePrefix(in: stabilized)
    }

    public static func makeStableSingleLineBlockPreview(from text: String) -> String {
        guard !text.isEmpty else { return "" }
        let stabilized = STMarkdownStreamingTransforms.stabilizeStreamingPresentationTail(in: text)
        if stabilized.hasSuffix("\n") {
            return stabilized.trimmingCharacters(in: .newlines)
        }
        return Self.containsPotentiallyUnstableMarkdownSyntax(stabilized) ? "" : stabilized
    }

    // MARK: - Table helpers

    public static func isLikelyStreamingTableHeaderCandidate(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        let pipeCount = trimmed.filter { $0 == "|" }.count
        guard pipeCount >= 2 else { return false }
        if trimmed.hasPrefix("|") || trimmed.hasSuffix("|") {
            return true
        }
        let cells = trimmed
            .split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard cells.count >= 2 else { return false }
        let hasSentencePunctuation = cells.contains { cell in
            cell.contains("。") || cell.contains("，") || cell.contains("；") || cell.contains("：")
        }
        let maxCellLength = cells.map(\.count).max() ?? 0
        return !hasSentencePunctuation && maxCellLength <= 24
    }

    public static func containsLikelyTableSyntax(in lines: [String]) -> Bool {
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            let pipeCount = trimmed.filter { $0 == "|" }.count
            if pipeCount >= 2 || trimmed.hasPrefix("|") {
                return true
            }
        }
        return false
    }

    public static func makeStreamingTablePresentation(from text: String) -> String {
        guard !text.isEmpty else { return "" }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard !lines.isEmpty else { return "" }
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

    public static func autoCloseEmphasisInTableRow(_ row: String) -> String {
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

    public static func autoCloseEmphasisInCellContent(_ cell: String) -> String {
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

    // MARK: - Emphasis / marker helpers

    public static func autoCloseTrailingStandaloneStrongLine(in text: String) -> String {
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
        let isHeadingStrongLine = Self.headingStrongLineRegex.firstMatch(
            in: trimmed, options: [], range: nsRange
        ) != nil
        guard isStandaloneStrongLine || isHeadingStrongLine else { return text }
        guard !trimmed.hasSuffix("**") else { return text }
        guard Self.countUnescapedOccurrences(of: "**", in: trimmed) == 1 else { return text }
        let closingSuffix = line.hasSuffix("*") ? "*" : "**"
        lines[lastNonEmptyIndex] = line + closingSuffix
        return lines.joined(separator: "\n")
    }

    public static func countUnescapedOccurrences(of token: String, in text: String) -> Int {
        guard !token.isEmpty else { return 0 }
        var count = 0
        var searchStart = text.startIndex
        while let range = text.range(of: token, range: searchStart..<text.endIndex) {
            let escaped = range.lowerBound > text.startIndex
                && text[text.index(before: range.lowerBound)] == "\\"
            if !escaped { count += 1 }
            searchStart = range.upperBound
        }
        return count
    }

    /// 在单行中检测最后一个未配对的 marker 并截断。
    public static func trimUnpairedTrailingMarker(in line: String, marker: String, markerLen: Int) -> String {
        var positions: [String.Index] = []

        if markerLen == 1 {
            let markerChar = marker.first!
            var i = line.startIndex
            while i < line.endIndex {
                if line[i] == markerChar {
                    let runStart = i
                    var runLength = 0
                    var j = i
                    while j < line.endIndex, line[j] == markerChar {
                        runLength += 1
                        j = line.index(after: j)
                    }
                    if runLength % 2 == 1 {
                        var isListBullet = false
                        if runLength == 1, marker == "*" || marker == "-" || marker == "+" {
                            let lineHead: String.Index
                            if let prevNewline = line[line.startIndex..<runStart].lastIndex(of: "\n") {
                                lineHead = line.index(after: prevNewline)
                            } else {
                                lineHead = line.startIndex
                            }
                            let beforeMarker = line[lineHead..<runStart]
                            let onlyWhitespace = beforeMarker.allSatisfy { $0 == " " || $0 == "\t" }
                            let followedBySpace: Bool
                            if j < line.endIndex {
                                let after = line[j]
                                followedBySpace = after == " " || after == "\t"
                            } else {
                                followedBySpace = true
                            }
                            isListBullet = onlyWhitespace && followedBySpace
                        }
                        if !isListBullet {
                            positions.append(line.index(before: j))
                        }
                    }
                    i = j
                } else {
                    i = line.index(after: i)
                }
            }
        } else {
            var searchStart = line.startIndex
            while let range = line.range(of: marker, range: searchStart..<line.endIndex) {
                positions.append(range.lowerBound)
                searchStart = range.upperBound
            }
        }

        guard positions.count % 2 != 0 else { return line }
        let lastUnpairedPos = positions.last!
        return String(line[..<lastUnpairedPos])
    }

    // MARK: - Static regex

    public static let unorderedListLineRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{0,3})[-+*]\s+(.+)$"#,
        options: []
    )
    public static let orderedListLineRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{0,3})(\d+)(?:\.|）)\s+(.+)$"#,
        options: []
    )
    public static let headingLineRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{0,3})#{1,6}[ \t]+(.+)$"#,
        options: []
    )
    public static let headingStrongLineRegex = try! NSRegularExpression(
        pattern: #"^[ \t]{0,3}#{1,6}[ \t]+\*\*.+$"#,
        options: []
    )
    public static let blockquoteLineRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{0,3})>[ \t]?(.*)$"#,
        options: []
    )
}
