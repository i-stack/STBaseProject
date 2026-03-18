//
//  STStaticTableAttachment.swift
//  STBaseProject
//

import UIKit

/// 非滚动表格的 NSTextAttachment 子类，携带 Citation 角标位置信息。
/// 用于在 MarkdownTextView 中叠加可点击的透明 UIButton 覆盖层。
public final class STStaticTableAttachment: NSTextAttachment {
    public let tableImage: UIImage
    public let citationRegions: [STTableCitationRegion]

    public init(tableImage: UIImage, displayBounds: CGRect, citationRegions: [STTableCitationRegion]) {
        self.tableImage = tableImage
        self.citationRegions = citationRegions
        super.init(data: nil, ofType: nil)
        self.image = tableImage
        self.bounds = displayBounds
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
