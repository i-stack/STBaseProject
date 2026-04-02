//
//  STMarkdownTableViewAttachment.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

/// AST 模式下的表格 NSTextAttachment：持有一个真实的 STMarkdownTableView。
/// 类似 FluidMarkdown 的 AMTableViewAttachment 设计：
/// - image 返回 nil（view-based，不走 TextKit 绘制）
/// - attachmentBounds 返回 containerWidth × computedHeight 作为占位
/// - 由 MarkdownTextView 的 overlay 系统负责定位 tableView
public final class STMarkdownTableViewAttachment: NSTextAttachment {

    public let tableViewModel: STMarkdownTableViewModel
    public let style: STMarkdownStyle
    public let containerWidth: CGFloat
    public var onCitationTap: ((String) -> Void)?

    private var _tableView: STMarkdownTableView?
    private var cachedSize: CGSize?

    public var tableView: STMarkdownTableView {
        if let existing = self._tableView { return existing }
        let view = STMarkdownTableView(style: self.style)
        view.tableData = self.tableViewModel
        view.onCitationTap = { [weak self] number in
            self?.onCitationTap?(number)
        }
        self._tableView = view
        return view
    }

    public init(
        tableViewModel: STMarkdownTableViewModel,
        style: STMarkdownStyle,
        containerWidth: CGFloat
    ) {
        self.tableViewModel = tableViewModel
        self.style = style
        self.containerWidth = containerWidth
        super.init(data: nil, ofType: nil)
        self.image = nil
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var image: UIImage? {
        get { nil }
        set { super.image = nil }
    }

    public override func attachmentBounds(
        for textContainer: NSTextContainer?,
        proposedLineFragment lineFrag: CGRect,
        glyphPosition position: CGPoint,
        characterIndex charIndex: Int
    ) -> CGRect {
        if let cached = self.cachedSize {
            return CGRect(origin: .zero, size: cached)
        }
        let size = STMarkdownTableView.computeSize(
            tableData: self.tableViewModel,
            containerWidth: self.containerWidth,
            style: self.style
        )
        // 宽度取容器宽度（宽表由 collection view 水平滚动处理）
        let resultSize = CGSize(width: self.containerWidth, height: size.height)
        self.cachedSize = resultSize
        return CGRect(origin: .zero, size: resultSize)
    }
}
