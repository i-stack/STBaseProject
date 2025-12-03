//
//  STCustomTabBar.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import UIKit

// MARK: - 自定义 TabBar 协议
/// 自定义 TabBar 代理协议
public protocol STCustomTabBarDelegate: AnyObject {
    /// TabBar Item 被选中
    /// - Parameters:
    ///   - tabBar: TabBar 实例
    ///   - index: 选中的索引
    func customTabBar(_ tabBar: STCustomTabBar, didSelectItemAt index: Int)
}

public class STCustomTabBar: UIView {
    
    public weak var delegate: STCustomTabBarDelegate?
    
    private var itemModels: [STTabBarItemModel] = []
    private var itemViews: [STTabBarItemView] = []
    private var selectedIndex: Int = 0
    private var config: STTabBarConfig = STTabBarConfig()
    private var heightConstraint: NSLayoutConstraint?
    
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var topBorderView: UIView = {
        let view = UIView()
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(contentView)
        addSubview(topBorderView)
        
        // 设置 contentView 约束
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // 设置 topBorderView 约束
        topBorderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topBorderView.topAnchor.constraint(equalTo: topAnchor),
            topBorderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBorderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBorderView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        updateAppearance()
    }
    
    // MARK: - 公共方法
    /// 配置 TabBar
    /// - Parameters:
    ///   - items: TabBar Item 数据数组
    ///   - config: TabBar 配置
    public func configure(items: [STTabBarItemModel], config: STTabBarConfig = STTabBarConfig()) {
        self.itemModels = items
        self.config = config
        setupItems()
        updateAppearance()
    }
    
    /// 设置选中的 Item
    /// - Parameter index: 索引
    public func setSelectedIndex(_ index: Int) {
        guard index >= 0 && index < itemViews.count else { return }
        if selectedIndex < itemViews.count {
            itemViews[selectedIndex].updateSelection(false)
        }
        selectedIndex = index
        itemViews[selectedIndex].updateSelection(true)
    }
    
    /// 更新指定 Item 的徽章数量
    /// - Parameters:
    ///   - index: Item 索引
    ///   - count: 徽章数量
    public func updateBadgeCount(at index: Int, count: Int) {
        guard index >= 0 && index < itemViews.count else { return }
        itemViews[index].updateBadgeCount(count)
    }
    
    /// 更新 TabBar 配置
    /// - Parameter config: 新的配置
    public func updateConfig(_ config: STTabBarConfig) {
        self.config = config
        updateAppearance()
    }
    
    /// 获取当前选中的索引
    public func getSelectedIndex() -> Int {
        return selectedIndex
    }
    
    /// 获取 Item 数量
    public func getItemCount() -> Int {
        return itemModels.count
    }
    
    private func setupItems() {
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews.removeAll()
        for (index, model) in itemModels.enumerated() {
            let itemView = STTabBarItemView()
            itemView.configure(with: model, config: config, isSelected: index == selectedIndex) { [weak self] in
                self?.handleItemTap(at: index)
            }
            contentView.addSubview(itemView)
            itemViews.append(itemView)
        }
        setupItemConstraints()
    }
    
    private func setupItemConstraints() {
        guard !itemViews.isEmpty else { return }
        
        // 移除所有现有约束
        itemViews.forEach { $0.removeFromSuperview() }
        for itemView in itemViews {
            contentView.addSubview(itemView)
        }
        
        for (index, itemView) in itemViews.enumerated() {
            let model = itemModels[index]
            itemView.translatesAutoresizingMaskIntoConstraints = false
            
            if model.isIrregular {
                // 不规则按钮：向上凸起
                NSLayoutConstraint.activate([
                    itemView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -model.irregularHeight / 2),
                    itemView.heightAnchor.constraint(equalToConstant: config.height + model.irregularHeight)
                ])
            } else {
                // 普通按钮：正常高度
                NSLayoutConstraint.activate([
                    itemView.topAnchor.constraint(equalTo: contentView.topAnchor),
                    itemView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ])
            }
            
            // 设置水平约束
            if index == 0 {
                NSLayoutConstraint.activate([
                    itemView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
                ])
            } else {
                NSLayoutConstraint.activate([
                    itemView.leadingAnchor.constraint(equalTo: itemViews[index - 1].trailingAnchor),
                    itemView.widthAnchor.constraint(equalTo: itemViews[index - 1].widthAnchor)
                ])
            }
            
            if index == itemViews.count - 1 {
                NSLayoutConstraint.activate([
                    itemView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
                ])
            }
        }
    }
    
    private func updateAppearance() {
        backgroundColor = config.backgroundColor
        
        // 更新高度约束
        if let heightConstraint = heightConstraint {
            heightConstraint.constant = config.height
        } else {
            heightConstraint = heightAnchor.constraint(equalToConstant: config.height)
            heightConstraint?.isActive = true
        }
        
        topBorderView.isHidden = !config.showTopBorder
        topBorderView.backgroundColor = config.topBorderColor
        
        // 更新 topBorderView 高度约束
        for constraint in topBorderView.constraints {
            if constraint.firstAttribute == .height {
                constraint.constant = config.topBorderWidth
                break
            }
        }
        
        if config.showShadow {
            layer.shadowColor = config.shadowColor.cgColor
            layer.shadowOffset = config.shadowOffset
            layer.shadowRadius = config.shadowRadius
            layer.shadowOpacity = config.shadowOpacity
            layer.masksToBounds = false
        } else {
            layer.shadowOpacity = 0
        }
    }
    
    private func handleItemTap(at index: Int) {
        guard index != selectedIndex else { return }
        setSelectedIndex(index)
        delegate?.customTabBar(self, didSelectItemAt: index)
    }
}

// MARK: - 便捷方法
extension STCustomTabBar {
    /// 创建默认的 TabBar
    /// - Parameter items: TabBar Item 数据数组
    /// - Returns: 配置好的 TabBar
    public static func createDefault(with items: [STTabBarItemModel]) -> STCustomTabBar {
        let tabBar = STCustomTabBar()
        tabBar.configure(items: items)
        return tabBar
    }
    
    /// 创建简单的 TabBar
    /// - Parameters:
    ///   - titles: 标题数组
    ///   - normalImages: 普通图标数组
    ///   - selectedImages: 选中图标数组
    /// - Returns: 配置好的 TabBar
    public static func createSimple(
        titles: [String],
        normalImages: [UIImage?],
        selectedImages: [UIImage?]
    ) -> STCustomTabBar {
        var items: [STTabBarItemModel] = []
        for i in 0..<titles.count {
            let model = STTabBarItemModel(
                title: titles[i],
                normalImage: i < normalImages.count ? normalImages[i] : nil,
                selectedImage: i < selectedImages.count ? selectedImages[i] : nil
            )
            items.append(model)
        }
        return createDefault(with: items)
    }
}
