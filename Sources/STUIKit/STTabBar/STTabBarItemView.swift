//
//  STTabBarItemView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import UIKit

/// 自定义 TabBar Item 视图
public class STTabBarItemView: UIView {
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.isUserInteractionEnabled = false
        return label
    }()
    
    private lazy var badgeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
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
    
    private var itemModel: STTabBarItemModel?
    private var config: STTabBarConfig?
    private var isSelected: Bool = false
    private var tapAction: (() -> Void)?
    
    // 约束管理
    private var iconImageViewConstraints: [NSLayoutConstraint] = []
    private var titleLabelConstraints: [NSLayoutConstraint] = []
    private var initialConstraints: [NSLayoutConstraint] = []
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(badgeLabel)
        addSubview(customContainerView)
        
        // 设置所有视图的自动转换
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        customContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置初始约束（默认图文模式）
        setupInitialConstraints()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }
    
    private func setupInitialConstraints() {
        // 清除现有约束
        NSLayoutConstraint.deactivate(initialConstraints)
        initialConstraints.removeAll()
        
        // 设置初始约束（默认图文模式）
        initialConstraints = [
            // iconImageView 初始约束
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // titleLabel 初始约束
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6),
            
            // badgeLabel 约束
            badgeLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor, constant: -4),
            badgeLabel.trailingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 4),
            badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 16),
            badgeLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 16),
            
            // customContainerView 约束
            customContainerView.topAnchor.constraint(equalTo: topAnchor),
            customContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            customContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            customContainerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(initialConstraints)
    }
    
    // MARK: - 配置方法
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
        
        updateUI()
    }
    
    /// 更新选中状态
    /// - Parameter selected: 是否选中
    public func updateSelection(_ selected: Bool) {
        guard self.isSelected != selected else { return }
        self.isSelected = selected
        if let config = config, config.enableAnimation {
            animateSelection(selected)
        } else {
            updateUI()
        }
    }
    
    /// 更新徽章数量
    /// - Parameter count: 徽章数量
    public func updateBadgeCount(_ count: Int) {
        guard let model = itemModel else { return }
        var updatedModel = model
        updatedModel.badgeCount = count
        self.itemModel = updatedModel
        updateBadgeUI()
    }
    
    private func updateUI() {
        guard let model = itemModel else { return }
        
        // 清除所有现有约束
        NSLayoutConstraint.deactivate(initialConstraints)
        NSLayoutConstraint.deactivate(iconImageViewConstraints)
        NSLayoutConstraint.deactivate(titleLabelConstraints)
        
        initialConstraints.removeAll()
        iconImageViewConstraints.removeAll()
        titleLabelConstraints.removeAll()
        
        // 根据显示模式设置UI
        switch model.displayMode {
        case .imageOnly:
            setupImageOnlyMode(model)
        case .textOnly:
            setupTextOnlyMode(model)
        case .imageAndText:
            setupImageAndTextMode(model)
        case .custom:
            setupCustomMode(model)
        case .irregular:
            setupIrregularMode(model)
        }
        
        updateBadgeUI()
        updateCustomView()
    }
    
    private func setupImageOnlyMode(_ model: STTabBarItemModel) {
        // 只显示图片
        iconImageView.isHidden = false
        titleLabel.isHidden = true
        
        iconImageView.image = isSelected ? model.selectedImage : model.normalImage
        backgroundColor = isSelected ? model.selectedBackgroundColor : model.normalBackgroundColor
        alpha = isSelected ? 1.0 : (config?.unselectedAlpha ?? 0.7)
        
        // 图片居中显示
        iconImageViewConstraints = [
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: model.imageSize?.width ?? 24),
            iconImageView.heightAnchor.constraint(equalToConstant: model.imageSize?.height ?? 24)
        ]
        NSLayoutConstraint.activate(iconImageViewConstraints)
    }
    
    private func setupTextOnlyMode(_ model: STTabBarItemModel) {
        // 只显示文字
        iconImageView.isHidden = true
        titleLabel.isHidden = false
        
        titleLabel.text = model.title
        titleLabel.textColor = isSelected ? model.selectedTextColor : model.normalTextColor
        let font = UIFont(name: model.titleFontName, size: model.titleSize) ?? UIFont.systemFont(ofSize: model.titleSize, weight: .medium)
        titleLabel.font = font
        backgroundColor = isSelected ? model.selectedBackgroundColor : model.normalBackgroundColor
        alpha = isSelected ? 1.0 : (config?.unselectedAlpha ?? 0.7)
        
        // 文字居中显示
        titleLabelConstraints = [
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4)
        ]
        NSLayoutConstraint.activate(titleLabelConstraints)
    }
    
    private func setupImageAndTextMode(_ model: STTabBarItemModel) {
        // 显示图片和文字（默认模式）
        iconImageView.isHidden = false
        titleLabel.isHidden = false
        
        iconImageView.image = isSelected ? model.selectedImage : model.normalImage
        titleLabel.text = model.title
        titleLabel.textColor = isSelected ? model.selectedTextColor : model.normalTextColor
        let font = UIFont(name: model.titleFontName, size: model.titleSize) ?? UIFont.systemFont(ofSize: model.titleSize, weight: .medium)
        titleLabel.font = font
        backgroundColor = isSelected ? model.selectedBackgroundColor : model.normalBackgroundColor
        alpha = isSelected ? 1.0 : (config?.unselectedAlpha ?? 0.7)
        
        // 图片在上，文字在下
        iconImageViewConstraints = [
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            iconImageView.widthAnchor.constraint(equalToConstant: model.imageSize?.width ?? 24),
            iconImageView.heightAnchor.constraint(equalToConstant: model.imageSize?.height ?? 24)
        ]
        NSLayoutConstraint.activate(iconImageViewConstraints)
        
        titleLabelConstraints = [
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6)
        ]
        NSLayoutConstraint.activate(titleLabelConstraints)
    }
    
    private func setupCustomMode(_ model: STTabBarItemModel) {
        // 自定义视图模式
        iconImageView.isHidden = true
        titleLabel.isHidden = true
        customContainerView.isHidden = false
        
        backgroundColor = .clear
        alpha = 1.0
    }
    
    private func setupIrregularMode(_ model: STTabBarItemModel) {
        // 不规则（凸起）按钮模式
        iconImageView.isHidden = false
        titleLabel.isHidden = false
        
        iconImageView.image = isSelected ? model.selectedImage : model.normalImage
        titleLabel.text = model.title
        titleLabel.textColor = model.normalTextColor
        let font = UIFont(name: model.titleFontName, size: model.titleSize) ?? UIFont.systemFont(ofSize: model.titleSize, weight: .medium)
        titleLabel.font = font
        
        // 设置不规则按钮样式（去掉背景颜色）
        backgroundColor = .clear
        layer.cornerRadius = 0
        layer.shadowColor = UIColor.clear.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 0
        layer.shadowOpacity = 0
        alpha = 1.0
        
        // 图片在上方，向上超出 tabbar，向下移动一些
        iconImageViewConstraints = [
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: -model.irregularHeight + 10),
            iconImageView.widthAnchor.constraint(equalToConstant: model.imageSize?.width ?? 24),
            iconImageView.heightAnchor.constraint(equalToConstant: model.imageSize?.height ?? 24)
        ]
        NSLayoutConstraint.activate(iconImageViewConstraints)
        
        // 文字在下方（在 tabbar 内部），向下移动一些
        titleLabelConstraints = [
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -4),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -6)
        ]
        NSLayoutConstraint.activate(titleLabelConstraints)
    }
    
    private func updateBadgeUI() {
        guard let model = itemModel else { return }
        if model.badgeCount > 0 {
            badgeLabel.isHidden = false
            badgeLabel.text = model.badgeCount > 99 ? "99+" : "\(model.badgeCount)"
            badgeLabel.backgroundColor = model.badgeBackgroundColor
            badgeLabel.textColor = model.badgeTextColor
        } else {
            badgeLabel.isHidden = true
        }
    }
    
    private func updateCustomView() {
        guard let model = itemModel else { return }
        customContainerView.subviews.forEach { $0.removeFromSuperview() }
        if let customView = model.customView {
            customContainerView.isHidden = false
            customContainerView.addSubview(customView)
            customView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                customView.topAnchor.constraint(equalTo: customContainerView.topAnchor),
                customView.leadingAnchor.constraint(equalTo: customContainerView.leadingAnchor),
                customView.trailingAnchor.constraint(equalTo: customContainerView.trailingAnchor),
                customView.bottomAnchor.constraint(equalTo: customContainerView.bottomAnchor)
            ])
        } else {
            customContainerView.isHidden = true
        }
    }
    
    private func animateSelection(_ selected: Bool) {
        guard let model = itemModel, let config = config else { return }
        UIView.animate(withDuration: config.animationDuration, delay: 0, options: [.curveEaseInOut], animations: {
            let scale = selected ? config.selectedScale : 1.0
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
            self.alpha = selected ? 1.0 : config.unselectedAlpha
            self.titleLabel.textColor = selected ? model.selectedTextColor : model.normalTextColor
            self.backgroundColor = selected ? model.selectedBackgroundColor : model.normalBackgroundColor
        }) { _ in
            UIView.transition(with: self.iconImageView, duration: 0.2, options: .transitionCrossDissolve) {
                self.iconImageView.image = selected ? model.selectedImage : model.normalImage
            }
        }
    }
    
    @objc private func handleTap() {
        guard let model = itemModel, model.isEnabled else { return }
        tapAction?()
    }
}

// MARK: - 扩展方法
extension STTabBarItemView {
    /// 创建默认的 TabBar Item
    /// - Parameters:
    ///   - title: 标题
    ///   - normalImage: 普通图标
    ///   - selectedImage: 选中图标
    /// - Returns: 配置好的 Item 视图
    public static func createDefault(
        title: String,
        normalImage: UIImage?,
        selectedImage: UIImage?
    ) -> STTabBarItemView {
        let itemView = STTabBarItemView()
        let model = STTabBarItemModel(
            title: title,
            normalImage: normalImage,
            selectedImage: selectedImage
        )
        itemView.configure(with: model)
        return itemView
    }
}
