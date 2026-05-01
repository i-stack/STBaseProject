//
//  STMarkdownCodeBlockSupport.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

private final class STMarkdownCodeBlockCacheEntry: NSObject {
    let fullBodyHeight: CGFloat
    let image: UIImage

    init(fullBodyHeight: CGFloat, image: UIImage) {
        self.fullBodyHeight = fullBodyHeight
        self.image = image
    }
}

public final class STMarkdownCodeBlockAttachment: NSTextAttachment {
    public static let collapsedBodyMaxHeight: CGFloat = 220

    /// 根据 style 计算按钮行预留宽度
    public static func buttonRowReservedWidth(for style: STMarkdownStyle) -> CGFloat {
        style.codeBlockButtonRowReservedWidth
    }

    private static let renderCache: NSCache<NSString, STMarkdownCodeBlockCacheEntry> = {
        let cache = NSCache<NSString, STMarkdownCodeBlockCacheEntry>()
        cache.countLimit = 48
        return cache
    }()

    public let language: String?
    public let code: String
    public let style: STMarkdownStyle
    public let renderedBodyHeight: CGFloat
    public let displayedBodyHeight: CGFloat
    public let headerHeight: CGFloat
    public let contentInsets: UIEdgeInsets
    public let isCollapsed: Bool

    public init(
        language: String?,
        code: String,
        style: STMarkdownStyle,
        visibleCode: String? = nil,
        forceCollapsed: Bool = false
    ) {
        self.language = language?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.code = code
        self.style = style
        self.contentInsets = style.codeBlockContentInsets
        let hasLanguage = self.language?.isEmpty == false
        if hasLanguage {
            let autoHeight = max(
                ceil(UIFont.st_monospacedSystemFont(ofSize: max(style.font.pointSize - 2, 12), weight: .semibold).lineHeight),
                18
            )
            self.headerHeight = style.codeBlockHeaderHeight > 0 ? style.codeBlockHeaderHeight : autoHeight
        } else {
            self.headerHeight = 0
        }

        let codeFont = UIFont.st_monospacedSystemFont(
            ofSize: max(style.font.pointSize - 1, 12),
            weight: .regular
        )
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        paragraphStyle.lineSpacing = max(style.bodyLineSpacing, 2)
        let codeWidth = max(
            Self.blockWidth(for: style) - contentInsets.left - contentInsets.right,
            1
        )
        let cacheKey = Self.cacheKey(
            language: self.language,
            code: code,
            visibleCode: visibleCode,
            forceCollapsed: forceCollapsed,
            style: style,
            codeWidth: codeWidth,
            headerHeight: self.headerHeight,
            contentInsets: self.contentInsets
        )

        if let cached = Self.renderCache.object(forKey: cacheKey as NSString) {
            self.renderedBodyHeight = cached.fullBodyHeight
            self.isCollapsed = cached.fullBodyHeight > Self.collapsedBodyMaxHeight
            self.displayedBodyHeight = min(cached.fullBodyHeight, Self.collapsedBodyMaxHeight)
            super.init(data: nil, ofType: nil)
            self.image = cached.image
            self.bounds = CGRect(origin: .zero, size: cached.image.size)
            return
        }

        let renderCode = visibleCode ?? code
        let highlightedBody = STMarkdownCodeSyntaxHighlighter.highlightedBody(
            language: self.language,
            code: renderCode,
            font: codeFont,
            textColor: style.codeBlockTextColor ?? style.textColor,
            paragraphStyle: paragraphStyle
        )
        let fullBodyHeight = max(
            ceil(highlightedBody.boundingRect(
                with: CGSize(width: codeWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).height),
            ceil(codeFont.lineHeight)
        )
        self.isCollapsed = forceCollapsed || fullBodyHeight > Self.collapsedBodyMaxHeight
        self.renderedBodyHeight = self.isCollapsed
            ? max(fullBodyHeight, Self.collapsedBodyMaxHeight + 1)
            : fullBodyHeight
        self.displayedBodyHeight = min(self.renderedBodyHeight, Self.collapsedBodyMaxHeight)

        super.init(data: nil, ofType: nil)

        let image = STMarkdownCodeBlockRenderer.renderAttachmentImage(
            language: self.language,
            style: style,
            highlightedBody: highlightedBody,
            bodyHeight: self.displayedBodyHeight,
            fullBodyHeight: self.renderedBodyHeight,
            headerHeight: self.headerHeight,
            contentInsets: self.contentInsets
        )
        self.image = image
        self.bounds = CGRect(origin: .zero, size: image.size)
        Self.renderCache.setObject(
            STMarkdownCodeBlockCacheEntry(
                fullBodyHeight: fullBodyHeight,
                image: image
            ),
            forKey: cacheKey as NSString
        )
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    private static func blockWidth(for style: STMarkdownStyle) -> CGFloat {
        if style.renderWidth > 0 {
            return style.renderWidth
        }
        return 280 + style.codeBlockContentInsets.left + style.codeBlockContentInsets.right
    }

    private static func cacheKey(
        language: String?,
        code: String,
        visibleCode: String?,
        forceCollapsed: Bool,
        style: STMarkdownStyle,
        codeWidth: CGFloat,
        headerHeight: CGFloat,
        contentInsets: UIEdgeInsets
    ) -> String {
        [
            language ?? "",
            String(code.hashValue),
            String(code.count),
            String(visibleCode?.hashValue ?? 0),
            String(visibleCode?.count ?? 0),
            forceCollapsed ? "1" : "0",
            String(format: "%.2f", codeWidth),
            String(format: "%.2f", headerHeight),
            String(format: "%.2f", contentInsets.top),
            String(format: "%.2f", contentInsets.left),
            String(format: "%.2f", contentInsets.bottom),
            String(format: "%.2f", contentInsets.right),
            String(format: "%.2f", style.font.pointSize),
            String(format: "%.2f", style.bodyLineSpacing),
            String(format: "%.2f", style.renderWidth),
            String(format: "%.2f", style.codeBlockCornerRadius),
            String(format: "%.2f", style.codeBlockBorderWidth),
            rgbaKey(style.textColor),
            rgbaKey(style.codeBlockTextColor),
            rgbaKey(style.codeBlockHeaderTextColor),
            rgbaKey(style.codeBlockBackgroundColor),
            rgbaKey(style.codeBlockBorderColor),
            rgbaKey(style.horizontalRuleColor),
        ].joined(separator: "|")
    }

    private static func rgbaKey(_ color: UIColor?) -> String {
        guard let color else { return "nil" }
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return color.description
        }
        return String(format: "%.4f,%.4f,%.4f,%.4f", red, green, blue, alpha)
    }
}

public struct STMarkdownCodeBlockRenderer: STMarkdownCodeBlockRendering {
    public init() {}

    public func renderCodeBlock(
        language: String?,
        code: String,
        style: STMarkdownStyle
    ) -> NSAttributedString? {
        let attachment = STMarkdownCodeBlockAttachment(language: language, code: code, style: style)
        return NSAttributedString(attachment: attachment)
    }

    static func renderAttachmentImage(
        language: String?,
        style: STMarkdownStyle,
        highlightedBody: NSAttributedString,
        bodyHeight: CGFloat,
        fullBodyHeight: CGFloat,
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
        let hasHeader = language?.isEmpty == false && headerHeight > 0
        let separatorSpacing = hasHeader ? style.codeBlockSeparatorSpacing : 0
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

            if hasHeader, let language {
                let headerText = language.uppercased()
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
                    withAttributes: [
                        .font: headerFont,
                        .foregroundColor: headerColor,
                    ]
                )

                let separatorRect = CGRect(
                    x: contentInsets.left,
                    y: contentInsets.top + headerHeight + separatorSpacing / 2,
                    width: contentWidth,
                    height: 1
                )
                cgContext.setFillColor((style.horizontalRuleColor ?? UIColor.separator).withAlphaComponent(0.35).cgColor)
                cgContext.fill(separatorRect)
            }

            let codeRect = CGRect(
                x: contentInsets.left,
                y: contentInsets.top + headerHeight + separatorSpacing,
                width: contentWidth,
                height: bodyHeight
            )
            cgContext.saveGState()
            cgContext.clip(to: codeRect)
            highlightedBody.draw(
                with: CGRect(
                    x: codeRect.minX,
                    y: codeRect.minY,
                    width: codeRect.width,
                    height: fullBodyHeight
                ),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
            cgContext.restoreGState()

            if fullBodyHeight > bodyHeight + 0.5 {
                let fadeHeight: CGFloat = 42
                let fadeRect = CGRect(
                    x: contentInsets.left,
                    y: max(codeRect.maxY - fadeHeight, codeRect.minY),
                    width: contentWidth,
                    height: fadeHeight
                )
                let colors = [
                    backgroundColor.withAlphaComponent(0).cgColor,
                    backgroundColor.withAlphaComponent(0.96).cgColor,
                    backgroundColor.cgColor,
                ] as CFArray
                let locations: [CGFloat] = [0, 0.7, 1]
                if let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: colors,
                    locations: locations
                ) {
                    cgContext.saveGState()
                    cgContext.clip(to: fadeRect)
                    cgContext.drawLinearGradient(
                        gradient,
                        start: CGPoint(x: fadeRect.minX, y: fadeRect.minY),
                        end: CGPoint(x: fadeRect.minX, y: fadeRect.maxY),
                        options: []
                    )
                    cgContext.restoreGState()
                }
            }
        }
    }
}

public enum STMarkdownCodeSyntaxHighlighter {
    public static func highlightedBody(
        language: String?,
        code: String,
        font: UIFont,
        textColor: UIColor,
        paragraphStyle: NSParagraphStyle
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(string: code, attributes: [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ])
        guard !code.isEmpty else { return result }
        let lang = normalize(language)
        let colors = Palette(
            keyword: UIColor.systemBlue,
            string: UIColor(fromHexString: "#C46B2D") ?? .systemOrange,
            comment: textColor.withAlphaComponent(0.55),
            number: UIColor(fromHexString: "#1F8A70") ?? .systemTeal,
            type: UIColor(fromHexString: "#7A57D1") ?? .systemIndigo,
            tag: UIColor(fromHexString: "#B5432A") ?? .systemRed
        )

        apply(patterns: keywordPatterns(for: lang), color: colors.keyword, to: result)
        apply(patterns: tagPatterns(for: lang), color: colors.tag, to: result)
        apply(patterns: typePatterns(for: lang), color: colors.type, to: result)
        apply(patterns: numberPatterns(), color: colors.number, to: result)
        apply(patterns: stringPatterns(for: lang), color: colors.string, to: result)
        apply(patterns: commentPatterns(for: lang), color: colors.comment, to: result)
        return result
    }

    private struct Palette {
        let keyword: UIColor
        let string: UIColor
        let comment: UIColor
        let number: UIColor
        let type: UIColor
        let tag: UIColor
    }

    private static func normalize(_ language: String?) -> String {
        language?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
    }

    // 编译后的正则表达式按 pattern 字符串缓存，避免每帧重复编译（流式阶段 20fps × 6 组 = 每秒 120 次编译）。
    private static let _regexCache = NSCache<NSString, NSRegularExpression>()

    private static func apply(patterns: [String], color: UIColor, to attributedText: NSMutableAttributedString) {
        let fullRange = NSRange(location: 0, length: attributedText.length)
        for pattern in patterns {
            let cacheKey = pattern as NSString
            let regex: NSRegularExpression
            if let cached = _regexCache.object(forKey: cacheKey) {
                regex = cached
            } else if let compiled = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) {
                _regexCache.setObject(compiled, forKey: cacheKey)
                regex = compiled
            } else {
                continue
            }
            regex.enumerateMatches(in: attributedText.string, options: [], range: fullRange) { match, _, _ in
                guard let match, match.range.location != NSNotFound else { return }
                attributedText.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }
    }

    private static func commentPatterns(for language: String) -> [String] {
        switch language {
        case "python", "bash", "shell", "sh", "yaml", "yml", "ruby":
            return [#"(?m)#.*$"#]
        case "sql":
            return [#"(?m)--.*$"#, #"/\*[\s\S]*?\*/"#]
        case "html", "xml", "svg":
            return [#"<!--[\s\S]*?-->"#]
        case "css":
            return [#"/\*[\s\S]*?\*/"#]
        default:
            return [#"(?m)//.*$"#, #"/\*[\s\S]*?\*/"#]
        }
    }

    private static func stringPatterns(for language: String) -> [String] {
        if language == "html" || language == "xml" || language == "svg" {
            return [#""([^"\\]|\\.)*""#, #"'([^'\\]|\\.)*'"#]
        }
        return [#""([^"\\]|\\.)*""#, #"'([^'\\]|\\.)*'"#, #"`([^`\\]|\\.)*`"#]
    }

    private static func numberPatterns() -> [String] {
        [#"\b\d+(?:\.\d+)?\b"#]
    }

    private static func typePatterns(for language: String) -> [String] {
        switch language {
        case "swift":
            return [#"\b(?:String|Int|Double|Bool|CGFloat|CGRect|UIView|UIColor|URL|Data|Result|Error|Any|Void)\b"#]
        case "typescript", "ts", "javascript", "js":
            return [#"\b(?:Promise|Array|Record|Map|Set|Date|RegExp|HTMLElement|HTMLDivElement|JSON)\b"#]
        case "python":
            return [#"\b(?:str|int|float|bool|list|dict|tuple|set|None)\b"#]
        default:
            return []
        }
    }

    private static func keywordPatterns(for language: String) -> [String] {
        let words: [String]
        switch language {
        case "swift":
            words = ["let", "var", "func", "if", "else", "guard", "return", "class", "struct", "enum", "protocol", "extension", "import", "private", "fileprivate", "internal", "public", "open", "static", "case", "switch", "for", "in", "while", "where", "try", "catch", "throw", "async", "await", "actor", "weak", "self", "nil", "true", "false"]
        case "typescript", "ts", "javascript", "js":
            words = ["const", "let", "var", "function", "return", "if", "else", "switch", "case", "break", "for", "while", "class", "extends", "new", "import", "from", "export", "default", "async", "await", "try", "catch", "throw", "null", "undefined", "true", "false"]
        case "python":
            words = ["def", "class", "if", "elif", "else", "for", "while", "in", "return", "import", "from", "as", "try", "except", "finally", "with", "lambda", "pass", "break", "continue", "None", "True", "False"]
        case "html", "xml", "svg":
            words = []
        case "css":
            words = ["display", "position", "color", "background", "padding", "margin", "border", "flex", "grid"]
        case "json":
            words = ["true", "false", "null"]
        case "bash", "shell", "sh":
            words = ["if", "then", "else", "fi", "for", "do", "done", "case", "esac", "function", "export", "local"]
        default:
            words = ["if", "else", "for", "while", "return", "class", "struct", "enum", "switch", "case", "break", "continue", "import", "from", "public", "private", "protected", "static", "const", "let", "var", "func", "def", "new", "true", "false", "null", "nil"]
        }
        guard !words.isEmpty else { return [] }
        let joined = words.joined(separator: "|")
        // `\(joined)` 已在字符串插值阶段被替换为关键字列表；这里的字面量已无需二次处理。
        return ["(?<![\\w$])(?:\(joined))(?![\\w$])"]
    }

    private static func tagPatterns(for language: String) -> [String] {
        switch language {
        case "html", "xml", "svg":
            return [
                #"</?[A-Za-z][A-Za-z0-9:-]*"#,
                #"\b[A-Za-z-:]+(?=\=)"#,
            ]
        case "css":
            return [#"(?m)^[ \t]*[A-Za-z-]+(?=\s*:)"#]
        default:
            return []
        }
    }
}
