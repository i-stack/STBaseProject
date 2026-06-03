//
//  STMarkdownTableView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

/// UICollectionView-based 表格视图，替代旧的 UIImage-based 渲染方案。
/// 借鉴 FluidMarkdown 的 AMMarkdownTableView 设计思想：
/// - 背景色 = border 色，cell 间隙形成网格线
/// - section = 行, item = 列
/// - 支持水平滚动（宽表自然溢出）
public final class STMarkdownTableView: UIView {

    /// 表格数据 façade。流式逐行追加（同列数、已有行内容不变、行数严格增多）时，
    /// 用 `performBatchUpdates` 插入新 section 并逐行淡入；否则全量 `reloadData()`。
    /// 注意：dataSource 实际读 `renderedTableData`，追加动画在 batch block 内才翻转底层数据，
    /// 以保证 UICollectionView 的 before/after section 数一致（否则会断言崩溃）。
    public var tableData: STMarkdownTableViewModel? {
        get { self.renderedTableData }
        set { self.applyTableData(newValue) }
    }

    /// 是否对「纯行追加」启用逐行淡入。详情页/一次性渲染不会触发追加，默认开即可。
    public var animatesRowAppends: Bool = true

    private var renderedTableData: STMarkdownTableViewModel?
    private var isApplyingAppend = false


    public var style: STMarkdownStyle = .default {
        didSet { self.applyStyle(); self.reloadData() }
    }

    public var onCitationTap: ((String) -> Void)?
    public var onExpandTable: ((STMarkdownTableViewModel) -> Void)?
    public var onCopyTable: (() -> Void)?
    public var onDownloadTable: ((STMarkdownTableViewModel) -> Void)?

    /// 顶部工具条高度（圆角卡片化后预留给「表格 / 复制 / 下载 / 全屏」）。
    public static let headerHeight: CGFloat = 44
    /// 整块表格圆角半径。
    public var cornerRadius: CGFloat = 10 {
        didSet { self.layer.cornerRadius = self.cornerRadius }
    }
    /// 是否展示顶部工具条。全屏详情页关闭（自带关闭按钮，避免重复表头与“全屏中再全屏”）。
    public var showsHeader: Bool = true {
        didSet {
            guard oldValue != self.showsHeader else { return }
            self.headerBar.isHidden = !self.showsHeader
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }

    private let gridLayout: STMarkdownTableGridLayout
    private let collectionView: UICollectionView
    private let cellInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)

    private let headerBar = UIView()
    private let titleLabel = UILabel()
    private let buttonStack = UIStackView()
    private let copyButton = UIButton(type: .system)
    private let downloadButton = UIButton(type: .system)
    private let fullscreenButton = UIButton(type: .system)
    private let headerSeparator = UIView()
    private var copyResetWorkItem: DispatchWorkItem?

    public init(style: STMarkdownStyle) {
        self.style = style
        self.gridLayout = STMarkdownTableGridLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.gridLayout)
        super.init(frame: .zero)
        self.clipsToBounds = true
        self.layer.cornerRadius = self.cornerRadius
        self.layer.borderWidth = 0.5
        self.setupCollectionView()
        self.setupHeader()
        self.applyStyle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCollectionView() {
        self.collectionView.register(STMarkdownTableCell.self, forCellWithReuseIdentifier: STMarkdownTableCell.reuseIdentifier)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.bounces = false
        self.collectionView.alwaysBounceHorizontal = false
        self.collectionView.alwaysBounceVertical = false
        self.collectionView.showsHorizontalScrollIndicator = true
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.isScrollEnabled = true
        self.collectionView.scrollsToTop = false
        self.collectionView.contentInset = .zero
        let expandGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleExpandGesture(_:)))
        self.collectionView.addGestureRecognizer(expandGesture)
        self.addSubview(self.collectionView)

        self.gridLayout.sizeForItem = { [weak self] indexPath in
            self?.sizeForItem(at: indexPath) ?? CGSize(width: 56, height: 35)
        }
    }

    private func setupHeader() {
        self.titleLabel.text = "表格"
        self.titleLabel.font = UIFont.st_systemFont(ofSize: 13, weight: .medium)

        self.copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        self.copyButton.addTarget(self, action: #selector(self.handleCopy), for: .touchUpInside)
        self.downloadButton.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        self.downloadButton.addTarget(self, action: #selector(self.handleDownload), for: .touchUpInside)
        self.fullscreenButton.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        self.fullscreenButton.addTarget(self, action: #selector(self.handleFullscreen), for: .touchUpInside)

        let imageConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        for button in [self.copyButton, self.downloadButton, self.fullscreenButton] {
            button.setPreferredSymbolConfiguration(imageConfig, forImageIn: .normal)
            button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        }

        self.buttonStack.axis = .horizontal
        self.buttonStack.alignment = .center
        self.buttonStack.spacing = 6
        self.buttonStack.addArrangedSubview(self.copyButton)
        self.buttonStack.addArrangedSubview(self.downloadButton)
        self.buttonStack.addArrangedSubview(self.fullscreenButton)

        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.buttonStack.translatesAutoresizingMaskIntoConstraints = false
        self.headerSeparator.translatesAutoresizingMaskIntoConstraints = false
        self.headerBar.addSubview(self.titleLabel)
        self.headerBar.addSubview(self.buttonStack)
        self.headerBar.addSubview(self.headerSeparator)
        self.addSubview(self.headerBar)

        NSLayoutConstraint.activate([
            self.titleLabel.leadingAnchor.constraint(equalTo: self.headerBar.leadingAnchor, constant: 14),
            self.titleLabel.centerYAnchor.constraint(equalTo: self.headerBar.centerYAnchor),

            self.buttonStack.trailingAnchor.constraint(equalTo: self.headerBar.trailingAnchor, constant: -10),
            self.buttonStack.centerYAnchor.constraint(equalTo: self.headerBar.centerYAnchor),
            self.buttonStack.heightAnchor.constraint(equalTo: self.headerBar.heightAnchor),

            self.headerSeparator.leadingAnchor.constraint(equalTo: self.headerBar.leadingAnchor),
            self.headerSeparator.trailingAnchor.constraint(equalTo: self.headerBar.trailingAnchor),
            self.headerSeparator.bottomAnchor.constraint(equalTo: self.headerBar.bottomAnchor),
            self.headerSeparator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    private func applyStyle() {
        let borderColor = self.style.tableBorderColor ?? UIColor.separator
        self.collectionView.backgroundColor = borderColor
        self.backgroundColor = borderColor
        self.gridLayout.interItemSpacing = 0.5
        self.gridLayout.lineSpacing = 0.5
        self.layer.borderColor = borderColor.cgColor

        let headerBg = self.style.tableBackgroundColor ?? UIColor.secondarySystemBackground
        let secondaryColor = (self.style.tableHeaderTextColor ?? self.style.textColor).withAlphaComponent(0.6)
        self.headerBar.backgroundColor = headerBg
        self.headerSeparator.backgroundColor = borderColor
        self.titleLabel.textColor = secondaryColor
        for button in [self.copyButton, self.downloadButton, self.fullscreenButton] {
            button.tintColor = secondaryColor
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let headerHeight = self.showsHeader ? Self.headerHeight : 0
        if self.showsHeader {
            let headerFrame = CGRect(x: 0, y: 0, width: self.bounds.width, height: headerHeight)
            if self.headerBar.frame != headerFrame {
                self.headerBar.frame = headerFrame
            }
        }
        let gridFrame = CGRect(
            x: 0,
            y: headerHeight,
            width: self.bounds.width,
            height: max(self.bounds.height - headerHeight, 0)
        )
        if self.collectionView.frame != gridFrame {
            self.collectionView.frame = gridFrame
        }
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let tableData, tableData.rowCount > 0, tableData.columnCount > 0 else { return .zero }
        return Self.computeSize(
            tableData: tableData,
            containerWidth: size.width,
            style: self.style,
            cellInsets: self.cellInsets,
            includesHeader: self.showsHeader
        )
    }

    public override var intrinsicContentSize: CGSize {
        self.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
    }

    public static func computeSize(
        tableData: STMarkdownTableViewModel,
        containerWidth: CGFloat,
        style: STMarkdownStyle,
        cellInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10),
        includesHeader: Bool = true
    ) -> CGSize {
        let gridSize = STMarkdownTableGridLayout.computeSize(
            rows: tableData.rowCount,
            columns: tableData.columnCount,
            sizeForItem: { indexPath in
                let cellData = tableData.cells[indexPath.section][indexPath.item]
                return STMarkdownTableCell.sizeThatFits(
                    cellData: cellData,
                    constrainedWidth: 360,
                    contentInsets: cellInsets
                )
            },
            metrics: STMarkdownTableGridLayout.ComputeSizeMetrics(
                fillWidth: true,
                containerWidth: containerWidth,
                minimumRowHeight: 35,
                minimumColumnWidth: 56,
                maximumColumnWidth: 360,
                interItemSpacing: 0.5,
                lineSpacing: 0.5
            )
        )
        guard gridSize.height > 0 else { return gridSize }
        let extra = includesHeader ? Self.headerHeight : 0
        return CGSize(width: gridSize.width, height: gridSize.height + extra)
    }

    private func reloadData() {
        self.gridLayout.invalidateLayout()
        self.collectionView.reloadData()
        self.invalidateIntrinsicContentSize()
        self.setNeedsLayout()
    }

    private func applyTableData(_ newValue: STMarkdownTableViewModel?) {
        let old = self.renderedTableData
        guard let newValue else {
            self.renderedTableData = nil
            self.reloadData()
            return
        }
        // 仅在「在屏 + 同一表格纯行追加 + 未处于动画中」时逐行淡入；其余一律 reloadData（崩溃安全）。
        if self.animatesRowAppends,
           !self.isApplyingAppend,
           self.window != nil,
           self.bounds.height > 0,
           let old,
           Self.isPureRowAppend(from: old, to: newValue) {
            self.animateRowAppend(from: old.rowCount, newData: newValue)
        } else {
            self.renderedTableData = newValue
            self.reloadData()
        }
    }

    /// new 是否为 old 的「纯行追加」：同列数、行数严格增多、且 old 的每一行内容未变。
    private static func isPureRowAppend(from old: STMarkdownTableViewModel, to new: STMarkdownTableViewModel) -> Bool {
        guard new.columnCount == old.columnCount, new.columnCount > 0 else { return false }
        guard new.rowCount > old.rowCount, old.rowCount > 0 else { return false }
        guard new.cells.count == new.rowCount, old.cells.count == old.rowCount else { return false }
        for row in 0..<old.rowCount {
            let oldRow = old.cells[row]
            let newRow = new.cells[row]
            guard oldRow.count == newRow.count else { return false }
            for col in 0..<oldRow.count where oldRow[col].attributedContent.string != newRow[col].attributedContent.string {
                return false
            }
        }
        return true
    }

    private func animateRowAppend(from oldRowCount: Int, newData: STMarkdownTableViewModel) {
        let targetRowCount = newData.rowCount
        self.isApplyingAppend = true
        self.gridLayout.animatesAppearingItemsFade = true
        self.collectionView.performBatchUpdates({
            // 在 block 内翻转底层数据：block 前 dataSource 仍返回旧行数，block 后返回新行数，
            // 与 insertSections 的增量一致，避免 NSInternalInconsistencyException。
            self.renderedTableData = newData
            self.gridLayout.invalidateLayout()
            self.collectionView.insertSections(IndexSet(integersIn: oldRowCount..<targetRowCount))
        }, completion: { [weak self] _ in
            guard let self else { return }
            self.isApplyingAppend = false
            self.gridLayout.animatesAppearingItemsFade = false
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        })
    }

    private func sizeForItem(at indexPath: IndexPath) -> CGSize {
        guard let tableData,
              indexPath.section < tableData.cells.count,
              indexPath.item < tableData.cells[indexPath.section].count else {
            return CGSize(width: 56, height: 35)
        }
        let cellData = tableData.cells[indexPath.section][indexPath.item]
        return STMarkdownTableCell.sizeThatFits(
            cellData: cellData,
            constrainedWidth: 360,
            contentInsets: self.cellInsets
        )
    }

    @objc private func handleExpandGesture(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        self.expandTableIfPossible()
    }

    private func expandTableIfPossible() {
        guard let tableData else { return }
        self.onExpandTable?(tableData)
    }

    @objc private func handleCopy() {
        guard let tableData else { return }
        UIPasteboard.general.string = tableData.plainText()
        self.onCopyTable?()
        self.showCopyFeedback()
    }

    @objc private func handleDownload() {
        guard let tableData else { return }
        self.onDownloadTable?(tableData)
    }

    @objc private func handleFullscreen() {
        self.expandTableIfPossible()
    }

    /// 复制成功后将图标临时切换为对勾，~1.2s 后还原，提供轻量内建反馈（无需宿主接线）。
    private func showCopyFeedback() {
        self.copyResetWorkItem?.cancel()
        self.copyButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
        let workItem = DispatchWorkItem { [weak self] in
            self?.copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        }
        self.copyResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
    }
}

extension STMarkdownTableView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let tableData,
              indexPath.section < tableData.cells.count,
              indexPath.item < tableData.cells[indexPath.section].count else { return }
        let citations = tableData.cells[indexPath.section][indexPath.item].citations
        if let first = citations.first {
            self.onCitationTap?(first)
            return
        }
        self.onExpandTable?(tableData)
    }
}

extension STMarkdownTableView: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        self.tableData?.rowCount ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.tableData?.columnCount ?? 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: STMarkdownTableCell.reuseIdentifier,
            for: indexPath
        )
        guard let cell = cell as? STMarkdownTableCell else {
            return cell
        }

        if let tableData,
           indexPath.section < tableData.cells.count,
           indexPath.item < tableData.cells[indexPath.section].count {
            let cellData = tableData.cells[indexPath.section][indexPath.item]
            cell.configure(with: cellData, style: self.style)
            cell.onCitationTap = { [weak self] number in
                self?.onCitationTap?(number)
            }
        }
        return cell
    }
}
