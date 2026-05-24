//
//  STMarkdownTableAttachmentRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public struct STMarkdownTableAttachmentRenderer: STMarkdownTableRendering {

    public var advancedRenderers: STMarkdownAdvancedRenderers
    public var onExpandTable: ((STMarkdownTableViewModel) -> Void)?

    public init(advancedRenderers: STMarkdownAdvancedRenderers = .empty, onExpandTable: ((STMarkdownTableViewModel) -> Void)? = nil) {
        self.advancedRenderers = advancedRenderers
        self.onExpandTable = onExpandTable
    }

    public func renderTable(_ table: STMarkdownTableModel, style: STMarkdownStyle) -> NSAttributedString? {
        guard (table.header != nil && !table.header!.isEmpty) || !table.rows.isEmpty else { return nil }
        let containerWidth = style.renderWidth
        let viewModel = STMarkdownTableViewModel(from: table, style: style, advancedRenderers: self.advancedRenderers)
        let attachment = STMarkdownTableViewAttachment(tableViewModel: viewModel, style: style, containerWidth: containerWidth > 0 ? containerWidth : 300)
        attachment.onExpandTable = self.onExpandTable
        return NSAttributedString(attachment: attachment)
    }
}
