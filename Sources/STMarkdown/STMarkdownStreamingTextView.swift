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
        if animated, self.tryAppendRenderedDelta(for: markdown, rendered: rendered) {
            self.textView.accessibilityValue = self.textView.renderedAttributedText.string
            return
        }
        // 流式模式下 tryAppendRenderedDelta 失败（如 rawMarkdown 前缀不匹配），
        // 使用 replaceTrailingAttributedText 基于字符串公共前缀做局部替换 + 逐字动画，
        // 避免全量 setRenderedAttributedText 导致已显示文本闪烁。
        if animated, !self.rawMarkdown.isEmpty {
            let current = self.textView.renderedAttributedText
            let currentStr = current.string
            let renderedStr = rendered.string
            let commonPrefix = currentStr.commonPrefix(with: renderedStr)
            let commonLen = commonPrefix.utf16.count
            if commonLen > 0 {
                let trailing = rendered.attributedSubstring(
                    from: NSRange(location: commonLen, length: rendered.length - commonLen)
                )
                self.rawMarkdown = markdown
                self.textView.replaceTrailingAttributedText(from: commonLen, with: trailing)
                self.textView.accessibilityValue = self.textView.renderedAttributedText.string
                self.bindAttachmentRefreshHandlers(in: self.textView.renderedAttributedText)
                self.invalidateIntrinsicContentSize()
                return
            }
        }
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

    private func tryAppendRenderedDelta(
        for markdown: String,
        rendered: NSAttributedString
    ) -> Bool {
        guard markdown.hasPrefix(self.rawMarkdown) else { return false }

        let current = self.textView.renderedAttributedText
        if self.hasStableAttributedPrefix(current, in: rendered) {
            return self.appendRenderedDelta(markdown: markdown, current: current, rendered: rendered)
        }

        // 流式场景下，Markdown 渲染器会对「最后一个段落」随后继段落的出现而回溯修改
        // NSParagraphStyle（如 paragraphSpacingAfter）。这会导致 hasStableAttributedPrefix
        // 误判，进而触发 replaceTrailingAttributedText（无动画瞬间替换）产生视觉跳动。
        //
        // 修复：若文字内容前缀稳定（string hasPrefix 成立），则仍走追加路径，
        // 只追加 delta 部分，前缀的 paragraphStyle 差异留给 finishStreamingRender
        // 的静态 AST 渲染最终修正，流式阶段 blockSeparator 的 minimumLineHeight 已提供视觉间距。
        if rendered.length >= current.length,
           (rendered.string as NSString).hasPrefix(current.string) {
            return self.appendRenderedDelta(markdown: markdown, current: current, rendered: rendered)
        }

        let stablePrefixLength = self.longestCommonAttributedPrefixLength(current, rendered: rendered)
        guard stablePrefixLength > 0 else { return false }

        let trailingRange = NSRange(
            location: stablePrefixLength,
            length: rendered.length - stablePrefixLength
        )
        let trailing = rendered.attributedSubstring(from: trailingRange)
        self.rawMarkdown = markdown
        self.textView.replaceTrailingAttributedText(from: stablePrefixLength, with: trailing)
        self.invalidateIntrinsicContentSize()
        return true
    }

    private func appendRenderedDelta(
        markdown: String,
        current: NSAttributedString,
        rendered: NSAttributedString
    ) -> Bool {
        guard rendered.length >= current.length else { return false }

        let deltaRange = NSRange(location: current.length, length: rendered.length - current.length)
        guard deltaRange.length > 0 else {
            self.rawMarkdown = markdown
            return true
        }

        let delta = rendered.attributedSubstring(from: deltaRange)
        self.rawMarkdown = markdown
        self.textView.appendAttributedText(delta, animated: true)
        self.bindAttachmentRefreshHandlers(in: self.textView.renderedAttributedText)
        self.invalidateIntrinsicContentSize()
        return true
    }

    private func hasStableAttributedPrefix(_ current: NSAttributedString, in rendered: NSAttributedString) -> Bool {
        guard rendered.length >= current.length else { return false }
        let prefix = rendered.attributedSubstring(from: NSRange(location: 0, length: current.length))
        return current.isEqual(to: prefix)
    }

    private func longestCommonAttributedPrefixLength(
        _ current: NSAttributedString,
        rendered: NSAttributedString
    ) -> Int {
        let currentString = current.string as NSString
        let renderedString = rendered.string as NSString
        let maxLength = min(current.length, rendered.length)
        guard maxLength > 0 else { return 0 }

        var index = 0
        while index < maxLength {
            let currentCharacter = currentString.substring(with: NSRange(location: index, length: 1))
            let renderedCharacter = renderedString.substring(with: NSRange(location: index, length: 1))
            guard currentCharacter == renderedCharacter else { break }
            guard self.attributesEqual(current, rendered, at: index) else { break }
            index += 1
        }

        return index
    }

    private func attributesEqual(
        _ lhs: NSAttributedString,
        _ rhs: NSAttributedString,
        at index: Int
    ) -> Bool {
        let lhsAttributes = lhs.attributes(at: index, effectiveRange: nil) as NSDictionary
        let rhsAttributes = rhs.attributes(at: index, effectiveRange: nil) as NSDictionary
        return lhsAttributes.isEqual(to: rhsAttributes as? [AnyHashable: Any] ?? [:])
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
