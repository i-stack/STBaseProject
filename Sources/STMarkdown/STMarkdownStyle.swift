//
//  STMarkdownStyle.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public struct STMarkdownStyle: @unchecked Sendable {
    public var font: UIFont
    public var textColor: UIColor
    public var lineHeight: CGFloat
    public var kern: CGFloat
    public var paragraphSpacing: CGFloat
    public var bodyLineSpacing: CGFloat
    public var headingTextColor: UIColor?
    public var linkColor: UIColor?
    public var inlineCodeTextColor: UIColor?
    public var codeBlockTextColor: UIColor?
    public var codeBlockHeaderTextColor: UIColor?
    public var codeBlockBackgroundColor: UIColor?
    public var tableTextColor: UIColor?
    public var tableHeaderTextColor: UIColor?
    public var tableBorderColor: UIColor?
    public var tableBackgroundColor: UIColor?
    public var imagePlaceholderTextColor: UIColor?
    public var imagePlaceholderBackgroundColor: UIColor?
    public var imagePlaceholderCaptionColor: UIColor?
    public var horizontalRuleColor: UIColor?
    public var horizontalRuleLength: Int
    public var strikethroughColor: UIColor?
    public var listItemSpacing: CGFloat
    public var listIndentPerLevel: CGFloat
    public var headingLineHeightMultiplier: CGFloat
    /// 块级元素之间的默认间距
    public var blockSpacing: CGFloat
    /// 标题上方间距（按 level 1-6 索引取值），nil 时使用 blockSpacing
    public var headingTopSpacing: [CGFloat]?
    /// 标题下方间距（按 level 1-6 索引取值），nil 时使用 blockSpacing
    public var headingBottomSpacing: [CGFloat]?
    /// 代码块内边距
    public var codeBlockContentInsets: UIEdgeInsets
    /// 代码块圆角半径
    public var codeBlockCornerRadius: CGFloat
    /// 代码块边框宽度，0 表示不描边
    public var codeBlockBorderWidth: CGFloat
    /// 代码块边框颜色
    public var codeBlockBorderColor: UIColor?
    /// 渲染宽度，0 表示使用默认宽度
    public var renderWidth: CGFloat
    /// 渲染缩放因子，0 表示自动检测
    public var displayScale: CGFloat

    public init(
        font: UIFont,
        textColor: UIColor,
        lineHeight: CGFloat,
        kern: CGFloat,
        paragraphSpacing: CGFloat = 8,
        bodyLineSpacing: CGFloat = 2,
        headingTextColor: UIColor? = nil,
        linkColor: UIColor? = nil,
        inlineCodeTextColor: UIColor? = nil,
        codeBlockTextColor: UIColor? = nil,
        codeBlockHeaderTextColor: UIColor? = nil,
        codeBlockBackgroundColor: UIColor? = nil,
        codeBlockContentInsets: UIEdgeInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14),
        codeBlockCornerRadius: CGFloat = 14,
        codeBlockBorderWidth: CGFloat = 0,
        codeBlockBorderColor: UIColor? = nil,
        tableTextColor: UIColor? = nil,
        tableHeaderTextColor: UIColor? = nil,
        tableBorderColor: UIColor? = nil,
        tableBackgroundColor: UIColor? = nil,
        imagePlaceholderTextColor: UIColor? = nil,
        imagePlaceholderBackgroundColor: UIColor? = nil,
        imagePlaceholderCaptionColor: UIColor? = nil,
        horizontalRuleColor: UIColor? = nil,
        horizontalRuleLength: Int = 24,
        strikethroughColor: UIColor? = nil,
        listItemSpacing: CGFloat = 8,
        listIndentPerLevel: CGFloat = 14,
        headingLineHeightMultiplier: CGFloat = 1.25,
        blockSpacing: CGFloat = 16,
        headingTopSpacing: [CGFloat]? = nil,
        headingBottomSpacing: [CGFloat]? = nil,
        renderWidth: CGFloat = 0,
        displayScale: CGFloat = 0
    ) {
        self.font = font
        self.textColor = textColor
        self.lineHeight = lineHeight
        self.kern = kern
        self.paragraphSpacing = paragraphSpacing
        self.bodyLineSpacing = bodyLineSpacing
        self.headingTextColor = headingTextColor
        self.linkColor = linkColor
        self.inlineCodeTextColor = inlineCodeTextColor
        self.codeBlockTextColor = codeBlockTextColor
        self.codeBlockHeaderTextColor = codeBlockHeaderTextColor
        self.codeBlockBackgroundColor = codeBlockBackgroundColor
        self.codeBlockContentInsets = codeBlockContentInsets
        self.codeBlockCornerRadius = codeBlockCornerRadius
        self.codeBlockBorderWidth = codeBlockBorderWidth
        self.codeBlockBorderColor = codeBlockBorderColor
        self.tableTextColor = tableTextColor
        self.tableHeaderTextColor = tableHeaderTextColor
        self.tableBorderColor = tableBorderColor
        self.tableBackgroundColor = tableBackgroundColor
        self.imagePlaceholderTextColor = imagePlaceholderTextColor
        self.imagePlaceholderBackgroundColor = imagePlaceholderBackgroundColor
        self.imagePlaceholderCaptionColor = imagePlaceholderCaptionColor
        self.horizontalRuleColor = horizontalRuleColor
        self.horizontalRuleLength = horizontalRuleLength
        self.strikethroughColor = strikethroughColor
        self.listItemSpacing = listItemSpacing
        self.listIndentPerLevel = listIndentPerLevel
        self.headingLineHeightMultiplier = headingLineHeightMultiplier
        self.blockSpacing = blockSpacing
        self.headingTopSpacing = headingTopSpacing
        self.headingBottomSpacing = headingBottomSpacing
        self.renderWidth = renderWidth
        self.displayScale = displayScale
    }

    public static let `default` = STMarkdownStyle(
        font: .st_systemFont(ofSize: 16, weight: .regular),
        textColor: .label,
        lineHeight: 24,
        kern: 0.12
    )

    public var resolvedDisplayScale: CGFloat {
        if self.displayScale > 0 { return self.displayScale }
        if #available(iOS 17.0, *) {
            return UITraitCollection.current.displayScale
        }
        return UIScreen.main.scale
    }
}

enum STMarkdownFontResolver {
    static func italicFont(from font: UIFont) -> UIFont {
        if let descriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic) {
            let resolved = UIFont(descriptor: descriptor, size: font.pointSize)
            if resolved.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                return resolved
            }
        }
        return font
    }

    static func boldFont(from font: UIFont) -> UIFont {
        if let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) {
            let resolved = UIFont(descriptor: descriptor, size: font.pointSize)
            if resolved.fontDescriptor.symbolicTraits.contains(.traitBold) {
                return resolved
            }
        }
        return .st_systemFont(ofSize: font.pointSize, weight: .bold)
    }

    static func boldItalicFont(from font: UIFont) -> UIFont {
        let traits: UIFontDescriptor.SymbolicTraits = [.traitBold, .traitItalic]
        if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
            let resolved = UIFont(descriptor: descriptor, size: font.pointSize)
            let symbolicTraits = resolved.fontDescriptor.symbolicTraits
            if symbolicTraits.contains(.traitBold), symbolicTraits.contains(.traitItalic) {
                return resolved
            }
        }
        return boldFont(from: italicFont(from: font))
    }

    static func italicObliqueness(from font: UIFont) -> CGFloat? {
        let italic = italicFont(from: font)
        guard italic.fontDescriptor.symbolicTraits.contains(.traitItalic) == false else {
            return nil
        }
        return 0.16
    }

    static func boldItalicObliqueness(from font: UIFont) -> CGFloat? {
        let boldItalic = boldItalicFont(from: font)
        guard boldItalic.fontDescriptor.symbolicTraits.contains(.traitItalic) == false else {
            return nil
        }
        return 0.16
    }
}
