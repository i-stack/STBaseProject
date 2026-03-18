//
//  STMarkdownAttributedStringRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public protocol STMarkdownAttributedStringRendering {
    func render(document: STMarkdownRenderDocument) -> NSAttributedString
}

public final class STMarkdownAttributedStringRenderer: STMarkdownAttributedStringRendering {
    
    public let style: STMarkdownStyle
    public let advancedRenderers: STMarkdownAdvancedRenderers

    public init(style: STMarkdownStyle = .default, advancedRenderers: STMarkdownAdvancedRenderers = .empty) {
        self.style = style
        self.advancedRenderers = advancedRenderers
    }

    public func render(document: STMarkdownRenderDocument) -> NSAttributedString {
        self.render(blocks: document.blocks)
    }
}

private extension STMarkdownAttributedStringRenderer {
    func render(blocks: [STMarkdownRenderBlock]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for (index, block) in blocks.enumerated() {
            if index > 0 {
                let spacing = self.blockSeparatorSpacing(
                    after: blocks[index - 1],
                    before: block
                )
                let separatorStyle = NSMutableParagraphStyle()
                separatorStyle.minimumLineHeight = spacing
                separatorStyle.maximumLineHeight = spacing
                separatorStyle.lineBreakMode = .byWordWrapping
                result.append(NSAttributedString(
                    string: "\n",
                    attributes: [
                        .font: self.style.font,
                        .foregroundColor: UIColor.clear,
                        .paragraphStyle: separatorStyle,
                    ]
                ))
            }
            result.append(self.render(block: block))
        }
        return result
    }

    func render(block: STMarkdownRenderBlock) -> NSAttributedString {
        switch block {
        case .paragraph(let inlines):
            return self.renderInline(nodes: inlines, baseFont: self.style.font, textColor: self.style.textColor)
        case .heading(let level, let content):
            let headingFont = self.headingFont(for: level)
            let headingColor = self.style.headingTextColor ?? self.style.textColor
            return self.renderInline(nodes: content, baseFont: headingFont, textColor: headingColor, paragraphStyle: self.headingParagraphStyle(font: headingFont))
        case .quote(let blocks):
            let rendered = NSMutableAttributedString()
            let paragraphStyle = self.bodyParagraphStyle()
            let prefix = NSAttributedString(
                string: "┃ ",
                attributes: [
                    .font: self.style.font,
                    .foregroundColor: UIColor.systemGray,
                    .paragraphStyle: paragraphStyle,
                ]
            )
            let body = self.render(blocks: blocks)
            rendered.append(prefix)
            rendered.append(body)
            return rendered
        case .list(let items):
            return self.renderList(items)
        case .codeBlock(let language, let code):
            if let rendered = self.advancedRenderers.codeBlockRenderer?.renderCodeBlock(
                language: language,
                code: code,
                style: self.style
            ) {
                return rendered
            }
            return self.renderCodeBlock(language: language, code: code)
        case .table(let table):
            if let rendered = self.advancedRenderers.tableRenderer?.renderTable(table, style: self.style) {
                return rendered
            }
            return self.renderTable(table)
        case .mathBlock(let latex):
            if let rendered = self.advancedRenderers.blockMathRenderer?.renderBlockMath(
                formula: latex,
                style: self.style
            ) {
                return rendered
            }
            return NSAttributedString(string: latex, attributes: self.baseAttributes())
        case .image(let url, let altText, let title):
            if let rendered = self.advancedRenderers.imageRenderer?.renderImage(
                url: url,
                altText: altText,
                title: title,
                style: self.style,
                inline: false
            ) {
                return rendered
            }
            return NSAttributedString(string: altText.isEmpty ? "[image]" : altText, attributes: self.baseAttributes())
        case .thematicBreak:
            if let rendered = self.advancedRenderers.horizontalRuleRenderer?.renderHorizontalRule(style: self.style) {
                return rendered
            }
            return NSAttributedString(string: "———", attributes: self.baseAttributes())
        }
    }

    func renderCodeBlock(language: String?, code: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.st_monospacedSystemFont(ofSize: 14, weight: .regular),
            .foregroundColor: self.style.textColor,
            .paragraphStyle: self.bodyParagraphStyle(),
        ]
        let renderedCode: String
        if let language, language.isEmpty == false {
            renderedCode = "\(language)\n\(code)"
        } else {
            renderedCode = code
        }
        return NSAttributedString(string: renderedCode, attributes: attributes)
    }

    func renderTable(_ table: STMarkdownTableModel) -> NSAttributedString {
        let rows = ([table.header].compactMap { $0 } + table.rows)
        let strings = rows.map { row in
            row.map { self.renderInline(nodes: $0, baseFont: self.style.font, textColor: self.style.textColor).string }
                .joined(separator: "  ")
        }
        return NSAttributedString(string: strings.joined(separator: "\n"), attributes: self.baseAttributes())
    }

    func renderInline(
        nodes: [STMarkdownInlineNode],
        baseFont: UIFont,
        textColor: UIColor,
        paragraphStyle: NSMutableParagraphStyle? = nil,
        italic: Bool = false,
        bold: Bool = false,
        linkDestination: String? = nil
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let italicFont = STMarkdownFontResolver.italicFont(from: baseFont)
        let boldFont = STMarkdownFontResolver.boldFont(from: baseFont)
        let boldItalicFont = STMarkdownFontResolver.boldItalicFont(from: baseFont)
        let style = paragraphStyle ?? self.bodyParagraphStyle()
        let useFont: UIFont
        let obliqueness: CGFloat?
        if italic && bold {
            useFont = boldItalicFont
            obliqueness = STMarkdownFontResolver.boldItalicObliqueness(from: baseFont)
        } else if bold {
            useFont = boldFont
            obliqueness = nil
        } else if italic {
            useFont = italicFont
            obliqueness = STMarkdownFontResolver.italicObliqueness(from: baseFont)
        } else {
            useFont = baseFont
            obliqueness = nil
        }
        var attributes: [NSAttributedString.Key: Any] = [
            .font: useFont,
            .foregroundColor: textColor,
            .kern: self.style.kern,
            .paragraphStyle: style,
        ]
        if let obliqueness {
            attributes[.obliqueness] = obliqueness
        }
        if let linkDestination, let url = URL(string: linkDestination) {
            attributes[.link] = url
            attributes[.foregroundColor] = self.style.linkColor ?? .systemBlue
        }
        for node in nodes {
            switch node {
            case .text(let text):
                result.append(NSAttributedString(string: text, attributes: attributes))
            case .inlineMath(let formula, _):
                if let rendered = self.advancedRenderers.inlineMathRenderer?.renderInlineMath(
                    formula: formula,
                    style: self.style,
                    baseFont: useFont,
                    textColor: textColor
                ) {
                    result.append(rendered)
                } else {
                    result.append(NSAttributedString(string: formula, attributes: attributes))
                }
            case .emphasis(let children):
                result.append(self.renderInline(
                    nodes: children,
                    baseFont: baseFont,
                    textColor: textColor,
                    paragraphStyle: style,
                    italic: true,
                    bold: bold,
                    linkDestination: linkDestination
                ))
            case .strong(let children):
                result.append(self.renderInline(
                    nodes: children,
                    baseFont: baseFont,
                    textColor: textColor,
                    paragraphStyle: style,
                    italic: italic,
                    bold: true,
                    linkDestination: linkDestination
                ))
            case .code(let code):
                var codeAttributes = attributes
                codeAttributes[.font] = UIFont.st_monospacedSystemFont(ofSize: max(baseFont.pointSize - 1, 12), weight: .regular)
                codeAttributes[.foregroundColor] = self.style.inlineCodeTextColor ?? textColor
                result.append(NSAttributedString(string: code, attributes: codeAttributes))
            case .link(let destination, let children):
                result.append(self.renderInline(
                    nodes: children,
                    baseFont: baseFont,
                    textColor: textColor,
                    paragraphStyle: style,
                    italic: italic,
                    bold: bold,
                    linkDestination: destination
                ))
            case .image(let source, let alt, let title):
                if let rendered = self.advancedRenderers.imageRenderer?.renderImage(
                    url: source,
                    altText: alt,
                    title: title,
                    style: self.style,
                    inline: true
                ) {
                    result.append(rendered)
                } else {
                    result.append(NSAttributedString(string: alt.isEmpty ? "[image]" : alt, attributes: attributes))
                }
            case .softBreak:
                result.append(NSAttributedString(string: "\n", attributes: attributes))
            case .strikethrough(let children):
                let strikethroughRendered = self.renderInline(
                    nodes: children,
                    baseFont: baseFont,
                    textColor: textColor,
                    paragraphStyle: style,
                    italic: italic,
                    bold: bold,
                    linkDestination: linkDestination
                )
                let mutable = NSMutableAttributedString(attributedString: strikethroughRendered)
                let strikeColor = self.style.strikethroughColor ?? textColor
                mutable.addAttributes([
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: strikeColor,
                ], range: NSRange(location: 0, length: mutable.length))
                result.append(mutable)
            }
        }

        return result
    }

    func renderList(_ items: [STMarkdownRenderListItem]) -> NSAttributedString {
        let result = NSMutableAttributedString()

        for (index, item) in items.enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: "\n", attributes: self.baseAttributes()))
            }

            let layout = self.listLayout(for: item)
            let markerAttributes: [NSAttributedString.Key: Any] = [
                .font: layout.markerFont,
                .foregroundColor: self.style.textColor,
                .paragraphStyle: layout.paragraphStyle,
                .baselineOffset: layout.baselineOffset,
            ]
            result.append(NSAttributedString(string: layout.markerText, attributes: markerAttributes))

            let leadingBlocks = self.leadingListBlocks(for: item)
            if leadingBlocks.isEmpty == false {
                let renderedLeading = NSMutableAttributedString(attributedString: self.render(blocks: leadingBlocks))
                self.applyListContentStyle(
                    renderedLeading,
                    item: item,
                    contentIndent: layout.contentIndent,
                    lineHeight: self.resolveLineHeight(for: leadingBlocks.first)
                )
                result.append(renderedLeading)
            }

            let trailingBlocks = self.trailingListBlocks(for: item)
            if trailingBlocks.isEmpty == false {
                let child = NSMutableAttributedString(attributedString: self.render(blocks: trailingBlocks))
                self.offsetParagraphStyles(in: child, by: layout.contentIndent)
                if child.length > 0 {
                    if leadingBlocks.isEmpty == false {
                        result.append(NSAttributedString(string: "\n", attributes: self.baseAttributes()))
                    }
                    result.append(child)
                }
            }
        }

        return result
    }

    func baseAttributes() -> [NSAttributedString.Key: Any] {
        [
            .font: self.style.font,
            .foregroundColor: self.style.textColor,
            .kern: self.style.kern,
            .paragraphStyle: self.bodyParagraphStyle(),
        ]
    }

    func bodyParagraphStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = self.style.lineHeight
        style.maximumLineHeight = self.style.lineHeight
        style.lineSpacing = self.style.bodyLineSpacing
        style.paragraphSpacing = self.style.paragraphSpacing
        style.lineBreakMode = .byWordWrapping
        return style
    }

    func headingParagraphStyle(font: UIFont) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        let lineHeight = font.pointSize * self.style.headingLineHeightMultiplier
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.paragraphSpacing = self.style.paragraphSpacing * 0.5
        style.lineBreakMode = .byWordWrapping
        return style
    }

    func headingFont(for level: Int) -> UIFont {
        switch level {
        case 1:
            return .st_systemFont(ofSize: 22, weight: .bold)
        case 2:
            return .st_systemFont(ofSize: 20, weight: .semibold)
        case 3:
            return .st_systemFont(ofSize: 18, weight: .semibold)
        case 4:
            return .st_systemFont(ofSize: 17, weight: .semibold)
        default:
            return .st_systemFont(ofSize: 16, weight: .medium)
        }
    }

    func listLayout(for item: STMarkdownRenderListItem) -> (markerText: String, markerFont: UIFont, contentIndent: CGFloat, baselineOffset: CGFloat, paragraphStyle: NSMutableParagraphStyle) {
        let firstLineIndent = CGFloat(item.level) * self.style.listIndentPerLevel
        let markerFont: UIFont
        let markerText: String
        let contentIndent: CGFloat
        let baselineOffset: CGFloat

        if let checkbox = item.checkbox {
            let checkboxMarker = checkbox == .checked ? "☑ " : "☐ "
            markerFont = .st_systemFont(ofSize: self.style.font.pointSize, weight: .regular)
            markerText = "\(checkboxMarker)\t"
            let markerWidth = ceil((checkboxMarker as NSString).size(withAttributes: [.font: markerFont]).width)
            contentIndent = firstLineIndent + markerWidth + 5
            baselineOffset = 0
        } else if item.ordered {
            markerFont = UIFont.st_monospacedDigitSystemFont(ofSize: self.style.font.pointSize, weight: .medium)
            let orderedIndex = item.orderedIndex ?? 1
            markerText = "\(orderedIndex).\t"
            let markerWidth = ceil(("\(orderedIndex)." as NSString).size(withAttributes: [.font: markerFont]).width)
            contentIndent = firstLineIndent + markerWidth + 5
            baselineOffset = 0
        } else {
            markerText = item.level == 0 ? "\t●\t" : "\t○\t"
            markerFont = .st_systemFont(ofSize: 7, weight: .regular)
            contentIndent = firstLineIndent + 13
            let baseMidline = (self.style.font.ascender + self.style.font.descender) / 2
            let markerMidline = (markerFont.ascender + markerFont.descender) / 2
            baselineOffset = baseMidline - markerMidline
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = firstLineIndent
        paragraphStyle.headIndent = firstLineIndent
        paragraphStyle.minimumLineHeight = self.style.lineHeight
        paragraphStyle.maximumLineHeight = self.style.lineHeight
        paragraphStyle.paragraphSpacing = self.style.listItemSpacing
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: firstLineIndent),
            NSTextTab(textAlignment: .left, location: contentIndent),
        ]
        paragraphStyle.defaultTabInterval = max(1, contentIndent)

        return (markerText, markerFont, contentIndent, baselineOffset, paragraphStyle)
    }

    func applyListContentStyle(
        _ attributed: NSMutableAttributedString,
        item: STMarkdownRenderListItem,
        contentIndent: CGFloat,
        lineHeight: CGFloat? = nil
    ) {
        self.enumerateParagraphStyles(in: attributed) { paragraphStyle, range in
            let resolvedStyle = paragraphStyle ?? self.bodyParagraphStyle()
            resolvedStyle.firstLineHeadIndent = CGFloat(item.level) * self.style.listIndentPerLevel
            resolvedStyle.headIndent = contentIndent
            resolvedStyle.paragraphSpacing = self.style.listItemSpacing
            resolvedStyle.tabStops = [NSTextTab(textAlignment: .left, location: contentIndent)]
            resolvedStyle.defaultTabInterval = max(1, contentIndent)
            if let lineHeight {
                resolvedStyle.minimumLineHeight = lineHeight
                resolvedStyle.maximumLineHeight = lineHeight
            }
            attributed.addAttribute(.paragraphStyle, value: resolvedStyle, range: range)
        }
    }

    func leadingListBlocks(for item: STMarkdownRenderListItem) -> [STMarkdownRenderBlock] {
        guard let firstBlock = item.blocks.first else {
            return []
        }

        switch firstBlock {
        case .paragraph, .heading:
            return [firstBlock]
        default:
            return []
        }
    }

    func trailingListBlocks(for item: STMarkdownRenderListItem) -> [STMarkdownRenderBlock] {
        guard let firstBlock = item.blocks.first else {
            return []
        }

        switch firstBlock {
        case .paragraph, .heading:
            return Array(item.blocks.dropFirst())
        default:
            return item.blocks
        }
    }

    func resolveLineHeight(for block: STMarkdownRenderBlock?) -> CGFloat? {
        guard let block else {
            return nil
        }

        switch block {
        case .heading(let level, _):
            let font = self.headingFont(for: level)
            return font.pointSize * self.style.headingLineHeightMultiplier
        default:
            return self.style.lineHeight
        }
    }

    func offsetParagraphStyles(in attributed: NSMutableAttributedString, by indent: CGFloat) {
        self.enumerateParagraphStyles(in: attributed) { paragraphStyle, range in
            let resolvedStyle = paragraphStyle ?? self.bodyParagraphStyle()
            resolvedStyle.firstLineHeadIndent += indent
            resolvedStyle.headIndent += indent
            resolvedStyle.tabStops = resolvedStyle.tabStops.map {
                NSTextTab(textAlignment: $0.alignment, location: $0.location + indent)
            }
            resolvedStyle.defaultTabInterval = max(1, resolvedStyle.defaultTabInterval + indent)
            attributed.addAttribute(.paragraphStyle, value: resolvedStyle, range: range)
        }
    }

    func enumerateParagraphStyles(
        in attributed: NSAttributedString,
        using body: (NSMutableParagraphStyle?, NSRange) -> Void
    ) {
        let fullRange = NSRange(location: 0, length: attributed.length)
        if fullRange.length == 0 {
            return
        }

        attributed.enumerateAttribute(.paragraphStyle, in: fullRange) { value, range, _ in
            let paragraphStyle = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle
            body(paragraphStyle, range)
        }
    }

    // MARK: - Block Spacing

    func blockSeparatorSpacing(
        after previousBlock: STMarkdownRenderBlock,
        before nextBlock: STMarkdownRenderBlock
    ) -> CGFloat {
        let trailingSpacing = self.trailingBlockSpacing(for: previousBlock)
        let leadingSpacing = self.leadingBlockSpacing(for: nextBlock)
        return max(max(trailingSpacing, leadingSpacing), 1)
    }

    func leadingBlockSpacing(for block: STMarkdownRenderBlock) -> CGFloat {
        switch block {
        case .heading(let level, _):
            if let topSpacings = self.style.headingTopSpacing,
               level >= 1, level <= topSpacings.count {
                return topSpacings[level - 1]
            }
            return self.style.blockSpacing
        case .list:
            return self.style.listItemSpacing
        default:
            return self.style.blockSpacing
        }
    }

    func trailingBlockSpacing(for block: STMarkdownRenderBlock) -> CGFloat {
        switch block {
        case .heading(let level, _):
            if let bottomSpacings = self.style.headingBottomSpacing,
               level >= 1, level <= bottomSpacings.count {
                return bottomSpacings[level - 1]
            }
            return self.style.blockSpacing
        case .list:
            return self.style.listItemSpacing
        default:
            return self.style.blockSpacing
        }
    }
}
