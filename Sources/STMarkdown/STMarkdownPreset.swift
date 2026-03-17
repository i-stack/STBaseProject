//
//  STMarkdownPreset.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public enum STMarkdownPresets {
    public static let `default` = STMarkdownStyle.default
    public static let defaultAdvancedRenderers = STMarkdownAdvancedRenderers(
        inlineMathRenderer: STMarkdownHighFidelityMathRenderer(),
        blockMathRenderer: STMarkdownHighFidelityMathRenderer(),
        codeBlockRenderer: STMarkdownCodeBlockAttachmentRenderer(),
        tableRenderer: STMarkdownTableAttachmentRenderer(),
        imageRenderer: STMarkdownAsyncImageRenderer(),
        horizontalRuleRenderer: STMarkdownDefaultHorizontalRuleRenderer()
    )

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
