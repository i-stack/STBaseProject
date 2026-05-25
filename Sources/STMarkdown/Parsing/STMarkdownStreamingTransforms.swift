//
//  STMarkdownCitationURLMatcher.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public enum STMarkdownStreamingTransforms {
    private static let trailingStreamingMarkdownMarkerRegexes: [NSRegularExpression] = [
        try! NSRegularExpression(pattern: #"(?s)\n?[ \t]{0,3}#{1,6}[ \t]*$"#),
        try! NSRegularExpression(pattern: #"(?s)\n?[ \t]{0,3}#{2,6}\S*$"#),
        try! NSRegularExpression(pattern: #"(?s)\n?[ \t]{0,3}>[ \t]*$"#),
        try! NSRegularExpression(pattern: #"(?is)webpage\s*\d*$"#),
        try! NSRegularExpression(pattern: #"(?is)citation\s*:?\s*\d*$"#),
        try! NSRegularExpression(pattern: #"(?s)(?<!\[)\[(?!(?:Citation|Webpage)\s*:?\s*\d)[^\[\]]{0,40}$"#),
        try! NSRegularExpression(pattern: #"(?s)(?<!\[)\[(?!(?:Citation|Webpage)\s*:?\s*\d)[^\[\]]{0,40}\]\([^)]{0,80}$"#),
    ]

    private static let dripSafeTrailingMarkdownMarkerRegexes: [NSRegularExpression] = [
        try! NSRegularExpression(pattern: #"(?s)\n?[ \t]{0,3}#{1,6}[ \t]*$"#),
        try! NSRegularExpression(pattern: #"(?s)\n?[ \t]{0,3}#{2,6}\S*$"#),
        try! NSRegularExpression(pattern: #"(?s)\n?[ \t]{0,3}>[ \t]*$"#),
        try! NSRegularExpression(pattern: #"(?is)webpage\s*\d*$"#),
        try! NSRegularExpression(pattern: #"(?is)citation\s*:?\s*\d*$"#),
        try! NSRegularExpression(pattern: #"(?s)(?<!\[)\[(?!(?:Citation|Webpage)\s*:?\s*\d)[^\[\]]{0,40}$"#),
        try! NSRegularExpression(pattern: #"(?s)(?<!\[)\[(?!(?:Citation|Webpage)\s*:?\s*\d)[^\[\]]{0,40}\]\([^)]{0,80}$"#),
    ]

    private static let trailingIncompleteHtmlTagRegex = try! NSRegularExpression(
        pattern: #"</?[a-zA-Z][a-zA-Z0-9]*(?:\s[^>]{0,100})?$"#,
        options: []
    )
    private static let trailingIncompleteHtmlCommentRegex = try! NSRegularExpression(
        pattern: #"<!--[^>]{0,100}$"#,
        options: []
    )
    private static let streamingIndentedUnorderedListRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{2,})([-+*])\s+\S"#,
        options: []
    )
    private static let streamingAnyListRegex = try! NSRegularExpression(
        pattern: #"^[ \t]{0,3}(?:[-+*]|\d+\.)\s+\S"#,
        options: []
    )
    private static let streamingAnyUnorderedListRegex = try! NSRegularExpression(
        pattern: #"^[ \t]*[-+*]\s+\S"#,
        options: []
    )
    private static let streamingPartialIndentedUnorderedListRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{2,})([-+*])[ \t]*$"#,
        options: []
    )
    private static let streamingOrderedListDoubleSpaceRegex = try! NSRegularExpression(
        pattern: #"^(\d+\.)[ \t]{2,}"#,
        options: .anchorsMatchLines
    )
    private static let streamingCitationTagRegexes: [NSRegularExpression] = [
        try! NSRegularExpression(pattern: #"(?is)\[\s*(?:Citation|Webpage)\s*:?\s*\d+\s*\]"#),
        try! NSRegularExpression(pattern: #"(?is)\[\[\s*(?:citation|webpage)\s*:?\s*\d+\s*\]\]"#),
        try! NSRegularExpression(pattern: #"(?is)\[\[?\s*(?:citation|webpage)\s*:?\s*\d*\s*\]?\]?"#),
        try! NSRegularExpression(pattern: #"(?is)\b(?:citation|webpage)\s*:?\s*\d+\]?"#),
    ]
    private static let trailingTrimSearchWindow = 500
    private static let trailingBareListMarkerRegex = try! NSRegularExpression(
        pattern: #"(?m)\n?([ \t]{0,3}(?:[-+*]|\d+\.)[ \t]*)$"#,
        options: []
    )
    private static let trailingListDanglingEmphasisRegex = try! NSRegularExpression(
        pattern: #"(?m)\n?([ \t]{0,3}(?:[-+*]|\d+\.)[ \t]+(?:\*{1,2}|_{1,2})[ \t]*)$"#,
        options: []
    )
    private static let listLineContentCaptureRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{0,3}(?:[-+*]|\d+\.)[ \t]+)(.*)$"#,
        options: []
    )
    private static let trailingBareBlockMarkerRegex = try! NSRegularExpression(
        pattern: #"(?m)\n?([ \t]{0,3}(?:#{1,6}|>)[ \t]*)$"#,
        options: []
    )
    private static let headingNormalizationRegex = try! NSRegularExpression(
        pattern: #"(?m)^([ \t]{0,3})(#{1,6})([^\s#])"#,
        options: []
    )
    private static let setextUnderlineRegex = try! NSRegularExpression(
        pattern: #"^[ ]{0,3}(?:[-]+|[=]+)[ ]*$"#,
        options: []
    )
    private static let unorderedListLineRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{0,3})[-+*]\s+(.+)$"#,
        options: []
    )
    private static let orderedListLineRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{0,3})(\d+)\.\s+(.+)$"#,
        options: []
    )
    private static let headingLineRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{0,3})#{1,6}[ \t]+(.+)$"#,
        options: []
    )
    private static let blockquoteLineRegex = try! NSRegularExpression(
        pattern: #"^([ \t]{0,3})>[ \t]?(.*)$"#,
        options: []
    )
    private static let streamingPartialOrderedListMarkerRegex = try! NSRegularExpression(
        pattern: #"^\d+\.?$"#,
        options: []
    )

    public static func normalizeStreamingUnorderedListIndentation(in text: String) -> String {
        guard !text.isEmpty else { return text }
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.contains(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return text
        }
        var inFencedCodeBlock = false
        var fenceToken: String?
        var lastNonEmptyLine = ""
        var lastWasStripped = false
        func leadingIndent(of line: String) -> Int {
            line.prefix { $0 == " " || $0 == "\t" }.count
        }
        func matches(_ regex: NSRegularExpression, in line: String) -> Bool {
            regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)) != nil
        }
        for index in lines.indices {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                let currentFence = String(trimmed.prefix(3))
                if !inFencedCodeBlock {
                    inFencedCodeBlock = true
                    fenceToken = currentFence
                } else if fenceToken == currentFence {
                    inFencedCodeBlock = false
                    fenceToken = nil
                }
                lastNonEmptyLine = lines[index]
                lastWasStripped = false
                continue
            }
            if inFencedCodeBlock {
                if !trimmed.isEmpty {
                    lastNonEmptyLine = lines[index]
                    lastWasStripped = false
                }
                continue
            }
            guard !trimmed.isEmpty else { continue }
            let rawLine = lines[index]
            if matches(Self.streamingIndentedUnorderedListRegex, in: rawLine) {
                let currentIndent = leadingIndent(of: rawLine)
                let previousIndent = leadingIndent(of: lastNonEmptyLine)
                let shouldKeepNestedIndent: Bool
                if lastWasStripped {
                    shouldKeepNestedIndent = currentIndent > previousIndent
                } else {
                    let previousIsList = matches(Self.streamingAnyUnorderedListRegex, in: lastNonEmptyLine)
                        || matches(Self.streamingAnyListRegex, in: lastNonEmptyLine)
                    shouldKeepNestedIndent = previousIsList && currentIndent >= previousIndent
                }
                if !shouldKeepNestedIndent {
                    lines[index] = String(rawLine.drop { $0 == " " || $0 == "\t" })
                    lastWasStripped = true
                } else {
                    lastWasStripped = false
                }
            } else if matches(Self.streamingPartialIndentedUnorderedListRegex, in: rawLine) {
                let currentIndent = leadingIndent(of: rawLine)
                let previousIndent = leadingIndent(of: lastNonEmptyLine)
                let shouldStrip: Bool
                if lastWasStripped {
                    shouldStrip = currentIndent <= previousIndent
                } else {
                    let previousIsList = matches(Self.streamingAnyUnorderedListRegex, in: lastNonEmptyLine)
                        || matches(Self.streamingAnyListRegex, in: lastNonEmptyLine)
                    shouldStrip = !previousIsList
                }
                if shouldStrip {
                    lines[index] = String(rawLine.drop { $0 == " " || $0 == "\t" })
                    lastWasStripped = true
                } else {
                    lastWasStripped = false
                }
            } else {
                lastWasStripped = false
            }
            lastNonEmptyLine = rawLine
        }
        return lines.joined(separator: "\n")
    }

    public static func normalizeStreamingOrderedListSpacing(in text: String) -> String {
        guard !text.isEmpty else { return text }
        return Self.streamingOrderedListDoubleSpaceRegex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "$1 "
        )
    }

    public static func trimTrailingDanglingEscapedMathDelimiter(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let inlineOpen = Self.lastDanglingEscapedMathStart(in: text, open: #"\("#, close: #"\)"#)
        let blockOpen = Self.lastDanglingEscapedMathStart(in: text, open: #"\["#, close: #"\]"#)
        guard let cutLocation = [inlineOpen, blockOpen].compactMap({ $0 }).min() else { return text }
        return (text as NSString).substring(to: cutLocation)
    }

    public static func trimIncompleteTrailingMarkdownSyntax(in text: String) -> String {
        Self.trimTrailingMarkdownSyntax(in: text, using: Self.trailingStreamingMarkdownMarkerRegexes)
    }

    public static func trimIncompleteTrailingMarkdownSyntaxForDrip(in text: String) -> String {
        Self.trimTrailingMarkdownSyntax(in: text, using: Self.dripSafeTrailingMarkdownMarkerRegexes)
    }

    public static func trimTrailingBareListMarker(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let ns = text as NSString
        let searchStart = max(0, ns.length - Self.trailingTrimSearchWindow)
        let searchRange = NSRange(location: searchStart, length: ns.length - searchStart)
        guard let match = Self.trailingBareListMarkerRegex.firstMatch(in: text, options: [], range: searchRange) else {
            return text
        }
        let matched = ns.substring(with: match.range)
        guard !matched.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return text }
        let replacement = matched.hasPrefix("\n") ? "\n" : ""
        return ns.replacingCharacters(in: match.range, with: replacement)
    }

    public static func trimTrailingListMarkerWithDanglingEmphasis(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let ns = text as NSString
        let searchStart = max(0, ns.length - Self.trailingTrimSearchWindow)
        let searchRange = NSRange(location: searchStart, length: ns.length - searchStart)
        guard let match = Self.trailingListDanglingEmphasisRegex.firstMatch(in: text, options: [], range: searchRange) else {
            return text
        }
        let matched = ns.substring(with: match.range)
        guard !matched.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return text }
        let replacement = matched.hasPrefix("\n") ? "\n" : ""
        return ns.replacingCharacters(in: match.range, with: replacement)
    }

    public static func softenTrailingListLeadingDanglingEmphasis(in text: String) -> String {
        guard !text.isEmpty else { return text }
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let lastNonEmptyIndex = lines.lastIndex(where: {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else { return text }
        let line = lines[lastNonEmptyIndex]
        guard Self.isStreamingListLine(line) else { return text }
        let lineRange = NSRange(location: 0, length: line.utf16.count)
        guard let match = Self.listLineContentCaptureRegex.firstMatch(in: line, options: [], range: lineRange),
              match.numberOfRanges == 3,
              let prefixRange = Range(match.range(at: 1), in: line),
              let contentRange = Range(match.range(at: 2), in: line) else {
            return text
        }
        let prefix = String(line[prefixRange])
        var content = String(line[contentRange])
        let original = content
        if content.hasPrefix("**"),
           Self.countUnescapedOccurrences(of: "**", in: content) % 2 == 1 {
            content.removeFirst(2)
        } else if content.hasPrefix("__"),
                  Self.countUnescapedOccurrences(of: "__", in: content) % 2 == 1 {
            content.removeFirst(2)
        } else if content.hasPrefix("*"),
                  !content.hasPrefix("**"),
                  Self.countUnescapedOccurrences(of: "*", in: content) % 2 == 1 {
            content.removeFirst()
        } else if content.hasPrefix("_"),
                  !content.hasPrefix("__"),
                  Self.countUnescapedOccurrences(of: "_", in: content) % 2 == 1 {
            content.removeFirst()
        }
        guard content != original else { return text }
        lines[lastNonEmptyIndex] = prefix + content
        return lines.joined(separator: "\n")
    }

    public static func trimTrailingBareBlockMarker(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let ns = text as NSString
        let searchStart = max(0, ns.length - Self.trailingTrimSearchWindow)
        let searchRange = NSRange(location: searchStart, length: ns.length - searchStart)
        guard let match = Self.trailingBareBlockMarkerRegex.firstMatch(in: text, options: [], range: searchRange) else {
            return text
        }
        let matched = ns.substring(with: match.range)
        guard !matched.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return text }
        let replacement = matched.hasPrefix("\n") ? "\n" : ""
        return ns.replacingCharacters(in: match.range, with: replacement)
    }

    public static func trimTrailingIncompleteHtmlTag(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let ns = text as NSString
        let searchStart = max(0, ns.length - 120)
        let searchRange = NSRange(location: searchStart, length: ns.length - searchStart)
        if let match = Self.trailingIncompleteHtmlCommentRegex.firstMatch(in: text, options: [], range: searchRange) {
            let replacement = ns.substring(with: match.range).hasPrefix("\n") ? "\n" : ""
            return ns.replacingCharacters(in: match.range, with: replacement)
        }
        if let match = Self.trailingIncompleteHtmlTagRegex.firstMatch(in: text, options: [], range: searchRange) {
            let replacement = ns.substring(with: match.range).hasPrefix("\n") ? "\n" : ""
            return ns.replacingCharacters(in: match.range, with: replacement)
        }
        return text
    }

    public static func trimTrailingIncompleteCitationTags(in text: String) -> String {
        guard !text.isEmpty else { return text }
        var cutIndex = text.endIndex
        func tightenCut(_ idx: String.Index) {
            if idx < cutIndex { cutIndex = idx }
        }
        let knownPrefixes = ["[[citation", "[[webpage", "[citation", "[webpage"]
        let lowered = text.lowercased()
        for prefix in knownPrefixes {
            guard let range = lowered.range(of: prefix, options: .backwards) else { continue }
            let tail = lowered[range.lowerBound...]
            let closing = prefix.hasPrefix("[[") ? "]]" : "]"
            if !tail.contains(closing),
               let originalRange = text.range(of: prefix, options: [.backwards, .caseInsensitive]) {
                tightenCut(originalRange.lowerBound)
            }
        }
        if let doubleOpen = text.range(of: "[[", options: .backwards) {
            let tail = text[doubleOpen.lowerBound...]
            if !tail.contains("]]") {
                let token = tail.dropFirst(2).drop(while: { $0 == " " || $0 == "\t" }).lowercased()
                if token.isEmpty || token.hasPrefix("c") || token.hasPrefix("w") {
                    tightenCut(doubleOpen.lowerBound)
                }
            }
        }
        if let singleOpen = text.range(of: "[", options: .backwards) {
            let isDoubleOpen = singleOpen.lowerBound > text.startIndex
                && text[text.index(before: singleOpen.lowerBound)] == "["
            if !isDoubleOpen {
                let tail = text[singleOpen.lowerBound...]
                if !tail.contains("]") {
                    let token = tail.dropFirst(1).drop(while: { $0 == " " || $0 == "\t" }).lowercased()
                    if token.isEmpty || token.hasPrefix("c") || token.hasPrefix("w") {
                        tightenCut(singleOpen.lowerBound)
                    }
                }
            }
        }
        return cutIndex == text.endIndex ? text : String(text[..<cutIndex])
    }

    public static func sanitizeStreamingCitationTagsForPresentation(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let processedLines = lines.map { line -> String in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let pipeCount = trimmed.filter { $0 == "|" }.count
            if trimmed.hasPrefix("|"), pipeCount >= 2 {
                return line
            }
            var result = line
            for regex in Self.streamingCitationTagRegexes {
                let nsRange = NSRange(location: 0, length: (result as NSString).length)
                result = regex.stringByReplacingMatches(in: result, options: [], range: nsRange, withTemplate: "")
            }
            result = result.replacingOccurrences(of: "[]", with: "")
            result = result.replacingOccurrences(of: "[ ]", with: "")
            return result
        }
        return processedLines.joined(separator: "\n")
    }

    public static func autoCloseTrailingCodeFence(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var inFencedCodeBlock = false
        var fenceToken: String?
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .init(charactersIn: " \t"))
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                let token = String(trimmed.prefix(3))
                if !inFencedCodeBlock {
                    inFencedCodeBlock = true
                    fenceToken = token
                } else if fenceToken == token {
                    let afterToken = trimmed.dropFirst(3)
                    if afterToken.allSatisfy({ $0 == Character(fenceToken!.first!.description) || $0.isWhitespace }) {
                        inFencedCodeBlock = false
                        fenceToken = nil
                    }
                }
            }
        }
        if inFencedCodeBlock, let token = fenceToken {
            return text + "\n" + token
        }
        return text
    }

    public static func normalizeStreamingHeadingSyntax(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let range = NSRange(location: 0, length: text.utf16.count)
        return Self.headingNormalizationRegex.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: "$1$2 $3"
        )
    }

    public static func trimIncompleteTrailingEmphasis(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let paragraphStart: String.Index
        if let doubleNewlineRange = text.range(of: "\n\n", options: .backwards) {
            paragraphStart = doubleNewlineRange.upperBound
        } else {
            paragraphStart = text.startIndex
        }
        let lastParagraph = String(text[paragraphStart...])
        guard !lastParagraph.isEmpty else { return text }
        let lines = lastParagraph.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var inCodeBlock = false
        var textLinesToCheck: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inCodeBlock.toggle()
                continue
            }
            if !inCodeBlock {
                textLinesToCheck.append(line)
            }
        }
        guard !textLinesToCheck.isEmpty else { return text }
        if Self.containsLikelyTableSyntax(in: textLinesToCheck) {
            return text
        }
        var result = text
        let markers: [(String, Int)] = [("~~", 2), ("**", 2), ("__", 2), ("*", 1), ("_", 1)]
        for (marker, markerLen) in markers {
            let currentParagraph: String
            if let dnr = result.range(of: "\n\n", options: .backwards) {
                currentParagraph = String(result[dnr.upperBound...])
            } else {
                currentParagraph = result
            }
            let currentLines = currentParagraph.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            var inCode = false
            var checkLines: [String] = []
            for line in currentLines {
                let t = line.trimmingCharacters(in: .whitespaces)
                if t.hasPrefix("```") || t.hasPrefix("~~~") {
                    inCode.toggle()
                    continue
                }
                if !inCode { checkLines.append(line) }
            }
            guard !checkLines.isEmpty else { continue }
            let joined = checkLines.joined(separator: "\n")
            let trimmed = Self.trimUnpairedTrailingMarker(in: joined, marker: marker, markerLen: markerLen)
            if trimmed.count < joined.count {
                let afterMarkerOffset = trimmed.count + markerLen
                let hasContentAfterMarker: Bool
                if afterMarkerOffset < joined.count,
                   let afterStart = joined.index(joined.startIndex, offsetBy: afterMarkerOffset, limitedBy: joined.endIndex) {
                    hasContentAfterMarker = !joined[afterStart...].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                } else {
                    hasContentAfterMarker = false
                }
                if hasContentAfterMarker {
                    let closingMarker: String
                    if marker.count > 1, result.hasSuffix(String(marker.prefix(1))) {
                        closingMarker = String(marker.dropFirst())
                    } else {
                        closingMarker = marker
                    }
                    result = result + closingMarker
                } else {
                    let dangling = joined.count - trimmed.count
                    if result.count >= dangling {
                        result = String(result.dropLast(dangling))
                    }
                }
            }
        }
        return result
    }

    public static func autoCloseTrailingInlineCode(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let paragraphStart: String.Index
        if let doubleNewlineRange = text.range(of: "\n\n", options: .backwards) {
            paragraphStart = doubleNewlineRange.upperBound
        } else {
            paragraphStart = text.startIndex
        }
        let lastParagraph = text[paragraphStart...]
        guard !lastParagraph.isEmpty else { return text }
        var inFence = false
        for line in lastParagraph.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                inFence.toggle()
            }
        }
        if inFence { return text }
        var backtickCount = 0
        var prevChar: Character = " "
        for ch in lastParagraph {
            if ch == "`" && prevChar != "\\" {
                backtickCount += 1
            }
            prevChar = ch
        }
        guard backtickCount % 2 != 0 else { return text }
        // SSE 流式阶段尾部反引号未闭合，后续 token 未知，不补闭合。
        // 将尾部孤立的反引号 trim 掉，待闭合符到达后再渲染整个 inline code。
        guard let lastBacktickRange = text.range(of: "`", options: .backwards) else { return text }
        return String(text[..<lastBacktickRange.lowerBound])
    }

    public static func trimTrailingSetextHeadingAmbiguity(in text: String) -> String {
        guard !text.isEmpty else { return text }
        guard let lastNewlineIndex = text.lastIndex(of: "\n") else { return text }
        let lastLineStart = text.index(after: lastNewlineIndex)
        let lastLine = String(text[lastLineStart...])
        let lastLineRange = NSRange(location: 0, length: lastLine.utf16.count)
        guard Self.setextUnderlineRegex.firstMatch(in: lastLine, options: [], range: lastLineRange) != nil else {
            return text
        }
        let beforeLastLine = text[..<lastNewlineIndex]
        guard let prevLineEnd = beforeLastLine.lastIndex(of: "\n") else {
            return String(beforeLastLine) + "\n"
        }
        let prevLineStart = beforeLastLine.index(after: prevLineEnd)
        let prevLine = String(beforeLastLine[prevLineStart...])
        if prevLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        return String(beforeLastLine) + "\n"
    }

    public static func transformTableBlocksForStreaming(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var fenceState = [Bool](repeating: false, count: lines.count)
        var fenceFlag = false
        for i in 0..<lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                fenceFlag.toggle()
            }
            fenceState[i] = fenceFlag
        }
        var resultLines: [String] = []
        var i = 0
        while i < lines.count {
            if fenceState[i] {
                resultLines.append(lines[i])
                i += 1
                continue
            }
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
            let pipeCount = trimmed.filter { $0 == "|" }.count
            guard !trimmed.isEmpty && pipeCount >= 2 else {
                resultLines.append(lines[i])
                i += 1
                continue
            }
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
                var validTableLines: [String] = [blockLines[0], blockLines[1]]
                for rowIdx in 2..<blockLines.count {
                    let rowTrimmed = blockLines[rowIdx].trimmingCharacters(in: .whitespaces)
                    let rowPipeCount = rowTrimmed.filter { $0 == "|" }.count
                    if rowPipeCount >= 2 {
                        validTableLines.append(blockLines[rowIdx])
                    }
                }
                if validTableLines.count >= 2 {
                    if validTableLines.count == 2 {
                        let colCount = max(blockLines[0].filter({ $0 == "|" }).count - 1, 1)
                        let emptyCells = Array(repeating: " ", count: colCount)
                        validTableLines.append("| " + emptyCells.joined(separator: " | ") + " |")
                    }
                    resultLines.append(contentsOf: validTableLines)
                }
            } else if blockLines.count == 1 {
                if !Self.isLikelyStreamingTableHeaderCandidate(blockLines[0]) {
                    resultLines.append(lines[blockStart])
                }
            }
        }
        var finalLines: [String] = []
        var lastWasEmpty = false
        for line in resultLines {
            let isEmpty = line.trimmingCharacters(in: .whitespaces).isEmpty
            if isEmpty && lastWasEmpty { continue }
            finalLines.append(line)
            lastWasEmpty = isEmpty
        }
        var result = finalLines.joined(separator: "\n")
        while result.hasSuffix("\n\n") {
            result.removeLast()
        }
        return result
    }

    private static func trimTrailingMarkdownSyntax(in text: String, using regexes: [NSRegularExpression]) -> String {
        guard !text.isEmpty else { return text }
        var result = text
        var resultNS = text as NSString
        var resultLen = resultNS.length
        for regex in regexes {
            let searchStart = max(0, resultLen - Self.trailingTrimSearchWindow)
            let searchRange = NSRange(location: searchStart, length: resultLen - searchStart)
            guard let match = regex.firstMatch(in: result, options: [], range: searchRange) else { continue }
            let matched = resultNS.substring(with: match.range)
            guard !matched.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            let replacement = matched.hasPrefix("\n") ? "\n" : ""
            result = resultNS.replacingCharacters(in: match.range, with: replacement)
            resultNS = result as NSString
            resultLen = resultNS.length
        }
        return result
    }

    private static func lastDanglingEscapedMathStart(in text: String, open: String, close: String) -> Int? {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var inFencedCodeBlock = false
        var fenceToken: String?
        var openStack: [Int] = []
        var globalOffset = 0
        for (lineIndex, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .init(charactersIn: " \t"))
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                let token = String(trimmed.prefix(3))
                if !inFencedCodeBlock {
                    inFencedCodeBlock = true
                    fenceToken = token
                } else if fenceToken == token {
                    inFencedCodeBlock = false
                    fenceToken = nil
                }
                globalOffset += line.utf16.count
                if lineIndex < lines.count - 1 { globalOffset += 1 }
                continue
            }
            if !inFencedCodeBlock {
                let nsLine = line as NSString
                var cursor = 0
                while cursor + 1 < nsLine.length {
                    let token = nsLine.substring(with: NSRange(location: cursor, length: 2))
                    if token == open {
                        openStack.append(globalOffset + cursor)
                        cursor += 2
                        continue
                    }
                    if token == close {
                        if !openStack.isEmpty { openStack.removeLast() }
                        cursor += 2
                        continue
                    }
                    cursor += 1
                }
            }
            globalOffset += line.utf16.count
            if lineIndex < lines.count - 1 { globalOffset += 1 }
        }
        return openStack.last
    }

    private static func containsLikelyTableSyntax(in lines: [String]) -> Bool {
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

    private static func trimUnpairedTrailingMarker(in line: String, marker: String, markerLen: Int) -> String {
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
        guard positions.count % 2 != 0, let lastUnpairedPos = positions.last else { return line }
        return String(line[..<lastUnpairedPos])
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

    static func isLikelyStreamingTableHeaderCandidate(_ line: String) -> Bool {
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

    static func isStreamingListLine(_ line: String) -> Bool {
        let range = NSRange(location: 0, length: line.utf16.count)
        return Self.streamingAnyListRegex.firstMatch(in: line, options: [], range: range) != nil
    }

    private static func trimTrailingSingleEmphasisMarker(in text: String) -> String {
        guard !text.isEmpty else { return text }
        let last = text.last!
        guard last == "*" || last == "_" else { return text }
        if text.count >= 2 {
            let secondLast = text[text.index(text.endIndex, offsetBy: -2)]
            if secondLast == last { return text }
        }
        if text.count >= 2 {
            let before = text[text.index(text.endIndex, offsetBy: -2)]
            if before == " " || before == "\t" || before == "\n" { return text }
        }
        return String(text.dropLast())
    }

    public static func trimTrailingMarkerOnlyEmphasisRun(in text: String) -> String {
        guard !text.isEmpty else { return text }
        var end = text.endIndex
        while end > text.startIndex {
            let previous = text.index(before: end)
            let ch = text[previous]
            if ch == " " || ch == "\t" { end = previous; continue }
            break
        }
        guard end > text.startIndex else { return text }
        let marker = text[text.index(before: end)]
        guard marker == "*" || marker == "_" || marker == "~" else { return text }
        var runStart = end
        while runStart > text.startIndex {
            let previous = text.index(before: runStart)
            if text[previous] == marker { runStart = previous } else { break }
        }
        let run = text[runStart..<end]
        guard !run.isEmpty, run.allSatisfy({ $0 == marker }) else { return text }
        if runStart == text.startIndex { return String(text[..<runStart]) }
        let previous = text[text.index(before: runStart)]
        guard previous == "\n" || previous == " " || previous == "\t" else { return text }
        return String(text[..<runStart])
    }

    public static func sanitizeDanglingInlineMarkdownFragments(in text: String) -> String {
        guard !text.isEmpty else { return text }
        var result = text
        if let imageOpen = result.range(of: "![", options: .backwards) {
            let tail = result[imageOpen.lowerBound...]
            if !(tail.contains("]") && tail.contains(")")) {
                result = String(result[..<imageOpen.lowerBound])
            }
        }
        if let linkOpen = result.range(of: "](", options: .backwards) {
            let tail = result[linkOpen.lowerBound...]
            if !tail.contains(")") {
                result = String(result[..<linkOpen.lowerBound])
            }
        }
        if let doubleOpen = result.range(of: "[[", options: .backwards) {
            let tail = result[doubleOpen.lowerBound...]
            if !tail.contains("]]") {
                result = String(result[..<doubleOpen.lowerBound])
            }
        }
        if let singleOpen = result.range(of: "[", options: .backwards) {
            let isDouble = singleOpen.lowerBound > result.startIndex
                && result[result.index(before: singleOpen.lowerBound)] == "["
            if !isDouble {
                let tail = result[singleOpen.lowerBound...]
                if !tail.contains("]") {
                    result = String(result[..<singleOpen.lowerBound])
                }
            }
        }
        return result
    }

    public static func flattenStreamingListSyntax(in text: String) -> String {
        guard !text.isEmpty else { return text }
        var inFencedCodeBlock = false
        var fenceToken: String?
        var output: [String] = []
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        output.reserveCapacity(lines.count)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                let token = String(trimmed.prefix(3))
                if !inFencedCodeBlock { inFencedCodeBlock = true; fenceToken = token }
                else if fenceToken == token { inFencedCodeBlock = false; fenceToken = nil }
                output.append(line); continue
            }
            if inFencedCodeBlock { output.append(line); continue }
            let range = NSRange(location: 0, length: (line as NSString).length)
            if Self.unorderedListLineRegex.firstMatch(in: line, options: [], range: range) != nil {
                output.append(Self.unorderedListLineRegex.stringByReplacingMatches(
                    in: line, options: [], range: range, withTemplate: "$1• $2"
                ))
                continue
            }
            if Self.orderedListLineRegex.firstMatch(in: line, options: [], range: range) != nil {
                output.append(Self.orderedListLineRegex.stringByReplacingMatches(
                    in: line, options: [], range: range, withTemplate: "$1$2) $3"
                ))
                continue
            }
            output.append(line)
        }
        return output.joined(separator: "\n")
    }

    public static func flattenStreamingBlockSyntax(in text: String) -> String {
        guard !text.isEmpty else { return text }
        var inFencedCodeBlock = false
        var fenceToken: String?
        var output: [String] = []
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        output.reserveCapacity(lines.count)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
                let token = String(trimmed.prefix(3))
                if !inFencedCodeBlock { inFencedCodeBlock = true; fenceToken = token }
                else if fenceToken == token { inFencedCodeBlock = false; fenceToken = nil }
                output.append(line); continue
            }
            if inFencedCodeBlock { output.append(line); continue }
            let range = NSRange(location: 0, length: (line as NSString).length)
            if Self.headingLineRegex.firstMatch(in: line, options: [], range: range) != nil {
                output.append(Self.headingLineRegex.stringByReplacingMatches(
                    in: line, options: [], range: range, withTemplate: "$1$2"
                ))
                continue
            }
            if Self.blockquoteLineRegex.firstMatch(in: line, options: [], range: range) != nil {
                output.append(Self.blockquoteLineRegex.stringByReplacingMatches(
                    in: line, options: [], range: range, withTemplate: "$1$2"
                ))
                continue
            }
            output.append(line)
        }
        return output.joined(separator: "\n")
    }

    public static func autoCloseTrailingIncompleteStrongEmphasisForStaticRender(in text: String) -> String {
        guard !text.isEmpty else { return text }
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let lastNonEmptyIndex = lines.lastIndex(where: {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) else { return text }
        let line = lines[lastNonEmptyIndex]
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !trimmed.contains("|") else { return text }
        guard !(trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~")) else { return text }
        let strongCount = Self.countUnescapedOccurrences(of: "**", in: trimmed)
        guard strongCount % 2 == 1, !trimmed.hasSuffix("**") else { return text }
        lines[lastNonEmptyIndex] = line + (line.hasSuffix("*") ? "*" : "**")
        return lines.joined(separator: "\n")
    }

    public static func stabilizeStreamingPresentationTail(in text: String) -> String {
        guard !text.isEmpty else { return "" }
        let citationTrimmed = Self.trimTrailingIncompleteCitationTags(in: text)
        let htmlTrimmed = Self.trimTrailingIncompleteHtmlTag(in: citationTrimmed)
        let emphasisClean = Self.trimIncompleteTrailingEmphasis(in: htmlTrimmed)
        let markerOnlyRunTrimmed = Self.trimTrailingMarkerOnlyEmphasisRun(in: emphasisClean)
        let singleMarkerTrimmed = Self.trimTrailingSingleEmphasisMarker(in: markerOnlyRunTrimmed)
        let listDanglingEmphasisTrimmed = Self.trimTrailingListMarkerWithDanglingEmphasis(in: singleMarkerTrimmed)
        let finalBareListTrimmed = Self.trimTrailingBareListMarker(in: listDanglingEmphasisTrimmed)
        let finalBareBlockTrimmed = Self.trimTrailingBareBlockMarker(in: finalBareListTrimmed)
        return Self.sanitizeStreamingCitationTagsForPresentation(in: finalBareBlockTrimmed)
    }
}
