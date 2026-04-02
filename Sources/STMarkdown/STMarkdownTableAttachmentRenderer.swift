//
//  STMarkdownTableAttachmentRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public struct STMarkdownTableAttachmentRenderer: STMarkdownTableRendering {

    /// 用于构建 STMarkdownTableViewModel 时传入的 advancedRenderers（主要为 inlineMath 渲染）
    public var advancedRenderers: STMarkdownAdvancedRenderers

    public init(advancedRenderers: STMarkdownAdvancedRenderers = .empty) {
        self.advancedRenderers = advancedRenderers
    }

    @available(*, deprecated, message: "forceStaticTable is no longer used; tables always render as UICollectionView")
    public init(forceStaticTable: Bool, advancedRenderers: STMarkdownAdvancedRenderers = .empty) {
        self.advancedRenderers = advancedRenderers
    }

    public func renderTable(_ table: STMarkdownTableModel, style: STMarkdownStyle) -> NSAttributedString? {
        guard (table.header != nil && !table.header!.isEmpty) || !table.rows.isEmpty else { return nil }

        let containerWidth = style.renderWidth
        let viewModel = STMarkdownTableViewModel(
            from: table,
            style: style,
            advancedRenderers: self.advancedRenderers
        )

        let attachment = STMarkdownTableViewAttachment(
            tableViewModel: viewModel,
            style: style,
            containerWidth: containerWidth > 0 ? containerWidth : 300
        )
        return NSAttributedString(attachment: attachment)
    }
}
