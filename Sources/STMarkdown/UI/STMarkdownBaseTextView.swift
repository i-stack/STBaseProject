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

    private var lastLaidOutSize: CGSize = .zero

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
        let w: CGFloat
        if self.preferredContentWidth > 0 {
            w = self.preferredContentWidth
        } else if self.bounds.width > 0 {
            w = self.bounds.width
        } else {
            w = self.window?.bounds.width ?? UIScreen.main.bounds.width
        }
        let fitting = self.textView.sizeThatFits(
            CGSize(width: w, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(fitting.height))
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
        }
    }

    public func sizeThatFitsMarkdown(width: CGFloat) -> CGSize {
        let size = self.textView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: width, height: ceil(size.height))
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
    }

    internal func resetBaseState() {
        self.rawMarkdown = ""
        self.tableOverlayCoordinator.reset()
        self.invalidateIntrinsicContentSize()
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
        STMarkdownAttachmentRefreshSupport.bindRefreshHandlers(in: attributedText) { [weak self] attachment in
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
}
