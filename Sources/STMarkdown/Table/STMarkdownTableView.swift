//
//  STMarkdownTableView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

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

    /// Streaming path: update only appended rows or changed cells when the table shape is stable.
    /// Falls back to `tableData` assignment for all structural changes.
    public func updateStreamingTableData(_ newValue: STMarkdownTableViewModel?) {
        self.applyTableData(newValue, allowsCellDiff: true)
    }

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
    public static let headerHeight: CGFloat = 41
    /// 整块表格圆角半径。
    public var cornerRadius: CGFloat = 8 {
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
    private let headerSeparator = UIView()
    private var headerButtons: [(item: STMarkdownTableHeaderItem, button: UIButton)] = []
    private var copyResetWorkItem: DispatchWorkItem?
    private weak var expandGesture: UILongPressGestureRecognizer?

    /// 全屏详情态：开启上下/左右滚动条与回弹，并关闭内置「长按展开」手势（由详情页接管长按菜单）。
    public var isFullScreenPresentation: Bool = false {
        didSet {
            guard oldValue != self.isFullScreenPresentation else { return }
            let full = self.isFullScreenPresentation
            self.collectionView.showsVerticalScrollIndicator = full
            self.collectionView.bounces = full
            self.collectionView.alwaysBounceVertical = false
            self.expandGesture?.isEnabled = !full
        }
    }

    public init(style: STMarkdownStyle) {
        self.style = style
        self.gridLayout = STMarkdownTableGridLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.gridLayout)
        super.init(frame: .zero)
        self.clipsToBounds = true
        self.layer.cornerRadius = self.cornerRadius
        self.layer.borderWidth = 0.5
        if let mask = style.tableCornerMask as CACornerMask? {
            self.layer.maskedCorners = mask
        }
        self.gridLayout.minimumRowHeight = style.tableMinimumRowHeight
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
        self.expandGesture = expandGesture
        self.addSubview(self.collectionView)

        self.gridLayout.sizeForItem = { [weak self] indexPath in
            self?.sizeForItem(at: indexPath) ?? CGSize(width: 56, height: 35)
        }
    }

    private func setupHeader() {
        self.titleLabel.text = self.style.tableTitleText ?? "表格"
        self.titleLabel.font = self.style.tableTitleFont ?? UIFont.st_systemFont(ofSize: 14, weight: .medium)

        let items = self.style.tableHeaderItems?.isEmpty == false
            ? self.style.tableHeaderItems!
            : STMarkdownTableHeaderItem.defaultItems
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)

        for item in items {
            let button = UIButton(type: .system)
            button.setImage(item.image, for: .normal)
            button.setPreferredSymbolConfiguration(imageConfig, forImageIn: .normal)
            button.widthAnchor.constraint(equalToConstant: self.style.tableHeaderButtonWidth).isActive = true
            button.heightAnchor.constraint(equalToConstant: self.style.tableHeaderButtonHeight).isActive = true
            button.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                item.action(self)
            }, for: .touchUpInside)
            self.headerButtons.append((item: item, button: button))
            self.buttonStack.addArrangedSubview(button)
        }

        self.buttonStack.axis = .horizontal
        self.buttonStack.alignment = .center
        self.buttonStack.spacing = self.style.tableHeaderButtonSpacing

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
        self.gridLayout.minimumRowHeight = self.style.tableMinimumRowHeight
        self.layer.borderColor = borderColor.cgColor

        let headerBg = self.style.tableHeaderBarBackgroundColor
            ?? self.style.tableBackgroundColor
            ?? UIColor.secondarySystemBackground
        let secondaryColor = (self.style.tableTitleTextColor
            ?? self.style.tableHeaderTextColor
            ?? self.style.textColor).withAlphaComponent(0.6)
        self.headerBar.backgroundColor = headerBg
        self.headerSeparator.backgroundColor = borderColor
        self.titleLabel.textColor = secondaryColor
        self.titleLabel.font = self.style.tableTitleFont ?? UIFont.st_systemFont(ofSize: 14, weight: .medium)
        self.titleLabel.text = self.style.tableTitleText ?? "表格"
        for (_, button) in self.headerButtons {
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
        let width = self.bounds.width > 1 ? self.bounds.width : UIScreen.main.bounds.width
        return self.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
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
                minimumRowHeight: style.tableMinimumRowHeight,
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
        self.gridLayout.firstColumnRowGroups = self.makeFirstColumnRowGroupsForLayout(from: self.renderedTableData)
        self.gridLayout.invalidateLayout()
        self.collectionView.reloadData()
        self.invalidateIntrinsicContentSize()
        self.setNeedsLayout()
    }

    private func applyTableData(_ newValue: STMarkdownTableViewModel?, allowsCellDiff: Bool = false) {
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
           Self.isPureRowAppend(from: old, to: newValue),
           Self.appendKeepsExistingRowGroupsStable(from: old, to: newValue) {
            self.animateRowAppend(from: old.rowCount, newData: newValue)
        } else if allowsCellDiff,
                  self.window != nil,
                  self.bounds.height > 0,
                  let old,
                  Self.hasStableLayoutShape(from: old, to: newValue),
                  let changedIndexPaths = Self.changedCellIndexPathsForStableShape(from: old, to: newValue) {
            self.renderedTableData = newValue
            self.gridLayout.firstColumnRowGroups = self.makeFirstColumnRowGroupsForLayout(from: newValue)
            guard !changedIndexPaths.isEmpty else { return }
            UIView.performWithoutAnimation {
                self.collectionView.reloadItems(at: changedIndexPaths)
                self.gridLayout.invalidateLayout()
                self.collectionView.layoutIfNeeded()
            }
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        } else {
            self.renderedTableData = newValue
            if allowsCellDiff, self.window != nil {
                self.reloadDataWithoutAnimation()
            } else {
                self.reloadData()
            }
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

    private static func changedCellIndexPathsForStableShape(from old: STMarkdownTableViewModel, to new: STMarkdownTableViewModel) -> [IndexPath]? {
        guard new.columnCount == old.columnCount,
              new.rowCount == old.rowCount,
              new.columnCount > 0,
              new.cells.count == old.cells.count else {
            return nil
        }
        var changed: [IndexPath] = []
        for row in 0..<old.rowCount {
            guard row < old.cells.count, row < new.cells.count else { return nil }
            let oldRow = old.cells[row]
            let newRow = new.cells[row]
            guard oldRow.count == newRow.count else { return nil }
            for col in 0..<oldRow.count {
                let oldText = oldRow[col].attributedContent.string
                let newText = newRow[col].attributedContent.string
                if oldText != newText {
                    guard newText.hasPrefix(oldText) else { return nil }
                    changed.append(IndexPath(item: col, section: row))
                }
            }
        }
        return changed
    }

    private static func hasStableLayoutShape(from old: STMarkdownTableViewModel, to new: STMarkdownTableViewModel) -> Bool {
        old.hasHeader == new.hasHeader
            && old.columnCount == new.columnCount
            && old.rowCount == new.rowCount
            && old.rowGroups == new.rowGroups
    }

    private static func appendKeepsExistingRowGroupsStable(from old: STMarkdownTableViewModel, to new: STMarkdownTableViewModel) -> Bool {
        guard old.hasHeader == new.hasHeader,
              new.rowCount > old.rowCount else {
            return false
        }
        return !new.rowGroups.contains { group in
            group.contains { $0 < old.rowCount } && group.contains { $0 >= old.rowCount }
        }
    }

    private func reloadDataWithoutAnimation() {
        UIView.performWithoutAnimation {
            self.reloadData()
            self.collectionView.layoutIfNeeded()
            self.layoutIfNeeded()
        }
    }

    private func animateRowAppend(from oldRowCount: Int, newData: STMarkdownTableViewModel) {
        let targetRowCount = newData.rowCount
        self.isApplyingAppend = true
        self.gridLayout.animatesAppearingItemsFade = true
        self.collectionView.performBatchUpdates({
            // 在 block 内翻转底层数据：block 前 dataSource 仍返回旧行数，block 后返回新行数，
            // 与 insertSections 的增量一致，避免 NSInternalInconsistencyException。
            self.renderedTableData = newData
            self.gridLayout.firstColumnRowGroups = self.makeFirstColumnRowGroupsForLayout(from: newData)
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

    private func makeFirstColumnRowGroupsForLayout(from tableData: STMarkdownTableViewModel?) -> [[Int]] {
        guard let tableData else { return [] }
        let rowOffset = tableData.hasHeader ? 1 : 0
        return tableData.rowGroups.map { group in
            group.compactMap { row in
                let section = row + rowOffset
                return section >= 0 && section < tableData.rowCount ? section : nil
            }
        }
        .filter { $0.count > 1 }
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

    /// 将整张表格（含离屏行列）渲染为图片，供「复制为图片 / 保存到相册」使用。
    /// 注意：会临时把 collectionView 放大到完整 contentSize 强制生成全部 cell 再渲染，渲染后还原。
    public func renderFullTableImage() -> UIImage? {
        guard self.tableData != nil else { return nil }
        self.collectionView.layoutIfNeeded()
        let contentSize = self.collectionView.collectionViewLayout.collectionViewContentSize
        guard contentSize.width > 0, contentSize.height > 0 else { return nil }

        let savedFrame = self.collectionView.frame
        let savedOffset = self.collectionView.contentOffset
        self.collectionView.frame = CGRect(origin: .zero, size: contentSize)
        self.collectionView.setContentOffset(.zero, animated: false)
        self.collectionView.layoutIfNeeded()

        let borderColor = self.style.tableBorderColor ?? UIColor.separator
        let renderer = UIGraphicsImageRenderer(size: contentSize)
        let image = renderer.image { context in
            borderColor.setFill()
            context.fill(CGRect(origin: .zero, size: contentSize))
            self.collectionView.layer.render(in: context.cgContext)
        }

        self.collectionView.frame = savedFrame
        self.collectionView.setContentOffset(savedOffset, animated: false)
        self.collectionView.layoutIfNeeded()
        return image
    }

    /// 复制成功后将图标临时切换为对勾，~1.2s 后还原，提供轻量内建反馈（无需宿主接线）。
    /// 仅对 `identifier == "copy"` 的按钮生效；若无匹配按钮则静默跳过。
    public func showCopyFeedback() {
        guard let entry = self.headerButtons.first(where: { $0.item.identifier == "copy" }) else { return }
        self.copyResetWorkItem?.cancel()
        entry.button.setImage(UIImage(systemName: "checkmark"), for: .normal)
        let workItem = DispatchWorkItem { [weak button = entry.button, image = entry.item.image] in
            button?.setImage(image, for: .normal)
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
