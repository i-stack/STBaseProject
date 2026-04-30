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
    public var isTextSelectionEnabled: Bool
    public var onLinkTap: ((URL) -> Void)?
    public var onSelectionChange: ((String) -> Void)?
    public var onCitationTap: ((String) -> Void)?

    public init(
        markdown: String,
        style: STMarkdownStyle = .default,
        advancedRenderers: STMarkdownAdvancedRenderers = .empty,
        engine: STMarkdownEngine = STMarkdownEngine(),
        isTextSelectionEnabled: Bool = true,
        onLinkTap: ((URL) -> Void)? = nil,
        onSelectionChange: ((String) -> Void)? = nil,
        onCitationTap: ((String) -> Void)? = nil
    ) {
        self.markdown = markdown
        self.style = style
        self.advancedRenderers = advancedRenderers
        self.engine = engine
        self.isTextSelectionEnabled = isTextSelectionEnabled
        self.onLinkTap = onLinkTap
        self.onSelectionChange = onSelectionChange
        self.onCitationTap = onCitationTap
    }

    public func makeUIView(context: Context) -> STMarkdownTextView {
        let view = STMarkdownTextView(
            style: self.style,
            advancedRenderers: self.advancedRenderers,
            engine: self.engine
        )
        self.applyCallbacks(to: view)
        view.isTextSelectionEnabled = self.isTextSelectionEnabled
        view.setMarkdown(self.markdown)
        context.coordinator.lastMarkdown = self.markdown
        context.coordinator.lastEngine = ObjectIdentifier(self.engine)
        return view
    }

    public func updateUIView(_ uiView: STMarkdownTextView, context: Context) {
        self.applyCallbacks(to: uiView)
        if uiView.isTextSelectionEnabled != self.isTextSelectionEnabled {
            uiView.isTextSelectionEnabled = self.isTextSelectionEnabled
        }
        let markdownChanged = context.coordinator.lastMarkdown != self.markdown
        let engineChanged = context.coordinator.lastEngine != ObjectIdentifier(self.engine)
        // style / advancedRenderers 是无 Equatable 的 struct，无法廉价 diff；只要这两项
        // 在父视图重建时没换实例，就不触发重渲染。典型 SwiftUI 场景下父组件会把它们以
        // 常量传入，短路 markdown 未变化即可消除大部分无效 render。
        guard markdownChanged || engineChanged else { return }
        if engineChanged {
            uiView.applyConfiguration(
                markdown: self.markdown,
                style: self.style,
                advancedRenderers: self.advancedRenderers,
                engine: self.engine
            )
        } else {
            uiView.setMarkdown(self.markdown)
        }
        context.coordinator.lastMarkdown = self.markdown
        context.coordinator.lastEngine = ObjectIdentifier(self.engine)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public final class Coordinator {
        var lastMarkdown: String?
        var lastEngine: ObjectIdentifier?
    }

    private func applyCallbacks(to view: STMarkdownTextView) {
        view.onLinkTap = self.onLinkTap
        view.onSelectionChange = self.onSelectionChange
        view.onCitationTap = self.onCitationTap
    }
}

/// 外部驱动流式视图命令的令牌。递增 `tick` 即触发对应动作；适配 SwiftUI @State 的值语义。
public struct STMarkdownStreamingCommand: Equatable {
    public enum Action: Equatable { case finish, reset }
    public var action: Action
    public var tick: Int

    public init(action: Action = .finish, tick: Int = 0) {
        self.action = action
        self.tick = tick
    }
}

/// SwiftUI 包装：流式 Markdown 渲染视图（支持增量追加动画）
public struct STMarkdownStreamingSwiftUIView: UIViewRepresentable {
    public let markdown: String
    public var style: STMarkdownStyle
    public var advancedRenderers: STMarkdownAdvancedRenderers
    public var engine: STMarkdownEngine
    public var animated: Bool
    public var isTextSelectionEnabled: Bool
    public var suppressSystemTextMenu: Bool
    public var animateAcrossNewlines: Bool
    public var tokenFadeDuration: TimeInterval?
    public var command: STMarkdownStreamingCommand?
    public var onLinkTap: ((URL) -> Void)?
    public var onSelectionChange: ((String) -> Void)?
    public var onCitationTap: ((String) -> Void)?

    public init(
        markdown: String,
        style: STMarkdownStyle = .default,
        advancedRenderers: STMarkdownAdvancedRenderers = .empty,
        engine: STMarkdownEngine = STMarkdownEngine(),
        animated: Bool = true,
        isTextSelectionEnabled: Bool = true,
        suppressSystemTextMenu: Bool = false,
        animateAcrossNewlines: Bool = false,
        tokenFadeDuration: TimeInterval? = nil,
        command: STMarkdownStreamingCommand? = nil,
        onLinkTap: ((URL) -> Void)? = nil,
        onSelectionChange: ((String) -> Void)? = nil,
        onCitationTap: ((String) -> Void)? = nil
    ) {
        self.markdown = markdown
        self.style = style
        self.advancedRenderers = advancedRenderers
        self.engine = engine
        self.animated = animated
        self.isTextSelectionEnabled = isTextSelectionEnabled
        self.suppressSystemTextMenu = suppressSystemTextMenu
        self.animateAcrossNewlines = animateAcrossNewlines
        self.tokenFadeDuration = tokenFadeDuration
        self.command = command
        self.onLinkTap = onLinkTap
        self.onSelectionChange = onSelectionChange
        self.onCitationTap = onCitationTap
    }

    public func makeUIView(context: Context) -> STMarkdownStreamingTextView {
        let view = STMarkdownStreamingTextView(
            style: self.style,
            advancedRenderers: self.advancedRenderers,
            engine: self.engine
        )
        self.applyCallbacks(to: view)
        self.applyToggles(to: view)
        view.setMarkdown(self.markdown, animated: self.animated)
        context.coordinator.lastMarkdown = self.markdown
        context.coordinator.lastEngine = ObjectIdentifier(self.engine)
        context.coordinator.lastCommand = self.command
        return view
    }

    public func updateUIView(_ uiView: STMarkdownStreamingTextView, context: Context) {
        self.applyCallbacks(to: uiView)
        self.applyToggles(to: uiView)
        let markdownChanged = context.coordinator.lastMarkdown != self.markdown
        let engineChanged = context.coordinator.lastEngine != ObjectIdentifier(self.engine)
        if markdownChanged || engineChanged {
            if engineChanged {
                // 配置变化走静态路径（animated: false），避免把配置切换误识别为增量 token 动画。
                uiView.applyConfiguration(
                    markdown: self.markdown,
                    style: self.style,
                    advancedRenderers: self.advancedRenderers,
                    engine: self.engine,
                    animated: false
                )
            } else {
                uiView.setMarkdown(self.markdown, animated: self.animated)
            }
            context.coordinator.lastMarkdown = self.markdown
            context.coordinator.lastEngine = ObjectIdentifier(self.engine)
        }
        self.dispatchCommandIfNeeded(uiView: uiView, coordinator: context.coordinator)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public final class Coordinator {
        var lastMarkdown: String?
        var lastEngine: ObjectIdentifier?
        var lastCommand: STMarkdownStreamingCommand?
    }

    private func applyCallbacks(to view: STMarkdownStreamingTextView) {
        view.onLinkTap = self.onLinkTap
        view.onSelectionChange = self.onSelectionChange
        view.onCitationTap = self.onCitationTap
    }

    private func applyToggles(to view: STMarkdownStreamingTextView) {
        if view.isTextSelectionEnabled != self.isTextSelectionEnabled {
            view.isTextSelectionEnabled = self.isTextSelectionEnabled
        }
        if view.suppressSystemTextMenu != self.suppressSystemTextMenu {
            view.suppressSystemTextMenu = self.suppressSystemTextMenu
        }
        if view.animateAcrossNewlines != self.animateAcrossNewlines {
            view.animateAcrossNewlines = self.animateAcrossNewlines
        }
        if let duration = self.tokenFadeDuration, view.tokenFadeDuration != duration {
            view.tokenFadeDuration = duration
        }
    }

    private func dispatchCommandIfNeeded(uiView: STMarkdownStreamingTextView, coordinator: Coordinator) {
        guard let command = self.command, command != coordinator.lastCommand else { return }
        coordinator.lastCommand = command
        switch command.action {
        case .finish:
            uiView.finishStreaming()
        case .reset:
            uiView.reset()
        }
    }
}
