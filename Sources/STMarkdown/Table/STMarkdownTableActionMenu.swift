//
//  STMarkdownTableActionMenu.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/06/04.
//

import UIKit

public enum STMarkdownTableAction {
    case copyText
    case copyImage
    case saveImage
}

public enum STMarkdownTableActionMenuIcon {
    case systemName(String)
    case image(UIImage)
}

public struct STMarkdownTableActionMenuItem {
    public let title: String
    public let icon: STMarkdownTableActionMenuIcon
    public let action: STMarkdownTableAction

    public init(title: String, icon: STMarkdownTableActionMenuIcon, action: STMarkdownTableAction) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public static let defaultItems: [STMarkdownTableActionMenuItem] = [
        STMarkdownTableActionMenuItem(title: "复制", icon: .systemName("doc.on.doc"), action: .copyText),
        STMarkdownTableActionMenuItem(title: "复制为图片", icon: .systemName("photo"), action: .copyImage),
        STMarkdownTableActionMenuItem(title: "保存到相册", icon: .systemName("square.and.arrow.down"), action: .saveImage)
    ]
}

final class STMarkdownTableActionMenu: UIView {

    var onSelect: ((STMarkdownTableAction) -> Void)?

    private let card = UIView()
    private let style: STMarkdownStyle
    private let rowHeight: CGFloat = 52
    private let cardWidth: CGFloat = 200
    private let items: [STMarkdownTableActionMenuItem]

    init(style: STMarkdownStyle, items: [STMarkdownTableActionMenuItem] = STMarkdownTableActionMenuItem.defaultItems) {
        self.style = style
        self.items = items
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

            let iconView = UIImageView(image: item.icon.image)
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

    func present(in container: UIView, at point: CGPoint) {
        guard !self.items.isEmpty else { return }
        self.frame = container.bounds
        container.addSubview(self)
        let cardHeight = CGFloat(self.items.count) * self.rowHeight
        var originX = point.x
        var originY = point.y
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

private extension STMarkdownTableActionMenuIcon {
    var image: UIImage? {
        switch self {
        case .systemName(let name):
            return UIImage(systemName: name)
        case .image(let image):
            return image
        }
    }
}
