//
//  STMarkdownCodeBlockRenderingPresets.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

/// 代码块渲染策略命名空间。
///
/// 历史上工程里同时存在三个 `STMarkdownCodeBlockRendering` 实现，命名互相错位：
///   - `STMarkdownDefaultCodeBlockRenderer`：纯文本（NSAttributedString）展示，最便宜；
///   - `STMarkdownCodeBlockAttachmentRenderer`：把代码段绘成 `UIImage` 并包成 `NSTextAttachment`，
///     无折叠、无语法高亮；
///   - `STMarkdownCodeBlockRenderer`（位于 `STMarkdownCodeBlockSupport.swift`）：
///     带缓存、语法高亮、折叠 + 渐隐的 attachment 实现。
///
/// 该枚举不引入运行期开销，仅作为"建议入口"的 facade，让调用方根据需求查阅 typealias 而不是
/// 在三个相似名称之间纠结。后续若要做 API 重命名/废弃，可从这里集中导出。
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
}
