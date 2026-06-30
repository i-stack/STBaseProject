//
//  STMarkdownCodeBlockRenderingPresets.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public enum STMarkdownCodeBlockRenderingPresets {
    /// 简单文本预设：等宽字体 + 头部语言名（无背景框）。性能最好，适合
    /// 流式 markdown 中初次出现的代码片段。
    public typealias PlainText = STMarkdownDefaultCodeBlockRenderer

    /// 单帧 attachment 预设：把代码绘制为 `UIImage` 嵌入文本流。无折叠/无语法高亮，
    /// 适合体量小、不需要交互的代码片段。
    public typealias StaticAttachment = STMarkdownCodeBlockAttachmentRenderer

    /// 富 attachment 预设：包含语法高亮、超长折叠 + 渐隐遮罩、按钮行预留以及全局缓存。
    /// 推荐生产环境优先使用。
    public typealias RichAttachment = STMarkdownCodeBlockRenderer

    /// highlight.js 预设：通过 JavaScriptCore + highlight.js 生成 token 着色的 `NSAttributedString`。
    /// 支持 20 种语言，结果按 `language|code` 为 key 缓存（10 MB）。
    /// 适合需要真实语法着色但不需要 attachment 图像的场景；调用方最好从后台线程触发。
    public typealias HighlightJS = STMarkdownCodeHighlighter
}
