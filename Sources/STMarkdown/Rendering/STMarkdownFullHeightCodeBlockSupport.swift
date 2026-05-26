//
//  STMarkdownFullHeightCodeBlockAttachment.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/05/26.
//

import UIKit

/// 全高（不折叠）代码块 attachment。
/// 与 STMarkdownCodeBlockAttachment（折叠 + 渲染缓存）的核心差异：
/// - 总是展示完整代码高度，不裁剪
/// - 不维护折叠状态（isCollapsed 始终为 false）
/// - 轻量缓存：同 key 命中时直接复用图片，避免流式阶段重复渲染
public final class STMarkdownFullHeightCodeBlockAttachment: NSTextAttachment {
    public let language: String?
    public let code: String
    public let style: STMarkdownStyle
    public let headerHeight: CGFloat
    public let contentInsets: UIEdgeInsets

    private static let renderCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 32
        return cache
    }()

    public static func clearRenderCache() {
        Self.renderCache.removeAllObjects()
    }

    public init(language: String?, code: String, style: STMarkdownStyle) {
        self.language = language?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.code = code
        self.style = style
        self.contentInsets = style.codeBlockContentInsets
        let autoHeight = max(
            ceil(UIFont.st_monospacedSystemFont(
                ofSize: max(style.font.pointSize - 2, 12),
                weight: .semibold
            ).lineHeight),
            18
        )
        self.headerHeight = style.codeBlockHeaderHeight > 0 ? style.codeBlockHeaderHeight : autoHeight
        super.init(data: nil, ofType: nil)

        let cacheKey = Self.cacheKey(language: self.language, code: code, style: style)
        if let cached = Self.renderCache.object(forKey: cacheKey as NSString) {
            self.image = cached
            self.bounds = CGRect(origin: .zero, size: cached.size)
            return
        }
        let image = STMarkdownDynamicHeightCodeBlockRenderer.renderAttachmentImage(
            language: self.language,
            code: code,
            style: style,
            headerHeight: self.headerHeight,
            contentInsets: self.contentInsets
        )
        Self.renderCache.setObject(image, forKey: cacheKey as NSString)
        self.image = image
        self.bounds = CGRect(origin: .zero, size: image.size)
    }

    public required init?(coder: NSCoder) { nil }

    private static func cacheKey(language: String?, code: String, style: STMarkdownStyle) -> String {
        let count = code.count
        let utf8Count = code.utf8.count
        let prefix = String(code.prefix(32))
        let suffix = String(code.suffix(32))
        let fingerprint = "c\(count)_b\(utf8Count)_h\(code.hashValue)_p\(prefix)_s\(suffix)"
        return [
            language ?? "",
            fingerprint,
            String(format: "%.2f", style.renderWidth),
            String(format: "%.2f", style.font.pointSize),
            String(format: "%.2f", style.bodyLineSpacing),
        ].joined(separator: "|")
    }
}

/// 全高代码块渲染器，实现 STMarkdownCodeBlockRendering 协议，可直接注入 STMarkdownAdvancedRenderers.codeBlockRenderer。
public struct STMarkdownDynamicHeightCodeBlockRenderer: STMarkdownCodeBlockRendering {
    public init() {}

    public func renderCodeBlock(language: String?, code: String, style: STMarkdownStyle) -> NSAttributedString? {
        NSAttributedString(attachment: STMarkdownFullHeightCodeBlockAttachment(language: language, code: code, style: style))
    }

    public static func renderAttachmentImage(
        language: String?,
        code: String,
        style: STMarkdownStyle,
        headerHeight: CGFloat,
        contentInsets: UIEdgeInsets
    ) -> UIImage {
        let blockWidth = max(
            style.renderWidth > 0
                ? style.renderWidth
                : (280 + style.codeBlockContentInsets.left + style.codeBlockContentInsets.right),
            1
        )
        let contentWidth = max(blockWidth - contentInsets.left - contentInsets.right, 1)
        let backgroundColor = style.codeBlockBackgroundColor ?? UIColor.secondarySystemBackground
        let borderColor = style.codeBlockBorderColor ?? UIColor.separator
        let headerColor = style.codeBlockHeaderTextColor ?? style.textColor.withAlphaComponent(0.72)
        let headerFont = UIFont.st_monospacedSystemFont(
            ofSize: max(style.font.pointSize - 2, 12),
            weight: .semibold
        )
        let codeFont = UIFont.st_monospacedSystemFont(
            ofSize: max(style.font.pointSize - 1, 12),
            weight: .regular
        )
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        paragraphStyle.lineSpacing = max(style.bodyLineSpacing, 2)
        let highlightedBody = STMarkdownCodeSyntaxHighlighter.highlightedBody(
            language: language,
            code: code,
            font: codeFont,
            textColor: style.codeBlockTextColor ?? style.textColor,
            paragraphStyle: paragraphStyle
        )
        let bodyHeight = max(
            ceil(highlightedBody.boundingRect(
                with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).height),
            ceil(codeFont.lineHeight)
        )
        let separatorSpacing = style.codeBlockSeparatorSpacing
        let buttonRowReservedWidth = style.codeBlockButtonRowReservedWidth
        let blockHeight = contentInsets.top + headerHeight + separatorSpacing + bodyHeight + contentInsets.bottom
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = style.resolvedDisplayScale
        return UIGraphicsImageRenderer(
            size: CGSize(width: blockWidth, height: blockHeight),
            format: format
        ).image { context in
            let cgContext = context.cgContext
            let rect = CGRect(x: 0, y: 0, width: blockWidth, height: blockHeight)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: style.codeBlockCornerRadius)
            backgroundColor.setFill()
            path.fill()
            if style.codeBlockBorderWidth > 0 {
                borderColor.setStroke()
                path.lineWidth = style.codeBlockBorderWidth
                path.stroke()
            }
            let headerText = (language?.isEmpty == false ? language?.uppercased() : "CODE") ?? "CODE"
            let headerTextSize = (headerText as NSString).size(withAttributes: [.font: headerFont])
            let headerTextY = contentInsets.top + max((headerHeight - headerTextSize.height) / 2, 0)
            let headerRect = CGRect(
                x: contentInsets.left,
                y: headerTextY,
                width: max(contentWidth - buttonRowReservedWidth, 1),
                height: headerTextSize.height
            )
            (headerText as NSString).draw(
                in: headerRect,
                withAttributes: [.font: headerFont, .foregroundColor: headerColor]
            )
            let separatorRect = CGRect(
                x: contentInsets.left,
                y: contentInsets.top + headerHeight + separatorSpacing / 2,
                width: contentWidth,
                height: 1
            )
            cgContext.setFillColor(
                (style.horizontalRuleColor ?? UIColor.separator).withAlphaComponent(0.35).cgColor
            )
            cgContext.fill(separatorRect)
            let codeRect = CGRect(
                x: contentInsets.left,
                y: contentInsets.top + headerHeight + separatorSpacing,
                width: contentWidth,
                height: bodyHeight
            )
            cgContext.saveGState()
            cgContext.clip(to: codeRect)
            highlightedBody.draw(
                with: codeRect,
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            cgContext.restoreGState()
        }
    }
}
