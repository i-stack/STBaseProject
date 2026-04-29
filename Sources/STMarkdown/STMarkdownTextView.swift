//
//  STMarkdownTextView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public final class STMarkdownTextView: UIView, STMarkdownInteractable {

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
                self.setMarkdown(self.rawMarkdown)
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
                self.setMarkdown(self.rawMarkdown)
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

    public private(set) var rawMarkdown: String = ""

    public var attributedText: NSAttributedString {
        self.textView.attributedText ?? NSAttributedString()
    }

    public var contentTextView: UITextView {
        self.textView
    }

    public var textViewInset: UIEdgeInsets {
        get { self.textView.textContainerInset }
        set {
            self.textView.textContainerInset = newValue
            self.invalidateIntrinsicContentSize()
        }
    }

    private var renderer: STMarkdownAttributedStringRenderer
    private var isApplyingConfiguration = false
    private let textView: UITextView = UITextView(usingTextLayoutManager: false)
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

    public override var intrinsicContentSize: CGSize {
        let width = self.bounds.width > 0 ? self.bounds.width : (self.window?.bounds.width ?? UIView.layoutFittingExpandedSize.width)
        let fitting = self.textView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: UIView.noIntrinsicMetric, height: ceil(fitting.height))
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.tableOverlayCoordinator.updateIfNeeded(
            attributedText: self.attributedText,
            containerBounds: self.bounds
        )
    }

    public func setMarkdown(_ markdown: String) {
        self.rawMarkdown = markdown
        let result = self.engine.process(markdown)
        let rendered = self.renderer.render(document: result.renderDocument)
        self.textView.attributedText = rendered
        self.textView.accessibilityValue = rendered.string
        self.bindAttachmentRefreshHandlers(in: rendered)
        self.tableOverlayCoordinator.markDirty()
        self.invalidateIntrinsicContentSize()
    }

    public func applyConfiguration(
        markdown: String,
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
        self.renderer = STMarkdownAttributedStringRenderer(
            style: style,
            advancedRenderers: advancedRenderers
        )
        self.setMarkdown(markdown)
    }

    public func reset() {
        self.rawMarkdown = ""
        self.textView.attributedText = nil
        self.tableOverlayCoordinator.reset()
        self.invalidateIntrinsicContentSize()
    }

    public func sizeThatFitsMarkdown(width: CGFloat) -> CGSize {
        let size = self.textView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        return CGSize(width: width, height: ceil(size.height))
    }

    private func setup() {
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
        self.textView.accessibilityTraits = .staticText
        self.textView.delegate = self
        self.addSubview(self.textView)
        NSLayoutConstraint.activate([
            self.textView.topAnchor.constraint(equalTo: self.topAnchor),
            self.textView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.textView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.textView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
        ])
    }

    @MainActor
    private func refreshRenderedAttachments() {
        let range = NSRange(location: 0, length: self.textView.attributedText.length)
        guard range.length > 0 else { return }
        self.textView.layoutManager.invalidateDisplay(forCharacterRange: range)
        self.textView.layoutManager.invalidateLayout(forCharacterRange: range, actualCharacterRange: nil)
        self.textView.setNeedsLayout()
        self.textView.layoutIfNeeded()
        self.invalidateIntrinsicContentSize()
    }

    private func bindAttachmentRefreshHandlers(in attributedText: NSAttributedString) {
        STMarkdownAttachmentRefreshSupport.bindRefreshHandlers(in: attributedText) { [weak self] in
            self?.refreshRenderedAttachments()
        }
    }
}

extension STMarkdownTextView: UITextViewDelegate {
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
