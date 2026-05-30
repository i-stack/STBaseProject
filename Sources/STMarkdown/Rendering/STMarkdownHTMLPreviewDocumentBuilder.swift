//
//  STMarkdownHTMLPreviewDocumentBuilder.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/05/26.
//

import UIKit

/// HTML 片段预览文档包装器。负责将裸 HTML fragment 包裹成完整可渲染的 HTML 文档，
/// 注入背景色、文字色、monospace 样式与内容宽度约束。
/// 不含任何宿主业务逻辑（分享、导航、主题系统）。
public enum STMarkdownHTMLPreviewDocumentBuilder {
    /// 将 HTML fragment 包裹为完整 HTML 文档。
    /// - Parameters:
    ///   - fragment: 待包裹的原始 HTML 片段。
    ///   - contentWidth: 文档 body 最大宽度（px），由宿主容器尺寸决定。
    ///   - style: 提供背景色、文字色等样式参数；为 nil 时使用系统默认色。
    ///   - backgroundColorFallback: style.codeBlockBackgroundColor 为 nil 时使用的兜底背景色，默认为系统次背景色。
    public static func wrappedHTMLDocument(
        fragment: String,
        contentWidth: CGFloat,
        style: STMarkdownStyle?,
        backgroundColorFallback: UIColor = .secondarySystemBackground
    ) -> String {
        let bg = rgbString(from: style?.codeBlockBackgroundColor ?? backgroundColorFallback)
        let fg = rgbString(from: style?.codeBlockTextColor ?? style?.textColor ?? UIColor.label)
        let muted = rgbString(
            from: style?.codeBlockHeaderTextColor
                ?? (style?.textColor ?? UIColor.label).withAlphaComponent(0.72)
        )
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
          * { box-sizing: border-box; }
          html, body {
            margin: 0;
            padding: 0;
            width: 100%;
            background: \(bg);
            color: \(fg);
            font: -apple-system-body;
            -webkit-text-size-adjust: 100%;
          }
          body {
            padding: 12px;
            max-width: \(Int(contentWidth))px;
          }
          pre, code {
            font-family: ui-monospace, Menlo, monospace;
            font-size: 13px;
            white-space: pre-wrap;
            word-wrap: break-word;
          }
          a { color: \(muted); }
        </style>
        </head>
        <body>
        \(fragment)
        </body>
        </html>
        """
    }

    private static func rgbString(from color: UIColor) -> String {
        let c = color.cgColor
        guard let components = c.components, components.count >= 3 else {
            return "rgb(128,128,128)"
        }
        let r = Int((components[0] * 255).rounded())
        let g = Int((components[1] * 255).rounded())
        let b = Int((components[2] * 255).rounded())
        return "rgb(\(r),\(g),\(b))"
    }
}
