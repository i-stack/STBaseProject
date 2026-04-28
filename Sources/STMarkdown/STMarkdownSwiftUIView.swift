//
//  STMarkdownSwiftUIView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import SwiftUI

/// SwiftUI 包装：静态 Markdown 渲染视图
public struct STMarkdownSwiftUIView: UIViewRepresentable {
    public let markdown: String
    public var style: STMarkdownStyle
    public var advancedRenderers: STMarkdownAdvancedRenderers
    public var engine: STMarkdownEngine
    public var onLinkTap: ((URL) -> Void)?

    public init(
        markdown: String,
        style: STMarkdownStyle = .default,
        advancedRenderers: STMarkdownAdvancedRenderers = .empty,
        engine: STMarkdownEngine = STMarkdownEngine(),
        onLinkTap: ((URL) -> Void)? = nil
    ) {
        self.markdown = markdown
        self.style = style
        self.advancedRenderers = advancedRenderers
        self.engine = engine
        self.onLinkTap = onLinkTap
    }

    public func makeUIView(context: Context) -> STMarkdownTextView {
        let view = STMarkdownTextView(
            style: self.style,
            advancedRenderers: self.advancedRenderers,
            engine: self.engine
        )
        view.onLinkTap = self.onLinkTap
        view.setMarkdown(self.markdown)
        return view
    }

    public func updateUIView(_ uiView: STMarkdownTextView, context: Context) {
        uiView.markdownStyle = self.style
        uiView.advancedRenderers = self.advancedRenderers
        uiView.engine = self.engine
        uiView.onLinkTap = self.onLinkTap
        uiView.setMarkdown(self.markdown)
    }
}

/// SwiftUI 包装：流式 Markdown 渲染视图（支持增量追加动画）
public struct STMarkdownStreamingSwiftUIView: UIViewRepresentable {
    public let markdown: String
    public var style: STMarkdownStyle
    public var advancedRenderers: STMarkdownAdvancedRenderers
    public var engine: STMarkdownEngine
    public var animated: Bool
    public var onLinkTap: ((URL) -> Void)?

    public init(
        markdown: String,
        style: STMarkdownStyle = .default,
        advancedRenderers: STMarkdownAdvancedRenderers = .empty,
        engine: STMarkdownEngine = STMarkdownEngine(),
        animated: Bool = true,
        onLinkTap: ((URL) -> Void)? = nil
    ) {
        self.markdown = markdown
        self.style = style
        self.advancedRenderers = advancedRenderers
        self.engine = engine
        self.animated = animated
        self.onLinkTap = onLinkTap
    }

    public func makeUIView(context: Context) -> STMarkdownStreamingTextView {
        let view = STMarkdownStreamingTextView(
            style: self.style,
            advancedRenderers: self.advancedRenderers,
            engine: self.engine
        )
        view.onLinkTap = self.onLinkTap
        view.setMarkdown(self.markdown, animated: self.animated)
        return view
    }

    public func updateUIView(_ uiView: STMarkdownStreamingTextView, context: Context) {
        uiView.markdownStyle = self.style
        uiView.advancedRenderers = self.advancedRenderers
        uiView.engine = self.engine
        uiView.onLinkTap = self.onLinkTap
        uiView.setMarkdown(self.markdown, animated: self.animated)
    }
}
