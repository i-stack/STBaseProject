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
            guard self.isApplyingConfiguration == false else { return }
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
            guard self.isApplyingConfiguration == false else { return }
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
    /// Citation 角标点击回调，参数为 citation 编号字符串
    public var onCitationTap: ((String) -> Void)? {
        didSet {
            self.tableOverlayCoordinator.onCitationTap = self.onCitationTap
        }
    }

    public var isTextSelectionEnabled: Bool {
        get { self.textView.isSelectable }
        set { self.textView.isSelectable = newValue }
    }

    public var suppressSystemTextMenu: Bool {
        get { self.textView.suppressSystemTextMenu }
        set { self.textView.suppressSystemTextMenu = newValue }
    }

    public var animateAcrossNewlines: Bool {
        get { self.textView.animateAcrossNewlines }
        set { self.textView.animateAcrossNewlines = newValue }
    }

    public private(set) var rawMarkdown: String = ""

    public var attributedText: NSAttributedString {
        self.textView.renderedAttributedText
    }

    public var contentTextView: UITextView {
        self.textView
    }

    private var renderer: STMarkdownAttributedStringRenderer
    private var isApplyingConfiguration = false
    private let textView: STShimmerTextView = STShimmerTextView(usingTextLayoutManager: false)
    private lazy var tableOverlayCoordinator = STMarkdownTableOverlayCoordinator(textView: self.textView)

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

    /// 外部（如 UITableViewCell 的 systemLayoutSizeFitting）在 cell 加入 window 之前
    /// 注入正确的内容宽度，确保第一次高度测量就准确。
    public var preferredContentWidth: CGFloat = 0 {
        didSet {
            guard self.preferredContentWidth != oldValue else { return }
            self.invalidateIntrinsicContentSize()
        }
    }

    private var lastLaidOutSize: CGSize = .zero

    public override var intrinsicContentSize: CGSize {
        let w: CGFloat
        if self.preferredContentWidth > 0 {
            w = self.preferredContentWidth
        } else if self.bounds.width > 0 {
            w = self.bounds.width
        } else {
            w = self.window?.bounds.width ?? UIScreen.main.bounds.width
        }
        let fitting = self.textView.sizeThatFits(CGSize(width: w, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(fitting.height))
    }

    /// 直接委托给内部 UITextView 的 sizeThatFits，使调用方能在 UIKit layout pass 执行前
    /// 即可拿到基于 TextKit LayoutManager 的真实文字高度，而非陈旧的 bounds.size。
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.textView.sizeThatFits(size)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let sizeChanged = self.bounds.size != self.lastLaidOutSize
        self.lastLaidOutSize = self.bounds.size
        self.tableOverlayCoordinator.updateIfNeeded(
            attributedText: self.textView.renderedAttributedText,
            containerBounds: self.bounds
        )
        // 宽度确定后重新计算高度，修正 systemLayoutSizeFitting 首次用 UIScreen.main.bounds.width
        // 估算的偏差，使 UITableView 以正确高度重新排版 cell。
        if sizeChanged && self.bounds.width > 0 {
            self.invalidateIntrinsicContentSize()
        }
    }

    public func reset() {
        self.rawMarkdown = ""
        self.textView.reset()
        self.tableOverlayCoordinator.reset()
        self.invalidateIntrinsicContentSize()
    }

    public func finishStreaming() {
        self.textView.finishAnimations()
    }

    public func setMarkdown(_ markdown: String, animated: Bool = false) {
        let rendered = self.render(markdown)
        guard animated, !self.rawMarkdown.isEmpty else {
            self.applyFullReplace(markdown: markdown, rendered: rendered)
            return
        }

        let current = self.textView.renderedAttributedText
        let currentStr = current.string
        let renderedStr = rendered.string

        // 路径 1：纯追加 — rendered 的字符串前缀与 current 完全一致
        if renderedStr.count >= currentStr.count,
           (renderedStr as NSString).hasPrefix(currentStr) {
            let prefixChanged = current.length > 0
                && !rendered.attributedSubstring(
                    from: NSRange(location: 0, length: current.length)
                ).isEqual(to: current)
            if prefixChanged {
                // 公共前缀的属性已变（表格 attachment 更新等）：全量替换
                self.applyFullReplace(markdown: markdown, rendered: rendered)
                return
            }
            let deltaLen = rendered.length - current.length
            if deltaLen > 0 {
                let delta = rendered.attributedSubstring(
                    from: NSRange(location: current.length, length: deltaLen)
                )
                self.applyAppendDelta(markdown: markdown, delta: delta)
            } else {
                // 字符串完全相同且属性一致，仅同步 rawMarkdown
                self.rawMarkdown = markdown
                self.textView.accessibilityValue = self.textView.renderedAttributedText.string
            }
            return
        }

        // 路径 2：字符串公共前缀 + 尾部替换（带 stagger 动画）
        let commonLen = currentStr.commonPrefix(with: renderedStr).utf16.count
        if commonLen > 0 {
            let commonPrefixChanged = !current.attributedSubstring(
                from: NSRange(location: 0, length: commonLen)
            ).isEqual(to: rendered.attributedSubstring(
                from: NSRange(location: 0, length: commonLen)
            ))
            let listMarkerInvolved = self.shouldDisableAnimationForTrailingReplacement(
                current: current,
                rendered: rendered,
                commonLength: commonLen
            )
            if commonPrefixChanged {
                // 公共前缀属性已变：仍需全量替换
                self.applyFullReplace(markdown: markdown, rendered: rendered)
            } else if listMarkerInvolved {
                // 列表结构变化：收敛到当前行起点做尾部替换，关闭动画避免旧/新 bullet 短暂共存。
                let replaceStart = self.replacementStartForListTransition(
                    currentString: currentStr,
                    commonLength: commonLen
                )
                let trailing = rendered.attributedSubstring(
                    from: NSRange(location: replaceStart, length: rendered.length - replaceStart)
                )
                self.applyTrailingReplace(
                    markdown: markdown,
                    from: replaceStart,
                    trailing: trailing,
                    animate: false
                )
            } else {
                let trailing = rendered.attributedSubstring(
                    from: NSRange(location: commonLen, length: rendered.length - commonLen)
                )
                self.applyTrailingReplace(
                    markdown: markdown,
                    from: commonLen,
                    trailing: trailing,
                    animate: true
                )
            }
            return
        }

        // 路径 3：完全无公共前缀（极端情况）— 全量替换
        self.applyFullReplace(markdown: markdown, rendered: rendered)
    }

    private func applyFullReplace(markdown: String, rendered: NSAttributedString) {
        self.rawMarkdown = markdown
        self.textView.setRenderedAttributedText(rendered)
        self.finalizeRenderUpdate()
    }

    private func applyAppendDelta(markdown: String, delta: NSAttributedString) {
        self.rawMarkdown = markdown
        self.textView.appendAttributedText(delta, animated: true)
        self.finalizeRenderUpdate()
    }

    private func applyTrailingReplace(
        markdown: String,
        from location: Int,
        trailing: NSAttributedString,
        animate: Bool
    ) {
        self.rawMarkdown = markdown
        self.textView.replaceTrailingAttributedText(
            from: location,
            with: trailing,
            animateNewPortion: animate
        )
        self.finalizeRenderUpdate()
    }

    private func finalizeRenderUpdate() {
        let rendered = self.textView.renderedAttributedText
        self.textView.accessibilityValue = rendered.string
        self.bindAttachmentRefreshHandlers(in: rendered)
        self.markTableOverlayDirty()
        self.invalidateIntrinsicContentSize()
    }

    public func applyConfiguration(
        markdown: String,
        style: STMarkdownStyle,
        advancedRenderers: STMarkdownAdvancedRenderers,
        engine: STMarkdownEngine,
        animated: Bool
    ) {
        self.isApplyingConfiguration = true
        self.markdownStyle = style
        self.advancedRenderers = advancedRenderers
        self.engine = engine
        self.isApplyingConfiguration = false
        self.textView.font = style.font
        self.textView.textColor = style.textColor
        self.renderer = STMarkdownAttributedStringRenderer(
            style: style,
            advancedRenderers: advancedRenderers
        )
        self.setMarkdown(markdown, animated: animated)
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

    private func shouldDisableAnimationForTrailingReplacement(
        current: NSAttributedString,
        rendered: NSAttributedString,
        commonLength: Int
    ) -> Bool {
        let currentSuffix = current.length > commonLength
            ? current.attributedSubstring(
                from: NSRange(location: commonLength, length: current.length - commonLength)
            ).string
            : ""
        let renderedSuffix = rendered.length > commonLength
            ? rendered.attributedSubstring(
                from: NSRange(location: commonLength, length: rendered.length - commonLength)
            ).string
            : ""

        return Self.containsRenderedListMarker(in: currentSuffix)
            || Self.containsRenderedListMarker(in: renderedSuffix)
    }

    private func replacementStartForListTransition(
        currentString: String,
        commonLength: Int
    ) -> Int {
        guard commonLength > 0 else { return 0 }
        let prefix = (currentString as NSString).substring(to: commonLength) as NSString
        let lastNewline = prefix.range(of: "\n", options: .backwards)
        guard lastNewline.location != NSNotFound else { return 0 }
        return lastNewline.location + lastNewline.length
    }

    private static func containsRenderedListMarker(in text: String) -> Bool {
        guard text.isEmpty == false else { return false }
        let range = NSRange(location: 0, length: text.utf16.count)
        return Self.unorderedListMarkerRegex.firstMatch(in: text, options: [], range: range) != nil
            || Self.orderedListMarkerRegex.firstMatch(in: text, options: [], range: range) != nil
    }

    // 匹配嵌套深度不限的有序列表标记：行首可有任意多 tab 作为缩进，随后 `<num>.\t`。
    private static let orderedListMarkerRegex = try! NSRegularExpression(
        pattern: #"(?m)^\t*\d+\.\t"#,
        options: []
    )

    // 匹配嵌套深度不限的无序列表标记：行首任意 tab 缩进 + 圆点/方块 + tab。
    private static let unorderedListMarkerRegex = try! NSRegularExpression(
        pattern: #"(?m)(?:^|\n)\t*[●▪]\t"#,
        options: []
    )
}

private extension STMarkdownStreamingTextView {
    @MainActor
    func refreshRenderedAttachment(_ attachment: NSTextAttachment) {
        let content = self.textView.renderedAttributedText
        guard content.length > 0 else { return }
        var hit: NSRange?
        content.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: content.length)
        ) { value, range, stop in
            if let candidate = value as? NSTextAttachment, candidate === attachment {
                hit = range
                stop.pointee = true
            }
        }
        guard let range = hit else { return }
        self.textView.layoutManager.invalidateDisplay(forCharacterRange: range)
        self.textView.layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
        self.invalidateIntrinsicContentSize()
    }

    func bindAttachmentRefreshHandlers(in attributedText: NSAttributedString) {
        STMarkdownAttachmentRefreshSupport.bindRefreshHandlers(in: attributedText) { [weak self] attachment in
            self?.refreshRenderedAttachment(attachment)
        }
    }

    func markTableOverlayDirty() {
        self.tableOverlayCoordinator.markDirty()
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
