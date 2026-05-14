//
//  STScrollableMarkdownView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

// MARK: - 内置目录列表（侧栏）

private final class STMarkdownTOCListHost: NSObject, UITableViewDataSource, UITableViewDelegate {

    var items: [STMarkdownTOCItem] = []
    weak var markdownTextView: STMarkdownBaseTextView?

    var onTOCItemTap: ((STMarkdownTOCItem) -> Void)?

    let tableView: UITableView

    override init() {
        self.tableView = UITableView(frame: .zero, style: .plain)
        super.init()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.rowHeight = 40
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "toc")
        self.tableView.backgroundColor = .secondarySystemGroupedBackground
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "toc", for: indexPath)
        let item = self.items[indexPath.row]
        let indent = String(repeating: "  ", count: max(0, item.level - 1))
        cell.textLabel?.font = .preferredFont(forTextStyle: .subheadline)
        cell.textLabel?.numberOfLines = 2
        cell.textLabel?.text = indent + item.title
        cell.accessibilityLabel = "TOC, level \(item.level), \(item.title)"
        cell.backgroundColor = .clear
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = self.items[indexPath.row]
        _ = self.markdownTextView?.scrollToTOCItem(anchorId: item.anchorId, animated: true)
        self.onTOCItemTap?(item)
    }
}

// MARK: - 滚动容器

/// 将 ``STMarkdownTextView`` 嵌入 ``UIScrollView``，并可选展示内置目录侧栏（对比文档 P1）。
public final class STScrollableMarkdownView: UIView {

    public let scrollView: UIScrollView
    public let markdownTextView: STMarkdownTextView

    /// 为 `true` 时在正文左侧展示可点击的标题目录列表。
    public var showsTableOfContents: Bool = false {
        didSet { self.applyTOCChromeVisibility() }
    }

    /// 侧栏目录宽度（pt）；仅在 ``showsTableOfContents`` 为 `true` 时生效。
    public var tableOfContentsPanelWidth: CGFloat = 168 {
        didSet { self.applyTOCChromeVisibility() }
    }

    /// 用户点击目录行后调用（在滚动到锚点之后）；与 Vendor ``onTOCItemTap`` 语义对齐。
    public var onTOCItemTap: ((STMarkdownTOCItem) -> Void)? {
        get { self.tocHost.onTOCItemTap }
        set { self.tocHost.onTOCItemTap = newValue }
    }

    public var onLinkTap: ((URL) -> Void)? {
        get { self.markdownTextView.onLinkTap }
        set { self.markdownTextView.onLinkTap = newValue }
    }

    public var onFootnoteTap: ((String) -> Void)? {
        get { self.markdownTextView.onFootnoteTap }
        set { self.markdownTextView.onFootnoteTap = newValue }
    }

    public var onContentLayoutHeightChange: ((CGFloat) -> Void)? {
        get { self.markdownTextView.onContentLayoutHeightChange }
        set { self.markdownTextView.onContentLayoutHeightChange = newValue }
    }

    /// 目录随正文管线刷新时调用（在更新内置侧栏之后）；流式宿主可在此与侧栏同帧对齐。
    public var onTableOfContentsChange: (([STMarkdownTOCItem]) -> Void)?

    private let horizontalStack = UIStackView()
    private let tocPanel = UIView()
    private let tocSeparator = UIView()
    private let tocHost = STMarkdownTOCListHost()
    private var tocWidthConstraint: NSLayoutConstraint!
    private var tocSeparatorWidthConstraint: NSLayoutConstraint!

    /// - Parameter usesTextLayoutManager: 传入内层 ``STMarkdownTextView`` 的 TextKit 2 开关（iOS 16+）。
    public init(frame: CGRect, usesTextLayoutManager: Bool = false) {
        self.scrollView = UIScrollView()
        self.markdownTextView = STMarkdownTextView(frame: .zero, usesTextLayoutManager: usesTextLayoutManager)
        super.init(frame: frame)
        self.installHierarchy()
    }

    public required init?(coder: NSCoder) {
        self.scrollView = UIScrollView()
        self.markdownTextView = STMarkdownTextView(coder: coder) ?? STMarkdownTextView(frame: .zero)
        super.init(coder: coder)
        self.installHierarchy()
    }

    public func setMarkdown(_ markdown: String) {
        self.markdownTextView.setMarkdown(markdown)
    }

    private func installHierarchy() {
        self.tocHost.markdownTextView = self.markdownTextView

        self.horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        self.horizontalStack.axis = .horizontal
        self.horizontalStack.alignment = .fill
        self.horizontalStack.distribution = .fill
        self.horizontalStack.spacing = 0
        self.addSubview(self.horizontalStack)

        self.tocPanel.translatesAutoresizingMaskIntoConstraints = false
        self.tocSeparator.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.markdownTextView.translatesAutoresizingMaskIntoConstraints = false

        self.tocSeparator.backgroundColor = .separator

        let table = self.tocHost.tableView
        table.translatesAutoresizingMaskIntoConstraints = false
        self.tocPanel.addSubview(table)
        NSLayoutConstraint.activate([
            table.leadingAnchor.constraint(equalTo: self.tocPanel.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: self.tocPanel.trailingAnchor),
            table.topAnchor.constraint(equalTo: self.tocPanel.topAnchor),
            table.bottomAnchor.constraint(equalTo: self.tocPanel.bottomAnchor),
        ])

        self.horizontalStack.addArrangedSubview(self.tocPanel)
        self.horizontalStack.addArrangedSubview(self.tocSeparator)
        self.horizontalStack.addArrangedSubview(self.scrollView)

        self.scrollView.alwaysBounceVertical = true
        self.scrollView.keyboardDismissMode = .interactive
        self.scrollView.addSubview(self.markdownTextView)

        self.tocWidthConstraint = self.tocPanel.widthAnchor.constraint(equalToConstant: 0)
        self.tocSeparatorWidthConstraint = self.tocSeparator.widthAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            self.horizontalStack.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.horizontalStack.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.horizontalStack.topAnchor.constraint(equalTo: self.topAnchor),
            self.horizontalStack.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.tocWidthConstraint,
            self.tocSeparatorWidthConstraint,
            self.markdownTextView.leadingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.leadingAnchor),
            self.markdownTextView.trailingAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.trailingAnchor),
            self.markdownTextView.topAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.topAnchor),
            self.markdownTextView.bottomAnchor.constraint(equalTo: self.scrollView.contentLayoutGuide.bottomAnchor),
            self.markdownTextView.widthAnchor.constraint(equalTo: self.scrollView.frameLayoutGuide.widthAnchor),
        ])

        self.markdownTextView.onTableOfContentsChange = { [weak self] items in
            guard let self else { return }
            self.tocHost.items = items
            self.tocHost.tableView.reloadData()
            self.onTableOfContentsChange?(items)
        }

        self.applyTOCChromeVisibility()
    }

    private func applyTOCChromeVisibility() {
        let show = self.showsTableOfContents
        let w = max(0, self.tableOfContentsPanelWidth)
        self.tocWidthConstraint.constant = show ? w : 0
        self.tocSeparatorWidthConstraint.constant = show ? (1.0 / max(UIScreen.main.scale, 1)) : 0
        self.tocPanel.isHidden = !show
        self.tocSeparator.isHidden = !show
        self.tocPanel.isUserInteractionEnabled = show
    }
}
