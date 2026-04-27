//
//  STCustomTabBar.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import UIKit

public protocol STCustomTabBarDelegate: AnyObject {
    func customTabBar(_ tabBar: STCustomTabBar, didSelectItemAt index: Int)
}

public class STCustomTabBar: UIView {
    
    public weak var delegate: STCustomTabBarDelegate?
    public var preferredLayoutHeight: CGFloat { self.config.height }
    
    @IBInspectable public var isLiquidGlassEnabled: Bool = false {
        didSet {
            self.updateLiquidGlassBackground()
        }
    }
    
    @IBInspectable public var liquidGlassTintColor: UIColor = UIColor.white.withAlphaComponent(0.18) {
        didSet {
            self.updateLiquidGlassBackground()
        }
    }
    
    @IBInspectable public var liquidGlassHighlightOpacity: Float = 0.35 {
        didSet {
            self.updateLiquidGlassBackground()
        }
    }
    
    @IBInspectable public var liquidGlassBorderColor: UIColor = UIColor.white.withAlphaComponent(0.35) {
        didSet {
            self.updateLiquidGlassBackground()
        }
    }
    
    private var selectedIndex: Int = 0
    private var itemViews: [STTabBarItemView] = []
    private var itemModels: [STTabBarItemModel] = []
    private var config: STTabBarConfig = STTabBarConfig()
    private var heightConstraint: NSLayoutConstraint?
    private var topBorderHeightConstraint: NSLayoutConstraint?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupUI()
    }
    
    private func setupUI() {
        self.clipsToBounds = false
        self.addSubview(self.backgroundImageView)
        self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.backgroundImageView.topAnchor.constraint(equalTo: topAnchor),
            self.backgroundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.backgroundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.backgroundImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        self.addSubview(self.contentView)
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.contentView.topAnchor.constraint(equalTo: topAnchor),
            self.contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        self.addSubview(self.topBorderView)
        self.topBorderView.translatesAutoresizingMaskIntoConstraints = false
        let borderHeight = self.topBorderView.heightAnchor.constraint(equalToConstant: self.config.topBorderWidth)
        self.topBorderHeightConstraint = borderHeight
        NSLayoutConstraint.activate([
            self.topBorderView.topAnchor.constraint(equalTo: topAnchor),
            self.topBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.topBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderHeight
        ])
        
        self.updateAppearance()
    }
    
    /// 配置 TabBar
    public func configure(items: [STTabBarItemModel], config: STTabBarConfig = STTabBarConfig()) {
        self.itemModels = items
        self.config = config
        self.clampSelectedIndexForCurrentItems()
        self.setupItems()
        self.updateAppearance()
    }
    
    public func setSelectedIndex(_ index: Int) {
        guard index >= 0, index < self.itemViews.count else { return }
        if self.selectedIndex < self.itemViews.count {
            self.itemViews[self.selectedIndex].updateSelection(false)
        }
        self.selectedIndex = index
        self.itemViews[self.selectedIndex].updateSelection(true)
    }
    
    public func updateBadgeCount(at index: Int, count: Int) {
        guard index >= 0, index < self.itemViews.count else { return }
        self.itemViews[index].updateBadgeCount(count)
    }
    
    public func updateConfig(_ config: STTabBarConfig) {
        self.config = config
        self.updateAppearance()
        self.itemViews.forEach { $0.reapplyTabBarConfig(config) }
    }
    
    public func st_setLiquidGlassBackground(
        tintColor: UIColor = UIColor.white.withAlphaComponent(0.18),
        highlightOpacity: Float = 0.35,
        borderColor: UIColor = UIColor.white.withAlphaComponent(0.35)
    ) {
        self.liquidGlassTintColor = tintColor
        self.liquidGlassHighlightOpacity = highlightOpacity
        self.liquidGlassBorderColor = borderColor
        self.isLiquidGlassEnabled = true
        self.updateLiquidGlassBackground()
    }
    
    public func getSelectedIndex() -> Int { self.selectedIndex }
    
    public func getItemCount() -> Int { self.itemModels.count }
    
    private func clampSelectedIndexForCurrentItems() {
        if self.itemModels.isEmpty {
            self.selectedIndex = 0
        } else {
            self.selectedIndex = min(self.selectedIndex, self.itemModels.count - 1)
        }
    }
    
    private func setupItems() {
        self.itemViews.forEach { $0.removeFromSuperview() }
        self.itemViews.removeAll()
        for (index, model) in self.itemModels.enumerated() {
            let itemView = STTabBarItemView()
            itemView.configure(with: model, config: self.config, isSelected: index == self.selectedIndex) { [weak self] in
                self?.handleItemTap(at: index)
            }
            contentView.addSubview(itemView)
            itemViews.append(itemView)
        }
        self.setupItemConstraints()
    }
    
    private func setupItemConstraints() {
        guard !self.itemViews.isEmpty else { return }
        for (index, itemView) in self.itemViews.enumerated() {
            let model = self.itemModels[index]
            itemView.translatesAutoresizingMaskIntoConstraints = false
            if model.isIrregular {
                let protrusion = model.irregular?.protrusionHeight ?? STTabBarIrregularStyle.standard.protrusionHeight
                NSLayoutConstraint.activate([
                    itemView.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor, constant: -protrusion / 2),
                    itemView.heightAnchor.constraint(equalToConstant: self.config.height + protrusion)
                ])
            } else {
                NSLayoutConstraint.activate([
                    itemView.topAnchor.constraint(equalTo: self.contentView.topAnchor),
                    itemView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor)
                ])
            }
            if index == 0 {
                itemView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
            } else {
                NSLayoutConstraint.activate([
                    itemView.leadingAnchor.constraint(equalTo: self.itemViews[index - 1].trailingAnchor),
                    itemView.widthAnchor.constraint(equalTo: self.itemViews[index - 1].widthAnchor)
                ])
            }
            if index == self.itemViews.count - 1 {
                itemView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
            }
        }
    }
    
    private func updateAppearance() {
        self.alpha = 1.0
        self.backgroundColor = self.config.backgroundColor
        if let image = self.config.backgroundImage {
            self.backgroundImageView.image = image
            self.backgroundImageView.isHidden = false
        } else {
            self.backgroundImageView.image = nil
            self.backgroundImageView.isHidden = true
        }
        if let existing = self.heightConstraint {
            existing.constant = self.config.height
        } else {
            let c = heightAnchor.constraint(equalToConstant: self.config.height)
            self.heightConstraint = c
            c.isActive = true
        }
        
        self.topBorderView.isHidden = !self.config.showTopBorder
        self.topBorderView.backgroundColor = self.config.topBorderColor
        self.topBorderHeightConstraint?.constant = self.config.topBorderWidth
        
        if self.config.showShadow {
            self.layer.shadowColor = self.config.shadowColor.cgColor
            self.layer.shadowOffset = self.config.shadowOffset
            self.layer.shadowRadius = self.config.shadowRadius
            self.layer.shadowOpacity = self.config.shadowOpacity
            self.layer.masksToBounds = false
        } else {
            self.layer.shadowOpacity = 0
        }
        self.updateLiquidGlassBackground()
    }
    
    private func updateLiquidGlassBackground() {
        guard self.isLiquidGlassEnabled else {
            self.st_disableLiquidGlassBackground()
            return
        }
        let glassView = self.st_enableLiquidGlassBackground(
            tintColor: self.liquidGlassTintColor,
            highlightOpacity: self.liquidGlassHighlightOpacity,
            borderColor: self.liquidGlassBorderColor
        )
        self.insertSubview(glassView, aboveSubview: self.backgroundImageView)
    }
    
    private func handleItemTap(at index: Int) {
        guard index != self.selectedIndex else { return }
        self.delegate?.customTabBar(self, didSelectItemAt: index)
    }
    
    private lazy var backgroundImageView: UIImageView = {
        let iv = UIImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleToFill
        iv.isHidden = true
        return iv
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.clipsToBounds = false
        return view
    }()
    
    private lazy var topBorderView: UIView = UIView()
}

extension STCustomTabBar {
    public static func createDefault(with items: [STTabBarItemModel]) -> STCustomTabBar {
        let tabBar = STCustomTabBar()
        tabBar.configure(items: items)
        return tabBar
    }
    
    public static func createSimple(titles: [String], normalImages: [UIImage?], selectedImages: [UIImage?]) -> STCustomTabBar {
        var items: [STTabBarItemModel] = []
        for i in 0..<titles.count {
            let model = STTabBarItemModel(title: titles[i], normalImage: i < normalImages.count ? normalImages[i] : nil, selectedImage: i < selectedImages.count ? selectedImages[i] : nil)
            items.append(model)
        }
        return createDefault(with: items)
    }
}
