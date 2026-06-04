//
//  STMarkdownTableActionMenu.swift
//  STBaseProject
//
//  Created by Codex on 2026/06/04.
//

import UIKit

/// 表格长按浮层菜单：复制 / 复制为图片 / 保存到相册。
/// 圆角卡片 + 竖排「标题 + 图标」行，点击外部或选项后自动消失。
final class STMarkdownTableActionMenu: UIView {

    enum Action {
        case copyText
        case copyImage
        case saveImage
    }

    var onSelect: ((Action) -> Void)?

    private let style: STMarkdownStyle
    private let card = UIView()
    private let rowHeight: CGFloat = 52
    private let cardWidth: CGFloat = 200

    private let items: [(title: String, icon: String, action: Action)] = [
        ("复制", "doc.on.doc", .copyText),
        ("复制为图片", "photo", .copyImage),
        ("保存到相册", "square.and.arrow.down", .saveImage)
    ]

    init(style: STMarkdownStyle) {
        self.style = style
        super.init(frame: .zero)
        self.setupCard()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCard() {
        self.backgroundColor = .clear

        self.card.backgroundColor = self.style.tableBackgroundColor ?? UIColor.secondarySystemBackground
        self.card.layer.cornerRadius = 14
        self.card.layer.shadowColor = UIColor.black.cgColor
        self.card.layer.shadowOpacity = 0.18
        self.card.layer.shadowRadius = 16
        self.card.layer.shadowOffset = CGSize(width: 0, height: 6)
        self.addSubview(self.card)

        let separatorColor = self.style.tableBorderColor ?? UIColor.separator
        let textColor = self.style.textColor

        for (index, item) in self.items.enumerated() {
            let row = UIControl()
            row.tag = index
            row.isAccessibilityElement = true
            row.accessibilityLabel = item.title
            row.accessibilityTraits = .button
            row.addTarget(self, action: #selector(self.handleRowTap(_:)), for: .touchUpInside)
            row.frame = CGRect(x: 0, y: CGFloat(index) * self.rowHeight, width: self.cardWidth, height: self.rowHeight)

            let titleLabel = UILabel()
            titleLabel.text = item.title
            titleLabel.font = UIFont.st_systemFont(ofSize: 16, weight: .regular)
            titleLabel.textColor = textColor
            titleLabel.frame = CGRect(x: 18, y: 0, width: self.cardWidth - 18 - 48, height: self.rowHeight)
            row.addSubview(titleLabel)

            let iconView = UIImageView(image: UIImage(systemName: item.icon))
            iconView.tintColor = textColor
            iconView.contentMode = .scaleAspectFit
            iconView.frame = CGRect(x: self.cardWidth - 18 - 22, y: (self.rowHeight - 22) / 2, width: 22, height: 22)
            row.addSubview(iconView)

            if index < self.items.count - 1 {
                let line = UIView(frame: CGRect(x: 16, y: self.rowHeight - 0.5, width: self.cardWidth - 32, height: 0.5))
                line.backgroundColor = separatorColor.withAlphaComponent(0.5)
                row.addSubview(line)
            }
            self.card.addSubview(row)
        }
    }

    /// 在 container 内、长按点附近弹出，并对 container 全屏铺一层透明遮罩用于点击外部关闭。
    func present(in container: UIView, at point: CGPoint) {
        self.frame = container.bounds
        container.addSubview(self)

        let cardHeight = CGFloat(self.items.count) * self.rowHeight
        var originX = point.x
        var originY = point.y
        // 防止越界
        originX = min(max(8, originX), container.bounds.width - self.cardWidth - 8)
        originY = min(max(8, originY), container.bounds.height - cardHeight - 8)
        self.card.frame = CGRect(x: originX, y: originY, width: self.cardWidth, height: cardHeight)

        self.card.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        self.card.alpha = 0
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
            self.card.transform = .identity
            self.card.alpha = 1
        }
    }

    @objc private func handleRowTap(_ sender: UIControl) {
        guard sender.tag < self.items.count else { return }
        let action = self.items[sender.tag].action
        self.dismiss { [weak self] in
            self?.onSelect?(action)
        }
    }

    private func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.12, animations: {
            self.card.alpha = 0
            self.card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: { _ in
            self.removeFromSuperview()
            completion?()
        })
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 点击卡片外部关闭
        if let touch = touches.first {
            let location = touch.location(in: self)
            if !self.card.frame.contains(location) {
                self.dismiss()
                return
            }
        }
        super.touchesBegan(touches, with: event)
    }
}
