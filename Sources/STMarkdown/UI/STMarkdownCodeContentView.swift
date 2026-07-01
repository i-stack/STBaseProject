//
//  STMarkdownCodeContentView.swift
//  STMarkdown
//
//  代码内容视图：行号 + 语法高亮，支持渲染为图片（UIGraphicsImageRenderer）。
//  所有颜色通过参数注入，不直接引用 ThemeManager。
//

import UIKit
import STBaseProject

/// 代码内容展示视图，带行号边栏和语法高亮，支持渲染为图片供附件使用。
public final class STMarkdownCodeContentView: UIView, UITextViewDelegate {

    private var lineNumberGutterWidth: CGFloat = 42
    private var lineNumberGutterWidthConstraint: NSLayoutConstraint?
    private var lineNumberHeightConstraint: NSLayoutConstraint?
    private var lineNumberTextContentHeight: CGFloat = 0
    private var isSyncingCodeScroll = false
    private var currentCode: String = ""
    private var currentStyle: STMarkdownStyle?
    private var currentCodeBlockTextColor: UIColor = UIColor.label
    private var currentLineNumberColor: UIColor = UIColor.secondaryLabel

    /// 可替换的代码字体
    public var codeFont: UIFont = UIFont.st_monospacedSystemFont(ofSize: 14, weight: .regular)
    /// 可替换的行号字体
    public var lineNumberFont: UIFont = UIFont.st_monospacedSystemFont(ofSize: 12, weight: .regular)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    /// 应用主题颜色（从外部注入，不直接引用 ThemeManager）。
    public func applyTheme(codeBlockTextColor: UIColor,
                           lineNumberColor: UIColor,
                           lineNumberBackgroundColor: UIColor,
                           codeBackgroundColor: UIColor) {
        self.backgroundColor = .clear
        self.lineNumberContainerView.backgroundColor = lineNumberBackgroundColor
        self.codeTextView.backgroundColor = .clear
        self.codeTextView.textColor = codeBlockTextColor
        self.currentCodeBlockTextColor = codeBlockTextColor
        self.currentLineNumberColor = lineNumberColor
        if let style = self.currentStyle {
            self.rebuildLineNumbersIfPossible(rawCode: self.currentCode, style: style)
        }
    }

    public func update(code: String, language: String?, style: STMarkdownStyle) {
        self.currentCode = code
        self.currentStyle = style
        let font = self.codeFont
        let lineSpacing = max(style.bodyLineSpacing, 2)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        paragraphStyle.lineSpacing = lineSpacing
        self.codeTextView.attributedText = STMarkdownCodeSyntaxHighlighter.highlightedBody(
            language: language,
            code: code,
            font: font,
            textColor: style.codeBlockTextColor ?? self.currentCodeBlockTextColor,
            paragraphStyle: paragraphStyle
        )
        let logicalLines = max(code.components(separatedBy: .newlines).count, 1)
        let digits = String(logicalLines).count
        let gutterWidth = max(34, CGFloat(digits) * 8 + 14)
        self.lineNumberGutterWidth = gutterWidth
        self.lineNumberGutterWidthConstraint?.constant = gutterWidth
        self.rebuildLineNumbersIfPossible(rawCode: code, style: style)
        self.syncLineNumberOffset(with: self.codeTextView.contentOffset)
    }

    /// 将代码内容渲染为 UIImage（用于附件快照）。
    public func renderCodeImage(style: STMarkdownStyle,
                                codeBackgroundColor: UIColor,
                                gutterBackgroundColor: UIColor) -> UIImage? {
        guard let codeAttributed = self.codeTextView.attributedText, codeAttributed.length > 0 else { return nil }
        let gutterWidth = self.lineNumberGutterWidth
        let targetWidth = max(self.bounds.width, 200)
        let codeWidth = max(targetWidth - gutterWidth, 120)
        let codeInsets = self.codeTextView.textContainerInset
        let lineContentHeight = self.lineNumberTextContentHeight
        let codeContentHeight = codeAttributed.boundingRect(
            with: CGSize(width: codeWidth - codeInsets.left - codeInsets.right, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height + codeInsets.top + codeInsets.bottom
        let contentHeight = max(ceil(max(lineContentHeight, codeContentHeight)), 100)
        let imageSize = CGSize(width: gutterWidth + codeWidth, height: contentHeight)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = max(UIScreen.main.scale, 3.0)
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)
        return renderer.image { context in
            codeBackgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))
            gutterBackgroundColor.setFill()
            context.fill(CGRect(x: 0, y: 0, width: gutterWidth, height: contentHeight))
            let lineRect = CGRect(x: 0, y: 0, width: gutterWidth, height: contentHeight)
            let codeRect = CGRect(x: gutterWidth, y: 0, width: codeWidth, height: contentHeight)
            self.lineNumberLabel.render(in: context.cgContext, bounds: lineRect)
            codeAttributed.draw(
                with: codeRect.inset(by: UIEdgeInsets(top: codeInsets.top, left: codeInsets.left, bottom: codeInsets.bottom, right: codeInsets.right)),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            )
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if let style = self.currentStyle, !self.currentCode.isEmpty {
            self.rebuildLineNumbersIfPossible(rawCode: self.currentCode, style: style)
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === self.codeTextView, !self.isSyncingCodeScroll else { return }
        self.syncLineNumberOffset(with: scrollView.contentOffset)
    }

    private func setupUI() {
        self.lineNumberContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.codeTextView.translatesAutoresizingMaskIntoConstraints = false
        self.lineNumberLabel.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(self.lineNumberContainerView)
        self.lineNumberContainerView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.lineNumberContainerView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.lineNumberContainerView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.lineNumberGutterWidthConstraint = self.lineNumberContainerView.widthAnchor.constraint(equalToConstant: 42)
        self.lineNumberGutterWidthConstraint?.isActive = true

        self.lineNumberContainerView.addSubview(self.lineNumberLabel)
        self.lineNumberLabel.leadingAnchor.constraint(equalTo: self.lineNumberContainerView.leadingAnchor).isActive = true
        self.lineNumberLabel.topAnchor.constraint(equalTo: self.lineNumberContainerView.topAnchor).isActive = true
        self.lineNumberLabel.trailingAnchor.constraint(equalTo: self.lineNumberContainerView.trailingAnchor).isActive = true
        self.lineNumberHeightConstraint = self.lineNumberLabel.heightAnchor.constraint(equalToConstant: 1)
        self.lineNumberHeightConstraint?.isActive = true

        self.addSubview(self.codeTextView)
        self.codeTextView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.codeTextView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.codeTextView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        self.codeTextView.leadingAnchor.constraint(equalTo: self.lineNumberContainerView.trailingAnchor).isActive = true
    }

    private func rebuildLineNumbersIfPossible(rawCode: String, style: STMarkdownStyle) {
        guard let codeAttributed = self.codeTextView.attributedText, codeAttributed.length > 0 else { return }
        let layoutManager = self.codeTextView.layoutManager
        let container = self.codeTextView.textContainer
        layoutManager.ensureLayout(for: container)
        let codeNSString = rawCode as NSString
        let glyphRange = layoutManager.glyphRange(for: container)
        var currentLogicalLine = 1
        var entries: [STMarkdownLineNumberEntry] = []
        let topInset = self.codeTextView.textContainerInset.top
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { _, _, _, fragmentGlyphRange, _ in
            let charRange = layoutManager.characterRange(forGlyphRange: fragmentGlyphRange, actualGlyphRange: nil)
            let isLineStart = charRange.location == 0 ||
                (charRange.location > 0 && codeNSString.character(at: charRange.location - 1) == 10)
            let rawY = layoutManager.lineFragmentRect(forGlyphAt: fragmentGlyphRange.location, effectiveRange: nil).minY + topInset
            let lineY = self.alignToPixel(rawY)
            if isLineStart {
                entries.append(.init(text: String(currentLogicalLine), y: lineY))
                currentLogicalLine += 1
            }
        }
        if entries.isEmpty {
            entries = [.init(text: "1", y: topInset)]
        }
        let usedHeight = layoutManager.usedRect(for: container).height + self.codeTextView.textContainerInset.top + self.codeTextView.textContainerInset.bottom
        let contentHeight = max(ceil(usedHeight), ceil(self.codeTextView.contentSize.height), 1)
        self.lineNumberTextContentHeight = contentHeight
        self.lineNumberHeightConstraint?.constant = contentHeight
        self.lineNumberLabel.update(entries: entries, font: self.lineNumberFont, color: self.currentLineNumberColor, rightInset: self.lineNumberInsets.right)
    }

    private func alignToPixel(_ value: CGFloat) -> CGFloat {
        let scale = max(UIScreen.main.scale, 1)
        return (value * scale).rounded(.toNearestOrAwayFromZero) / scale
    }

    private func syncLineNumberOffset(with contentOffset: CGPoint) {
        guard !self.isSyncingCodeScroll else { return }
        self.isSyncingCodeScroll = true
        let maxOffsetY = max(self.lineNumberTextContentHeight - self.lineNumberContainerView.bounds.height, 0)
        let y = min(max(contentOffset.y, 0), maxOffsetY)
        self.lineNumberLabel.transform = CGAffineTransform(translationX: 0, y: -y)
        self.isSyncingCodeScroll = false
    }

    private var lineNumberInsets: UIEdgeInsets {
        UIEdgeInsets(top: 12, left: 0, bottom: 20, right: 6)
    }

    private lazy var lineNumberContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.backgroundColor = .clear
        return view
    }()

    private lazy var lineNumberLabel: STMarkdownLineNumberDrawView = {
        let view = STMarkdownLineNumberDrawView()
        view.backgroundColor = .clear
        return view
    }()

    /// 公开 codeTextView 供外部自定义
    public private(set) lazy var codeTextView: UITextView = {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.backgroundColor = .clear
        view.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 20, right: 12)
        view.font = self.codeFont
        view.showsVerticalScrollIndicator = true
        view.alwaysBounceVertical = true
        view.delegate = self
        view.textColor = UIColor.label
        return view
    }()
}
