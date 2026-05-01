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
    
    public var style: STMarkdownStyle
    public let advancedRenderers: STMarkdownAdvancedRenderers

    public init(style: STMarkdownStyle = .default, advancedRenderers: STMarkdownAdvancedRenderers = .empty) {
        self.style = style
        self.advancedRenderers = advancedRenderers
    }

    public func render(document: STMarkdownRenderDocument) -> NSAttributedString {
        self.render(blocks: document.blocks)
    }
}

public extension STMarkdownAttributedStringRenderer {

    /// 渲染 inline 节点数组为 NSAttributedString，保留完整样式（bold/italic/code/strikethrough/link）。
    /// 供表格 cell 等外部组件复用。
    func renderInlineContent(
        nodes: [STMarkdownInlineNode],
        baseFont: UIFont,
        textColor: UIColor,
        paragraphStyle: NSMutableParagraphStyle? = nil
    ) -> NSAttributedString {
        self.renderInline(
            nodes: nodes,
            baseFont: baseFont,
            textColor: textColor,
            paragraphStyle: paragraphStyle
        )
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
            return self.renderInline(nodes: content, baseFont: headingFont, textColor: headingColor, paragraphStyle: self.headingParagraphStyle(font: headingFont), kernOverride: self.style.headingKern)
        case .quote(let blocks):
            return self.renderQuote(blocks: blocks)
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
        // 早期实现把 inline 节点 render 成 NSAttributedString 后只取 `.string`，
        // 把粗体/斜体/链接等格式全部丢掉。这里复用 `STMarkdownDefaultTableRenderer`
        // 至少能维持等宽对齐与表头分隔，明显优于"裸文本拼接"。
        if let rendered = STMarkdownDefaultTableRenderer().renderTable(table, style: self.style) {
            return rendered
        }
        let rows = ([table.header].compactMap { $0 } + table.rows)
        let strings = rows.map { row in
            row.map { self.renderInline(nodes: $0, baseFont: self.style.font, textColor: self.style.textColor).string }
                .joined(separator: "  ")
        }
        return NSAttributedString(string: strings.joined(separator: "\n"), attributes: self.baseAttributes())
    }

    /// 渲染引用块。
    ///
    /// 与早期"只在最前面拼一个 `┃ `"的实现不同，这里对每一行（含多段、跨段以及空行）都补上
    /// 左侧竖线，遵循 CommonMark 视觉语义；同时引用 `STMarkdownStyle.blockquoteLineColor`
    /// 作为竖线颜色（之前是硬编码 `UIColor.systemGray`，使该 style 字段沦为 dead config）。
    ///
    /// 另外把 `style.blockquoteIndentation`（非负）下沉到段落 `firstLineHeadIndent`/`headIndent`
    /// 中，使得长段落自动换行后内容仍保持与左竖线对齐的缩进。
    func renderQuote(blocks: [STMarkdownRenderBlock]) -> NSAttributedString {
        let body = NSMutableAttributedString(attributedString: self.render(blocks: blocks))
        guard body.length > 0 else { return body }

        let lineColor = self.style.blockquoteLineColor ?? UIColor.systemGray
        let prefixGlyph = "▎  "
        let indent = max(self.style.blockquoteIndentation, 0)
        let prefixAttributes: [NSAttributedString.Key: Any] = [
            .font: self.style.font,
            .foregroundColor: lineColor,
        ]

        // 收集每个段落的起点（按 NSString.paragraphRange 切分，覆盖 \n / \r\n / 段落分隔符）。
        let nsString = body.string as NSString
        var paragraphStarts: [Int] = []
        var paragraphRanges: [NSRange] = []
        var cursor = 0
        while cursor < nsString.length {
            let paraRange = nsString.paragraphRange(for: NSRange(location: cursor, length: 0))
            let snippet = nsString.substring(with: paraRange)
            if snippet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                paragraphStarts.append(paraRange.location)
                paragraphRanges.append(paraRange)
            }
            cursor = NSMaxRange(paraRange)
        }

        // 若配置了缩进，把 blockquoteIndentation 注入每个非空段落的 paragraphStyle。
        if indent > 0 {
            for range in paragraphRanges {
                body.enumerateAttribute(.paragraphStyle, in: range) { value, subRange, _ in
                    let style = ((value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle) ?? self.bodyParagraphStyle()
                    style.firstLineHeadIndent += indent
                    style.headIndent += indent
                    body.addAttribute(.paragraphStyle, value: style, range: subRange)
                }
            }
        }

        // 倒序插入避免索引漂移。
        for location in paragraphStarts.reversed() {
            var attributes = prefixAttributes
            if let paragraphStyle = body.attribute(.paragraphStyle, at: location, effectiveRange: nil) {
                attributes[.paragraphStyle] = paragraphStyle
            }
            let prefix = NSAttributedString(string: prefixGlyph, attributes: attributes)
            body.insert(prefix, at: location)
        }
        return body
    }

    func renderInline(
        nodes: [STMarkdownInlineNode],
        baseFont: UIFont,
        textColor: UIColor,
        paragraphStyle: NSMutableParagraphStyle? = nil,
        italic: Bool = false,
        bold: Bool = false,
        linkDestination: String? = nil,
        kernOverride: CGFloat? = nil
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let italicFont = STMarkdownFontResolver.italicFont(from: baseFont)
        let boldFont = self.style.boldFont.map { UIFont(descriptor: $0.fontDescriptor, size: baseFont.pointSize) }
            ?? STMarkdownFontResolver.boldFont(from: baseFont)
        let boldItalicFont: UIFont = {
            if self.style.boldFont != nil {
                return STMarkdownFontResolver.italicFont(from: boldFont)
            }
            return STMarkdownFontResolver.boldItalicFont(from: baseFont)
        }()
        let style = paragraphStyle ?? self.bodyParagraphStyle()
        let useFont: UIFont
        let obliqueness: CGFloat?
        let resolvedTextColor: UIColor
        if italic && bold {
            useFont = boldItalicFont
            obliqueness = STMarkdownFontResolver.boldItalicObliqueness(from: baseFont)
            resolvedTextColor = self.style.boldTextColor ?? textColor
        } else if bold {
            useFont = boldFont
            obliqueness = nil
            resolvedTextColor = self.style.boldTextColor ?? textColor
        } else if italic {
            useFont = italicFont
            obliqueness = STMarkdownFontResolver.italicObliqueness(from: baseFont)
            resolvedTextColor = textColor
        } else {
            useFont = baseFont
            obliqueness = nil
            resolvedTextColor = textColor
        }
        var attributes: [NSAttributedString.Key: Any] = [
            .font: useFont,
            .foregroundColor: resolvedTextColor,
            .kern: kernOverride ?? self.style.kern,
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
                    // 让 attachment 承载周围文字的 paragraphStyle / kern / link，避免行高抖动及
                    // 被"排除在链接可点击区域之外"。attachment 自带的 font/foreground/bounds
                    // 不会被这里的 `mergeInheritableAttributes` 覆盖。
                    result.append(self.mergeInheritableAttributes(into: rendered, from: attributes))
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
                if let inlineBg = self.style.inlineCodeBackgroundColor {
                    codeAttributes[.backgroundColor] = inlineBg
                }
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
                    // 同 inline math：让 attachment 继承 paragraph / kern / link，
                    // 嵌在链接里的图片点击区域才能覆盖到 attachment glyph。
                    result.append(self.mergeInheritableAttributes(into: rendered, from: attributes))
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
                    // leading 段落已包含内联文本且后跟 `\n`；这里补一个分隔即可。
                    // 当 leading 为空（列表项以 quote / codeBlock / list 等块级元素开头），
                    // marker 后没有任何换行，直接 append 会让 marker 与块内容挤在同一行。
                    result.append(NSAttributedString(string: "\n", attributes: self.baseAttributes()))
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

    /// 把段落级属性（paragraphStyle / kern / link）下沉到 attachment 字符上，避免：
    ///   1. inline math / 图像 attachment 与周围文字行高不一致；
    ///   2. 嵌在链接内的图像无法被 TextKit 视作链接可点击区域。
    /// 不会覆盖 attachment 自身关心的 `.font` / `.foregroundColor` / `.attachment`。
    func mergeInheritableAttributes(
        into rendered: NSAttributedString,
        from attributes: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        guard rendered.length > 0 else { return rendered }
        let mutable = NSMutableAttributedString(attributedString: rendered)
        let fullRange = NSRange(location: 0, length: mutable.length)
        let inheritKeys: [NSAttributedString.Key] = [.paragraphStyle, .kern, .link]
        for key in inheritKeys {
            guard let value = attributes[key] else { continue }
            // 仅在目标 range 内还没有显式值时补齐；`.link` 是个例外——
            // 当上层处于链接上下文时无论如何都要覆盖，否则 attachment 无法响应点击。
            if key == .link {
                mutable.addAttribute(key, value: value, range: fullRange)
                continue
            }
            mutable.enumerateAttribute(key, in: fullRange) { existing, range, _ in
                if existing == nil {
                    mutable.addAttribute(key, value: value, range: range)
                }
            }
        }
        return mutable
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
        if let provider = self.style.headingFontProvider {
            return provider(level)
        }
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
