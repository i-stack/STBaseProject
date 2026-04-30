//
//  STScrollableTableAttachment.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

/// 用于可水平滑动 Markdown 表格的 NSTextAttachment 子类。
///
/// TextKit 测量时返回 containerWidth × 等比高度 作为占位尺寸，
/// 避免超宽图片撑破 UITextView 布局；实际完整宽度的表格图片由
/// 业务层视图中的 overlay UIScrollView 负责展示。
public final class STScrollableTableAttachment: NSTextAttachment {

    public let tableImage: UIImage
    public let containerWidth: CGFloat
    public let backgroundColor: UIColor?
    /// 表格图片中 Citation 角标的位置列表，供 overlay 层叠加可点击按钮
    public let citationRegions: [STTableCitationRegion]

    public init(
        tableImage: UIImage,
        containerWidth: CGFloat,
        backgroundColor: UIColor? = nil,
        citationRegions: [STTableCitationRegion] = []
    ) {
        self.tableImage = tableImage
        self.containerWidth = containerWidth
        self.backgroundColor = backgroundColor
        self.citationRegions = citationRegions
        super.init(data: nil, ofType: nil)
        // 将 image 设为 nil，防止 TextKit 用原始超宽图片直接绘制导致”背景占位图”残留
        self.image = nil
    }

    /// 强制返回 nil，确保 TextKit 渲染路径完全不绘制背景，由应用层 UIScrollView 提供背景色
    public override var image: UIImage? {
        get { return nil }
        set { super.image = nil }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// TextKit 向此方法询问附件在 line fragment 中的尺寸。
    /// 返回 containerWidth × 等比缩放后的高度，保证 UITextView 高度测量正确，
    /// 同时保证占位宽度不超出容器（避免触发 UITextView 横向扩展）。
    public override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let imageSize = tableImage.size
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGRect(origin: .zero, size: CGSize(width: containerWidth, height: 44))
        }
        // 宽度固定为容器宽度，高度采用图片自然高度（不再按比例缩小），以防止垂直滚动并保持排版正确。
        return CGRect(origin: .zero, size: CGSize(width: containerWidth, height: imageSize.height))
    }
}
