//
//  STTabBarItemView.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import UIKit
import SnapKit

// MARK: - 自定义 TabBar Item 视图
/// 自定义 TabBar Item 视图
public class STTabBarItemView: UIView {
    
    // MARK: - UI 组件
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
    
    // MARK: - 属性
    private var itemModel: STTabBarItemModel?
    private var config: STTabBarConfig?
    private var isSelected: Bool = false
    private var tapAction: (() -> Void)?
    
    // MARK: - 初始化
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - 设置方法
    private func setupUI() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(badgeLabel)
        addSubview(customContainerView)
        
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(6)
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(2)
            make.left.right.equalToSuperview().inset(4)
            make.bottom.lessThanOrEqualToSuperview().offset(-6)
        }
        
        badgeLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.top).offset(-4)
            make.right.equalTo(iconImageView.snp.right).offset(4)
            make.width.height.greaterThanOrEqualTo(16)
        }
        
        customContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 添加点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
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
    
    // MARK: - 私有方法
    private func updateUI() {
        guard let model = itemModel else { return }
        
        // 更新图标
        iconImageView.image = isSelected ? model.selectedImage : model.normalImage
        
        // 更新标题
        titleLabel.text = model.title
        titleLabel.textColor = isSelected ? model.selectedTextColor : model.normalTextColor
        
        // 更新背景
        backgroundColor = isSelected ? model.selectedBackgroundColor : model.normalBackgroundColor
        
        // 更新透明度
        alpha = isSelected ? 1.0 : (config?.unselectedAlpha ?? 0.7)
        
        // 更新徽章
        updateBadgeUI()
        
        // 更新自定义视图
        updateCustomView()
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
        
        // 移除旧的自定义视图
        customContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        if let customView = model.customView {
            customContainerView.isHidden = false
            customContainerView.addSubview(customView)
            customView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            customContainerView.isHidden = true
        }
    }
    
    private func animateSelection(_ selected: Bool) {
        guard let model = itemModel, let config = config else { return }
        
        UIView.animate(withDuration: config.animationDuration, delay: 0, options: [.curveEaseInOut], animations: {
            // 缩放动画
            let scale = selected ? config.selectedScale : 1.0
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            // 透明度动画
            self.alpha = selected ? 1.0 : config.unselectedAlpha
            
            // 颜色动画
            self.titleLabel.textColor = selected ? model.selectedTextColor : model.normalTextColor
            self.backgroundColor = selected ? model.selectedBackgroundColor : model.normalBackgroundColor
            
        }) { _ in
            // 图标切换动画
            UIView.transition(with: self.iconImageView, duration: 0.2, options: .transitionCrossDissolve) {
                self.iconImageView.image = selected ? model.selectedImage : model.normalImage
            }
        }
    }
    
    // MARK: - 事件处理
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
