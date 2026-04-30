//
//  STMarkdownStreamingTextView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public final class STMarkdownStreamingTextView: STMarkdownBaseTextView {

    public var tokenFadeDuration: TimeInterval {
        get { self.shimmerTextView.tokenFadeDuration }
        set { self.shimmerTextView.tokenFadeDuration = newValue }
    }

    public var customDocumentRenderer: ((STMarkdownRenderDocument) -> NSAttributedString)?

    public var suppressSystemTextMenu: Bool {
        get { self.shimmerTextView.suppressSystemTextMenu }
        set { self.shimmerTextView.suppressSystemTextMenu = newValue }
    }

    public var animateAcrossNewlines: Bool {
        get { self.shimmerTextView.animateAcrossNewlines }
        set { self.shimmerTextView.animateAcrossNewlines = newValue }
    }

    private var shimmerTextView: STShimmerTextView {
        guard let textView = self.textView as? STShimmerTextView else {
            preconditionFailure("STMarkdownStreamingTextView requires STShimmerTextView")
        }
        return textView
    }

    public override var attributedText: NSAttributedString {
        self.shimmerTextView.renderedAttributedText
    }

    internal override var currentAttributedText: NSAttributedString {
        self.shimmerTextView.renderedAttributedText
    }

    public init(frame: CGRect) {
        super.init(
            textView: STShimmerTextView(usingTextLayoutManager: false),
            frame: frame,
            style: .default,
            advancedRenderers: .empty,
            engine: STMarkdownEngine(),
            accessibilityTraits: [.staticText, .updatesFrequently]
        )
    }

    public convenience init(
        style: STMarkdownStyle = .default,
        advancedRenderers: STMarkdownAdvancedRenderers = .empty,
        engine: STMarkdownEngine = STMarkdownEngine()
    ) {
        self.init(frame: .zero)
        self.applyConfigurationCommon(
            style: style,
            advancedRenderers: advancedRenderers,
            engine: engine
        )
    }

    public required init?(coder: NSCoder) {
        super.init(
            textView: STShimmerTextView(usingTextLayoutManager: false),
            coder: coder,
            style: .default,
            advancedRenderers: .empty,
            engine: STMarkdownEngine(),
            accessibilityTraits: [.staticText, .updatesFrequently]
        )
    }

    public func reset() {
        self.shimmerTextView.reset()
        self.resetBaseState()
    }

    public func finishStreaming() {
        self.shimmerTextView.finishAnimations()
    }

    public func setMarkdown(_ markdown: String, animated: Bool = false) {
        let rendered = self.render(markdown)
        guard animated, !self.rawMarkdown.isEmpty else {
            self.applyFullReplace(markdown: markdown, rendered: rendered)
            return
        }

        let current = self.shimmerTextView.renderedAttributedText
        let currentStr = current.string
        let renderedStr = rendered.string

        if renderedStr.count >= currentStr.count,
           (renderedStr as NSString).hasPrefix(currentStr) {
            let prefixChanged = current.length > 0
                && !rendered.attributedSubstring(
                    from: NSRange(location: 0, length: current.length)
                ).isEqual(to: current)
            if prefixChanged {
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
                self.rawMarkdown = markdown
                self.textView.accessibilityValue = self.shimmerTextView.renderedAttributedText.string
            }
            return
        }

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
                self.applyFullReplace(markdown: markdown, rendered: rendered)
            } else if listMarkerInvolved {
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

        self.applyFullReplace(markdown: markdown, rendered: rendered)
    }

    public func applyConfiguration(
        markdown: String,
        style: STMarkdownStyle,
        advancedRenderers: STMarkdownAdvancedRenderers,
        engine: STMarkdownEngine,
        animated: Bool
    ) {
        self.applyConfigurationCommon(
            style: style,
            advancedRenderers: advancedRenderers,
            engine: engine
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

    internal override func configurationDidChangeRerender() {
        self.setMarkdown(self.rawMarkdown, animated: false)
    }

    private func applyFullReplace(markdown: String, rendered: NSAttributedString) {
        self.rawMarkdown = markdown
        self.shimmerTextView.setRenderedAttributedText(rendered)
        self.finalizeRenderUpdate(rendered: rendered)
    }

    private func applyAppendDelta(markdown: String, delta: NSAttributedString) {
        self.rawMarkdown = markdown
        self.shimmerTextView.appendAttributedText(delta, animated: true)
        self.finalizeRenderUpdate(rendered: self.shimmerTextView.renderedAttributedText)
    }

    private func applyTrailingReplace(
        markdown: String,
        from location: Int,
        trailing: NSAttributedString,
        animate: Bool
    ) {
        self.rawMarkdown = markdown
        self.shimmerTextView.replaceTrailingAttributedText(
            from: location,
            with: trailing,
            animateNewPortion: animate
        )
        self.finalizeRenderUpdate(rendered: self.shimmerTextView.renderedAttributedText)
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

    private func replacementStartForListTransition(currentString: String, commonLength: Int) -> Int {
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

    private static let orderedListMarkerRegex = try! NSRegularExpression(
        pattern: #"(?m)^\t*\d+\.\t"#,
        options: []
    )

    private static let unorderedListMarkerRegex = try! NSRegularExpression(
        pattern: #"(?m)(?:^|\n)\t*[●▪]\t"#,
        options: []
    )
}
