//
//  STTabBarItemView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import UIKit

public class STTabBarItemView: UIView {
    
    private var itemModel: STTabBarItemModel?
    private var config: STTabBarConfig?
    private var isSelected: Bool = false
    private var tapAction: (() -> Void)?
    private var iconImageViewConstraints: [NSLayoutConstraint] = []
    private var titleLabelConstraints: [NSLayoutConstraint] = []
    private var initialConstraints: [NSLayoutConstraint] = []
    private var lastEffectiveBarHeightUsed: CGFloat = -1
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupUI()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let model = self.itemModel, model.displayMode == .imageAndText else { return }
        let eff = self.effectiveBarHeightForImageTextLayout()
        if abs(eff - self.lastEffectiveBarHeightUsed) > 0.5 {
            self.lastEffectiveBarHeightUsed = eff
            self.updateUI()
        }
    }
    
    private func setupUI() {
        self.addSubview(self.iconImageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.badgeLabel)
        self.addSubview(self.customContainerView)
        self.iconImageView.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        self.customContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.setupInitialConstraints()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tapGesture)
    }
    
    private func setupInitialConstraints() {
        NSLayoutConstraint.deactivate(self.initialConstraints)
        self.initialConstraints.removeAll()
        // 设置初始约束（默认图文模式）
        self.initialConstraints = [
            // iconImageView 初始约束
            self.iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            self.iconImageView.widthAnchor.constraint(equalToConstant: 24),
            self.iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // titleLabel 初始约束
            self.titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.titleLabel.topAnchor.constraint(equalTo: self.iconImageView.bottomAnchor, constant: 2),
            self.titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            self.titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            self.titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6),
            
            // badgeLabel 约束
            self.badgeLabel.topAnchor.constraint(equalTo: self.iconImageView.topAnchor, constant: -4),
            self.badgeLabel.trailingAnchor.constraint(equalTo: self.iconImageView.trailingAnchor, constant: 4),
            self.badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),
            self.badgeLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16),
            
            // customContainerView 约束
            self.customContainerView.topAnchor.constraint(equalTo: topAnchor),
            self.customContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.customContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.customContainerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(self.initialConstraints)
    }
    
    /// 配置 TabBar Item
    /// - Parameters:
    ///   - model: Item 数据模型
    ///   - config: TabBar 配置
    ///   - isSelected: 是否选中
    ///   - tapAction: 点击回调
    public func configure(with model: STTabBarItemModel, config: STTabBarConfig? = nil, isSelected: Bool = false, tapAction: (() -> Void)? = nil) {
        self.itemModel = model
        self.config = config
        self.isSelected = isSelected
        self.tapAction = tapAction
        self.lastEffectiveBarHeightUsed = -1
        self.updateUI()
    }
    
    /// Tab 栏整体配置变更后由 `STCustomTabBar.updateConfig` 调用，使内部布局使用最新的 `config`（`STTabBarConfig` 为值类型，需主动同步）
    public func reapplyTabBarConfig(_ config: STTabBarConfig) {
        self.config = config
        self.lastEffectiveBarHeightUsed = -1
        guard self.itemModel != nil else { return }
        self.updateUI()
    }
    
    /// 更新选中状态
    /// - Parameter selected: 是否选中
    public func updateSelection(_ selected: Bool) {
        guard self.isSelected != selected else { return }
        self.isSelected = selected
        if let config = config, config.enableAnimation {
            self.animateSelection(selected)
        } else {
            self.updateUI()
        }
    }
    
    /// 更新徽章数量
    /// - Parameter count: 徽章数量
    public func updateBadgeCount(_ count: Int) {
        guard let model = self.itemModel else { return }
        var updatedModel = model
        updatedModel.badge.count = count
        self.itemModel = updatedModel
        self.updateBadgeUI()
    }
    
    private func updateUI() {
        guard let model = self.itemModel else { return }

        NSLayoutConstraint.deactivate(self.initialConstraints)
        NSLayoutConstraint.deactivate(self.iconImageViewConstraints)
        NSLayoutConstraint.deactivate(self.titleLabelConstraints)
        
        self.initialConstraints.removeAll()
        self.iconImageViewConstraints.removeAll()
        self.titleLabelConstraints.removeAll()
        
        switch model.displayMode {
        case .imageOnly:
            self.setupImageOnlyMode(model)
        case .textOnly:
            self.setupTextOnlyMode(model)
        case .imageAndText:
            self.setupImageAndTextMode(model)
        case .custom:
            self.setupCustomMode(model)
        case .irregular:
            self.setupIrregularMode(model)
        }
        
        self.updateBadgeUI()
        self.updateCustomView()
    }
    
    private enum ImageAndTextMetrics {
        static let titleGap: CGFloat = 2
        static let bottomPadding: CGFloat = 6
    }
    
    /// 单行标题占用高度（用于在固定 TabBar 高度内分配图标与「距顶」）
    private func titleLineHeight(for model: STTabBarItemModel) -> CGFloat {
        let font = UIFont(name: model.typography.fontName, size: model.typography.fontSize) ?? UIFont.st_systemFont(ofSize: model.typography.fontSize, weight: .medium)
        return ceil(font.lineHeight)
    }
    
    /// 图文排版可用高度：`config.height` 与父视图（contentView）实际高度取较小，避免配置值与约束高度不一致时仍按大值排版
    private func effectiveBarHeightForImageTextLayout() -> CGFloat {
        let configured = self.config?.height ?? 49
        guard let superview = self.superview else { return max(1, configured) }
        let measured = superview.bounds.height
        if measured > 0.5 {
            return max(1, min(configured, measured))
        }
        return max(1, configured)
    }
    
    /// 将 `imageTopInset`、图标尺寸约束在可用高度内，避免 Auto Layout 无法同时满足
    private func resolvedImageAndTextLayout(for model: STTabBarItemModel) -> (topInset: CGFloat, iconWidth: CGFloat, iconHeight: CGFloat) {
        let barH = self.effectiveBarHeightForImageTextLayout()
        let baseW = model.layout.imageSize?.width ?? 24
        let baseH = model.layout.imageSize?.height ?? 24
        let titleH = self.titleLineHeight(for: model)
        let fixedTail = ImageAndTextMetrics.titleGap + titleH + ImageAndTextMetrics.bottomPadding
        let maxTop = barH - fixedTail - baseH
        let top = min(model.layout.imageTopInset, max(0, maxTop))
        var iconW = baseW
        var iconH = baseH
        let total = top + iconH + ImageAndTextMetrics.titleGap + titleH + ImageAndTextMetrics.bottomPadding
        if total > barH {
            let iconBudget = max(1, barH - top - fixedTail)
            let scale = min(1, iconBudget / baseH)
            iconH = baseH * scale
            iconW = baseW * scale
        }
        return (top, iconW, iconH)
    }
    
    private func setupImageOnlyMode(_ model: STTabBarItemModel) {
        // 只显示图片
        self.iconImageView.isHidden = false
        self.titleLabel.isHidden = true
        self.iconImageView.image = self.isSelected ? model.selectedImage : model.normalImage
        self.backgroundColor = self.isSelected ? model.colors.selectedBackground : model.colors.normalBackground
        self.alpha = self.isSelected ? 1.0 : (self.config?.unselectedAlpha ?? 0.7)
        
        // 图片居中显示
        self.iconImageViewConstraints = [
            self.iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            self.iconImageView.widthAnchor.constraint(equalToConstant: model.layout.imageSize?.width ?? 24),
            self.iconImageView.heightAnchor.constraint(equalToConstant: model.layout.imageSize?.height ?? 24)
        ]
        NSLayoutConstraint.activate(self.iconImageViewConstraints)
    }
    
    private func setupTextOnlyMode(_ model: STTabBarItemModel) {
        // 只显示文字
        self.iconImageView.isHidden = true
        self.titleLabel.isHidden = false
        self.titleLabel.text = model.title
        self.titleLabel.textColor = self.isSelected ? model.colors.selectedText : model.colors.normalText
        let font = UIFont(name: model.typography.fontName, size: model.typography.fontSize) ?? UIFont.st_systemFont(ofSize: model.typography.fontSize, weight: .medium)
        self.titleLabel.font = font
        self.backgroundColor = self.isSelected ? model.colors.selectedBackground : model.colors.normalBackground
        self.alpha = self.isSelected ? 1.0 : (self.config?.unselectedAlpha ?? 0.7)

        // 文字居中显示
        self.titleLabelConstraints = [
            self.titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            self.titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            self.titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4)
        ]
        NSLayoutConstraint.activate(self.titleLabelConstraints)
    }
    
    private func setupImageAndTextMode(_ model: STTabBarItemModel) {
        // 显示图片和文字（默认模式）
        self.iconImageView.isHidden = false
        self.titleLabel.isHidden = false
        
        self.iconImageView.image = isSelected ? model.selectedImage : model.normalImage
        self.titleLabel.text = model.title
        self.titleLabel.textColor = self.isSelected ? model.colors.selectedText : model.colors.normalText
        let font = UIFont(name: model.typography.fontName, size: model.typography.fontSize) ?? UIFont.st_systemFont(ofSize: model.typography.fontSize, weight: .medium)
        self.titleLabel.font = font
        self.backgroundColor = isSelected ? model.colors.selectedBackground : model.colors.normalBackground
        self.alpha = self.isSelected ? 1.0 : (self.config?.unselectedAlpha ?? 0.7)

        let layout = self.resolvedImageAndTextLayout(for: model)
        // 图片在上，文字在下（距顶 + 图标 + 标题总高度不超过 TabBar，避免与固定高度冲突）
        self.iconImageViewConstraints = [
            self.iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: layout.topInset),
            self.iconImageView.widthAnchor.constraint(equalToConstant: layout.iconWidth),
            self.iconImageView.heightAnchor.constraint(equalToConstant: layout.iconHeight)
        ]
        NSLayoutConstraint.activate(self.iconImageViewConstraints)
        
        self.titleLabelConstraints = [
            self.titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.titleLabel.topAnchor.constraint(equalTo: self.iconImageView.bottomAnchor, constant: 2),
            self.titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            self.titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            self.titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6)
        ]
        NSLayoutConstraint.activate(self.titleLabelConstraints)
    }
    
    private func setupCustomMode(_ model: STTabBarItemModel) {
        // 自定义视图模式
        self.iconImageView.isHidden = true
        self.titleLabel.isHidden = true
        self.customContainerView.isHidden = false
        self.backgroundColor = .clear
        self.alpha = 1.0
    }
    
    private func setupIrregularMode(_ model: STTabBarItemModel) {
        // 不规则（凸起）按钮模式
        self.iconImageView.isHidden = false
        self.titleLabel.isHidden = false
        self.iconImageView.image = self.isSelected ? model.selectedImage : model.normalImage
        self.titleLabel.text = model.title
        self.titleLabel.textColor = model.colors.normalText
        let font = UIFont(name: model.typography.fontName, size: model.typography.fontSize) ?? UIFont.st_systemFont(ofSize: model.typography.fontSize, weight: .medium)
        self.titleLabel.font = font

        // 设置不规则按钮样式（去掉背景颜色）
        self.backgroundColor = .clear
        self.layer.cornerRadius = 0
        self.layer.shadowColor = UIColor.clear.cgColor
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 0
        self.layer.shadowOpacity = 0
        self.alpha = 1.0
        
        let protrusion = model.irregular?.protrusionHeight ?? STTabBarIrregularStyle.standard.protrusionHeight
        // 图片在上方，向上超出 tabbar，向下移动一些
        self.iconImageViewConstraints = [
            self.iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: -protrusion + 10 + model.layout.imageTopInset - 6),
            self.iconImageView.widthAnchor.constraint(equalToConstant: model.layout.imageSize?.width ?? 24),
            self.iconImageView.heightAnchor.constraint(equalToConstant: model.layout.imageSize?.height ?? 24)
        ]
        NSLayoutConstraint.activate(iconImageViewConstraints)
        
        // 文字在下方（在 tabbar 内部），向下移动一些
        self.titleLabelConstraints = [
            self.titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.titleLabel.topAnchor.constraint(equalTo: self.iconImageView.bottomAnchor, constant: 8),
            self.titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            self.titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            self.titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6)
        ]
        NSLayoutConstraint.activate(self.titleLabelConstraints)
    }
    
    private func updateBadgeUI() {
        guard let model = self.itemModel else { return }
        if model.badge.count > 0 {
            self.badgeLabel.isHidden = false
            self.badgeLabel.text = model.badge.count > 99 ? "99+" : "\(model.badge.count)"
            self.badgeLabel.backgroundColor = model.badge.backgroundColor
            self.badgeLabel.textColor = model.badge.textColor
        } else {
            self.badgeLabel.isHidden = true
        }
    }
    
    private func updateCustomView() {
        guard let model = self.itemModel else { return }
        self.customContainerView.subviews.forEach { $0.removeFromSuperview() }
        if let customView = model.customView {
            self.customContainerView.isHidden = false
            self.customContainerView.addSubview(customView)
            customView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                customView.topAnchor.constraint(equalTo: self.customContainerView.topAnchor),
                customView.leadingAnchor.constraint(equalTo: self.customContainerView.leadingAnchor),
                customView.trailingAnchor.constraint(equalTo: self.customContainerView.trailingAnchor),
                customView.bottomAnchor.constraint(equalTo: self.customContainerView.bottomAnchor)
            ])
        } else {
            self.customContainerView.isHidden = true
        }
    }
    
    private func animateSelection(_ selected: Bool) {
        guard let model = itemModel, let config = config else { return }
        UIView.animate(withDuration: config.animationDuration, delay: 0, options: [.curveEaseInOut], animations: {
            let scale = selected ? config.selectedScale : 1.0
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.alpha = selected ? 1.0 : config.unselectedAlpha
            self.titleLabel.textColor = selected ? model.colors.selectedText : model.colors.normalText
            self.backgroundColor = selected ? model.colors.selectedBackground : model.colors.normalBackground
        }) { _ in
            UIView.transition(with: self.iconImageView, duration: 0.2, options: .transitionCrossDissolve) {
                self.iconImageView.image = selected ? model.selectedImage : model.normalImage
            }
        }
    }
    
    @objc private func handleTap() {
        guard let model = self.itemModel, model.isEnabled else { return }
        self.tapAction?()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        guard var model = self.itemModel else { return }
        var updated = false
        if let name = model.normalImageName,
           let img = UIImage(named: name)?.withRenderingMode(.alwaysOriginal) {
            model.normalImage = img
            updated = true
        }
        if let name = model.selectedImageName,
           let img = UIImage(named: name)?.withRenderingMode(.alwaysOriginal) {
            model.selectedImage = img
            updated = true
        }
        if updated {
            self.itemModel = model
            self.updateUI()
        }
    }
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.st_systemFont(ofSize: 10, weight: .medium)
        label.isUserInteractionEnabled = false
        return label
    }()
    
    private lazy var badgeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.st_systemFont(ofSize: 10, weight: .bold)
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.isHidden = true
        label.isUserInteractionEnabled = false
        return label
    }()
    
    private lazy var customContainerView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }()
}

extension STTabBarItemView {
    /// 创建默认的 TabBar Item
    /// - Parameters:
    ///   - title: 标题
    ///   - normalImage: 普通图标
    ///   - selectedImage: 选中图标
    /// - Returns: 配置好的 Item 视图
    public static func createDefault(title: String, normalImage: UIImage?, selectedImage: UIImage?) -> STTabBarItemView {
        let itemView = STTabBarItemView()
        let model = STTabBarItemModel(title: title, normalImage: normalImage, selectedImage: selectedImage)
        itemView.configure(with: model)
        return itemView
    }
}
