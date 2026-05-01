//
//  STMarkdownTypography.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public enum STMarkdownTypography {
    public static func bodyParagraphStyle(style: STMarkdownStyle) -> NSMutableParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = style.lineHeight
        paragraphStyle.maximumLineHeight = style.lineHeight
        paragraphStyle.lineSpacing = style.bodyLineSpacing
        paragraphStyle.paragraphSpacing = style.paragraphSpacing
        paragraphStyle.lineBreakMode = .byWordWrapping
        return paragraphStyle
    }

    public static func headingFont(for level: Int) -> UIFont {
        switch level {
        case 1:
            return UIFont.st_systemFont(ofSize: 22, weight: .bold)
        case 2:
            return UIFont.st_systemFont(ofSize: 20, weight: .semibold)
        case 3:
            return UIFont.st_systemFont(ofSize: 18, weight: .semibold)
        case 4:
            return UIFont.st_systemFont(ofSize: 17, weight: .semibold)
        default:
            // level 5、6 共用更小字重，避免与 H4 混淆。
            return UIFont.st_systemFont(ofSize: 16, weight: .medium)
        }
    }

    public static func headingInsets(for level: Int) -> UIEdgeInsets {
        switch level {
        case 1:
            return UIEdgeInsets(top: 32, left: 0, bottom: 10, right: 0)
        case 2:
            return UIEdgeInsets(top: 28, left: 0, bottom: 10, right: 0)
        case 3:
            return UIEdgeInsets(top: 24, left: 0, bottom: 8, right: 0)
        case 4:
            return UIEdgeInsets(top: 20, left: 0, bottom: 8, right: 0)
        default:
            return UIEdgeInsets(top: 16, left: 0, bottom: 6, right: 0)
        }
    }

    public static func headingParagraphStyle(
        level: Int,
        font: UIFont,
        style: STMarkdownStyle
    ) -> NSMutableParagraphStyle {
        let insets = headingInsets(for: level)
        let paragraphStyle = NSMutableParagraphStyle()
        let lineHeight = font.pointSize * style.headingLineHeightMultiplier
        paragraphStyle.minimumLineHeight = lineHeight
        paragraphStyle.maximumLineHeight = lineHeight
        // paragraphSpacingBefore + 前一段落的 paragraphSpacing = headingInsets.top
        paragraphStyle.paragraphSpacingBefore = max(insets.top - style.paragraphSpacing, 0)
        paragraphStyle.paragraphSpacing = insets.bottom
        paragraphStyle.lineBreakMode = .byWordWrapping
        return paragraphStyle
    }
}

// MARK: - List Layout

public struct STMarkdownListLayout {
    public let markerText: String
    public let markerFont: UIFont
    public let markerIndent: CGFloat
    public let contentIndent: CGFloat
    public let baselineOffset: CGFloat
    /// 段落样式。对外暴露为不可变类型，避免外部修改污染其他使用该 layout 的段落。
    /// 若确需微调，请自行 `paragraphStyle.mutableCopy()` 后再改写。
    public let paragraphStyle: NSParagraphStyle

    public init(
        markerText: String,
        markerFont: UIFont,
        markerIndent: CGFloat,
        contentIndent: CGFloat,
        baselineOffset: CGFloat,
        paragraphStyle: NSParagraphStyle
    ) {
        self.markerText = markerText
        self.markerFont = markerFont
        self.markerIndent = markerIndent
        self.contentIndent = contentIndent
        self.baselineOffset = baselineOffset
        self.paragraphStyle = paragraphStyle
    }
}

public enum STMarkdownListStyleResolver {
    private static let unorderedLevel0Size: CGFloat = 7
    private static let unorderedLevel0Spacing: CGFloat = 6
    private static let unorderedLevel1Size: CGFloat = 7
    private static let unorderedLevel1Spacing: CGFloat = 6
    private static let unorderedLevelDefaultSize: CGFloat = 6
    private static let unorderedLevelDefaultSpacing: CGFloat = 5
    private static let orderedSpacing: CGFloat = 5

    public static func makeLayout(
        ordered: Bool,
        level: Int,
        orderedIndex: Int?,
        baseFont: UIFont,
        style: STMarkdownStyle
    ) -> STMarkdownListLayout {
        let firstLineIndent = CGFloat(level) * style.listIndentPerLevel
        let markerIndent: CGFloat
        let contentIndent: CGFloat
        let markerText: String
        let markerFont: UIFont
        let baselineOffset: CGFloat

        if ordered {
            let index = max(orderedIndex ?? 1, 1)
            markerFont = UIFont.monospacedDigitSystemFont(ofSize: baseFont.pointSize, weight: .medium)
            markerText = "\(index).\t"
            markerIndent = firstLineIndent
            let markerWidth = ceil(("\(index)." as NSString).size(withAttributes: [.font: markerFont]).width)
            contentIndent = markerIndent + markerWidth + orderedSpacing
            baselineOffset = 0
        } else {
            markerIndent = firstLineIndent + 1
            switch level {
            case 0:
                markerText = "\t●\t"
                markerFont = UIFont.st_systemFont(ofSize: unorderedLevel0Size, weight: .regular)
                contentIndent = markerIndent + unorderedLevel0Size + unorderedLevel0Spacing
            case 1:
                markerText = "\t●\t"
                markerFont = UIFont.st_systemFont(ofSize: unorderedLevel1Size, weight: .regular)
                contentIndent = markerIndent + unorderedLevel1Size + unorderedLevel1Spacing
            default:
                markerText = "\t▪\t"
                markerFont = UIFont.st_systemFont(ofSize: unorderedLevelDefaultSize, weight: .regular)
                contentIndent = markerIndent + unorderedLevelDefaultSize + unorderedLevelDefaultSpacing
            }
            let baseMidline = (baseFont.ascender + baseFont.descender) / 2
            let markerMidline = (markerFont.ascender + markerFont.descender) / 2
            baselineOffset = baseMidline - markerMidline
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = firstLineIndent
        paragraphStyle.headIndent = firstLineIndent
        paragraphStyle.minimumLineHeight = style.lineHeight
        paragraphStyle.maximumLineHeight = style.lineHeight
        paragraphStyle.paragraphSpacingBefore = 0
        paragraphStyle.paragraphSpacing = style.listItemSpacing
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .left, location: markerIndent),
            NSTextTab(textAlignment: .left, location: contentIndent),
        ]
        paragraphStyle.defaultTabInterval = max(1, contentIndent)

        // 对外暴露不可变副本，防止调用方意外篡改。
        let immutableParagraphStyle = (paragraphStyle.copy() as? NSParagraphStyle) ?? paragraphStyle

        return STMarkdownListLayout(
            markerText: markerText,
            markerFont: markerFont,
            markerIndent: markerIndent,
            contentIndent: contentIndent,
            baselineOffset: baselineOffset,
            paragraphStyle: immutableParagraphStyle
        )
    }

    /// 为列表项的"后续行 / 续段"统一缩进。
    ///
    /// - Parameters:
    ///   - firstLineIndent: 列表项首行（marker 所在行）的左缩进。仅保留参数以兼容旧 API；
    ///     续行段落真正使用的是 `contentIndent`，从而保证视觉上与正文对齐。
    ///   - contentIndent: 正文起点缩进，续行的 `firstLineHeadIndent` / `headIndent` 均对齐于此。
    public static func applyContinuationIndent(
        to attributed: NSMutableAttributedString,
        firstLineIndent: CGFloat,
        contentIndent: CGFloat,
        style: STMarkdownStyle
    ) {
        _ = firstLineIndent // 保留以兼容旧调用方；续段以 contentIndent 为准。
        let string = attributed.string as NSString
        var location = 0
        while location < attributed.length {
            let range = string.paragraphRange(for: NSRange(location: location, length: 0))
            guard range.length > 0 else { break }
            let existing = attributed.attribute(.paragraphStyle, at: range.location, effectiveRange: nil) as? NSParagraphStyle
            let paragraph = (existing?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            // 续段的首行与后续行都应对齐到 contentIndent，避免退回 marker 列形成视觉错位。
            paragraph.firstLineHeadIndent = contentIndent
            paragraph.headIndent = contentIndent
            paragraph.minimumLineHeight = style.lineHeight
            paragraph.maximumLineHeight = style.lineHeight
            paragraph.paragraphSpacing = style.listItemSpacing
            paragraph.lineBreakMode = .byWordWrapping
            paragraph.tabStops = [NSTextTab(textAlignment: .left, location: contentIndent)]
            paragraph.defaultTabInterval = max(1, contentIndent)
            attributed.addAttribute(.paragraphStyle, value: paragraph, range: range)
            location = range.location + range.length
        }
    }
}
