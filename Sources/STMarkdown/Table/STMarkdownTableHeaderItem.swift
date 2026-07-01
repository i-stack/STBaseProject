//
//  STMarkdownTableHeaderItem.swift
//  STBaseProject
//

import UIKit

/// 表格顶部工具条的操作按钮配置项。
/// 通过 `tableHeaderItems` 即可自定义展示哪些按钮、图标以及回调逻辑。
public struct STMarkdownTableHeaderItem: @unchecked Sendable {
    /// 按钮标识，`"copy"` 的按钮在复制成功后会短暂切换为对勾图标以提供内建反馈。
    public let identifier: String
    /// 按钮图标（nil 时按钮仍会占位但不显示图标）。
    public let image: UIImage?
    /// 按钮点击回调，宿主可在此访问 `STMarkdownTableView` 来操作表格数据。
    public let action: (STMarkdownTableView) -> Void

    public init(
        identifier: String,
        image: UIImage?,
        action: @escaping (STMarkdownTableView) -> Void
    ) {
        self.identifier = identifier
        self.image = image
        self.action = action
    }
}

extension STMarkdownTableHeaderItem {
    /// 内建「复制」按钮：将表格纯文本复制到剪贴板并播放反馈。
    public static func copyItem(image: UIImage? = UIImage(systemName: "doc.on.doc")) -> STMarkdownTableHeaderItem {
        STMarkdownTableHeaderItem(identifier: "copy", image: image) { tableView in
            guard let tableData = tableView.tableData else { return }
            UIPasteboard.general.string = tableData.plainText()
            tableView.onCopyTable?()
            tableView.showCopyFeedback()
        }
    }

    /// 内建「下载」按钮：触发 `onDownloadTable` 回调。
    public static func downloadItem(image: UIImage? = UIImage(systemName: "square.and.arrow.down")) -> STMarkdownTableHeaderItem {
        STMarkdownTableHeaderItem(identifier: "download", image: image) { tableView in
            guard let tableData = tableView.tableData else { return }
            tableView.onDownloadTable?(tableData)
        }
    }

    /// 内建「全屏」按钮：触发 `onExpandTable` 回调。
    public static func fullscreenItem(image: UIImage? = UIImage(systemName: "arrow.up.left.and.arrow.down.right")) -> STMarkdownTableHeaderItem {
        STMarkdownTableHeaderItem(identifier: "fullscreen", image: image) { tableView in
            guard let tableData = tableView.tableData else { return }
            tableView.onExpandTable?(tableData)
        }
    }

    /// 默认三个按钮集合：复制、下载、全屏。
    public static var defaultItems: [STMarkdownTableHeaderItem] {
        [.copyItem(), .downloadItem(), .fullscreenItem()]
    }
}
