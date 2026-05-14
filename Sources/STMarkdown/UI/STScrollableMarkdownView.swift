//
//  STScrollableMarkdownView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

/// 将 ``STMarkdownTextView`` 嵌入 ``UIScrollView`` 的只读 Markdown 预览容器。
///
/// - Note: 目录数据仍由 ``STMarkdownTextView/tableOfContents`` 与 ``scrollToHeadingAnchor`` 提供；
///   侧栏 UI 与 `onTOCItemTap` 由宿主组合（对比文档 **【部分对齐】**）。
public final class STScrollableMarkdownView: UIView {

    public let scrollView: UIScrollView
    public let markdownTextView: STMarkdownTextView

    public var onLinkTap: ((URL) -> Void)? {
        get { self.markdownTextView.onLinkTap }
        set { self.markdownTextView.onLinkTap = newValue }
    }

    public var onContentLayoutHeightChange: ((CGFloat) -> Void)? {
        get { self.markdownTextView.onContentLayoutHeightChange }
        set { self.markdownTextView.onContentLayoutHeightChange = newValue }
    }

    /// - Parameter usesTextLayoutManager: 传入内层 ``STMarkdownTextView`` 的 TextKit 2 开关（iOS 16+）。
    public init(frame: CGRect, usesTextLayoutManager: Bool = false) {
        self.scrollView = UIScrollView()
        self.markdownTextView = STMarkdownTextView(frame: .zero, usesTextLayoutManager: usesTextLayoutManager)
        super.init(frame: frame)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.alwaysBounceVertical = true
        self.scrollView.keyboardDismissMode = .interactive
        self.markdownTextView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.markdownTextView)
        NSLayoutConstraint.activate([
            self.scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.markdownTextView.leadingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.leadingAnchor),
            self.markdownTextView.trailingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.trailingAnchor),
            self.markdownTextView.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor),
            self.markdownTextView.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor),
            self.markdownTextView.widthAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    public required init?(coder: NSCoder) {
        self.scrollView = UIScrollView()
        self.markdownTextView = STMarkdownTextView(coder: coder) ?? STMarkdownTextView(frame: .zero)
        super.init(coder: coder)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.markdownTextView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.scrollView)
        self.scrollView.addSubview(self.markdownTextView)
        NSLayoutConstraint.activate([
            self.scrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.scrollView.topAnchor.constraint(equalTo: self.topAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.markdownTextView.leadingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.leadingAnchor),
            self.markdownTextView.trailingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.trailingAnchor),
            self.markdownTextView.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor),
            self.markdownTextView.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor),
            self.markdownTextView.widthAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.widthAnchor),
        ])
    }

    public func setMarkdown(_ markdown: String) {
        self.markdownTextView.setMarkdown(markdown)
    }
}
