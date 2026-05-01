//
//  STMarkdownStyle.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

/// Markdown 样式配置。
///
/// - Note: 含有大量 `UIColor` / `UIFont` / `UIEdgeInsets` 字段。UIKit 官方并未将其声明为
///   `Sendable`，但这些值在读写已有实例的 API 边界上是实践安全的，因此用
///   `@unchecked Sendable` 抑制编译器提示。`headingFontProvider` 已显式约束为 `@Sendable`，
///   调用方务必确保自定义闭包捕获的状态亦满足 `Sendable`。
public struct STMarkdownStyle: @unchecked Sendable {
    public var font: UIFont
    /// 加粗字体（nil 时由 STMarkdownFontResolver.boldFont(from: font) 自动推导）
    public var boldFont: UIFont?
    /// 加粗文本颜色（nil 时沿用 textColor）
    public var boldTextColor: UIColor?
    public var textColor: UIColor
    public var lineHeight: CGFloat
    public var kern: CGFloat
    public var paragraphSpacing: CGFloat
    public var bodyLineSpacing: CGFloat
    public var bodyTextInsets: UIEdgeInsets
    public var headingTextColor: UIColor?
    /// 标题字间距（nil 时沿用 kern）
    public var headingKern: CGFloat?
    /// 自定义标题字体（按 level 1-6 返回），nil 时使用默认 headingFont(for:)
    ///
    /// 闭包被标注为 `@Sendable`，调用方必须保证它捕获的状态也满足 `Sendable`，
    /// 以免样式在跨线程使用时引入 data race。
    public var headingFontProvider: (@Sendable (Int) -> UIFont)?
    public var linkColor: UIColor?
    public var inlineCodeTextColor: UIColor?
    /// 行内代码背景色。nil 时沿用 codeBlockBackgroundColor 或不绘制背景。
    public var inlineCodeBackgroundColor: UIColor?
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
    public var listFirstLineHeadIndent: CGFloat
    public var listHeadIndent: CGFloat
    public var listMarkerWidth: CGFloat
    public var listMarkerColor: UIColor?
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
    /// 分隔线高度
    public var dividerHeight: CGFloat
    /// 分隔线颜色
    public var dividerColor: UIColor?
    /// 引用块左侧竖线宽度
    public var blockquoteLineWidth: CGFloat
    /// 引用块内容与竖线的间距
    public var blockquoteIndentation: CGFloat
    /// 引用块竖线颜色
    public var blockquoteLineColor: UIColor?
    /// 引用块背景色
    public var blockquoteBackgroundColor: UIColor?
    /// 引用块圆角半径
    public var blockquoteCornerRadius: CGFloat
    /// 渲染宽度，0 表示使用默认宽度
    public var renderWidth: CGFloat
    /// 渲染缩放因子，0 表示自动检测
    public var displayScale: CGFloat
    /// Citation 角标圆圈背景色（nil 时使用 systemBlue）
    public var citationBadgeBgColor: UIColor?
    /// Citation 角标数字文本色（nil 时使用 white）
    public var citationBadgeTextColor: UIColor?
    /// 代码块头部高度（0 表示根据字体自动计算）
    public var codeBlockHeaderHeight: CGFloat
    /// 代码块头部与正文之间的间距
    public var codeBlockSeparatorSpacing: CGFloat
    /// 代码块按钮行预留宽度
    public var codeBlockButtonRowReservedWidth: CGFloat

    public init(
        font: UIFont,
        boldFont: UIFont? = nil,
        boldTextColor: UIColor? = nil,
        textColor: UIColor,
        lineHeight: CGFloat,
        kern: CGFloat,
        paragraphSpacing: CGFloat = 8,
        bodyLineSpacing: CGFloat = 2,
        bodyTextInsets: UIEdgeInsets = .zero,
        headingTextColor: UIColor? = nil,
        headingKern: CGFloat? = nil,
        headingFontProvider: (@Sendable (Int) -> UIFont)? = nil,
        linkColor: UIColor? = nil,
        inlineCodeTextColor: UIColor? = nil,
        inlineCodeBackgroundColor: UIColor? = nil,
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
        listFirstLineHeadIndent: CGFloat = 12,
        listHeadIndent: CGFloat = 24,
        listMarkerWidth: CGFloat = 18,
        listMarkerColor: UIColor? = nil,
        headingLineHeightMultiplier: CGFloat = 1.25,
        blockSpacing: CGFloat = 16,
        headingTopSpacing: [CGFloat]? = nil,
        headingBottomSpacing: [CGFloat]? = nil,
        dividerHeight: CGFloat = 1,
        dividerColor: UIColor? = nil,
        blockquoteLineWidth: CGFloat = 3,
        blockquoteIndentation: CGFloat = 12,
        blockquoteLineColor: UIColor? = nil,
        blockquoteBackgroundColor: UIColor? = nil,
        blockquoteCornerRadius: CGFloat = 10,
        renderWidth: CGFloat = 0,
        displayScale: CGFloat = 0,
        citationBadgeBgColor: UIColor? = nil,
        citationBadgeTextColor: UIColor? = nil,
        codeBlockHeaderHeight: CGFloat = 0,
        codeBlockSeparatorSpacing: CGFloat = 8,
        codeBlockButtonRowReservedWidth: CGFloat = 120
    ) {
        self.font = font
        self.boldFont = boldFont
        self.boldTextColor = boldTextColor
        self.textColor = textColor
        self.lineHeight = lineHeight
        self.kern = kern
        self.paragraphSpacing = paragraphSpacing
        self.bodyLineSpacing = bodyLineSpacing
        self.bodyTextInsets = bodyTextInsets
        self.headingTextColor = headingTextColor
        self.headingKern = headingKern
        self.headingFontProvider = headingFontProvider
        self.linkColor = linkColor
        self.inlineCodeTextColor = inlineCodeTextColor
        self.inlineCodeBackgroundColor = inlineCodeBackgroundColor
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
        self.listFirstLineHeadIndent = listFirstLineHeadIndent
        self.listHeadIndent = listHeadIndent
        self.listMarkerWidth = listMarkerWidth
        self.listMarkerColor = listMarkerColor
        self.headingLineHeightMultiplier = headingLineHeightMultiplier
        self.blockSpacing = blockSpacing
        self.headingTopSpacing = headingTopSpacing
        self.headingBottomSpacing = headingBottomSpacing
        self.dividerHeight = dividerHeight
        self.dividerColor = dividerColor
        self.blockquoteLineWidth = blockquoteLineWidth
        self.blockquoteIndentation = blockquoteIndentation
        self.blockquoteLineColor = blockquoteLineColor
        self.blockquoteBackgroundColor = blockquoteBackgroundColor
        self.blockquoteCornerRadius = blockquoteCornerRadius
        self.renderWidth = renderWidth
        self.displayScale = displayScale
        self.citationBadgeBgColor = citationBadgeBgColor
        self.citationBadgeTextColor = citationBadgeTextColor
        self.codeBlockHeaderHeight = codeBlockHeaderHeight
        self.codeBlockSeparatorSpacing = codeBlockSeparatorSpacing
        self.codeBlockButtonRowReservedWidth = codeBlockButtonRowReservedWidth
    }

    public static let `default` = STMarkdownStyle(
        font: .st_systemFont(ofSize: 16, weight: .regular),
        textColor: .label,
        lineHeight: 24,
        kern: 0.12
    )

    public var resolvedDisplayScale: CGFloat {
        if self.displayScale > 0 { return self.displayScale }
        // iOS 13+ 起优先使用当前 trait 环境，避免 multi-scene 下 `UIScreen.main` 结果失真。
        if #available(iOS 13.0, *) {
            let scale = UITraitCollection.current.displayScale
            if scale > 0 { return scale }
        }
        return UIScreen.main.scale
    }
}

public enum STMarkdownFontResolver {
    /// `UIFont.Weight` rawValue 在相邻级别间相差约 0.23。
    /// 这里留一个较保守的阈值，用于判断 `withSymbolicTraits(.traitBold)` 是否实际让字重上升；
    /// 若升幅不足，则走 `systemFont(weight: .bold)` 兜底以避免 "regular→semibold" 的降级误判。
    private static let boldWeightBumpThreshold: CGFloat = 0.1

    /// 开启斜体失败时使用的几何倾斜（obliqueness）兜底值，经验值 0.16 接近大多数西文字体斜体角度。
    private static let fallbackObliqueness: CGFloat = 0.16

    private static func fontWeight(of font: UIFont) -> CGFloat {
        let traits = font.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
        if let weight = traits?[.weight] as? CGFloat {
            return weight
        }
        if let weight = traits?[.weight] as? NSNumber {
            return CGFloat(truncating: weight)
        }
        return UIFont.Weight.regular.rawValue
    }

    public static func italicFont(from font: UIFont) -> UIFont {
        if let descriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic) {
            let resolved = UIFont(descriptor: descriptor, size: font.pointSize)
            if resolved.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                return resolved
            }
        }
        return font
    }

    public static func boldFont(from font: UIFont) -> UIFont {
        if let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) {
            let resolved = UIFont(descriptor: descriptor, size: font.pointSize)
            let baseWeight = fontWeight(of: font)
            let resolvedWeight = fontWeight(of: resolved)
            if resolved.fontDescriptor.symbolicTraits.contains(.traitBold),
               resolvedWeight > baseWeight + boldWeightBumpThreshold {
                return resolved
            }
        }
        return .st_systemFont(ofSize: font.pointSize, weight: .bold)
    }

    public static func boldItalicFont(from font: UIFont) -> UIFont {
        let traits: UIFontDescriptor.SymbolicTraits = [.traitBold, .traitItalic]
        if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
            let resolved = UIFont(descriptor: descriptor, size: font.pointSize)
            let resolvedTraits = resolved.fontDescriptor.symbolicTraits
            if resolvedTraits.contains(.traitBold), resolvedTraits.contains(.traitItalic) {
                return resolved
            }
        }
        return boldFont(from: italicFont(from: font))
    }

    public static func italicObliqueness(from font: UIFont) -> CGFloat? {
        let italic = italicFont(from: font)
        // 若能真实拿到斜体字形，则无需倾斜模拟。
        guard !italic.fontDescriptor.symbolicTraits.contains(.traitItalic) else {
            return nil
        }
        return fallbackObliqueness
    }

    public static func boldItalicObliqueness(from font: UIFont) -> CGFloat? {
        let boldItalic = boldItalicFont(from: font)
        // 若能真实拿到粗斜体字形，则无需倾斜模拟。
        guard !boldItalic.fontDescriptor.symbolicTraits.contains(.traitItalic) else {
            return nil
        }
        return fallbackObliqueness
    }
}
