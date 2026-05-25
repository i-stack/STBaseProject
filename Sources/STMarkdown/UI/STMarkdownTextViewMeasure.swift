//
//  STMarkdownTextViewMeasure.swift
//  STBaseProject
//

import UIKit

/// TextKit 1 `UITextView` 高度测量工具。
///
/// 使用 `layoutManager.usedRect(for:)` 计算精确内容高度，
/// 结果对齐到指定网格（`gridSize`），避免亚像素抖动。
///
/// 与视图层无耦合，可在任何需要测量 `UITextView` 高度的场景复用。
public enum STMarkdownTextViewMeasure {

    /// 测量 `UITextView` 在给定宽度下的内容高度。
    ///
    /// 内部会强制将 `textView.bounds.width` 与 `containerView.bounds.width` 对齐到
    /// `targetWidth`，触发 TextKit 重新布局后读取 `usedRect`。
    ///
    /// - Parameters:
    ///   - textView: 目标 `UITextView`（TextKit 1，`layoutManager` 非 nil）
    ///   - width: 期望的测量宽度（> 0）
    ///   - gridSize: 高度对齐网格步长（≥ 1），默认 2.0pt
    ///   - containerView: 若 `textView` 嵌套在额外容器内，传入该容器以一并设置宽度
    /// - Returns: 对齐到 `gridSize` 的最小内容高度（≥ 1pt）
    public static func measure(
        _ textView: UITextView,
        width: CGFloat,
        gridSize: CGFloat = 2.0,
        containerView: UIView? = nil
    ) -> CGFloat {
        let targetWidth = max(width, 1)

        if let containerView, abs(containerView.bounds.width - targetWidth) > 0.5 {
            containerView.bounds.size.width = targetWidth
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
        }
        if abs(textView.bounds.width - targetWidth) > 0.5 {
            textView.bounds.size.width = targetWidth
        }
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
        textView.layoutManager.ensureLayout(for: textView.textContainer)

        let usedRect = textView.layoutManager.usedRect(for: textView.textContainer)
        let fixedDescender = max(ceil(abs(textView.font?.descender ?? 0)), 2)
        let rawHeight = usedRect.height
            + textView.textContainerInset.top
            + textView.textContainerInset.bottom
            + fixedDescender

        let appliedGrid = max(gridSize, 1)
        return max(ceil(rawHeight / appliedGrid) * appliedGrid, 1)
    }
}
