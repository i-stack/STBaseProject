//
//  STMarkdownPreset.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public enum STMarkdownPresets {
    public static let `default` = STMarkdownStyle.default

    /// 构造一组默认的高级渲染器实例。
    ///
    /// 高级渲染器（图片、表格、代码块等）通常持有内部缓存或可变状态，因此
    /// **每个调用方应单独持有自己的实例**，避免跨场景共享导致的并发污染。
    /// 故采用工厂方法返回新实例，禁止使用全局单例。
    public static func makeDefaultAdvancedRenderers() -> STMarkdownAdvancedRenderers {
        STMarkdownAdvancedRenderers(
            inlineMathRenderer: STMarkdownHighFidelityMathRenderer(),
            blockMathRenderer: STMarkdownHighFidelityMathRenderer(),
            codeBlockRenderer: STMarkdownCodeBlockRenderer(),
            tableRenderer: STMarkdownTableAttachmentRenderer(),
            imageRenderer: STMarkdownAsyncImageRenderer(),
            horizontalRuleRenderer: STMarkdownDefaultHorizontalRuleRenderer()
        )
    }

    @available(*, deprecated, message: "Use makeDefaultAdvancedRenderers() to avoid sharing renderer instances.")
    public static var defaultAdvancedRenderers: STMarkdownAdvancedRenderers {
        self.makeDefaultAdvancedRenderers()
    }

    public static let article = STMarkdownStyle(
        font: .st_systemFont(ofSize: 17, weight: .regular),
        textColor: .label,
        lineHeight: 26,
        kern: 0.1,
        paragraphSpacing: 10,
        bodyLineSpacing: 3,
        headingTextColor: .label,
        linkColor: .systemBlue,
        inlineCodeTextColor: .secondaryLabel,
        codeBlockTextColor: .label,
        codeBlockHeaderTextColor: .secondaryLabel,
        codeBlockBackgroundColor: UIColor.secondarySystemBackground,
        tableTextColor: .label,
        tableHeaderTextColor: .label,
        tableBorderColor: UIColor.separator,
        tableBackgroundColor: UIColor.secondarySystemBackground,
        imagePlaceholderTextColor: .label,
        imagePlaceholderBackgroundColor: UIColor.tertiarySystemBackground,
        imagePlaceholderCaptionColor: .secondaryLabel,
        horizontalRuleColor: UIColor.separator,
        horizontalRuleLength: 24,
        listItemSpacing: 10,
        listIndentPerLevel: 16,
        headingLineHeightMultiplier: 1.25
    )

    public static let compact = STMarkdownStyle(
        font: .st_systemFont(ofSize: 14, weight: .regular),
        textColor: .label,
        lineHeight: 20,
        kern: 0.08,
        paragraphSpacing: 6,
        bodyLineSpacing: 1,
        headingTextColor: .label,
        linkColor: .systemBlue,
        inlineCodeTextColor: .secondaryLabel,
        codeBlockTextColor: .label,
        codeBlockHeaderTextColor: .secondaryLabel,
        codeBlockBackgroundColor: UIColor.secondarySystemBackground,
        tableTextColor: .label,
        tableHeaderTextColor: .label,
        tableBorderColor: UIColor.separator,
        tableBackgroundColor: UIColor.secondarySystemBackground,
        imagePlaceholderTextColor: .label,
        imagePlaceholderBackgroundColor: UIColor.tertiarySystemBackground,
        imagePlaceholderCaptionColor: .secondaryLabel,
        horizontalRuleColor: UIColor.separator,
        horizontalRuleLength: 18,
        listItemSpacing: 6,
        listIndentPerLevel: 12,
        headingLineHeightMultiplier: 1.18
    )
}
