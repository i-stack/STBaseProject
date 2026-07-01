//
//  STStreamingMarkdownTableHostView.swift
//  STMarkdown
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit
import STBaseProject

public final class STStreamingMarkdownTableHostView: UIView {

    private let tableView: STMarkdownTableView
    private var cachedMeasure: (tableID: ObjectIdentifier, width: CGFloat, topInset: CGFloat, height: CGFloat)?
    public private(set) var maxUpdateDuration: CFTimeInterval = 0
    public private(set) var maxMeasureDuration: CFTimeInterval = 0

    /// 表格之前若有正文，给表格留出与最终 AST 一致的顶部间距。
    public var topInset: CGFloat = 0 {
        didSet {
            guard oldValue != self.topInset else { return }
            self.tableTopConstraint.constant = self.topInset
            self.cachedMeasure = nil
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }

    /// 宿主注入的实测渲染宽度，用于 intrinsicContentSize 的高度计算。
    public var preferredContentWidth: CGFloat = 0 {
        didSet {
            guard abs(oldValue - self.preferredContentWidth) > 0.5 else { return }
            self.invalidateIntrinsicContentSize()
        }
    }

    public var tableStyle: STMarkdownStyle {
        didSet {
            self.cachedMeasure = nil
            self.tableView.style = self.tableStyle
        }
    }

    public var onCitationTap: ((String) -> Void)? {
        didSet { self.tableView.onCitationTap = self.onCitationTap }
    }
    public var onExpandTable: ((STMarkdownTableViewModel) -> Void)? {
        didSet { self.tableView.onExpandTable = self.onExpandTable }
    }
    public var onDownloadTable: ((STMarkdownTableViewModel) -> Void)? {
        didSet { self.tableView.onDownloadTable = self.onDownloadTable }
    }

    private var tableTopConstraint: NSLayoutConstraint!

    public init(style: STMarkdownStyle) {
        self.tableStyle = style
        self.tableView = STMarkdownTableView(style: style)
        super.init(frame: .zero)
        self.backgroundColor = .clear
        self.tableView.animatesRowAppends = true
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.tableView)
        self.tableTopConstraint = self.tableView.topAnchor.constraint(equalTo: self.topAnchor, constant: self.topInset)
        NSLayoutConstraint.activate([
            self.tableTopConstraint,
            self.tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 当前是否承载有效表格数据。
    public var hasContent: Bool {
        guard let data = self.tableView.tableData else { return false }
        return data.rowCount > 0 && data.columnCount > 0
    }

    /// 行追加 / 当前 cell 追加 / 全量替换由 STMarkdownTableView 内部判定。
    public func update(tableData: STMarkdownTableViewModel?) {
        let startedAt = CACurrentMediaTime()
        defer {
            self.maxUpdateDuration = max(self.maxUpdateDuration, CACurrentMediaTime() - startedAt)
        }
        self.tableView.updateStreamingTableData(tableData)
        self.cachedMeasure = nil
        self.invalidateIntrinsicContentSize()
        self.setNeedsLayout()
    }

    public func clear() {
        self.tableView.tableData = nil
        self.cachedMeasure = nil
        self.maxUpdateDuration = 0
        self.maxMeasureDuration = 0
        self.invalidateIntrinsicContentSize()
    }

    /// 在给定宽度下测量宿主高度（含 topInset 与表格自身的 header）。供外部高度合算使用。
    public func measuredHeight(forWidth width: CGFloat) -> CGFloat {
        guard let data = self.tableView.tableData, data.rowCount > 0, data.columnCount > 0, width > 1 else {
            return 0
        }
        let tableID = ObjectIdentifier(data)
        if let cached = self.cachedMeasure,
           cached.tableID == tableID,
           abs(cached.width - width) < 0.5,
           abs(cached.topInset - self.topInset) < 0.5 {
            return cached.height
        }
        let startedAt = CACurrentMediaTime()
        defer {
            self.maxMeasureDuration = max(self.maxMeasureDuration, CACurrentMediaTime() - startedAt)
        }
        let size = STMarkdownTableView.computeSize(
            tableData: data,
            containerWidth: width,
            style: self.tableStyle
        )
        guard size.height > 0 else { return 0 }
        let height = ceil(size.height + self.topInset)
        self.cachedMeasure = (tableID: tableID, width: width, topInset: self.topInset, height: height)
        return height
    }

    public override var intrinsicContentSize: CGSize {
        let width = self.preferredContentWidth > 0 ? self.preferredContentWidth : self.bounds.width
        let height = self.measuredHeight(forWidth: width)
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
}
