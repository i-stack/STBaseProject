//
//  STMarkdownTextView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public final class STMarkdownTextView: STMarkdownBaseTextView {

    public init(frame: CGRect, usesTextLayoutManager: Bool = false) {
        super.init(
            textView: UITextView(usingTextLayoutManager: usesTextLayoutManager),
            frame: frame,
            style: .default,
            advancedRenderers: .empty,
            engine: STMarkdownEngine(),
            accessibilityTraits: .staticText
        )
    }

    public convenience init(
        style: STMarkdownStyle = .default,
        advancedRenderers: STMarkdownAdvancedRenderers = .empty,
        engine: STMarkdownEngine = STMarkdownEngine(),
        usesTextLayoutManager: Bool = false
    ) {
        self.init(frame: .zero, usesTextLayoutManager: usesTextLayoutManager)
        self.applyConfigurationCommon(
            style: style,
            advancedRenderers: advancedRenderers,
            engine: engine
        )
    }

    public required init?(coder: NSCoder) {
        super.init(
            textView: UITextView(usingTextLayoutManager: false),
            coder: coder,
            style: .default,
            advancedRenderers: .empty,
            engine: STMarkdownEngine(),
            accessibilityTraits: .staticText
        )
    }

    public func setMarkdown(_ markdown: String) {
        self.rawMarkdown = markdown
        let rendered = self.renderMarkdown(markdown)
        self.textView.attributedText = rendered
        self.finalizeRenderUpdate(rendered: rendered)
    }

    public func applyConfiguration(
        markdown: String,
        style: STMarkdownStyle,
        advancedRenderers: STMarkdownAdvancedRenderers,
        engine: STMarkdownEngine
    ) {
        self.applyConfigurationCommon(
            style: style,
            advancedRenderers: advancedRenderers,
            engine: engine
        )
        self.setMarkdown(markdown)
    }

    public func reset() {
        self.textView.attributedText = NSAttributedString()
        self.resetBaseState()
    }

    internal override func configurationDidChangeRerender() {
        self.setMarkdown(self.rawMarkdown)
    }
}
