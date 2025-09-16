//
//  STCustomTabBar.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import UIKit
import SnapKit

// MARK: - 自定义 TabBar 协议
/// 自定义 TabBar 代理协议
public protocol STCustomTabBarDelegate: AnyObject {
    /// TabBar Item 被选中
    /// - Parameters:
    ///   - tabBar: TabBar 实例
    ///   - index: 选中的索引
    func customTabBar(_ tabBar: STCustomTabBar, didSelectItemAt index: Int)
}

// MARK: - 自定义 TabBar
/// 自定义 TabBar 类
public class STCustomTabBar: UIView {
    
    // MARK: - 属性
    public weak var delegate: STCustomTabBarDelegate?
    
    private var itemModels: [STTabBarItemModel] = []
    private var itemViews: [STTabBarItemView] = []
    private var selectedIndex: Int = 0
    private var config: STTabBarConfig = STTabBarConfig()
    
    // MARK: - UI 组件
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private lazy var topBorderView: UIView = {
        let view = UIView()
        return view
    }()
    
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
        addSubview(contentView)
        addSubview(topBorderView)
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        topBorderView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        // 设置默认样式
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
        
        // 更新之前选中的 Item
        if selectedIndex < itemViews.count {
            itemViews[selectedIndex].updateSelection(false)
        }
        
        // 设置新的选中项
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
    
    // MARK: - 私有方法
    private func setupItems() {
        // 移除旧的 Item 视图
        itemViews.forEach { $0.removeFromSuperview() }
        itemViews.removeAll()
        
        // 创建新的 Item 视图
        for (index, model) in itemModels.enumerated() {
            let itemView = STTabBarItemView()
            itemView.configure(with: model, config: config, isSelected: index == selectedIndex) { [weak self] in
                self?.handleItemTap(at: index)
            }
            contentView.addSubview(itemView)
            itemViews.append(itemView)
        }
        
        // 设置约束
        setupItemConstraints()
    }
    
    private func setupItemConstraints() {
        guard !itemViews.isEmpty else { return }
        
        for (index, itemView) in itemViews.enumerated() {
            itemView.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                
                if index == 0 {
                    make.left.equalToSuperview()
                } else {
                    make.left.equalTo(itemViews[index - 1].snp.right)
                    make.width.equalTo(itemViews[index - 1])
                }
                
                if index == itemViews.count - 1 {
                    make.right.equalToSuperview()
                }
            }
        }
    }
    
    private func updateAppearance() {
        // 设置背景颜色
        backgroundColor = config.backgroundColor
        
        // 设置高度约束
        snp.updateConstraints { make in
            make.height.equalTo(config.height)
        }
        
        // 设置顶部边框
        topBorderView.isHidden = !config.showTopBorder
        topBorderView.backgroundColor = config.topBorderColor
        topBorderView.snp.updateConstraints { make in
            make.height.equalTo(config.topBorderWidth)
        }
        
        // 设置阴影
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
