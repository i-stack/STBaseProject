# STCustomTabBar 使用示例

## 概述
`STCustomTabBar` 是一个完全自定义的 TabBar 解决方案，支持自定义样式、高度、动画效果和 TabBar Item。

## 主要特性
- ✅ 完全自定义的 TabBar 样式
- ✅ 支持自定义高度
- ✅ 支持自定义 TabBar Item（图标、标题、颜色等）
- ✅ 支持徽章显示
- ✅ 支持动画效果
- ✅ 支持自定义视图
- ✅ 支持阴影和边框
- ✅ 简单易用的 API

## 基本使用

### 1. 创建简单的 TabBar Controller

```swift
import STBaseProject

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建 ViewControllers
        let homeVC = HomeViewController()
        let processVC = ProcessViewController()
        let myVC = MyViewController()
        
        // 创建 TabBar Controller
        let tabBarController = STCustomTabBarController.createSimple(
            viewControllers: [homeVC, processVC, myVC],
            titles: ["首页", "流程", "我的"],
            normalImages: [
                UIImage(systemName: "house"),
                UIImage(systemName: "list.bullet"),
                UIImage(systemName: "person")
            ],
            selectedImages: [
                UIImage(systemName: "house.fill"),
                UIImage(systemName: "list.bullet.circle"),
                UIImage(systemName: "person.fill")
            ]
        )
        
        // 添加到当前视图
        addChild(tabBarController)
        view.addSubview(tabBarController.view)
        tabBarController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tabBarController.didMove(toParent: self)
    }
}
```

### 2. 高级配置

```swift
// 创建自定义配置
let config = STTabBarConfig(
    backgroundColor: .systemBackground,
    height: 60.0,  // 自定义高度
    showTopBorder: true,
    topBorderColor: .systemGray4,
    showShadow: true,
    shadowColor: .black,
    shadowOffset: CGSize(width: 0, height: -2),
    shadowRadius: 4,
    shadowOpacity: 0.1,
    enableAnimation: true,
    animationDuration: 0.3,
    selectedScale: 1.1,
    unselectedAlpha: 0.7
)

// 创建自定义 TabBar Items
let items = [
    STTabBarItemModel(
        title: "首页",
        normalImage: UIImage(systemName: "house"),
        selectedImage: UIImage(systemName: "house.fill"),
        normalTextColor: .systemGray,
        selectedTextColor: .systemBlue,
        badgeCount: 5,
        badgeBackgroundColor: .systemRed,
        badgeTextColor: .white
    ),
    STTabBarItemModel(
        title: "流程",
        normalImage: UIImage(systemName: "list.bullet"),
        selectedImage: UIImage(systemName: "list.bullet.circle"),
        normalTextColor: .systemGray,
        selectedTextColor: .systemGreen
    ),
    STTabBarItemModel(
        title: "我的",
        normalImage: UIImage(systemName: "person"),
        selectedImage: UIImage(systemName: "person.fill"),
        normalTextColor: .systemGray,
        selectedTextColor: .systemOrange
    )
]

// 创建 TabBar Controller
let tabBarController = STCustomTabBarController()
tabBarController.setViewControllers(
    [homeVC, processVC, myVC],
    tabBarItems: items,
    config: config
)
```

### 3. 动态更新

```swift
// 更新徽章数量
tabBarController.updateBadgeCount(at: 0, count: 10)

// 切换选中的 Tab
tabBarController.setSelectedIndex(1)

// 更新 TabBar 配置
let newConfig = STTabBarConfig(
    backgroundColor: .systemBlue,
    height: 80.0
)
tabBarController.updateTabBarConfig(newConfig)
```

### 4. 自定义 TabBar Item

```swift
// 创建自定义视图
let customView = UIView()
let customLabel = UILabel()
customLabel.text = "自定义"
customLabel.textAlignment = .center
customView.addSubview(customLabel)
customLabel.snp.makeConstraints { make in
    make.edges.equalToSuperview()
}

// 创建自定义 TabBar Item
let customItem = STTabBarItemModel(
    title: "自定义",
    normalImage: nil,
    selectedImage: nil,
    customView: customView
)

// 使用自定义 Item
let items = [customItem, ...otherItems]
```

## API 参考

### STTabBarItemModel
```swift
public struct STTabBarItemModel {
    public var title: String                    // 标题
    public var normalImage: UIImage?            // 普通状态图标
    public var selectedImage: UIImage?          // 选中状态图标
    public var normalTextColor: UIColor         // 普通状态文字颜色
    public var selectedTextColor: UIColor       // 选中状态文字颜色
    public var normalBackgroundColor: UIColor   // 普通状态背景颜色
    public var selectedBackgroundColor: UIColor // 选中状态背景颜色
    public var isEnabled: Bool                  // 是否启用
    public var badgeCount: Int                  // 徽章数量
    public var badgeBackgroundColor: UIColor    // 徽章背景颜色
    public var badgeTextColor: UIColor          // 徽章文字颜色
    public var customView: UIView?              // 自定义视图
}
```

### STTabBarConfig
```swift
public struct STTabBarConfig {
    public var backgroundColor: UIColor         // TabBar 背景颜色
    public var height: CGFloat                  // TabBar 高度
    public var showTopBorder: Bool              // 是否显示顶部边框
    public var topBorderColor: UIColor          // 顶部边框颜色
    public var topBorderWidth: CGFloat          // 顶部边框宽度
    public var showShadow: Bool                 // 是否显示阴影
    public var shadowColor: UIColor             // 阴影颜色
    public var shadowOffset: CGSize             // 阴影偏移
    public var shadowRadius: CGFloat            // 阴影半径
    public var shadowOpacity: Float             // 阴影透明度
    public var enableAnimation: Bool            // 是否启用动画
    public var animationDuration: TimeInterval  // 动画持续时间
    public var selectedScale: CGFloat           // 选中项缩放比例
    public var unselectedAlpha: CGFloat         // 未选中项透明度
}
```

### STCustomTabBarController
```swift
public class STCustomTabBarController: UIViewController {
    // 设置 ViewControllers
    public func setViewControllers(
        _ viewControllers: [UIViewController],
        tabBarItems: [STTabBarItemModel],
        config: STTabBarConfig = STTabBarConfig()
    )
    
    // 设置选中的 ViewController
    public func setSelectedIndex(_ index: Int)
    
    // 获取当前选中的索引
    public func getSelectedIndex() -> Int
    
    // 更新指定 Item 的徽章数量
    public func updateBadgeCount(at index: Int, count: Int)
    
    // 更新 TabBar 配置
    public func updateTabBarConfig(_ config: STTabBarConfig)
}
```

## 注意事项
1. 确保 `viewControllers` 和 `tabBarItems` 数组长度一致
2. 图标建议使用 SF Symbols 以获得最佳效果
3. 自定义高度需要考虑安全区域
4. 动画效果在低端设备上可能会影响性能
5. 徽章数量超过 99 会显示 "99+"
