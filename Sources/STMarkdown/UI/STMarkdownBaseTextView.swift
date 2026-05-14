//
//  STMarkdownBaseTextView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public class STMarkdownBaseTextView: UIView, STMarkdownInteractable {

    public var markdownStyle: STMarkdownStyle {
        didSet {
            guard self.isApplyingConfiguration == false else { return }
            self.textView.font = self.markdownStyle.font
            self.textView.textColor = self.markdownStyle.textColor
            self.rebuildRenderer()
            if self.rawMarkdown.isEmpty == false {
                self.configurationDidChangeRerender()
            }
        }
    }

    public var advancedRenderers: STMarkdownAdvancedRenderers {
        didSet {
            guard self.isApplyingConfiguration == false else { return }
            self.rebuildRenderer()
            if self.rawMarkdown.isEmpty == false {
                self.configurationDidChangeRerender()
            }
        }
    }

    public var engine: STMarkdownEngine
    public var onLinkTap: ((URL) -> Void)?
    public var onSelectionChange: ((String) -> Void)?
    /// 内容高度变化回调；相对 ``contentLayoutHeightNotificationThreshold`` 防抖，避免频繁抖动。
    ///
    /// - Note: 不影响 ``intrinsicContentSize`` 的计算与 Auto Layout  intrinsic 更新，仅控制该可选回调的触发频率。
    public var onContentLayoutHeightChange: ((CGFloat) -> Void)?
    /// 与 ``onContentLayoutHeightChange`` 搭配：高度变化小于该阈值（pt）时不触发回调。
    public var contentLayoutHeightNotificationThreshold: CGFloat = 9
    /// 已有文本但测得高度为 0 时跳过高度回调（等待后续布局 pass）。
    public var suppressTransientZeroContentLayoutHeightNotification: Bool = true
    /// 两次 ``onContentLayoutHeightChange`` 之间的最短间隔（秒）；0 表示不节流。用于 TableView Cell 流式输出时压低高度抖动频率。
    public var contentLayoutHeightNotificationMinInterval: TimeInterval = 0

    public var onCitationTap: ((String) -> Void)? {
        didSet {
            self.tableOverlayCoordinator.onCitationTap = self.onCitationTap
        }
    }

    public var isTextSelectionEnabled: Bool {
        get { self.textView.isSelectable }
        set { self.textView.isSelectable = newValue }
    }

    public var isSelectable: Bool {
        get { self.isTextSelectionEnabled }
        set { self.isTextSelectionEnabled = newValue }
    }

    public var linkTextAttributes: [NSAttributedString.Key: Any] {
        get { self.textView.linkTextAttributes }
        set { self.textView.linkTextAttributes = newValue }
    }

    public internal(set) var rawMarkdown: String = ""

    public var attributedText: NSAttributedString {
        self.currentAttributedText
    }

    public var contentTextView: UITextView {
        self.textView
    }

    public var textViewInset: UIEdgeInsets {
        get { self.textView.textContainerInset }
        set {
            self.textView.textContainerInset = newValue
            self.markTableOverlayDirty()
            self.invalidateIntrinsicContentSize()
        }
    }

    public var preferredContentWidth: CGFloat = 0 {
        didSet {
            guard self.preferredContentWidth != oldValue else { return }
            self.invalidateIntrinsicContentSize()
        }
    }

    internal let textView: UITextView
    internal var isApplyingConfiguration = false
    internal var renderer: STMarkdownAttributedStringRenderer

    /// 当前 attributedText 上所有异步 attachment 的刷新订阅。
    /// 文本被替换时需要先把旧 token 全部 `invalidate`，避免共享 attachment 的多个 TextView
    /// 在旧内容被丢弃后仍然收到回调（虽然 `[weak self]` 会让回调成为 no-op，但仍会在
    /// attachment 内保留无效 entry）。
    private var attachmentRefreshTokens: [STMarkdownRefreshObservation] = []

    private var lastLaidOutSize: CGSize = .zero
    private var lastNotifiedContentLayoutHeight: CGFloat = -1
    private var lastContentLayoutHeightNotifyUptime: TimeInterval = -1

    internal init(
        textView: UITextView,
        frame: CGRect,
        style: STMarkdownStyle,
        advancedRenderers: STMarkdownAdvancedRenderers,
        engine: STMarkdownEngine,
        accessibilityTraits: UIAccessibilityTraits
    ) {
        self.textView = textView
        self.markdownStyle = style
        self.advancedRenderers = advancedRenderers
        self.engine = engine
        self.renderer = STMarkdownAttributedStringRenderer(
            style: style,
            advancedRenderers: advancedRenderers
        )
        super.init(frame: frame)
        self.setup(accessibilityTraits: accessibilityTraits)
    }

    internal init?(
        textView: UITextView,
        coder: NSCoder,
        style: STMarkdownStyle,
        advancedRenderers: STMarkdownAdvancedRenderers,
        engine: STMarkdownEngine,
        accessibilityTraits: UIAccessibilityTraits
    ) {
        self.textView = textView
        self.markdownStyle = style
        self.advancedRenderers = advancedRenderers
        self.engine = engine
        self.renderer = STMarkdownAttributedStringRenderer(
            style: style,
            advancedRenderers: advancedRenderers
        )
        super.init(coder: coder)
        self.setup(accessibilityTraits: accessibilityTraits)
    }

    public required init?(coder: NSCoder) {
        let style = STMarkdownStyle.default
        self.textView = UITextView(usingTextLayoutManager: false)
        self.markdownStyle = style
        self.advancedRenderers = .empty
        self.engine = STMarkdownEngine()
        self.renderer = STMarkdownAttributedStringRenderer(style: style, advancedRenderers: .empty)
        super.init(coder: coder)
        self.setup(accessibilityTraits: .staticText)
    }

    public override var intrinsicContentSize: CGSize {
        let w = self.resolvedMarkdownMeasurementWidth()
        let fitting = self.textView.sizeThatFits(
            CGSize(width: w, height: .greatestFiniteMagnitude)
        )
        let h = self.resolvedTextViewContentHeight(
            width: w,
            sizeThatFitsHeight: fitting.height
        )
        return CGSize(width: UIView.noIntrinsicMetric, height: h)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.textView.sizeThatFits(size)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let sizeChanged = self.bounds.size != self.lastLaidOutSize
        self.lastLaidOutSize = self.bounds.size
        self.tableOverlayCoordinator.updateIfNeeded(
            attributedText: self.currentAttributedText,
            containerBounds: self.bounds
        )
        if sizeChanged && self.bounds.width > 0 {
            self.invalidateIntrinsicContentSize()
            self.publishContentLayoutHeightNotificationIfNeeded(force: false)
        }
    }

    public func sizeThatFitsMarkdown(width: CGFloat) -> CGSize {
        let size = self.textView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        let h = self.resolvedTextViewContentHeight(width: width, sizeThatFitsHeight: size.height)
        return CGSize(width: width, height: h)
    }

    internal var currentAttributedText: NSAttributedString {
        self.textView.attributedText ?? NSAttributedString()
    }

    internal func renderMarkdown(_ markdown: String) -> NSAttributedString {
        let result = self.engine.process(markdown)
        return self.renderer.render(document: result.renderDocument)
    }

    internal func applyConfigurationCommon(
        style: STMarkdownStyle,
        advancedRenderers: STMarkdownAdvancedRenderers,
        engine: STMarkdownEngine
    ) {
        self.isApplyingConfiguration = true
        self.markdownStyle = style
        self.advancedRenderers = advancedRenderers
        self.engine = engine
        self.isApplyingConfiguration = false
        self.textView.font = style.font
        self.textView.textColor = style.textColor
        self.rebuildRenderer()
    }

    internal func finalizeRenderUpdate(rendered: NSAttributedString) {
        self.textView.accessibilityValue = rendered.string
        self.bindAttachmentRefreshHandlers(in: rendered)
        self.markTableOverlayDirty()
        self.invalidateIntrinsicContentSize()
        self.publishContentLayoutHeightNotificationIfNeeded(force: false)
    }

    internal func publishContentLayoutHeightNotificationIfNeeded(force: Bool = false) {
        guard self.onContentLayoutHeightChange != nil else { return }
        let height = self.currentMeasuredTextViewContentHeight()
        let hasContent = !self.rawMarkdown.isEmpty || (self.textView.attributedText?.length ?? 0) > 0
        if self.suppressTransientZeroContentLayoutHeightNotification && !force && height <= 0 && hasContent {
            return
        }
        let last = self.lastNotifiedContentLayoutHeight
        guard force || last < 0 || abs(height - last) >= self.contentLayoutHeightNotificationThreshold else {
            return
        }
        if force == false,
           self.contentLayoutHeightNotificationMinInterval > 0 {
            let now = ProcessInfo.processInfo.systemUptime
            if self.lastContentLayoutHeightNotifyUptime >= 0,
               now - self.lastContentLayoutHeightNotifyUptime < self.contentLayoutHeightNotificationMinInterval {
                return
            }
        }
        self.lastNotifiedContentLayoutHeight = height
        if self.contentLayoutHeightNotificationMinInterval > 0 {
            self.lastContentLayoutHeightNotifyUptime = ProcessInfo.processInfo.systemUptime
        }
        self.onContentLayoutHeightChange?(height)
    }

    private func currentMeasuredTextViewContentHeight() -> CGFloat {
        let w = self.resolvedMarkdownMeasurementWidth()
        let fitting = self.textView.sizeThatFits(
            CGSize(width: w, height: .greatestFiniteMagnitude)
        )
        return self.resolvedTextViewContentHeight(width: w, sizeThatFitsHeight: fitting.height)
    }

    /// Cell 流式场景下 superview 尚未完成布局时，优先用 ``preferredContentWidth``，其次用自身 bounds、再 fallback 到 TextView 的几何宽度。
    internal func resolvedMarkdownMeasurementWidth() -> CGFloat {
        if self.preferredContentWidth > 0 {
            return self.preferredContentWidth
        }
        if self.bounds.width > 0 {
            return self.bounds.width
        }
        if self.textView.bounds.width > 0 {
            return self.textView.bounds.width
        }
        if self.textView.frame.width > 0 {
            return self.textView.frame.width
        }
        return self.window?.bounds.width ?? UIScreen.main.bounds.width
    }

    /// 对齐常见 Markdown 组件：在 `sizeThatFits` 暂为 0 时回退 `contentSize` / `bounds` 高度，减轻 Cell 初始 pass 的 0↔实际高度跳变。
    private func resolvedTextViewContentHeight(width: CGFloat, sizeThatFitsHeight: CGFloat) -> CGFloat {
        var h = ceil(sizeThatFitsHeight)
        let hasAttr = (self.textView.attributedText?.length ?? 0) > 0
        if h <= 0, hasAttr, width > 0 {
            let contentH = ceil(self.textView.contentSize.height)
            if contentH > 0 {
                h = contentH
            }
        }
        if h <= 0, hasAttr, self.textView.bounds.height > 0 {
            h = ceil(self.textView.bounds.height)
        }
        return h
    }

    internal func resetBaseState() {
        self.rawMarkdown = ""
        for token in self.attachmentRefreshTokens {
            token.invalidate()
        }
        self.attachmentRefreshTokens.removeAll()
        self.tableOverlayCoordinator.reset()
        self.invalidateIntrinsicContentSize()
        self.lastNotifiedContentLayoutHeight = -1
        self.lastContentLayoutHeightNotifyUptime = -1
    }

    internal func markTableOverlayDirty() {
        self.tableOverlayCoordinator.markDirty()
    }

    internal func configurationDidChangeRerender() {
    }

    private func setup(accessibilityTraits: UIAccessibilityTraits) {
        self.backgroundColor = .clear
        self.isAccessibilityElement = false
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        self.textView.isEditable = false
        self.textView.isSelectable = true
        self.textView.isScrollEnabled = false
        self.textView.backgroundColor = .clear
        self.textView.textContainerInset = .zero
        self.textView.textContainer.lineFragmentPadding = 0
        self.textView.font = self.markdownStyle.font
        self.textView.textColor = self.markdownStyle.textColor
        self.textView.accessibilityTraits = accessibilityTraits
        self.textView.delegate = self
        self.addSubview(self.textView)
        NSLayoutConstraint.activate([
            self.textView.topAnchor.constraint(equalTo: self.topAnchor),
            self.textView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.textView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.textView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }

    private func rebuildRenderer() {
        self.renderer = STMarkdownAttributedStringRenderer(
            style: self.markdownStyle,
            advancedRenderers: self.advancedRenderers
        )
    }

    @MainActor
    private func refreshRenderedAttachment(_ attachment: NSTextAttachment) {
        let content = self.currentAttributedText
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

    private func bindAttachmentRefreshHandlers(in attributedText: NSAttributedString) {
        // 先释放旧订阅，避免 TextView 在不同 attributedText 之间切换时，
        // 共享的 attachment 继续把回调派发到已被替换的内容上。
        for token in self.attachmentRefreshTokens {
            token.invalidate()
        }
        self.attachmentRefreshTokens = STMarkdownAttachmentRefreshSupport.bindRefreshHandlers(in: attributedText) { [weak self] attachment in
            self?.refreshRenderedAttachment(attachment)
        }
    }

    private lazy var tableOverlayCoordinator: STMarkdownTableOverlayCoordinator = {
        return STMarkdownTableOverlayCoordinator(textView: self.textView)
    }()
}

extension STMarkdownBaseTextView: UITextViewDelegate {
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

    @available(iOS 17.0, *)
    public func textView(
        _ textView: UITextView,
        primaryActionFor textItem: UITextItem,
        defaultAction: UIAction
    ) -> UIAction? {
        guard case let .link(url) = textItem.content else {
            return defaultAction
        }
        return UIAction { [weak self] _ in
            self?.onLinkTap?(url)
        }
    }
}
