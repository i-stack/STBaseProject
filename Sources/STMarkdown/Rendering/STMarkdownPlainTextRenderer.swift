import Foundation

public enum STMarkdownPlainTextRenderer {

    private static let plainTextParser = STMarkdownStructureParser()

    public static func makeDeferredPlainTextActivePresentation(
        from text: String,
        kind: STMarkdownStreamingBlockKind
    ) -> String {
        guard !text.isEmpty else { return "" }
        let prepared = Self.prepareActivePlainTextMarkdown(text, kind: kind)
        guard !prepared.isEmpty else { return "" }
        let document = Self.plainTextParser.parse(prepared)
        let rendered = Self.renderPlainText(document.blocks)
        guard !rendered.isEmpty else {
            return Self.fallbackPlainText(from: prepared, kind: kind)
        }
        return rendered
    }

    private static func prepareActivePlainTextMarkdown(
        _ text: String,
        kind: STMarkdownStreamingBlockKind
    ) -> String {
        guard !text.isEmpty else { return "" }
        var candidate = STMarkdownStreamingTransforms.trimTrailingIncompleteCitationTags(in: text)
        candidate = STMarkdownStreamingTransforms.trimIncompleteTrailingMarkdownSyntax(in: candidate)
        candidate = STMarkdownStreamingTransforms.trimTrailingIncompleteHtmlTag(in: candidate)
        candidate = STMarkdownStreamingTransforms.sanitizeDanglingInlineMarkdownFragments(in: candidate)
        candidate = STMarkdownStreamingTransforms.trimIncompleteTrailingEmphasis(in: candidate)
        candidate = STMarkdownStreamingTransforms.autoCloseTrailingInlineCode(in: candidate)
        if kind == .list {
            candidate = STMarkdownStreamingTransforms.softenTrailingListLeadingDanglingEmphasis(in: candidate)
        }
        return candidate.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func fallbackPlainText(
        from text: String,
        kind: STMarkdownStreamingBlockKind
    ) -> String {
        var flattened = STMarkdownStreamingTransforms.flattenStreamingBlockSyntax(in: text)
        if kind == .list {
            flattened = STMarkdownStreamingTransforms.flattenStreamingListSyntax(in: flattened)
        }
        flattened = flattened.replacingOccurrences(of: "**", with: "")
        flattened = flattened.replacingOccurrences(of: "__", with: "")
        flattened = flattened.replacingOccurrences(of: "~~", with: "")
        flattened = flattened.replacingOccurrences(of: "`", with: "")
        flattened = flattened.replacingOccurrences(of: "*", with: "")
        flattened = flattened.replacingOccurrences(of: "_", with: "")
        return STMarkdownStreamingTransforms.sanitizeDanglingInlineMarkdownFragments(in: flattened)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func renderPlainText(_ blocks: [STMarkdownBlockNode], quoteDepth: Int = 0) -> String {
        guard !blocks.isEmpty else { return "" }
        var parts: [String] = []
        for block in blocks {
            let rendered = Self.renderPlainText(block, quoteDepth: quoteDepth)
            if !rendered.isEmpty {
                parts.append(rendered)
            }
        }
        return parts.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func renderPlainText(_ block: STMarkdownBlockNode, quoteDepth: Int) -> String {
        switch block {
        case .paragraph(let inlines):
            return Self.quotePrefix(depth: quoteDepth) + Self.renderPlainText(inlines)
        case .heading(_, let content):
            return Self.quotePrefix(depth: quoteDepth) + Self.renderPlainText(content)
        case .quote(let blocks):
            return Self.renderPlainText(blocks, quoteDepth: quoteDepth + 1)
        case .list(let kind, let items):
            return Self.renderPlainTextList(kind: kind, items: items, quoteDepth: quoteDepth)
        case .codeBlock(_, let code):
            let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return "" }
            return Self.quotePrefix(depth: quoteDepth) + trimmed
        case .thematicBreak:
            return ""
        case .details(let summary, let body):
            let summaryText = Self.renderPlainText(summary)
            let bodyText = Self.renderPlainText(body, quoteDepth: quoteDepth)
            return [summaryText, bodyText]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
        case .rawHTML(let html):
            let trimmed = html.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return "" }
            return Self.quotePrefix(depth: quoteDepth) + trimmed
        case .image(_, let altText, _):
            return Self.quotePrefix(depth: quoteDepth) + altText
        case .table, .mathBlock:
            return ""
        }
    }

    private static func renderPlainTextList(
        kind: STMarkdownListKind,
        items: [STMarkdownListItemNode],
        quoteDepth: Int
    ) -> String {
        guard !items.isEmpty else { return "" }
        var lines: [String] = []
        for (index, item) in items.enumerated() {
            let marker: String
            switch kind {
            case .unordered:
                marker = quoteDepth > 0 ? "◦" : "•"
            case .ordered(let startIndex):
                marker = "\(startIndex + index)）"
            }
            let itemBody = Self.renderPlainText(item.blocks, quoteDepth: quoteDepth)
            let itemLines = itemBody.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            guard let firstLine = itemLines.first, !firstLine.isEmpty else { continue }
            lines.append("\(marker) \(firstLine)")
            for continuation in itemLines.dropFirst() where !continuation.isEmpty {
                lines.append("\(Self.quotePrefix(depth: quoteDepth))\(continuation)")
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func renderPlainText(_ inlines: [STMarkdownInlineNode]) -> String {
        var output = ""
        for inline in inlines {
            switch inline {
            case .text(let text):
                output += text
            case .inlineMath(let text, _):
                output += text
            case .emphasis(let children),
                 .strong(let children),
                 .strikethrough(let children):
                output += Self.renderPlainText(children)
            case .code(let code):
                output += code
            case .link(_, let children):
                output += Self.renderPlainText(children)
            case .image(_, let alt, _):
                output += alt
            case .softBreak:
                output += "\n"
            case .footnoteReference(let label):
                output += "[\(label)]"
            case .inlineRawHTML(let html):
                output += html
            }
        }
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func quotePrefix(depth: Int) -> String {
        guard depth > 0 else { return "" }
        return String(repeating: "│ ", count: depth)
    }
}
