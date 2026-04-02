//
//  STMarkdownTableCell.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

/// 表格 UICollectionView 的 cell，使用 UILabel 展示带样式的 NSAttributedString。
/// Citation badge 已作为内联 NSTextAttachment 嵌入 attributedContent，无需额外 UIButton 叠加。
public final class STMarkdownTableCell: UICollectionViewCell {

    static let reuseIdentifier = "STMarkdownTableCell"

    public var contentInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10) {
        didSet { self.setNeedsLayout() }
    }

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    var onCitationTap: ((String) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.contentLabel)
        self.contentView.clipsToBounds = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let insets = self.contentInsets
        self.contentLabel.frame = CGRect(
            x: insets.left,
            y: insets.top,
            width: self.contentView.bounds.width - insets.left - insets.right,
            height: self.contentView.bounds.height - insets.top - insets.bottom
        )
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        self.contentLabel.attributedText = nil
    }

    // MARK: - Configure

    func configure(with cellData: STMarkdownTableCellData, style: STMarkdownStyle) {
        self.contentLabel.attributedText = cellData.attributedContent

        let bgColor = style.tableBackgroundColor ?? UIColor.secondarySystemBackground
        self.contentView.backgroundColor = cellData.isHeader
            ? bgColor.withAlphaComponent(0.92)
            : bgColor
    }

    // MARK: - Static Size

    static func sizeThatFits(
        cellData: STMarkdownTableCellData,
        constrainedWidth: CGFloat,
        contentInsets: UIEdgeInsets
    ) -> CGSize {
        let textWidth = constrainedWidth - contentInsets.left - contentInsets.right
        guard textWidth > 0 else {
            return CGSize(width: constrainedWidth, height: contentInsets.top + contentInsets.bottom)
        }
        let boundingSize = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
        let textRect = cellData.attributedContent.boundingRect(
            with: boundingSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let width = min(constrainedWidth, ceil(textRect.width) + contentInsets.left + contentInsets.right)
        let height = ceil(textRect.height) + contentInsets.top + contentInsets.bottom
        return CGSize(width: width, height: height)
    }
}
