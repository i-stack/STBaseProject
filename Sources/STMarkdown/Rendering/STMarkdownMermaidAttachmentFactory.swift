//
//  STMarkdownMermaidAttachmentFactory.swift
//  STBaseProject
//

import UIKit

/// Mermaid 图表 `NSAttributedString` attachment 工厂。
///
/// 将渲染完成的 `UIImage` 或"加载中"占位图包装为适合嵌入 `UITextView` 的
/// `NSTextAttachment`，宽度自动等比缩放至 `renderWidth`。
///
/// 与 `STMarkdownMermaidRenderer` 解耦：工厂只负责包装，不负责触发异步渲染。
public enum STMarkdownMermaidAttachmentFactory {

    /// 将渲染完成的 Mermaid 图片包装为内嵌 attachment，宽度等比缩放至 `renderWidth`。
    public static func imageAttachment(
        _ image: UIImage,
        renderWidth: CGFloat
    ) -> NSAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = image
        let scale = image.size.width > 0 ? renderWidth / image.size.width : 1.0
        attachment.bounds = CGRect(
            origin: .zero,
            size: CGSize(width: renderWidth, height: image.size.height * scale)
        )
        return NSAttributedString(attachment: attachment)
    }

    /// 生成圆角背景 + 居中文字的"加载中"占位 attachment，高度固定 100pt。
    ///
    /// - Parameters:
    ///   - width: 占位块宽度（等于 `renderWidth`）
    ///   - style: 当前 Markdown 样式（取 `codeBlockBackgroundColor` 和 `codeBlockCornerRadius`）
    ///   - loadingText: 占位文字，默认 `"Loading diagram..."`
    public static func placeholderAttachment(
        width: CGFloat,
        style: STMarkdownStyle,
        loadingText: String = "Loading diagram..."
    ) -> NSAttributedString {
        let height: CGFloat = 100
        let bgColor = style.codeBlockBackgroundColor ?? UIColor.secondarySystemBackground
        let cornerRadius = style.codeBlockCornerRadius
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let image = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        ).image { _ in
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).fill()
            bgColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).fill()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.secondaryLabel,
            ]
            let textSize = (loadingText as NSString).size(withAttributes: attrs)
            let textOrigin = CGPoint(
                x: (width - textSize.width) / 2,
                y: (height - textSize.height) / 2
            )
            (loadingText as NSString).draw(at: textOrigin, withAttributes: attrs)
        }
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        return NSAttributedString(attachment: attachment)
    }
}
