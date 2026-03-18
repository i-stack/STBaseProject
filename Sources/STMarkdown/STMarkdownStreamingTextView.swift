//
//  STMarkdownStreamingTextView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public final class STMarkdownStreamingTextView: UIView, STMarkdownInteractable {

    public var markdownStyle: STMarkdownStyle {
        didSet {
            self.textView.font = self.markdownStyle.font
            self.textView.textColor = self.markdownStyle.textColor
            self.renderer = STMarkdownAttributedStringRenderer(
                style: self.markdownStyle,
                advancedRenderers: self.advancedRenderers
            )
            if self.rawMarkdown.isEmpty == false {
                self.setMarkdown(self.rawMarkdown, animated: false)
            }
        }
    }

    public var advancedRenderers: STMarkdownAdvancedRenderers {
        didSet {
            self.renderer = STMarkdownAttributedStringRenderer(
                style: self.markdownStyle,
                advancedRenderers: self.advancedRenderers
            )
            if self.rawMarkdown.isEmpty == false {
                self.setMarkdown(self.rawMarkdown, animated: false)
            }
        }
    }

    public var tokenFadeDuration: TimeInterval {
        get { self.textView.tokenFadeDuration }
        set { self.textView.tokenFadeDuration = newValue }
    }

    /// 自定义文档渲染闭包：若设置，则 render 时使用此闭包代替默认的 STMarkdownAttributedStringRenderer，
    /// 使流式渲染和 AST 最终渲染使用同一套样式，避免流式结束切换时出现样式跳变。
    public var customDocumentRenderer: ((STMarkdownRenderDocument) -> NSAttributedString)?

    public var engine: STMarkdownEngine
    public var onLinkTap: ((URL) -> Void)?
    public var onSelectionChange: ((String) -> Void)?

    public var isTextSelectionEnabled: Bool {
        get { self.textView.isSelectable }
        set { self.textView.isSelectable = newValue }
    }

    public var suppressSystemTextMenu: Bool {
        get { self.textView.suppressSystemTextMenu }
        set { self.textView.suppressSystemTextMenu = newValue }
    }

    public private(set) var rawMarkdown: String = ""

    public var attributedText: NSAttributedString {
        self.textView.renderedAttributedText
    }

    public var contentTextView: UITextView {
        self.textView
    }

    private var renderer: STMarkdownAttributedStringRenderer
    private let textView: STShimmerTextView = {
        if #available(iOS 16.0, *) {
            return STShimmerTextView(usingTextLayoutManager: false)
        }
        return STShimmerTextView()
    }()

    public override init(frame: CGRect) {
        let style = STMarkdownStyle.default
        self.markdownStyle = style
        self.advancedRenderers = .empty
        self.engine = STMarkdownEngine()
        self.renderer = STMarkdownAttributedStringRenderer(style: style, advancedRenderers: .empty)
        super.init(frame: frame)
        self.setup()
    }

    public convenience init(
        style: STMarkdownStyle = .default,
        advancedRenderers: STMarkdownAdvancedRenderers = .empty,
        engine: STMarkdownEngine = STMarkdownEngine()
    ) {
        self.init(frame: .zero)
        self.markdownStyle = style
        self.advancedRenderers = advancedRenderers
        self.engine = engine
        self.renderer = STMarkdownAttributedStringRenderer(style: style, advancedRenderers: advancedRenderers)
        self.textView.font = style.font
        self.textView.textColor = style.textColor
    }

    public required init?(coder: NSCoder) {
        let style = STMarkdownStyle.default
        self.markdownStyle = style
        self.advancedRenderers = .empty
        self.engine = STMarkdownEngine()
        self.renderer = STMarkdownAttributedStringRenderer(style: style, advancedRenderers: .empty)
        super.init(coder: coder)
        self.setup()
    }

    public override var intrinsicContentSize: CGSize {
        let fitting = self.textView.sizeThatFits(
            CGSize(width: self.bounds.width > 0 ? self.bounds.width : (self.window?.bounds.width ?? UIView.layoutFittingExpandedSize.width), height: .greatestFiniteMagnitude)
        )
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(fitting.height))
    }

    /// 直接委托给内部 UITextView 的 sizeThatFits，使调用方能在 UIKit layout pass 执行前
    /// 即可拿到基于 TextKit LayoutManager 的真实文字高度，而非陈旧的 bounds.size。
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.textView.sizeThatFits(size)
    }

    public func reset() {
        self.rawMarkdown = ""
        self.textView.reset()
        self.invalidateIntrinsicContentSize()
    }

    public func finishStreaming() {
        self.textView.finishAnimations()
    }

    public func setMarkdown(_ markdown: String, animated: Bool = false) {
        let rendered = self.render(markdown)
        guard animated, !self.rawMarkdown.isEmpty else {
            // 非动画模式或首次渲染：全量替换
            self.rawMarkdown = markdown
            self.textView.setRenderedAttributedText(rendered)
            self.textView.accessibilityValue = self.textView.renderedAttributedText.string
            self.bindAttachmentRefreshHandlers(in: self.textView.renderedAttributedText)
            self.invalidateIntrinsicContentSize()
            return
        }

        let current = self.textView.renderedAttributedText
        let currentStr = current.string
        let renderedStr = rendered.string

        // 路径 1：纯追加 — rendered 的字符串前缀与 current 完全一致
        if renderedStr.count >= currentStr.count,
           (renderedStr as NSString).hasPrefix(currentStr) {
            let deltaLen = rendered.length - current.length
            // 检测公共前缀部分的属性是否变化（如表格 attachment 图片更新）
            let prefixChanged: Bool = {
                guard current.length > 0 else { return false }
                let prefixRange = NSRange(location: 0, length: current.length)
                let renderedPrefix = rendered.attributedSubstring(from: prefixRange)
                return !renderedPrefix.isEqual(to: current)
            }()
            if prefixChanged {
                // 公共前缀的属性已变（表格 attachment 更新等）：全量替换
                self.rawMarkdown = markdown
                self.textView.setRenderedAttributedText(rendered)
                self.bindAttachmentRefreshHandlers(in: self.textView.renderedAttributedText)
                self.invalidateIntrinsicContentSize()
            } else if deltaLen > 0 {
                let delta = rendered.attributedSubstring(
                    from: NSRange(location: current.length, length: deltaLen)
                )
                self.rawMarkdown = markdown
                self.textView.appendAttributedText(delta, animated: true)
                self.bindAttachmentRefreshHandlers(in: self.textView.renderedAttributedText)
                self.invalidateIntrinsicContentSize()
            } else {
                self.rawMarkdown = markdown
            }
            self.textView.accessibilityValue = self.textView.renderedAttributedText.string
            return
        }

        // 路径 2：字符串公共前缀 + 尾部替换（带 stagger 动画）
        let commonLen = currentStr.commonPrefix(with: renderedStr).utf16.count
        if commonLen > 0 {
            // 检测公共前缀部分的属性是否变化（如表格 attachment 更新）
            let commonPrefixChanged: Bool = {
                guard commonLen > 0 else { return false }
                let currentPrefix = current.attributedSubstring(from: NSRange(location: 0, length: commonLen))
                let renderedCommon = rendered.attributedSubstring(from: NSRange(location: 0, length: commonLen))
                return !renderedCommon.isEqual(to: currentPrefix)
            }()
            if commonPrefixChanged {
                // 公共前缀属性已变：全量替换
                self.rawMarkdown = markdown
                self.textView.setRenderedAttributedText(rendered)
            } else {
                let trailing = rendered.attributedSubstring(
                    from: NSRange(location: commonLen, length: rendered.length - commonLen)
                )
                self.rawMarkdown = markdown
                self.textView.replaceTrailingAttributedText(from: commonLen, with: trailing)
            }
            self.textView.accessibilityValue = self.textView.renderedAttributedText.string
            self.bindAttachmentRefreshHandlers(in: self.textView.renderedAttributedText)
            self.invalidateIntrinsicContentSize()
            return
        }

        // 路径 3：完全无公共前缀（极端情况）— 全量替换
        self.rawMarkdown = markdown
        self.textView.setRenderedAttributedText(rendered)
        self.textView.accessibilityValue = self.textView.renderedAttributedText.string
        self.bindAttachmentRefreshHandlers(in: self.textView.renderedAttributedText)
        self.invalidateIntrinsicContentSize()
    }

    public func appendMarkdownFragment(_ fragment: String, animated: Bool = true) {
        guard fragment.isEmpty == false else { return }
        self.setMarkdown(self.rawMarkdown + fragment, animated: animated)
    }

    public func updateStreamingMarkdown(_ fullMarkdown: String) {
        self.setMarkdown(fullMarkdown, animated: true)
    }

    private func setup() {
        self.backgroundColor = .clear
        self.isAccessibilityElement = false
        self.textView.font = self.markdownStyle.font
        self.textView.textColor = self.markdownStyle.textColor
        self.textView.accessibilityTraits = [.staticText, .updatesFrequently]
        self.textView.delegate = self
        self.addSubview(self.textView)
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.textView.topAnchor.constraint(equalTo: self.topAnchor),
            self.textView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.textView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.textView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }

    private func render(_ markdown: String) -> NSAttributedString {
        let result = self.engine.process(markdown)
        if let customRenderer = self.customDocumentRenderer {
            return customRenderer(result.renderDocument)
        }
        return self.renderer.render(document: result.renderDocument)
    }
}

private extension STMarkdownStreamingTextView {
    @MainActor
    func refreshRenderedAttachments() {
        let range = NSRange(location: 0, length: self.textView.renderedAttributedText.length)
        guard range.length > 0 else { return }
        self.textView.layoutManager.invalidateDisplay(forCharacterRange: range)
        self.textView.layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
        self.textView.setNeedsLayout()
        self.textView.layoutIfNeeded()
        self.invalidateIntrinsicContentSize()
    }

    func bindAttachmentRefreshHandlers(in attributedText: NSAttributedString) {
        STMarkdownAttachmentRefreshSupport.bindRefreshHandlers(in: attributedText) { [weak self] in
            self?.refreshRenderedAttachments()
        }
    }
}

extension STMarkdownStreamingTextView: UITextViewDelegate {
    public func textViewDidChangeSelection(_ textView: UITextView) {
        guard let range = textView.selectedTextRange else {
            self.onSelectionChange?("")
            return
        }
        self.onSelectionChange?(textView.text(in: range) ?? "")
    }

    public func textView(
        _ textView: UITextView,
        shouldInteractWith url: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        self.onLinkTap?(url)
        return false
    }
}
