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

    public var tableData: STMarkdownTableViewModel? {
        didSet { self.reloadData() }
    }

    public var style: STMarkdownStyle = .default {
        didSet { self.applyStyle(); self.reloadData() }
    }

    public var onCitationTap: ((String) -> Void)?

    private let gridLayout: STMarkdownTableGridLayout
    private let collectionView: UICollectionView

    private let cellInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)

    // MARK: - Init

    public init(style: STMarkdownStyle) {
        self.style = style
        self.gridLayout = STMarkdownTableGridLayout()
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.gridLayout)
        super.init(frame: .zero)
        self.setupCollectionView()
        self.applyStyle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupCollectionView() {
        self.collectionView.register(STMarkdownTableCell.self, forCellWithReuseIdentifier: STMarkdownTableCell.reuseIdentifier)
        self.collectionView.dataSource = self
        self.collectionView.bounces = false
        self.collectionView.alwaysBounceHorizontal = false
        self.collectionView.alwaysBounceVertical = false
        self.collectionView.showsHorizontalScrollIndicator = true
        self.collectionView.showsVerticalScrollIndicator = false
        self.collectionView.isScrollEnabled = true
        self.collectionView.scrollsToTop = false
        self.collectionView.contentInset = .zero
        self.addSubview(self.collectionView)

        self.gridLayout.sizeForItem = { [weak self] indexPath in
            self?.sizeForItem(at: indexPath) ?? CGSize(width: 56, height: 35)
        }
    }

    private func applyStyle() {
        let borderColor = self.style.tableBorderColor ?? UIColor.separator
        self.collectionView.backgroundColor = borderColor
        self.backgroundColor = borderColor
        self.gridLayout.interItemSpacing = 0.5
        self.gridLayout.lineSpacing = 0.5
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.collectionView.frame != self.bounds {
            self.collectionView.frame = self.bounds
        }
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let tableData, tableData.rowCount > 0, tableData.columnCount > 0 else { return .zero }
        return Self.computeSize(tableData: tableData, containerWidth: size.width, style: self.style, cellInsets: self.cellInsets)
    }

    public override var intrinsicContentSize: CGSize {
        self.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
    }

    // MARK: - Static Size Computation

    public static func computeSize(
        tableData: STMarkdownTableViewModel,
        containerWidth: CGFloat,
        style: STMarkdownStyle,
        cellInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
    ) -> CGSize {
        STMarkdownTableGridLayout.computeSize(
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
            fillWidth: true,
            containerWidth: containerWidth,
            minimumRowHeight: 35,
            minimumColumnWidth: 56,
            maximumColumnWidth: 360,
            interItemSpacing: 0.5,
            lineSpacing: 0.5
        )
    }

    // MARK: - Private

    private func reloadData() {
        self.gridLayout.invalidateLayout()
        self.collectionView.reloadData()
        self.invalidateIntrinsicContentSize()
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
}

// MARK: - UICollectionViewDataSource

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
        ) as! STMarkdownTableCell

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
