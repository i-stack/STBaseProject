//
//  STMarkdownTextViewLinkHitTest.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/04/26.
//

import UIKit

/// TextKit 1 `UITextView` 链接命中测试工具。
///
/// 在点击位置精确命中 glyph 后读取 `.link` 属性，返回对应 `URL`。
/// 与 Markdown / 流式渲染无耦合，可在任何含超链接的 `UITextView` 场景复用。
public enum STMarkdownTextViewLinkHitTest {

    /// 在 `textView` 坐标系内的给定点命中链接，返回 `URL`；未命中返回 `nil`。
    ///
    /// - Parameters:
    ///   - textView: 目标 `UITextView`（TextKit 1）
    ///   - point: 相对于 `textView` 坐标系的点
    /// - Returns: 命中的链接 `URL`，或 `nil`
    public static func linkURL(in textView: UITextView, at point: CGPoint) -> URL? {
        guard let attributedText = textView.attributedText, attributedText.length > 0 else { return nil }

        let textContainerPoint = CGPoint(
            x: point.x - textView.textContainerInset.left - textView.textContainer.lineFragmentPadding,
            y: point.y - textView.textContainerInset.top
        )
        guard textContainerPoint.x >= 0, textContainerPoint.y >= 0 else { return nil }

        let layoutManager = textView.layoutManager
        let textContainer = textView.textContainer
        let glyphIndex = layoutManager.glyphIndex(for: textContainerPoint, in: textContainer)
        guard glyphIndex < layoutManager.numberOfGlyphs else { return nil }

        let glyphRect = layoutManager.boundingRect(
            forGlyphRange: NSRange(location: glyphIndex, length: 1),
            in: textContainer
        )
        // 给予 ±6pt 点击容差，改善小字体链接的可点击性
        guard glyphRect.insetBy(dx: -6, dy: -6).contains(textContainerPoint) else { return nil }

        let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
        guard characterIndex < attributedText.length else { return nil }

        if let url = attributedText.attribute(.link, at: characterIndex, effectiveRange: nil) as? URL {
            return url
        }
        if let urlString = attributedText.attribute(.link, at: characterIndex, effectiveRange: nil) as? String {
            return URL(string: urlString)
        }
        return nil
    }
}
