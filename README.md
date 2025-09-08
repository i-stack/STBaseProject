# STBaseProject

[![Version](https://img.shields.io/cocoapods/v/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![License](https://img.shields.io/cocoapods/l/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![Platform](https://img.shields.io/cocoapods/p/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![Swift](https://img.shields.io/badge/Swift-5.9_5.10_6.0-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.9_5.10_6.0-Orange?style=flat-square)

STBaseProject 是一个功能强大的 iOS 基础组件库，提供了丰富的 UI 组件和工具类，帮助开发者快速构建高质量的 iOS 应用。

## 主要特性

- 🎨 **自定义导航栏**：支持多种样式和配置选项
- 🌐 **WebView 控制器**：完整的 WebView 功能，支持 JavaScript 交互
- 🧰 **模块化设计**：STKit 工具集，支持按需引入（Core/UI/Network/Media/Scan/Security/Localization/Location）
- 📱 **现代化设计**：支持深色模式，适配不同屏幕尺寸
- 🔧 **高度可配置**：丰富的配置选项，满足不同需求
- 🛡️ **错误处理**：完善的错误处理和状态管理
- 📐 **设备适配**：智能的设备判断和尺寸计算
- 🎯 **比例缩放**：基于设计稿的精确比例缩放
- 📸 **统一图片管理**：整合相机、照片库和图片处理功能
- 🌐 **本地化支持**：完整的国际化支持
- 🎨 **自定义弹窗**：统一的弹窗 API，支持系统和自定义样式
- 📱 **二维码扫描**：高度可配置的扫码界面和管理器
- 🔒 **网络安全**：SSL证书绑定、数据加密、反调试检测，全面防护抓包攻击

## Installation

### 完整安装（推荐用于快速开始）

```ruby
pod 'STBaseProject'
```

### 按需引入（推荐用于生产环境）

STBaseProject 已重构为模块化设计，您可以根据项目需求按需引入：

```ruby
# 常用模块（推荐引入）：
pod 'STBaseProject/STKit/Core'           # 必选：核心工具（数据处理、字符串、颜色等）
pod 'STBaseProject/STKit/UI'             # 常用：UI 组件（按钮、标签、弹窗等）
pod 'STBaseProject/STKit/Network'        # 常用：网络工具
pod 'STBaseProject/STKit/Localization'   # 常用：本地化
pod 'STBaseProject/STKit/Security'       # 常用：加密与安全存储

# 可选模块（按需引入）：
pod 'STBaseProject/STKit/Media'          # 可选：图片处理与截图
pod 'STBaseProject/STKit/Scan'           # 可选：二维码扫描
pod 'STBaseProject/STKit/Location'       # 可选：定位服务
pod 'STBaseProject/STKit/Dialog'         # 可选：对话框组件

# 基础架构模块：
pod 'STBaseProject/STBaseModule'         # 基础 MVVM 架构
pod 'STBaseProject/STConfig'             # 配置管理
```

## Basic Configuration

Configure in AppDelegate:

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // 配置基础设置
    STBaseConfig.shared.st_setDefaultConfig()
    
    // 或者自定义配置
    STBaseConfig.shared.st_configCompleteUI(
        designSize: CGSize(width: 375, height: 812),  // iPhone X 设计稿尺寸
        navNormalHeight: 64,    // 普通设备导航栏高度
        navSafeHeight: 88,      // 刘海屏设备导航栏高度
        tabBarNormalHeight: 49, // 普通设备 TabBar 高度
        tabBarSafeHeight: 83    // 刘海屏设备 TabBar 高度
    )
    
    return true
}
```

## 组件使用指南

### 一、STBaseConfig 和 STDeviceAdapter

#### STBaseConfig - 基础配置管理

`STBaseConfig` 负责管理设计基准尺寸和界面高度配置，提供统一的配置接口。

##### 主要功能

- **设计基准配置**：设置设计稿的基准尺寸
- **导航栏配置**：自定义导航栏高度
- **TabBar 配置**：自定义 TabBar 高度
- **完整配置**：一次性配置所有界面尺寸

##### 使用示例

```swift
// 设置默认配置（推荐）
STBaseConfig.shared.st_setDefaultConfig()

// 自定义设计基准尺寸
STBaseConfig.shared.st_configBenchmarkDesign(size: CGSize(width: 375, height: 812))

// 自定义导航栏高度
STBaseConfig.shared.st_configCustomNavBar(normalHeight: 64, safeHeight: 88)

// 自定义 TabBar 高度
STBaseConfig.shared.st_configCustomTabBar(normalHeight: 49, safeHeight: 83)

// 完整配置
STBaseConfig.shared.st_configCompleteUI(
    designSize: CGSize(width: 375, height: 812),
    navNormalHeight: 64,
    navSafeHeight: 88,
    tabBarNormalHeight: 49,
    tabBarSafeHeight: 83
)
```

#### STDeviceAdapter - 设备适配和尺寸计算

`STDeviceAdapter` 提供设备判断、尺寸计算、比例缩放等功能，支持多设备适配。

##### 主要功能

- **设备判断**：iPhone、iPad、刘海屏等设备类型判断
- **尺寸计算**：屏幕尺寸、导航栏高度、安全区域等
- **比例缩放**：基于设计稿的精确比例计算
- **实用方法**：内容区域高度、方向判断等

##### 设备判断

```swift
// 设备类型判断
let deviceType = STDeviceAdapter.st_deviceType()
let isIPad = STDeviceAdapter.st_isIPad()
let isNotchScreen = STDeviceAdapter.st_isNotchScreen()

// 屏幕方向判断
let isLandscape = STDeviceAdapter.st_isLandscape()
let isPortrait = STDeviceAdapter.st_isPortrait()
```

##### 尺寸获取

```swift
// 屏幕尺寸
let screenWidth = STDeviceAdapter.st_appw()
let screenHeight = STDeviceAdapter.st_apph()
let screenSize = STDeviceAdapter.st_screenSize()

// 界面高度
let navHeight = STDeviceAdapter.st_navHeight()
let tabBarHeight = STDeviceAdapter.st_tabBarHeight()
let statusBarHeight = STDeviceAdapter.st_statusBarHeight()
let safeBarHeight = STDeviceAdapter.st_safeBarHeight()

// 内容区域高度
let contentHeight = STDeviceAdapter.st_contentHeight()
let contentHeightWithTabBar = STDeviceAdapter.st_contentHeightWithTabBar()
```

##### 比例缩放

```swift
// 基础比例计算
let multiplier = STDeviceAdapter.st_multiplier()
let heightMultiplier = STDeviceAdapter.st_heightMultiplier()

// 尺寸适配
let adaptedWidth = STDeviceAdapter.st_adaptWidth(100)      // 适配宽度
let adaptedHeight = STDeviceAdapter.st_adaptHeight(50)     // 适配高度
let adaptedFontSize = STDeviceAdapter.st_adaptFontSize(16) // 适配字体
let adaptedSpacing = STDeviceAdapter.st_adaptSpacing(10)   // 适配间距

// 手动计算
let result = STDeviceAdapter.st_handleFloat(100)           // 基于宽度
let heightResult = STDeviceAdapter.st_handleHeightFloat(50) // 基于高度
```

##### 实际应用示例

```swift
class CustomView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 使用适配后的尺寸
        let buttonWidth = STDeviceAdapter.st_adaptWidth(120)
        let buttonHeight = STDeviceAdapter.st_adaptHeight(44)
        let fontSize = STDeviceAdapter.st_adaptFontSize(16)
        let margin = STDeviceAdapter.st_adaptSpacing(20)
        
        let button = UIButton(frame: CGRect(x: margin, y: margin, width: buttonWidth, height: buttonHeight))
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        button.setTitle("适配按钮", for: .normal)
        
        addSubview(button)
    }
}

### 二、STBtn

`STBtn` 是一个功能强大的自定义按钮类，支持图片和文字的不同位置布局以及圆角设置。它提供了灵活的布局选项和丰富的样式配置。

#### 主要特性

- **多种布局样式**：图片在上/下/左/右，文字在对应位置
- **灵活的间距配置**：支持自定义图片和文字之间的间距
- **圆角和边框**：支持圆角、边框宽度、边框颜色设置
- **渐变背景**：支持渐变背景色设置
- **阴影效果**：支持阴影颜色、偏移、半径、透明度设置
- **Storyboard 支持**：支持在 Interface Builder 中直接设置属性

#### 布局样式

```swift
// 图片在上，文字在下
button.st_setImageTopTitleBottom(spacing: 8)

// 图片在左，文字在右
button.st_setImageLeftTitleRight(spacing: 8)

// 图片在右，文字在左
button.st_setImageRightTitleLeft(spacing: 8)

// 图片在下，文字在上
button.st_setImageBottomTitleTop(spacing: 8)
```

#### 高级布局配置

```swift
// 自定义间距配置
let spacing = STBtnSpacing(
    spacing: 10,           // 图片和文字之间的间距
    topSpacing: 5,         // 顶部间距
    leftSpacing: 15,       // 左侧间距
    rightSpacing: 15       // 右侧间距
)

// 设置布局样式和间距
button.st_layoutButtonWithEdgeInsets(style: .top, spacing: spacing)
```

#### 样式设置

```swift
// 设置圆角
button.st_roundedButton(cornerRadius: 8)

// 设置圆角和边框
button.st_roundedButton(cornerRadius: 8, borderWidth: 1, borderColor: UIColor.blue)

// 设置渐变背景
button.st_setGradientBackground(
    colors: [UIColor.blue, UIColor.purple],
    startPoint: CGPoint(x: 0, y: 0),
    endPoint: CGPoint(x: 1, y: 1)
)

// 设置阴影
button.st_setShadow(
    color: UIColor.black,
    offset: CGSize(width: 0, height: 2),
    radius: 4,
    opacity: 0.3
)
```

#### Storyboard 属性设置

在 Interface Builder 中可以设置以下属性：

- **Localized Title**：本地化标题
- **Border Width**：边框宽度
- **Corner Radius**：圆角半径
- **Border Color**：边框颜色
- **Auto Adapt Font Size**：是否自动适配字体大小

#### 实际应用示例

```swift
class CustomButtonViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
    }
    
    private func setupButtons() {
        // 创建按钮
        let button = STBtn(frame: CGRect(x: 20, y: 100, width: 200, height: 60))
        button.setTitle("自定义按钮", for: .normal)
        button.setImage(UIImage(named: "icon"), for: .normal)
        
        // 设置图片在上、文字在下的布局
        button.st_setImageTopTitleBottom(spacing: 8)
        
        // 设置圆角和渐变背景
        button.st_roundedButton(cornerRadius: 12, borderWidth: 1, borderColor: UIColor.blue)
        button.st_setGradientBackground(colors: [UIColor.systemBlue, UIColor.systemPurple])
        
        // 设置阴影
        button.st_setShadow()
        
        view.addSubview(button)
    }
}

#### 统一弹窗 API（系统 / 自定义）

```swift
// 系统弹窗（UIAlertController）
STAlertController.st_showSystemAlert(
    on: self,
    title: "标题",
    message: "这是一条消息",
    preferredStyle: .alert,
    actions: [
        STAlertActionItem(title: "取消", style: .cancel),
        STAlertActionItem(title: "确定", titleColor: .systemRed, style: .default) {
            print("点击确定")
        }
    ]
)

// 自定义弹窗（STAlertController）
STAlertController.st_showCustomAlert(
    on: self,
    title: "自定义弹窗",
    message: "支持字体/颜色/自定义按钮",
    preferredStyle: .alert,
    actions: [
        STAlertActionItem(title: "取消", style: .cancel),
        STAlertActionItem(title: "继续", titleColor: .systemBlue, font: .boldSystemFont(ofSize: 16)) {
            print("继续操作")
        }
    ]
)
```

### 三、STTabBarItem

`STTabBarItem` 是一个功能强大的自定义 TabBarItem 类，支持本地化、徽章、多种配置选项。它提供了灵活的配置方式和丰富的功能特性。

#### 主要特性

- **本地化支持**：支持多语言切换和动态更新
- **配置模型**：使用 `STTabBarItemConfig` 进行统一配置
- **徽章功能**：支持设置和清除徽章
- **批量创建**：支持批量创建多个 TabBarItem
- **错误处理**：完善的错误处理和日志记录
- **向后兼容**：保持与原有 API 的兼容性

#### 基础使用

```swift
// 使用原有方法（向后兼容）
let tabBarItem = STTabBarItem.st_setTabBarItem(
    title: "首页",
    titleSize: 12,
    titleFontName: "PingFangSC-Regular",
    normalImage: "home_normal",
    selectedImage: "home_selected",
    normalTitleColor: .systemGray,
    selectedTitleColor: .systemBlue,
    backgroundColor: .clear
)

// 使用配置模型（推荐）
let config = STTabBarItemConfig(
    title: "消息",
    titleSize: 14,
    titleFontName: "PingFangSC-Medium",
    normalImage: "message_normal",
    selectedImage: "message_selected",
    normalTitleColor: .systemGray,
    selectedTitleColor: .systemRed,
    backgroundColor: .clear,
    badgeValue: "99+",
    badgeColor: .systemRed,
    isLocalized: true
)
let tabBarItem = STTabBarItem.st_createTabBarItem(with: config)
```

#### 本地化支持

```swift
// 创建带本地化的 TabBarItem
let localizedItem = STTabBarItem.st_createLocalizedTabBarItem(
    localizedTitle: "tab_home", // 本地化键
    normalImage: "home_normal",
    selectedImage: "home_selected",
    normalColor: .systemGray,
    selectedColor: .systemBlue
)

// 动态更新本地化标题
STTabBarItem.st_updateLocalizedTitle(for: tabBarItem, localizedTitle: "tab_updated")
```

#### 批量创建

```swift
let configs = [
    STTabBarItemConfig(
        title: "tab_home",
        normalImage: "home_normal",
        selectedImage: "home_selected",
        isLocalized: true
    ),
    STTabBarItemConfig(
        title: "tab_message",
        normalImage: "message_normal",
        selectedImage: "message_selected",
        badgeValue: "5",
        isLocalized: true
    ),
    STTabBarItemConfig(
        title: "tab_profile",
        normalImage: "profile_normal",
        selectedImage: "profile_selected",
        isLocalized: true
    )
]
let tabBarItems = STTabBarItem.st_createTabBarItems(with: configs)
```

#### UITabBarItem 扩展

```swift
// 设置徽章
tabBarItem.st_setBadge(value: "新", color: .systemOrange)

// 清除徽章
tabBarItem.st_clearBadge()

// 更新图片
tabBarItem.st_setCustomImages(normalImageName: "new_normal", selectedImageName: "new_selected")

// 使用 UIImage 对象设置图片
tabBarItem.st_setCustomImages(normalImage: normalImage, selectedImage: selectedImage)
```

#### 在 TabBarController 中使用

```swift
func setupTabBarController() -> UITabBarController {
    let tabBarController = UITabBarController()
    
    // 创建视图控制器
    let homeVC = UIViewController()
    let messageVC = UIViewController()
    let profileVC = UIViewController()
    
    // 设置 TabBarItems
    homeVC.tabBarItem = STTabBarItem.st_createLocalizedTabBarItem(
        localizedTitle: "tab_home",
        normalImage: "home_normal",
        selectedImage: "home_selected"
    )
    
    messageVC.tabBarItem = STTabBarItem.st_createTabBarItem(with: STTabBarItemConfig(
        title: "tab_message",
        normalImage: "message_normal",
        selectedImage: "message_selected",
        badgeValue: "99+",
        isLocalized: true
    ))
    
    profileVC.tabBarItem = STTabBarItem.st_createLocalizedTabBarItem(
        localizedTitle: "tab_profile",
        normalImage: "profile_normal",
        selectedImage: "profile_selected"
    )
    
    // 设置视图控制器
    tabBarController.viewControllers = [homeVC, messageVC, profileVC]
    
    return tabBarController
}
```

### 四、STView (UIView 扩展)

`STView` 提供了丰富的 UIView 扩展功能，包括圆角设置、阴影效果、渐变背景、动画效果、约束布局等。它大大简化了常见的 UI 操作，提高了开发效率。

#### 主要特性

- **圆角设置**：支持自定义圆角和统一圆角设置
- **阴影效果**：灵活的阴影配置选项
- **渐变背景**：支持多种渐变效果
- **动画效果**：淡入淡出、缩放、弹性、震动等动画
- **约束布局**：便捷的 AutoLayout 辅助方法
- **视图控制器查找**：快速获取当前视图控制器
- **便捷工具**：截图、样式清除等实用功能

#### 圆角设置

```swift
// 设置统一圆角
view.st_setCornerRadius(10)

// 设置圆角和边框
view.st_setCornerRadius(10, borderWidth: 1, borderColor: .systemBlue)

// 设置自定义圆角
view.st_setCustomCorners(topLeft: 10, topRight: 5, bottomLeft: 5, bottomRight: 10)

// 使用配置结构
let cornerRadius = STCornerRadius(all: 8)
view.st_setCustomCorners(cornerRadius)
```

#### 阴影效果

```swift
// 基础阴影设置
view.st_setShadow()

// 自定义阴影
view.st_setShadow(color: .black, offset: CGSize(width: 0, height: 4), radius: 8, opacity: 0.5)

// 使用配置结构
let shadowConfig = STShadowConfig(color: .systemBlue, offset: CGSize(width: 2, height: 2), radius: 6, opacity: 0.4)
view.st_setShadow(shadowConfig)

// 清除阴影
view.st_clearShadow()
```

#### 渐变背景

```swift
// 基础渐变
view.st_setGradientBackground(colors: [.systemBlue, .systemPurple])

// 自定义渐变
view.st_setGradientBackground(
    colors: [.red, .orange, .yellow],
    startPoint: CGPoint(x: 0, y: 0),
    endPoint: CGPoint(x: 1, y: 1)
)

// 使用配置结构
let gradientConfig = STGradientConfig(
    colors: [.systemBlue, .systemTeal],
    startPoint: CGPoint(x: 0, y: 0),
    endPoint: CGPoint(x: 1, y: 0)
)
view.st_setGradientBackground(gradientConfig)

// 清除渐变
view.st_clearGradientBackground()
```

#### 动画效果

```swift
// 淡入动画
view.st_fadeIn(duration: 0.5) {
    print("淡入完成")
}

// 淡出动画
view.st_fadeOut(duration: 0.3) {
    print("淡出完成")
}

// 缩放动画
view.st_scaleAnimation(scale: 1.2, duration: 0.3)

// 弹性动画
view.st_springAnimation(scale: 1.1, duration: 0.6) {
    print("弹性动画完成")
}

// 震动动画
view.st_shakeAnimation(intensity: 15, duration: 0.5)
```

#### 约束和布局

```swift
// 添加子视图并设置边距
let subview = UIView()
parentView.st_addSubview(subview, withInsets: UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20))

// 居中添加子视图
parentView.st_addSubviewCentered(subview, size: CGSize(width: 100, height: 100))

// 设置固定尺寸
view.st_setSize(CGSize(width: 200, height: 100))

// 设置宽高比
view.st_setAspectRatio(16.0/9.0) // 16:9 比例
```

#### 视图控制器查找

```swift
// 获取当前视图控制器
if let currentVC = view.st_currentViewController() {
    print("当前视图控制器: \(currentVC)")
}

// 获取关键窗口
if let keyWindow = view.st_keyWindow() {
    print("关键窗口: \(keyWindow)")
}
```

#### 便捷工具方法

```swift
// 截图
if let screenshot = view.st_screenshot() {
    // 使用截图
}

// 移除所有子视图
view.st_removeAllSubviews()

// 设置十六进制背景色
view.st_setBackgroundColor(hex: "#FF6B6B")

// 设置边框
view.st_setBorder(width: 2, color: .systemBlue)

// 清除所有样式
view.st_clearAllStyles()
```

#### 实际应用示例

```swift
class CustomView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // 设置圆角和阴影
        st_setCornerRadius(12)
        st_setShadow(color: .black, offset: CGSize(width: 0, height: 2), radius: 8, opacity: 0.1)
        
        // 设置渐变背景
        st_setGradientBackground(colors: [.systemBlue, .systemPurple])
        
        // 添加内容视图
        let contentView = UIView()
        st_addSubview(contentView, withInsets: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16))
        contentView.backgroundColor = .white
        contentView.st_setCornerRadius(8)
    }
    
    func showWithAnimation() {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        st_fadeIn(duration: 0.3) {
            self.st_springAnimation(scale: 1.0, duration: 0.4)
        }
    }
    
    func hideWithAnimation() {
        st_fadeOut(duration: 0.2) {
            self.removeFromSuperview()
        }
    }
}
```

### 五、STHUD

`STHUD` 是一个功能强大的 HUD 提示组件，支持多种类型、主题和自定义配置。它提供了丰富的提示功能，包括成功、错误、警告、信息、加载等不同类型的提示，以及完整的主题系统和本地化支持。

#### 主要特性

- **多种 HUD 类型**：成功、错误、警告、信息、加载、进度、自定义
- **主题系统**：支持默认、浅色、深色主题，可自定义主题配置
- **本地化支持**：完整的国际化支持，与项目其他组件保持一致
- **便捷方法**：提供丰富的便捷显示方法
- **配置驱动**：使用配置结构体统一管理所有参数
- **向后兼容**：保持与原有 API 的完全兼容
- **自动图标**：根据类型自动生成对应的图标
- **位置控制**：支持顶部、居中、底部三种显示位置

#### 基础使用

```swift
// 使用原有方法（向后兼容）
view.showAutoHidden(text: "操作成功")
view.showLoadingManualHidden(text: "加载中...")
view.hideHUD()

// 使用新的便捷方法
view.st_showSuccess(title: "操作成功")
view.st_showError(title: "操作失败", detailText: "请检查网络连接")
view.st_showWarning(title: "警告", detailText: "此操作不可撤销")
view.st_showInfo(title: "提示", detailText: "新功能已上线")
view.st_showLoading(text: "加载中...")
view.st_hideHUD()
```

#### 使用配置显示

```swift
// 使用配置结构体
let config = STHUDConfig(
    type: .success,
    title: "操作成功",
    detailText: "数据已保存",
    location: .center,
    autoHide: true,
    hideDelay: 2.0,
    theme: .light,
    isLocalized: true
)
view.st_showHUD(with: config)

// 直接使用 STHUD 类
let hud = STHUD.sharedHUD
hud.showSuccess(title: "成功", detailText: "操作完成")
hud.showError(title: "错误", detailText: "网络连接失败")
hud.showLoading(title: "加载中...")
hud.hide(animated: true)
```

#### 主题配置

```swift
// 使用预设主题
let lightTheme = STHUDTheme.light
let darkTheme = STHUDTheme.dark
let defaultTheme = STHUDTheme.default

// 自定义主题
let customTheme = STHUDTheme(
    backgroundColor: UIColor.systemBlue.withAlphaComponent(0.9),
    textColor: .white,
    detailTextColor: .lightGray,
    successColor: .systemGreen,
    errorColor: .systemRed,
    warningColor: .systemOrange,
    infoColor: .systemBlue,
    loadingColor: .systemBlue,
    cornerRadius: 12,
    shadowEnabled: true
)

// 应用主题
STHUD.sharedHUD.applyTheme(customTheme)
```

#### 位置控制

```swift
// 顶部显示
view.st_showAutoHidden(text: "顶部提示", location: .top)

// 居中显示（默认）
view.st_showAutoHidden(text: "居中提示", location: .center)

// 底部显示
view.st_showAutoHidden(text: "底部提示", location: .bottom)
```

#### 本地化支持

```swift
// 自动本地化（默认）
view.st_showSuccess(title: "hud_success_title") // 会自动调用 localized

// 禁用本地化
let config = STHUDConfig(
    title: "Success",
    isLocalized: false
)
view.st_showHUD(with: config)
```

#### 自定义图标和视图

```swift
// 使用自定义图标
let config = STHUDConfig(
    type: .custom,
    title: "自定义提示",
    iconName: "custom_icon",
    theme: .default
)
view.st_showHUD(with: config)

// 使用自定义视图
let customView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
customView.backgroundColor = .systemPurple
customView.layer.cornerRadius = 25

let config = STHUDConfig(
    type: .custom,
    title: "自定义视图",
    customView: customView
)
view.st_showHUD(with: config)
```

#### 回调处理

```swift
// 设置完成回调
STHUD.sharedHUD.hudComplection { state in
    if state {
        print("HUD 显示完成")
    } else {
        print("HUD 隐藏完成")
    }
}
```

#### 实际应用示例

```swift
class NetworkViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // 设置主题
        STHUD.sharedHUD.applyTheme(.light)
    }
    
    // 网络请求示例
    func performNetworkRequest() {
        // 显示加载中
        view.st_showLoading(text: "正在请求...")
        
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // 隐藏加载
            self.view.st_hideHUD()
            
            // 显示结果
            if Bool.random() {
                self.view.st_showSuccess(title: "请求成功", detailText: "数据加载完成")
            } else {
                self.view.st_showError(title: "请求失败", detailText: "网络连接异常，请重试")
            }
        }
    }
    
    // 表单验证示例
    func validateForm() {
        guard !usernameTextField.text!.isEmpty else {
            view.st_showWarning(title: "用户名不能为空")
            return
        }
        
        guard passwordTextField.text!.count >= 6 else {
            view.st_showWarning(title: "密码长度不足", detailText: "密码至少需要6位字符")
            return
        }
        
        // 验证通过
        view.st_showSuccess(title: "验证通过")
    }
    
    // 批量操作示例
    func performBatchOperation() {
        let config = STHUDConfig(
            type: .loading,
            title: "批量处理中...",
            detailText: "正在处理 100 条数据",
            autoHide: false,
            theme: .dark
        )
        view.st_showHUD(with: config)
        
        // 模拟批量处理
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.view.st_hideHUD()
            
            let successConfig = STHUDConfig(
                type: .success,
                title: "批量处理完成",
                detailText: "成功处理 95 条数据，失败 5 条",
                hideDelay: 3.0
            )
            self.view.st_showHUD(with: successConfig)
        }
    }
}
```

#### 高级配置示例

```swift
class AdvancedHUDExample {
    
    func showCustomHUD() {
        // 创建自定义配置
        let config = STHUDConfig(
            type: .info,
            title: "新功能上线",
            detailText: "我们为您带来了全新的用户体验，快来体验吧！",
            location: .top,
            autoHide: true,
            hideDelay: 4.0,
            theme: STHUDTheme(
                backgroundColor: UIColor.systemIndigo.withAlphaComponent(0.9),
                textColor: .white,
                detailTextColor: .lightGray,
                cornerRadius: 16,
                shadowEnabled: true
            ),
            isLocalized: true
        )
        
        // 显示 HUD
        if let window = UIApplication.shared.windows.first {
            window.st_showHUD(with: config)
        }
    }
    
    func showProgressHUD() {
        let hud = STHUD.sharedHUD
        let targetView = UIApplication.shared.windows.first!
        
        hud.configManualHiddenHUD(showInView: targetView)
        hud.show(text: "上传中...", detailText: "0%")
        
        // 模拟进度更新
        var progress: Float = 0
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.1
            hud.progressHUD?.progress = progress
            hud.progressHUD?.detailsLabel?.text = "\(Int(progress * 100))%"
            
            if progress >= 1.0 {
                timer.invalidate()
                hud.hide(animated: true, afterDelay: 1.0)
            }
        }
    }
}
```

### 六、STLocalizationManager

`STLocalizationManager` 是一个功能强大的本地化管理器，支持多语言切换和 Storyboard 本地化。它提供了完整的国际化解决方案，包括语言切换、字符串本地化、UI 组件本地化等功能。

#### 主要特性

- **多语言支持**：支持多种语言的切换和管理
- **Storyboard 支持**：支持在 Interface Builder 中直接设置本地化键
- **自动更新**：语言切换时自动更新 UI 文本
- **通知机制**：语言切换时发送通知，便于 UI 更新
- **便捷扩展**：为常用 UI 组件提供本地化扩展

#### 支持的语言

```swift
// 支持的语言结构（动态从项目的 .lproj 文件夹获取）
public struct STSupportedLanguage {
    public let languageCode: String      // 语言代码，如 "zh-Hans"
    public let displayName: String       // 显示名称，如 "简体中文"
    public let locale: Locale            // 语言环境
    
    // 获取项目中所有可用的语言
    public static func getAvailableLanguages() -> [STSupportedLanguage]
    
    // 检查语言是否可用
    public static func isLanguageAvailable(_ languageCode: String) -> Bool
    
    // 根据语言代码获取语言对象
    public static func getLanguage(by languageCode: String) -> STSupportedLanguage?
}
```

#### 基础使用

```swift
// 在 AppDelegate 中配置
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // 配置本地化管理器
    Bundle.st_configureLocalization()
    return true
}

// 设置语言
Bundle.st_setCustomLanguage("zh-Hans")

// 获取可用语言并设置
let availableLanguages = STSupportedLanguage.getAvailableLanguages()
if let chineseLanguage = availableLanguages.first(where: { $0.languageCode == "zh-Hans" }) {
    Bundle.st_setSupportedLanguage(chineseLanguage)
}

// 获取本地化字符串
let text = Bundle.st_localizedString(key: "hello_world")
let text2 = "hello_world".localized

// 恢复系统语言
Bundle.st_restoreSystemLanguage()
```

#### Storyboard 本地化

在 Interface Builder 中可以设置以下属性：

**STLabel:**
- **Localized Text**：本地化文本键（支持动态切换）

**STBtn:**
- **Localized Title**：普通状态的本地化标题键（支持动态切换）
- **Localized Selected Title**：选中状态的本地化标题键（支持动态切换）

**STTextField:**
- **Localized Placeholder**：占位符的本地化键（支持动态切换）

#### 代码中的本地化

```swift
class LocalizedViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: STLabel!
    @IBOutlet weak var confirmButton: STBtn!
    @IBOutlet weak var inputField: STTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocalization()
    }
    
    private func setupLocalization() {
        // 设置本地化键（支持动态切换）
        titleLabel.localizedText = "welcome_title"
        confirmButton.localizedTitle = "confirm_button"
        inputField.localizedPlaceholder = "input_placeholder"
        
        // 或者直接使用本地化字符串
        titleLabel.text = "welcome_title".localized
        confirmButton.setTitle("confirm_button".localized, for: .normal)
        inputField.placeholder = "input_placeholder".localized
    }
    
    // 语言切换时更新 UI
    @objc private func languageDidChange() {
        st_updateLocalizedTexts()
    }
}
```

#### 语言切换和通知

```swift
class LanguageSettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLanguageObserver()
    }
    
    private func setupLanguageObserver() {
        // 监听语言切换通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .stLanguageDidChange,
            object: nil
        )
    }
    
    @objc private func languageDidChange() {
        // 更新当前页面的本地化文本
        st_updateLocalizedTexts()
    }
    
    @IBAction func switchToChinese() {
        if let chineseLanguage = STSupportedLanguage.getLanguage(by: "zh-Hans") {
            Bundle.st_setSupportedLanguage(chineseLanguage)
        }
    }
    
    @IBAction func switchToEnglish() {
        if let englishLanguage = STSupportedLanguage.getLanguage(by: "en") {
            Bundle.st_setSupportedLanguage(englishLanguage)
        }
    }
    
    @IBAction func switchToJapanese() {
        if let japaneseLanguage = STSupportedLanguage.getLanguage(by: "ja") {
            Bundle.st_setSupportedLanguage(japaneseLanguage)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
```

#### 高级功能

```swift
// 检查语言包是否存在
let isAvailable = Bundle.st_isLanguageAvailable("zh-Hans")

// 获取所有可用的语言
let availableLanguages = STSupportedLanguage.getAvailableLanguages()
let availableLanguageCodes = Bundle.st_getAvailableLanguageCodes()

// 获取当前语言
let currentLanguage = Bundle.st_getCurrentLanguage()
let currentLanguageObject = Bundle.st_getCurrentLanguageObject()

// 获取系统语言
let systemLanguage = Bundle.st_getSystemLanguage()
```

#### 实际应用示例

```swift
class MultiLanguageApp {
    
    static func configure() {
        // 配置本地化管理器
        Bundle.st_configureLocalization()
        
        // 设置默认语言（如果没有保存的设置）
        if Bundle.st_getCurrentLanguage() == nil {
            let systemLanguage = Bundle.st_getSystemLanguage()
            let supportedLanguage = STSupportedLanguage(rawValue: systemLanguage) ?? .english
            Bundle.st_setSupportedLanguage(supportedLanguage)
        }
    }
    
    static func switchLanguage(_ languageCode: String) {
        if let language = STSupportedLanguage.getLanguage(by: languageCode) {
            Bundle.st_setSupportedLanguage(language)
            
            // 发送语言切换通知，让所有页面更新
            NotificationCenter.default.post(name: .stLanguageDidChange, object: nil)
        }
    }
}

// 在 AppDelegate 中使用
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    MultiLanguageApp.configure()
    return true
}

#### 动态语言选择示例

```swift
class LanguageSelectionViewController: UIViewController {
    
    @IBOutlet weak var languageTableView: UITableView!
    private var availableLanguages: [STSupportedLanguage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLanguages()
        setupTableView()
    }
    
    private func setupLanguages() {
        // 动态获取项目中所有可用的语言
        availableLanguages = STSupportedLanguage.getAvailableLanguages()
        
        // 获取当前语言
        let currentLanguage = Bundle.st_getCurrentLanguage()
        
        // 将当前语言移到列表顶部
        if let currentIndex = availableLanguages.firstIndex(where: { $0.languageCode == currentLanguage }) {
            let currentLanguage = availableLanguages.remove(at: currentIndex)
            availableLanguages.insert(currentLanguage, at: 0)
        }
    }
    
    private func setupTableView() {
        languageTableView.delegate = self
        languageTableView.dataSource = self
        languageTableView.register(UITableViewCell.self, forCellReuseIdentifier: "LanguageCell")
    }
}

extension LanguageSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableLanguages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LanguageCell", for: indexPath)
        let language = availableLanguages[indexPath.row]
        
        cell.textLabel?.text = language.displayName
        cell.detailTextLabel?.text = language.languageCode
        
        // 标记当前选中的语言
        if language.languageCode == Bundle.st_getCurrentLanguage() {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let language = availableLanguages[indexPath.row]
        Bundle.st_setSupportedLanguage(language)
        
        // 更新 UI
        tableView.reloadData()
        
        // 显示切换成功提示
        let alert = UIAlertController(title: "语言切换", message: "已切换到 \(language.displayName)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
```

### 四、STBaseViewController

`STBaseViewController` 是一个功能强大的基础视图控制器类，专门用于定制导航栏样式。所有继承自 `STBaseViewController` 的视图控制器都可以使用统一的导航栏样式，同时支持子类进行个性化定制。

#### 主要特性

- **导航栏样式支持**：浅色、深色、自定义导航栏
- **丰富的配置选项**：背景色、标题颜色、字体、按钮样式等
- **灵活的按钮配置**：支持图片和文字组合，左右按钮独立配置
- **现代化设计**：支持 iOS 13+ 深色模式，自动适配不同屏幕尺寸

#### 快速开始

```swift
class MyViewController: STBaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置标题
        self.st_setTitle("我的页面")
        
        // 显示导航栏和左按钮
        self.st_showNavBtnType(type: .showLeftBtn)
        
        // 设置导航栏样式
        self.st_setNavigationBarStyle(.light)
    }
}
```

#### 导航栏样式

```swift
// 浅色导航栏
self.st_setNavigationBarStyle(.light)

// 深色导航栏
self.st_setNavigationBarStyle(.dark)

// 自定义导航栏
self.st_setNavigationBarStyle(.custom)
self.st_setNavigationBarBackgroundColor(UIColor.systemBlue)
self.st_setNavigationBarTitleColor(UIColor.white)
```

#### 按钮配置

```swift
// 设置左按钮
self.st_setLeftButton(image: UIImage(named: "back_icon"), title: "返回")

// 设置右按钮
self.st_setRightButton(image: UIImage(named: "more_icon"), title: "更多")

// 自定义按钮样式
self.st_setButtonTitleColor(UIColor.white)
self.st_setButtonTitleFont(UIFont.systemFont(ofSize: 18))
```

#### 自定义标题视图

```swift
let titleView = createCustomTitleView()
self.st_setTitleView(titleView)
```

#### 状态栏控制

```swift
// 隐藏状态栏
self.st_setStatusBarHidden(true)
```

### 五、STBaseWKViewController

`STBaseWKViewController` 是一个功能强大的 WebView 控制器类，专门用于全局样式的 WebView 加载。它基于 `STBaseViewController` 构建，提供了完整的 WebView 功能，包括加载状态管理、错误处理、JavaScript 交互等。

#### 主要特性

- **多种内容加载方式**：URL 加载、HTML 内容、自定义背景
- **丰富的配置选项**：媒体播放、用户代理、数据存储等
- **完整的状态管理**：加载状态、自动指示器、进度显示
- **JavaScript 交互**：消息处理、脚本执行、弹窗处理
- **错误处理**：网络错误、加载失败、自定义处理

#### 快速开始

```swift
class MyWebViewController: STBaseWKViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 配置 WebView 信息
        self.webInfo = STWebInfo(
            url: "https://www.example.com",
            titleText: "示例页面",
            showProgressView: true,
            enableJavaScript: true
        )
        
        // 加载内容
        self.st_loadWebInfo()
    }
}
```

#### HTML 内容加载

```swift
let htmlContent = """
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body { font-family: -apple-system; margin: 20px; }
        h1 { color: #007AFF; }
    </style>
</head>
<body>
    <h1>欢迎使用 STBaseWKViewController</h1>
    <p>这是一个优化的 WebView 控制器。</p>
</body>
</html>
"""

self.webInfo = STWebInfo(
    htmlString: htmlContent,
    titleText: "HTML 内容",
    bgColor: "#F2F2F7",
    enableJavaScript: true
)
```

#### JavaScript 交互

```swift
class InteractiveWebViewController: STBaseWKViewController, STWebViewMessageHandler {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置消息处理器
        self.messageHandler = self
        
        // 添加消息处理器
        self.st_addScriptMessageHandler(name: "nativeHandler")
        
        self.st_loadWebInfo()
    }
    
    // MARK: - STWebViewMessageHandler
    func webView(_ webView: WKWebView, didReceiveMessage message: WKScriptMessage) {
        if message.name == "nativeHandler" {
            // 处理来自 WebView 的消息
            print("收到消息: \(message.body)")
        }
    }
}
```

#### 自定义配置

```swift
// 自定义 WebView 配置
self.webViewConfig = STWebViewConfig(
    allowsInlineMediaPlayback: true,
    mediaTypesRequiringUserActionForPlayback: [],
    allowsAirPlayForMediaPlayback: true,
    allowsPictureInPictureMediaPlayback: true,
    customUserAgent: "MyApp/1.0"
)

// 自定义 WebView 信息
self.webInfo = STWebInfo(
    url: "https://www.youtube.com",
    titleText: "视频播放",
    allowsBackForwardNavigationGestures: true,
    allowsLinkPreview: true,
    isScrollEnabled: true,
    showProgressView: true,
    enableJavaScript: true,
    enableZoom: true
)
```

#### 导航控制

```swift
// 后退
self.st_goBack()

// 前进
self.st_goForward()

// 重新加载
self.st_reload()

// 停止加载
self.st_stopLoading()
```

#### JavaScript 执行

```swift
// 执行 JavaScript 代码
self.st_evaluateJavaScript("document.title") { result, error in
    if let title = result as? String {
        print("页面标题: \(title)")
    }
}

// 发送数据到 WebView
let data = ["name": "iOS 用户", "device": "iPhone"]
let script = "receiveDataFromNative(\(data))"
self.st_evaluateJavaScript(script)
```

### 六、STBaseView

`STBaseView` 是一个功能强大的基础视图类，提供了多种布局模式和自动滚动功能。它可以根据内容大小自动选择合适的布局方式，支持 ScrollView、TableView、CollectionView 等多种布局模式。

#### 主要特性

- **多种布局模式**：自动、滚动、固定、表格、集合视图
- **智能滚动检测**：根据内容大小自动决定是否需要滚动
- **灵活的滚动方向**：支持垂直、水平、双向滚动
- **自动布局支持**：完整的 Auto Layout 约束管理
- **便捷的代理设置**：快速设置 TableView 和 CollectionView 代理

#### 布局模式

```swift
// 自动检测是否需要滚动
st_setLayoutMode(.auto)

// 强制使用ScrollView
st_setLayoutMode(.scroll)

// 固定布局，不滚动
st_setLayoutMode(.fixed)

// 使用TableView布局
st_setLayoutMode(.table)

// 使用CollectionView布局
st_setLayoutMode(.collection)
```

#### 滚动方向设置

```swift
// 垂直滚动
st_setScrollDirection(.vertical)

// 水平滚动
st_setScrollDirection(.horizontal)

// 双向滚动
st_setScrollDirection(.both)

// 不滚动
st_setScrollDirection(.none)
```

#### 基础使用

```swift
class MyCustomView: STBaseView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // 设置布局模式
        st_setLayoutMode(.auto)
        st_setScrollDirection(.vertical)
        
        // 创建子视图
        let titleLabel = UILabel()
        titleLabel.text = "标题"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加到内容区域
        st_addSubviewToContent(titleLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: st_getContentView().topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: st_getContentView().leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: st_getContentView().trailingAnchor, constant: -20)
        ])
    }
}
```

#### ScrollView 模式

```swift
class ScrollViewExample: STBaseView {
    
    private func setupUI() {
        // 强制使用ScrollView模式
        st_setLayoutMode(.scroll)
        st_setScrollDirection(.vertical)
        
        // 创建多个子视图
        for i in 0..<5 {
            let cardView = createCardView(index: i)
            st_addSubviewToContent(cardView)
            
            // 设置约束
            NSLayoutConstraint.activate([
                cardView.topAnchor.constraint(equalTo: st_getContentView().topAnchor, constant: CGFloat(i * 120 + 20)),
                cardView.leadingAnchor.constraint(equalTo: st_getContentView().leadingAnchor, constant: 20),
                cardView.trailingAnchor.constraint(equalTo: st_getContentView().trailingAnchor, constant: -20),
                cardView.heightAnchor.constraint(equalToConstant: 100)
            ])
        }
        
        // 设置内容视图底部约束
        if let lastCard = st_getContentView().subviews.last {
            NSLayoutConstraint.activate([
                st_getContentView().bottomAnchor.constraint(equalTo: lastCard.bottomAnchor, constant: 20)
            ])
        }
    }
    
    private func createCardView(index: Int) -> UIView {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "卡片 \(index + 1)"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
}
```

#### TableView 模式

```swift
class TableViewExample: STBaseView, UITableViewDelegate, UITableViewDataSource {
    
    private func setupUI() {
        // 设置TableView模式
        st_setLayoutMode(.table)
        st_setTableViewStyle(.plain)
        
        // 设置代理
        st_setupTableView(delegate: self, dataSource: self)
        
        // 注册Cell
        st_registerTableViewCell(UITableViewCell.self)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = "行 \(indexPath.row + 1)"
        return cell
    }
}
```

#### CollectionView 模式

```swift
class CollectionViewExample: STBaseView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private func setupUI() {
        // 设置CollectionView模式
        st_setLayoutMode(.collection)
        
        // 设置代理
        st_setupCollectionView(delegate: self, dataSource: self)
        
        // 注册Cell
        st_registerCollectionViewCell(UICollectionViewCell.self)
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell", for: indexPath)
        cell.backgroundColor = .systemBlue
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
}
```

#### 公共方法

```swift
// 添加子视图到内容区域
st_addSubviewToContent(subview)

// 更新内容大小
st_updateContentSize()

// 获取当前布局模式
let mode = st_getCurrentLayoutMode()

// 获取ScrollView（如果存在）
let scrollView = st_getScrollView()

// 获取内容视图
let contentView = st_getContentView()

// 获取TableView（如果存在）
let tableView = st_getTableView()

// 获取CollectionView（如果存在）
let collectionView = st_getCollectionView()
```

### 七、STBaseModel

`STBaseModel` 是一个功能强大的统一iOS模型基类，为iOS项目提供完整的模型管理解决方案。通过继承该类，可以快速构建具有丰富功能的模型类，支持标准模式和灵活模式两种使用方式。

#### 主要特性

- **双模式支持**：标准模式和灵活模式，适用于不同场景
- **基础功能**：内存管理、键值编码、动态方法解析
- **模型工具**：属性反射、字典转换、属性更新、模型描述
- **高级功能**：对象复制、相等性比较、哈希支持、Codable支持

#### 标准模式使用

```swift
class STStandardUserModel: STBaseModel {
    var userId: String = ""
    var username: String = ""
    var email: String = ""
    var age: Int = 0
    var isActive: Bool = false
}

// 创建实例
let user = STStandardUserModel()
user.userId = "12345"
user.username = "john_doe"
user.email = "john@example.com"
user.age = 30
user.isActive = true

// 使用标准模式方法
let properties = user.st_propertyNames()
let userDict = user.st_toDictionary()
user.st_update(from: updateDict)
```

#### 灵活模式使用

```swift
class STFlexibleUserModel: STBaseModel {
    
    /// 用户ID - 可能是字符串或数字
    var userId: String {
        return st_getString(forKey: "userId", default: "")
    }
    
    /// 年龄 - 可能是字符串或数字
    var age: Int {
        return st_getInt(forKey: "age", default: 0)
    }
    
    /// 是否激活 - 可能是布尔值、字符串或数字
    var isActive: Bool {
        return st_getBool(forKey: "isActive", default: false)
    }
    
    override init() {
        super.init()
        // 启用灵活模式
        st_isFlexibleMode = true
    }
}
```

#### 字典转换

```swift
// 模型转字典
let userDict = user.st_toDictionary()
print(userDict)
// ["userId": "12345", "username": "john_doe", "email": "john@example.com", "age": 30, "isActive": true]

// 从字典更新模型
let updateDict = ["age": 31, "isActive": false]
user.st_update(from: updateDict)
```

#### JSON编码解码

```swift
// 编码为JSON
do {
    let encoder = JSONEncoder()
    let data = try encoder.encode(user)
    let jsonString = String(data: data, encoding: .utf8)
    print(jsonString ?? "")
} catch {
    print("编码错误: \(error)")
}

// 从JSON解码
do {
    let decoder = JSONDecoder()
    let decodedUser = try decoder.decode(UserModel.self, from: data)
    print(decodedUser)
} catch {
    print("解码错误: \(error)")
}
```

#### 泛型模型

```swift
class NetworkResponseModel<T: STBaseModel>: STBaseModel {
    var code: Int = 0
    var message: String = ""
    var data: T?
    var timestamp: TimeInterval = 0
}

// 使用泛型模型
let response = NetworkResponseModel<UserModel>()
response.code = 200
response.message = "success"
response.data = user
```

### 八、STBaseViewModel

`STBaseViewModel` 是一个功能强大的 ViewModel 基类，提供了完整的 MVVM 架构支持。它基于 Combine 框架构建，提供了网络请求、状态管理、缓存、分页、数据验证等丰富的功能。

#### 主要特性

- **网络请求管理**：自动处理网络错误、重试机制、JSON 解析
- **状态管理**：加载状态、刷新状态、错误状态管理
- **缓存管理**：内存缓存、磁盘缓存、缓存策略
- **分页管理**：自动分页加载、下拉刷新、上拉加载更多
- **数据验证**：表单验证、响应验证、自定义验证规则
- **数据绑定**：基于 Combine 的响应式数据绑定

#### 基础使用

```swift
class UserListViewModel: STBaseViewModel {
    
    @Published var users: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    override init() {
        super.init()
        st_setupBindings()
        st_setupConfig()
    }
    
    private func st_setupBindings() {
        // 绑定加载状态
        st_bindLoadingState(to: self, keyPath: \.isLoading)
        
        // 绑定错误信息
        st_bindError(to: self, keyPath: \.errorMessage)
        
        // 绑定数据更新
        st_bindDataUpdate(to: self) { [weak self] _ in
            self?.st_handleDataUpdate()
        }
    }
    
    private func st_setupConfig() {
        // 配置请求参数
        requestConfig = STRequestConfig(
            timeoutInterval: 30,
            retryCount: 2,
            showLoading: true,
            showError: true
        )
        
        // 配置分页参数
        paginationConfig = STPaginationConfig(
            pageSize: 20,
            currentPage: 1,
            hasMoreData: true
        )
        
        // 配置缓存参数
        cacheConfig = STCacheConfig(
            enableCache: true,
            cacheKey: "user_list",
            cacheExpiration: 300,
            cachePolicy: .both
        )
    }
    
    override func st_loadData(page: Int) {
        let url = URL(string: "https://api.example.com/users?page=\(page)")!
        let request = st_createRequest(url: url)
        
        st_request(request, responseType: UserListResponse.self) { [weak self] result in
            switch result {
            case .success(let response):
                self?.st_handleSuccess(response)
            case .failure(let error):
                self?.st_handleFailure(error)
            }
        }
    }
}
```

#### 网络请求

```swift
// GET 请求
st_get(url: "https://api.example.com/users", responseType: UserListResponse.self) { result in
    switch result {
    case .success(let response):
        print("获取用户列表成功: \(response.data.count) 个用户")
    case .failure(let error):
        print("获取用户列表失败: \(error.errorDescription ?? "")")
    }
}

// POST 请求
let parameters = ["name": "张三", "email": "zhangsan@example.com"]
st_post(url: "https://api.example.com/users", parameters: parameters, responseType: UserResponse.self) { result in
    switch result {
    case .success(let response):
        print("创建用户成功: \(response.data.name)")
    case .failure(let error):
        print("创建用户失败: \(error.errorDescription ?? "")")
    }
}

// PUT 请求
st_put(url: "https://api.example.com/users/123", parameters: parameters, responseType: UserResponse.self) { result in
    // 处理响应
}

// DELETE 请求
st_delete(url: "https://api.example.com/users/123", responseType: UserResponse.self) { result in
    // 处理响应
}
```

#### 缓存管理

```swift
// 设置缓存
st_setCache(userData, forKey: "user_cache")

// 获取缓存
if let cachedData = st_getCache(forKey: "user_cache") {
    print("从缓存获取数据: \(cachedData)")
}

// 移除缓存
st_removeCache(forKey: "user_cache")

// 清空缓存
st_clearCache()
```

#### 分页管理

```swift
// 刷新数据
st_refresh()

// 加载下一页
st_loadNextPage()

// 重写加载数据方法
override func st_loadData(page: Int) {
    let url = URL(string: "https://api.example.com/users?page=\(page)")!
    let request = st_createRequest(url: url)
    
    st_request(request, responseType: UserListResponse.self) { [weak self] result in
        // 处理响应
    }
}
```

#### 数据验证

```swift
// 表单验证
class FormViewModel: STBaseViewModel {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isFormValid: Bool = false
    
    private func st_validateForm() {
        let isEmailValid = st_validateEmail(email)
        let isPasswordValid = password.count >= 6
        isFormValid = isEmailValid && isPasswordValid
    }
    
    func submitForm() {
        guard isFormValid else {
            let error = STBaseError.validationError("表单验证失败")
            self.error.send(error)
            return
        }
        
        // 提交表单
    }
}
```

#### 状态管理

```swift
// 监听加载状态
loadingState
    .sink { state in
        switch state {
        case .loading:
            print("正在加载...")
        case .loaded:
            print("加载完成")
        case .failed(let error):
            print("加载失败: \(error.errorDescription ?? "")")
        case .empty:
            print("数据为空")
        case .idle:
            break
        }
    }
    .store(in: &cancellables)

// 监听刷新状态
refreshState
    .sink { state in
        switch state {
        case .refreshing:
            print("正在刷新...")
        case .noMoreData:
            print("没有更多数据")
        case .failed(let error):
            print("刷新失败: \(error.errorDescription ?? "")")
        case .idle:
            break
        }
    }
    .store(in: &cancellables)
```

#### 文件上传和下载

```swift
// 上传文件
let uploadFile = STUploadFile(
    data: fileData,
    fileName: "document.pdf",
    mimeType: "application/pdf"
)

st_upload(
    url: "https://api.example.com/upload",
    parameters: ["category": "document"],
    files: [uploadFile],
    responseType: UploadResponse.self,
    progress: { progress in
        print("上传进度: \(progress.progress * 100)%")
    }
) { result in
    switch result {
    case .success(let response):
        print("文件上传成功")
    case .failure(let error):
        print("文件上传失败: \(error.errorDescription ?? "")")
    }
}

// 下载文件
st_download(
    url: "https://api.example.com/download/file.pdf",
    progress: { progress in
        print("下载进度: \(progress.progress * 100)%")
    }
) { localURL, error in
    if let localURL = localURL {
        print("文件下载成功: \(localURL)")
    } else {
        print("文件下载失败: \(error?.errorDescription ?? "")")
    }
}
```

#### 网络状态监控

```swift
// 检查网络状态
let networkStatus = st_checkNetworkStatus()
switch networkStatus {
case .reachable(let connectionType):
    switch connectionType {
    case .ethernetOrWiFi:
        print("WiFi 或以太网连接")
    case .cellular:
        print("蜂窝网络连接")
    }
case .notReachable:
    print("网络不可用")
case .unknown:
    print("网络状态未知")
}

// 等待网络可用
st_waitForNetwork {
    print("网络已可用，可以执行请求")
}
```

#### 认证和请求头管理

```swift
// 设置认证 Token
st_setAuthToken("your_token_here")

// 设置自定义请求头
st_setCustomHeaders([
    "X-Client-Version": "1.0.0",
    "X-Platform": "iOS"
])

// 清除认证信息
st_clearAuth()
```

#### 错误处理

```swift
// 自定义错误处理
override func st_onFailed(_ error: STBaseError) {
    super.st_onFailed(error)
    
    switch error {
    case .networkError(let message):
        print("网络错误: \(message)")
    case .dataError(let message):
        print("数据错误: \(message)")
    case .businessError(let code, let message):
        print("业务错误 [\(code)]: \(message)")
    default:
        print("其他错误: \(error.errorDescription ?? "")")
    }
}
```

### 九、STFileManager

`STFileManager` 是一个功能强大的文件管理器类，提供了完整的文件操作功能。它基于 `FileManager` 构建，提供了文件读写、目录管理、文件监控、类型检查等丰富的功能。

#### 主要特性

- **文件操作**：读写、创建、删除、复制、移动文件
- **目录管理**：创建目录、获取目录内容、计算目录大小
- **路径管理**：获取各种系统目录路径（文档、缓存、临时等）
- **文件监控**：监控文件变化，实时响应文件操作
- **类型检查**：自动识别图片、视频、音频、文档等文件类型
- **属性获取**：文件大小、创建时间、修改时间等详细信息
- **错误处理**：完善的错误处理和返回值管理
- **编码支持**：支持多种编码格式的文件操作

#### 基础文件操作

```swift
// 写入文件
let success = STFileManager.st_writeToFile(
    content: "Hello World",
    filePath: "/path/to/file.txt"
)

// 覆盖写入文件
let success = STFileManager.st_overwriteToFile(
    content: "New Content",
    filePath: "/path/to/file.txt"
)

// 追加内容到文件
let success = STFileManager.st_appendToFile(
    content: "\nAdditional content",
    filePath: "/path/to/file.txt"
)

// 读取文件内容
let content = STFileManager.st_readFromFile(filePath: "/path/to/file.txt")

// 读取文件数据
if let data = STFileManager.st_readDataFromFile(filePath: "/path/to/file.txt") {
    // 处理文件数据
}
```

#### 路径管理

```swift
// 获取系统目录路径
let homePath = STFileManager.st_getHomePath()
let documentsPath = STFileManager.st_getDocumentsPath()
let cachePath = STFileManager.st_getLibraryCachePath()
let tempPath = STFileManager.st_getTmpPath()
let appSupportPath = STFileManager.st_getApplicationSupportPath()

// 创建文件路径
let filePath = STFileManager.st_create(
    filePath: documentsPath,
    fileName: "example.txt"
)

// 创建临时文件
let tempFilePath = STFileManager.st_createTempFile(fileName: "temp.txt")
```

#### 目录操作

```swift
// 创建目录
let success = STFileManager.st_createDirectory(path: "/path/to/new/directory")

// 获取目录内容
let contents = STFileManager.st_getContentsOfDirectory(atPath: "/path/to/directory")

// 获取完整路径列表
let fullPaths = STFileManager.st_getFullPathsOfDirectory(atPath: "/path/to/directory")

// 计算目录大小
let directorySize = STFileManager.st_getDirectorySize(path: "/path/to/directory")

// 清空目录内容
let success = STFileManager.st_clearDirectory(path: "/path/to/directory")
```

#### 文件操作

```swift
// 复制文件
let success = STFileManager.st_copyItem(
    atPath: "/source/file.txt",
    toPath: "/destination/file.txt"
)

// 移动文件
let success = STFileManager.st_moveItem(
    atPath: "/old/location/file.txt",
    toPath: "/new/location/file.txt"
)

// 删除文件
let success = STFileManager.st_removeItem(atPath: "/path/to/file.txt")

// 检查文件是否存在
let (exists, isDirectory) = STFileManager.st_fileExistAt(path: "/path/to/file.txt")
```

#### 文件属性获取

```swift
// 获取文件属性
if let attributes = STFileManager.st_getFileAttributes(path: "/path/to/file.txt") {
    // 处理文件属性
}

// 获取文件大小
let fileSize = STFileManager.st_getFileSize(path: "/path/to/file.txt")

// 获取文件创建时间
if let creationDate = STFileManager.st_getFileCreationDate(path: "/path/to/file.txt") {
    print("文件创建时间: \(creationDate)")
}

// 获取文件修改时间
if let modificationDate = STFileManager.st_getFileModificationDate(path: "/path/to/file.txt") {
    print("文件修改时间: \(modificationDate)")
}
```

#### 文件类型检查

```swift
// 检查文件类型
let isImage = STFileManager.st_isImageFile(path: "/path/to/image.jpg")
let isVideo = STFileManager.st_isVideoFile(path: "/path/to/video.mp4")
let isAudio = STFileManager.st_isAudioFile(path: "/path/to/audio.mp3")
let isDocument = STFileManager.st_isDocumentFile(path: "/path/to/document.pdf")

// 根据文件类型进行不同处理
if STFileManager.st_isImageFile(path: filePath) {
    // 处理图片文件
    let image = UIImage(contentsOfFile: filePath)
} else if STFileManager.st_isVideoFile(path: filePath) {
    // 处理视频文件
    let videoURL = URL(fileURLWithPath: filePath)
}
```

#### 文件监控

```swift
// 监控文件变化
let fileMonitor = STFileManager.st_monitorFile(path: "/path/to/file.txt") { filePath in
    print("文件发生变化: \(filePath)")
    // 处理文件变化事件
}

// 停止监控
fileMonitor?.cancel()
```

#### URL 操作

```swift
// 从 URL 读取文件
let url = URL(fileURLWithPath: "/path/to/file.txt")
if let content = STFileManager.st_readFromURL(url: url) {
    print("文件内容: \(content)")
}

// 写入内容到 URL
let success = STFileManager.st_writeToURL(
    content: "New content",
    url: url
)
```

#### 日志管理

```swift
// 写入日志到文件
STFileManager.st_logWriteToFile()

// 获取日志输出路径
let logPath = STFileManager.st_outputLogPath()
```

#### 实际应用示例

```swift
class FileManagerExample {
    
    // 保存用户数据
    static func saveUserData(_ userData: [String: Any]) {
        let documentsPath = STFileManager.st_getDocumentsPath()
        let userDataPath = "\(documentsPath)/UserData"
        
        // 确保目录存在
        STFileManager.st_createDirectory(path: userDataPath)
        
        // 保存数据
        let dataString = userData.description
        let filePath = "\(userDataPath)/user_data.txt"
        STFileManager.st_writeToFile(content: dataString, filePath: filePath)
    }
    
    // 清理缓存
    static func clearCache() {
        let cachePath = STFileManager.st_getLibraryCachePath()
        let success = STFileManager.st_clearDirectory(path: cachePath)
        
        if success {
            print("缓存清理成功")
        } else {
            print("缓存清理失败")
        }
    }
    
    // 获取应用大小
    static func getAppSize() -> String {
        let documentsPath = STFileManager.st_getDocumentsPath()
        let libraryPath = STFileManager.st_getLibraryPath()
        
        let documentsSize = STFileManager.st_getDirectorySize(path: documentsPath)
        let librarySize = STFileManager.st_getDirectorySize(path: libraryPath)
        
        let totalSize = documentsSize + librarySize
        let sizeInMB = Double(totalSize) / (1024 * 1024)
        
        return String(format: "%.2f MB", sizeInMB)
    }
    
    // 备份重要文件
    static func backupImportantFiles() {
        let documentsPath = STFileManager.st_getDocumentsPath()
        let backupPath = "\(documentsPath)/Backup"
        
        // 创建备份目录
        STFileManager.st_createDirectory(path: backupPath)
        
        // 获取所有重要文件
        let importantFiles = STFileManager.st_getContentsOfDirectory(atPath: documentsPath)
            .filter { fileName in
                // 过滤重要文件
                return fileName.hasSuffix(".db") || fileName.hasSuffix(".json")
            }
        
        // 复制到备份目录
        for fileName in importantFiles {
            let sourcePath = "\(documentsPath)/\(fileName)"
            let backupFilePath = "\(backupPath)/\(fileName)"
            STFileManager.st_copyItem(atPath: sourcePath, toPath: backupFilePath)
        }
    }
}
```

### 十、STHexColor

`STHexColor` 是一个功能强大的颜色管理扩展，提供了完整的颜色创建、转换和管理功能。它支持暗黑模式、多种颜色格式、动态颜色创建等特性，同时支持代码和 Interface Builder 两种使用方式。

#### 主要特性

- **多种颜色创建方式**：十六进制、RGB、颜色集等
- **完整的暗黑模式支持**：iOS 13+ 动态颜色，iOS 11+ 颜色集
- **Interface Builder 支持**：@IBInspectable 属性，支持在 Storyboard 中设置
- **颜色操作工具**：透明度调整、颜色混合、对比色获取等
- **向后兼容性**：保持旧版本 API 的兼容性
- **系统颜色预设**：常用系统颜色的暗黑模式适配

#### 基础颜色创建

```swift
// 从十六进制字符串创建颜色
let color1 = UIColor.st_color(hexString: "#FF0000")
let color2 = UIColor.st_color(hexString: "0xFF0000")
let color3 = UIColor.st_color(hexString: "FF0000")

// 带透明度的颜色
let colorWithAlpha = UIColor.st_color(hexString: "#FF0000", alpha: 0.5)

// 从 RGB 值创建颜色
let rgbColor = UIColor.st_color(red: 255, green: 0, blue: 0)
let rgbColorWithAlpha = UIColor.st_color(red: 255, green: 0, blue: 0, alpha: 0.8)

// 从 0-1 范围的 RGB 值创建颜色
let normalizedColor = UIColor.st_color(red: 1.0, green: 0.0, blue: 0.0)
```

#### 暗黑模式支持

```swift
// 创建支持暗黑模式的动态颜色
if #available(iOS 13.0, *) {
    let dynamicColor = UIColor.st_dynamicColor(
        lightHex: "#FFFFFF",  // 浅色模式：白色
        darkHex: "#000000"    // 暗黑模式：黑色
    )
    
    // 带透明度的动态颜色
    let dynamicColorWithAlpha = UIColor.st_dynamicColor(
        lightHex: "#007AFF",
        darkHex: "#0A84FF",
        alpha: 0.8
    )
}

// 兼容 iOS 13 以下的动态颜色
let compatibleColor = UIColor.st_dynamicColor(
    lightHex: "#FFFFFF",
    darkHex: "#000000",
    defaultHex: "#FFFFFF"  // iOS 13 以下使用的默认颜色
)

// 从 Assets 中的颜色集创建颜色
if #available(iOS 11.0, *) {
    let colorSetColor = UIColor.st_color(colorSet: "PrimaryColor")
    let colorSetColorWithAlpha = UIColor.st_color(colorSet: "PrimaryColor", alpha: 0.8)
}
```

#### 颜色操作工具

```swift
// 调整透明度
let originalColor = UIColor.st_color(hexString: "#FF0000")
let transparentColor = originalColor.st_withAlpha(0.5)

// 混合两个颜色
let redColor = UIColor.st_color(hexString: "#FF0000")
let blueColor = UIColor.st_color(hexString: "#0000FF")
let mixedColor = redColor.st_blend(with: blueColor, ratio: 0.5)

// 获取对比色（用于文字等）
let backgroundColor = UIColor.st_color(hexString: "#FFFFFF")
let textColor = backgroundColor.st_contrastColor() // 返回黑色

// 获取颜色亮度
let brightness = backgroundColor.st_brightness()
```

#### 系统颜色预设

```swift
if #available(iOS 13.0, *) {
    // 系统主色调
    let primaryColor = UIColor.st_systemPrimary
    
    // 系统背景色
    let backgroundColor = UIColor.st_systemBackground
    
    // 系统标签色
    let labelColor = UIColor.st_systemLabel
    
    // 系统次要标签色
    let secondaryLabelColor = UIColor.st_systemSecondaryLabel
    
    // 系统分隔线色
    let separatorColor = UIColor.st_systemSeparator
}
```

#### 便捷颜色创建

```swift
// 创建随机颜色
let randomColor = UIColor.st_random()
let randomColorWithAlpha = UIColor.st_random(alpha: 0.8)

// 从图片获取主色调
if let image = UIImage(named: "avatar") {
    let dominantColor = UIColor.st_dominantColor(from: image)
}
```

#### Interface Builder 支持

```swift
// 在 Storyboard 中使用 STDynamicColorView
class CustomViewController: UIViewController {
    
    @IBOutlet weak var dynamicColorView: STDynamicColorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 代码中也可以动态设置
        dynamicColorView.lightHexColor = "#FFFFFF"
        dynamicColorView.darkHexColor = "#000000"
        dynamicColorView.colorAlpha = 0.8
    }
}
```

在 Interface Builder 中可以设置以下属性：
- **Light Hex Color**：浅色模式下的十六进制颜色
- **Dark Hex Color**：暗黑模式下的十六进制颜色  
- **Color Alpha**：透明度值

#### 动态颜色管理

```swift
// 从 JSON 文件加载颜色配置
UIColor.st_resolvedColor(jsonString: "/path/to/colors.json")

// 使用配置中的动态颜色
let dynamicColor = UIColor.st_color(dynamicProvider: "primary")

// 清理关联对象
UIColor.st_cleanColorAssociatedObject()
```

JSON 配置文件格式：
```json
{
    "primary": {
        "light": "#007AFF",
        "dark": "#0A84FF"
    },
    "background": {
        "light": "#FFFFFF",
        "dark": "#000000"
    }
}
```

#### 实际应用示例

```swift
class ThemeManager {
    
    // 应用主题颜色
    static func applyTheme() {
        if #available(iOS 13.0, *) {
            // 使用动态颜色
            let primaryColor = UIColor.st_dynamicColor(
                lightHex: "#007AFF",
                darkHex: "#0A84FF"
            )
            
            let backgroundColor = UIColor.st_dynamicColor(
                lightHex: "#F2F2F7",
                darkHex: "#1C1C1E"
            )
            
            // 应用到全局样式
            UINavigationBar.appearance().tintColor = primaryColor
            UINavigationBar.appearance().backgroundColor = backgroundColor
        } else {
            // iOS 13 以下使用静态颜色
            let primaryColor = UIColor.st_color(hexString: "#007AFF")
            let backgroundColor = UIColor.st_color(hexString: "#F2F2F7")
            
            UINavigationBar.appearance().tintColor = primaryColor
            UINavigationBar.appearance().backgroundColor = backgroundColor
        }
    }
    
    // 创建渐变颜色
    static func createGradientColors() -> [UIColor] {
        let startColor = UIColor.st_color(hexString: "#FF6B6B")
        let endColor = UIColor.st_color(hexString: "#4ECDC4")
        
        return [startColor, endColor]
    }
}

// 在视图控制器中使用
class MyViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置背景色（支持暗黑模式）
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.st_dynamicColor(
                lightHex: "#FFFFFF",
                darkHex: "#000000"
            )
        } else {
            view.backgroundColor = UIColor.st_color(hexString: "#FFFFFF")
        }
        
        // 设置标签颜色
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.st_color(hexString: "#333333")
        titleLabel.backgroundColor = UIColor.st_color(hexString: "#F0F0F0", alpha: 0.8)
    }
}
```

### 十一、STJSONValue

`STJSONValue` 是一个功能强大的 JSON 处理扩展，提供了完整的 JSON 创建、解析、转换和管理功能。它整合了项目中所有 JSON 相关的方法，提供统一的 API 接口，支持多种数据类型和 Codable 协议。

#### 主要特性

- **统一的 JSON 处理**：整合项目中所有 JSON 相关方法，避免重复代码
- **多种数据类型支持**：支持所有 JSON 数据类型，包括 null 值
- **完整的 Codable 支持**：编码、解码、错误处理等完整功能
- **扩展方法丰富**：为 Data、String、Dictionary、Array 等类型提供 JSON 扩展
- **工具类支持**：提供 JSON 验证、比较、合并、文件操作等实用工具
- **向后兼容性**：保持旧版本 API 的兼容性，渐进式升级

#### 基础 JSON 值类型

```swift
// 创建 JSON 值
let jsonString = STJSONValue.string("Hello")
let jsonInt = STJSONValue.int(42)
let jsonBool = STJSONValue.bool(true)
let jsonArray = STJSONValue.array([.string("item1"), .int(123)])
let jsonObject = STJSONValue.object(["name": .string("John"), "age": .int(30)])
let jsonNull = STJSONValue.null

// 获取值
let stringValue = jsonString.stringValue        // "Hello"
let intValue = jsonInt.intValue                // 42
let boolValue = jsonBool.boolValue             // true
let arrayValue = jsonArray.arrayValue          // [STJSONValue]
let objectValue = jsonObject.objectValue       // [String: STJSONValue]
let isNull = jsonNull.isNull                   // true
```

#### Data JSON 扩展

```swift
// 从 Data 解析 JSON
let data: Data = // ... JSON 数据
let jsonObject = data.st_toJSONObject()
let dictionary = data.st_toDictionary()
let array = data.st_toArray()

// 检查是否为有效 JSON
let isValid = data.st_isValidJSON

// 从 JSON 对象创建 Data
let newData = Data.st_fromJSONObject(["key": "value"])

// Codable 支持
let user: User? = data.st_decode(User.self)
let result: Result<User, Error> = data.st_decodeWithError(User.self)
```

#### String JSON 扩展

```swift
// 从 JSON 字符串解析
let jsonString = "{\"name\": \"John\", \"age\": 30}"
let dictionary = jsonString.st_toDictionary()
let array = jsonString.st_toArray()
let jsonObject = jsonString.st_toJSONObject()

// 检查是否为有效 JSON
let isValid = jsonString.st_isValidJSON

// Codable 支持
let user: User? = jsonString.st_decode(User.self)
let result: Result<User, Error> = jsonString.st_decodeWithError(User.self)
```

#### Dictionary JSON 扩展

```swift
let dict = ["name": "John", "age": 30, "city": "New York"]

// 转换为 JSON 字符串
let jsonString = dict.st_toJSONString()
let prettyJsonString = dict.st_toJSONString(prettyPrinted: true)

// 转换为 JSON 数据
let jsonData = dict.st_toJSONData()
let prettyJsonData = dict.st_toJSONData(prettyPrinted: true)

// 检查是否为有效 JSON
let isValid = dict.st_isValidJSON
```

#### Array JSON 扩展

```swift
let array = ["item1", "item2", "item3"]

// 转换为 JSON 字符串
let jsonString = array.st_toJSONString()
let prettyJsonString = array.st_toJSONString(prettyPrinted: true)

// 转换为 JSON 数据
let jsonData = array.st_toJSONData()
let prettyJsonData = array.st_toJSONData(prettyPrinted: true)

// 检查是否为有效 JSON
let isValid = array.st_isValidJSON
```

#### Codable 扩展

```swift
struct User: Codable {
    let name: String
    let age: Int
    let email: String
}

let user = User(name: "John", age: 30, email: "john@example.com")

// 编码为 JSON 数据
let jsonData = user.st_toJSONData()
let jsonString = user.st_toJSONString()

// 带错误处理的编码
let dataResult = user.st_toJSONDataWithError()
let stringResult = user.st_toJSONStringWithError()

switch dataResult {
case .success(let data):
    print("编码成功: \(data)")
case .failure(let error):
    print("编码失败: \(error)")
}
```

#### JSON 工具类

```swift
// 创建美化的 JSON 字符串
let prettyString = STJSONUtils.st_prettyJSONString(from: ["key": "value"])

// 验证 JSON
let isValidString = STJSONUtils.st_validateJSON(jsonString)
let isValidData = STJSONUtils.st_validateJSONData(jsonData)

// 比较两个 JSON 对象
let areEqual = STJSONUtils.st_areEqual(obj1, obj2)

// 深度合并 JSON 对象
let merged = STJSONUtils.st_merge(dict1, dict2)

// 文件操作
let jsonFromFile = STJSONUtils.st_readJSONFromFile("/path/to/file.json")
let success = STJSONUtils.st_writeJSONToFile(data, path: "/path/to/output.json", prettyPrinted: true)

// 从 Bundle 读取
let jsonFromBundle = STJSONUtils.st_readJSONFromBundle(name: "config")
let user: User? = STJSONUtils.st_readJSONFromBundle(name: "users", type: User.self)
```

#### 实际应用示例

```swift
class JSONManager {
    
    // 解析网络响应
    static func parseResponse<T: Codable>(_ data: Data, type: T.Type) -> T? {
        return data.st_decode(type)
    }
    
    // 保存用户配置
    static func saveUserConfig(_ user: User) -> Bool {
        let jsonString = user.st_toJSONString()
        guard let jsonString = jsonString else { return false }
        
        return STJSONUtils.st_writeJSONToFile(
            ["user": jsonString],
            path: "/path/to/config.json",
            prettyPrinted: true
        )
    }
    
    // 加载应用配置
    static func loadAppConfig() -> [String: Any]? {
        return STJSONUtils.st_readJSONFromBundle(name: "app_config")
    }
    
    // 验证用户输入
    static func validateUserInput(_ input: String) -> Bool {
        return STJSONUtils.st_validateJSON(input)
    }
    
    // 合并配置
    static func mergeConfigs(_ defaultConfig: [String: Any], _ userConfig: [String: Any]) -> [String: Any] {
        return STJSONUtils.st_merge(defaultConfig, userConfig)
    }
}

// 在视图控制器中使用
class SettingsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSettings()
    }
    
    private func loadSettings() {
        // 从 Bundle 加载默认配置
        if let defaultConfig = STJSONUtils.st_readJSONFromBundle(name: "default_settings") {
            print("默认配置: \(defaultConfig)")
        }
        
        // 从文件加载用户配置
        if let userConfig = STJSONUtils.st_readJSONFromFile("/path/to/user_settings.json") {
            print("用户配置: \(userConfig)")
        }
    }
    
    private func saveSettings(_ settings: [String: Any]) {
        let success = STJSONUtils.st_writeJSONToFile(
            settings,
            path: "/path/to/user_settings.json",
            prettyPrinted: true
        )
        
        if success {
            print("设置保存成功")
        } else {
            print("设置保存失败")
        }
    }
}
```

#### 迁移指南

由于已经将项目中所有 JSON 相关方法统一到 `STJSONValue.swift`，旧的方法已被移除，请使用新的方法：

```swift
// 新方法（推荐使用）
let dict = data.st_toDictionary()
let jsonString = dict.st_toJSONString()
```

### 十二、STPredicateCheck

`STPredicateCheck` 是一个功能强大的字符串验证工具类，提供了完整的正则表达式验证功能。它支持多种验证类型，包括密码、用户名、联系方式、数字、字符等，同时提供了便捷的 String 扩展方法。

#### 主要特性

- **多种验证类型**：密码、用户名、联系方式、数字、字符、网络地址、时间等
- **正则表达式常量**：预定义常用正则表达式模式，便于维护和复用
- **密码强度检测**：支持密码强度评估和描述
- **组合验证**：支持表单数据的批量验证
- **String 扩展**：为 String 类型提供便捷的验证属性
- **代码结构优化**：使用 MARK 注释分组，提高代码可读性

#### 正则表达式常量

```swift
// 使用预定义的正则表达式模式
let emailPattern = STRegexPattern.email
let phonePattern = STRegexPattern.phoneNumber
let idCardPattern = STRegexPattern.idCard
let strongPasswordPattern = STRegexPattern.strongPassword
```

#### 密码验证

```swift
// 基础密码验证
let hasCapital = STPredicateCheck.st_checkCapitalPassword(password: "MyPassword123")
let hasLowercase = STPredicateCheck.st_checkLowercasePassword(password: "MyPassword123")
let hasNumber = STPredicateCheck.st_checkNumberPassword(password: "MyPassword123")
let hasSpecialChar = STPredicateCheck.st_checkSpecialCharPassword(password: "MyPassword123")

// 密码强度验证
let strongPassword = STPredicateCheck.st_checkStrongPassword(password: "MyPassword123!")
let mediumPassword = STPredicateCheck.st_checkMediumPassword(password: "MyPassword123")
let weakPassword = STPredicateCheck.st_checkWeakPassword(password: "MyPass123")

// 密码强度评估
let strength = STPredicateCheck.st_checkPasswordStrength(password: "MyPassword123!")
let description = STPredicateCheck.st_getPasswordStrengthDescription(password: "MyPassword123!")
// 返回：强度等级（0-5）和描述（很弱、弱、中等、强、很强）
```

#### 用户名验证

```swift
// 基础用户名验证
let isValidUsername = STPredicateCheck.st_checkUserName(userName: "张三123")

// 包含空格的用户名验证
let isValidUsernameWithSpace = STPredicateCheck.st_checkUserName(
    userName: "张三 123", 
    hasSpace: true
)
```

#### 联系方式验证

```swift
// 邮箱验证
let isValidEmail = STPredicateCheck.st_checkEmail(email: "user@example.com")

// 手机号验证（中国大陆）
let isValidPhone = STPredicateCheck.st_checkPhoneNum(phoneNum: "13800138000")

// 身份证号验证（中国大陆）
let isValidIdCard = STPredicateCheck.st_checkIdCard(idCard: "110101199001011234")

// 邮政编码验证
let isValidPostalCode = STPredicateCheck.st_checkPostalCode(postalCode: "100000")

// 银行卡号验证
let isValidBankCard = STPredicateCheck.st_checkBankCard(bankCard: "6222021234567890123")

// 信用卡号验证
let isValidCreditCard = STPredicateCheck.st_checkCreditCard(creditCard: "4000123456789012")
```

#### 数字验证

```swift
// 基础数字验证
let isDigits = STPredicateCheck.st_checkIsDigit(text: "12345")
let isInteger = STPredicateCheck.st_checkIsInteger(text: "-123")
let isPositiveInteger = STPredicateCheck.st_checkIsPositiveInteger(text: "123")
let isNonNegativeInteger = STPredicateCheck.st_checkIsNonNegativeInteger(text: "0")
let isFloat = STPredicateCheck.st_checkIsFloat(text: "123.45")
let isPositiveFloat = STPredicateCheck.st_checkIsPositiveFloat(text: "123.45")
```

#### 字符验证

```swift
// 中文字符验证
let isChinese = STPredicateCheck.st_checkChinaChar(text: "中文")

// 英文字母验证
let isEnglish = STPredicateCheck.st_checkEnglishLetters(text: "English")
let isUppercase = STPredicateCheck.st_checkUppercaseLetters(text: "ABC")
let isLowercase = STPredicateCheck.st_checkLowercaseLetters(text: "abc")

// 字母数字组合验证
let isAlphanumeric = STPredicateCheck.st_checkAlphanumeric(text: "ABC123")

// 标点符号验证
let isPunctuation = STPredicateCheck.st_checkPunctuation(text: "!@#$%")

// 中英文数字标点符号验证
let isNormalWithPunctuation = STPredicateCheck.st_normalWithPunctuation(text: "中文ABC123!@#")
```

#### 网络相关验证

```swift
// URL 验证
let isValidURL = STPredicateCheck.st_checkURL(url: "https://www.example.com")

// IP 地址验证
let isValidIPv4 = STPredicateCheck.st_checkIPv4(ip: "192.168.1.1")
let isValidIPv6 = STPredicateCheck.st_checkIPv6(ip: "2001:0db8:85a3:0000:0000:8a2e:0370:7334")
```

#### 时间相关验证

```swift
// 日期格式验证
let isValidDate = STPredicateCheck.st_checkDate(date: "2023-12-25")

// 时间格式验证
let isValidTime = STPredicateCheck.st_checkTime(time: "14:30:00")

// 日期时间格式验证
let isValidDateTime = STPredicateCheck.st_checkDateTime(dateTime: "2023-12-25 14:30:00")
```

#### 长度验证

```swift
// 长度范围验证
let isValidLength = STPredicateCheck.st_checkLength(text: "Hello", minLength: 3, maxLength: 10)

// 最小长度验证
let hasMinLength = STPredicateCheck.st_checkMinLength(text: "Hello", minLength: 3)

// 最大长度验证
let hasMaxLength = STPredicateCheck.st_checkMaxLength(text: "Hello", maxLength: 10)
```

#### 组合验证

```swift
// 表单数据验证
let formResult = STPredicateCheck.st_validateForm(
    email: "user@example.com",
    phone: "13800138000",
    password: "MyPassword123"
)

if formResult.isValid {
    print("表单验证通过")
} else {
    print("表单验证失败：\(formResult.errors)")
}
```

#### String 扩展

```swift
let email = "user@example.com"
let phone = "13800138000"
let password = "MyPassword123"

// 使用便捷属性验证
if email.st_isValidEmail {
    print("邮箱格式正确")
}

if phone.st_isValidPhone {
    print("手机号格式正确")
}

if password.st_isValidPassword {
    print("密码格式正确")
}

// 密码强度
let strength = password.st_passwordStrength
let description = password.st_passwordStrengthDescription
print("密码强度：\(strength)，描述：\(description)")

// 其他验证
let text = "Hello123"
if text.st_isAlphanumeric {
    print("文本包含字母和数字")
}

let chineseText = "中文"
if chineseText.st_isChinese {
    print("文本为中文字符")
}
```

#### 实际应用示例

```swift
class FormValidator {
    
    // 验证用户注册表单
    static func validateRegistrationForm(
        username: String,
        email: String,
        phone: String,
        password: String,
        confirmPassword: String
    ) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        // 用户名验证
        if !STPredicateCheck.st_checkUserName(userName: username) {
            errors.append("用户名格式不正确（1-32位中英文数字）")
        }
        
        // 邮箱验证
        if !STPredicateCheck.st_checkEmail(email: email) {
            errors.append("邮箱格式不正确")
        }
        
        // 手机号验证
        if !STPredicateCheck.st_checkPhoneNum(phoneNum: phone) {
            errors.append("手机号格式不正确")
        }
        
        // 密码验证
        if !STPredicateCheck.st_checkPassword(password: password) {
            errors.append("密码格式不正确（8-32位，包含大小写字母和数字）")
        }
        
        // 密码确认
        if password != confirmPassword {
            errors.append("两次输入的密码不一致")
        }
        
        return (errors.isEmpty, errors)
    }
    
    // 验证密码强度
    static func validatePasswordStrength(_ password: String) -> String {
        let strength = STPredicateCheck.st_checkPasswordStrength(password: password)
        let description = STPredicateCheck.st_getPasswordStrengthDescription(password: password)
        
        switch strength {
        case 0, 1:
            return "密码强度过低，建议包含大小写字母、数字和特殊字符"
        case 2:
            return "密码强度较低，建议增加字符类型"
        case 3:
            return "密码强度中等，可以考虑增加特殊字符"
        case 4:
            return "密码强度良好"
        case 5:
            return "密码强度很强"
        default:
            return "密码强度未知"
        }
    }
    
    // 验证网络配置
    static func validateNetworkConfig(
        serverURL: String,
        ipAddress: String
    ) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        if !STPredicateCheck.st_checkURL(url: serverURL) {
            errors.append("服务器URL格式不正确")
        }
        
        if !STPredicateCheck.st_checkIPv4(ip: ipAddress) && 
           !STPredicateCheck.st_checkIPv6(ip: ipAddress) {
            errors.append("IP地址格式不正确")
        }
        
        return (errors.isEmpty, errors)
    }
}

// 在视图控制器中使用
class RegistrationViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBAction func registerButtonTapped(_ sender: UIButton) {
        let result = FormValidator.validateRegistrationForm(
            username: usernameTextField.text ?? "",
            email: emailTextField.text ?? "",
            phone: phoneTextField.text ?? "",
            password: passwordTextField.text ?? "",
            confirmPassword: confirmPasswordTextField.text ?? ""
        )
        
        if result.isValid {
            // 注册逻辑
            print("表单验证通过，开始注册")
        } else {
            // 显示错误信息
            let errorMessage = result.errors.joined(separator: "\n")
            showAlert(title: "验证失败", message: errorMessage)
        }
    }
    
    // 实时密码强度检测
    @IBAction func passwordChanged(_ sender: UITextField) {
        guard let password = sender.text else { return }
        
        let strengthDescription = FormValidator.validatePasswordStrength(password)
        updatePasswordStrengthIndicator(strengthDescription)
    }
}
```

### 十三、STString

`STString` 是一个功能强大的字符串处理工具类，提供了丰富的字符串操作、类型转换、格式化、URL 处理等功能。它通过 String 扩展的方式提供便捷的字符串处理方法。

#### 主要特性

- **类型转换**：支持任意对象到字符串的转换，包括 STJSONValue 类型
- **数字格式化**：支持金额、百分比、文件大小等格式化
- **URL 处理**：支持 URL 参数提取、添加、移除等操作
- **掩码处理**：支持手机号、邮箱、身份证号等敏感信息掩码
- **命名转换**：支持驼峰命名、蛇形命名等转换
- **工具方法**：提供随机字符串生成、剪贴板操作等实用功能
- **编码转换**：编码转换功能已迁移到 STData.swift 中，提供更专业的实现

#### 类型转换

```swift
// 基础类型转换
let number = String.st_returnStr(object: 123)           // "123"
let bool = String.st_returnStr(object: true)            // "1"
let string = String.st_returnStr(object: "Hello")       // "Hello"

// STJSONValue 转换
let jsonValue = STJSONValue.string("World")
let result = String.st_returnStr(object: jsonValue)     // "World"

// 复杂类型转换
let array = [1, 2, 3]
let arrayString = String.st_returnStr(object: array)    // "1,2,3"

let dict = ["name": "张三", "age": 25]
let dictString = String.st_returnStr(object: dict)      // "{name: 张三, age: 25}"
```

#### 模型转换

```swift
// 将模型转换为参数字典
struct User {
    let name: String
    let age: Int
    let email: String
}

let user = User(name: "张三", age: 25, email: "zhangsan@example.com")
let params = String.st_convertModelToParams(user)
// 结果: ["name": "张三", "age": "25", "email": "zhangsan@example.com"]

// 将参数字典转换为 URL 编码的 Data
let data = String.st_convertDictToURLEncoded(params: params)
```

#### 尺寸计算

```swift
let text = "Hello World"
let font = UIFont.systemFont(ofSize: 16)

// 计算字符串宽度
let width = text.st_returnStrWidth(font: font)

// 计算字符串高度
let height = text.st_calculateHeight(font: font, maxWidth: 200)
```

#### 数字格式化

```swift
let amount = "1234567.89"

// 金额格式化（添加千分位分隔符）
let formattedAmount = amount.st_divideAmount()          // "1,234,567.89"

// 转换为 Double
let doubleValue = amount.st_stringToDouble()            // 1234567.89

// 转换为 Int
let intValue = "123".st_stringToInt()                   // 123

// 货币格式
let currency = "100".st_convertToCurrency(style: .currency)  // "$100.00"

// 百分比格式
let percentage = "75.5".st_convertToPercentage()        // "75.50%"

// 文件大小格式
let fileSize = "1048576".st_formatFileSize()            // "1 MB"
```

#### URL 处理

```swift
let urlString = "https://www.example.com/path?param1=value1&param2=value2"

// 提取 URL 参数
let parameters = urlString.st_parameterWithURL()
// 结果: ["param1": "value1", "param2": "value2"]

// 添加参数
let newURL = urlString.st_appendParametersToURLUsingComponents(
    parameters: ["param3": "value3"]
)
// 结果: "https://www.example.com/path?param1=value1&param2=value2&param3=value3"

// 移除参数
let cleanedURL = urlString.st_removeParametersFromURL(parameterNames: ["param1"])
// 结果: "https://www.example.com/path?param2=value2"

// URL 验证
let isValid = urlString.st_isValidURL()                 // true

// 获取域名
let domain = urlString.st_getDomainFromURL()            // "www.example.com"

// 获取路径
let path = urlString.st_getPathFromURL()                // "/path"
```

#### 掩码处理

```swift
let phone = "13800138000"
let email = "user@example.com"
let idCard = "110101199001011234"

// 手机号掩码
let maskedPhone = phone.st_maskPhoneNumber(start: 3, end: 7)  // "138****8000"

// 邮箱掩码
let maskedEmail = email.st_maskEmail()                  // "u***r@example.com"

// 身份证号掩码
let maskedIdCard = idCard.st_maskIdCard()               // "1101**********1234"
```

#### 编码转换

```swift
let text = "Hello World"

// 转换为 Data
let data = text.st_toData()                            // Data 对象

// Base64 编码（在 STData.swift 中实现）
let base64 = text.st_toBase64()                        // "SGVsbG8gV29ybGQ="

// Base64 解码
let decoded = base64.st_fromBase64()                   // "Hello World"

// URL 安全的 Base64 编码
let urlSafeBase64 = text.st_toBase64URLSafe()          // "SGVsbG8gV29ybGQ"

// 十六进制编码
let hex = text.st_toHex()                              // "48656c6c6f20576f726c64"

// 验证编码格式
let isValidBase64 = base64.st_isValidBase64()          // true
let isValidHex = hex.st_isValidHex()                   // true
```

#### 字符串处理

```swift
let text = "  Hello World  "

// 移除首尾空白
let trimmed = text.st_trim()                           // "Hello World"

// 移除所有空白
let noSpaces = text.st_removeAllWhitespaces()          // "HelloWorld"

// 首字母大写
let capitalized = "hello world".st_capitalizeFirstLetter()  // "Hello world"

// 首字母小写
let lowercased = "Hello World".st_lowercaseFirstLetter()    // "hello World"

// 驼峰命名转换
let camelCase = "hello world".st_toCamelCase()         // "helloWorld"

// 蛇形命名转换
let snakeCase = "helloWorld".st_toSnakeCase()          // "hello_world"
```

#### 工具方法

```swift
// 生成随机字符串
let random1 = String.st_generateRandomString()         // 6-10位随机字符串
let random2 = String.st_generateRandomString(length: 8) // 8位随机字符串
let random3 = String.st_generateRandomString(
    length: 12,
    includeNumbers: true,
    includeUppercase: true,
    includeLowercase: true,
    includeSymbols: true
)                                                      // 12位包含特殊符号的随机字符串

// 剪贴板操作
"Hello World".st_copyToPasteboard()                   // 复制到剪贴板
"".st_copyToPasteboard(pasteboardString: "Test")      // 复制指定字符串到剪贴板
```

#### 实际应用示例

```swift
class StringUtils {
    
    // 格式化用户信息显示
    static func formatUserInfo(_ user: User) -> String {
        let name = String.st_returnStr(object: user.name)
        let age = String.st_returnStr(object: user.age)
        let email = user.email.st_maskEmail()
        
        return "姓名: \(name), 年龄: \(age), 邮箱: \(email)"
    }
    
    // 生成 API 请求参数
    static func generateAPIParams(from model: Any) -> Data {
        let params = String.st_convertModelToParams(model)
        return String.st_convertDictToURLEncoded(params: params)
    }
    
    // 格式化文件大小显示
    static func formatFileSize(_ bytes: String) -> String {
        return bytes.st_formatFileSize()
    }
    
    // 验证和格式化 URL
    static func processURL(_ urlString: String) -> String? {
        guard urlString.st_isValidURL() else { return nil }
        
        // 移除敏感参数
        return urlString.st_removeParametersFromURL(parameterNames: ["token", "key"])
    }
    
    // 生成安全的随机密码
    static func generateSecurePassword() -> String {
        return String.st_generateRandomString(
            length: 12,
            includeNumbers: true,
            includeUppercase: true,
            includeLowercase: true,
            includeSymbols: true
        )
    }
}

// 在视图控制器中使用
class ProfileViewController: UIViewController {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUserInfo()
    }
    
    private func setupUserInfo() {
        let user = getCurrentUser()
        
        // 格式化显示
        nameLabel.text = String.st_returnStr(object: user.name)
        emailLabel.text = user.email.st_maskEmail()
        phoneLabel.text = user.phone.st_maskPhoneNumber(start: 3, end: 7)
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        let userInfo = StringUtils.formatUserInfo(getCurrentUser())
        userInfo.st_copyToPasteboard()
        showAlert(title: "已复制", message: "用户信息已复制到剪贴板")
    }
}
```

### 十四、STData

`STData` 是一个功能强大的数据处理工具类，提供了丰富的数据转换、编码解码、哈希计算、文件操作等功能。它通过 Data 扩展的方式提供便捷的数据处理方法。

#### 主要特性

- **字符串转换**：支持 Data 与 String 之间的双向转换
- **十六进制操作**：支持十六进制字符串的编码解码
- **Base64 操作**：支持标准 Base64 和 URL 安全的 Base64 编码解码
- **哈希计算**：支持 MD5、SHA1、SHA256、SHA512 等哈希算法
- **文件操作**：支持数据的文件读写操作
- **数据压缩**：支持 LZFSE 压缩算法
- **数据验证**：提供数据有效性检查功能
- **编码转换**：为 String 提供便捷的编码转换扩展

#### 字符串转换

```swift
let data = "Hello World".data(using: .utf8)!

// 转换为字符串
let string = data.toString()                              // "Hello World"
let utf8String = data.toStringUTF8()                      // "Hello World"

// 追加字符串到 Data
var mutableData = Data()
mutableData.append("Hello", encoding: .utf8)
mutableData.append(" World", encoding: .utf8)
```

#### 十六进制操作

```swift
let data = "Hello".data(using: .utf8)!

// 转换为十六进制字符串
let hex = data.toHexString()                              // "48656c6c6f"
let upperHex = data.toHexString(uppercase: true)          // "48656C6C6F"

// 从十六进制字符串创建 Data
let hexData = Data.fromHexString("48656c6c6f")            // Data 对象
```

#### Base64 操作

```swift
let data = "Hello World".data(using: .utf8)!

// 标准 Base64 编码
let base64 = data.toBase64String()                        // "SGVsbG8gV29ybGQ="

// URL 安全的 Base64 编码
let urlSafeBase64 = data.toBase64URLSafeString()          // "SGVsbG8gV29ybGQ"

// 从 Base64 字符串创建 Data
let decodedData = Data.fromBase64String("SGVsbG8gV29ybGQ=")
let urlSafeDecodedData = Data.fromBase64URLSafeString("SGVsbG8gV29ybGQ")
```

#### 哈希计算

```swift
let data = "Hello World".data(using: .utf8)!

// 各种哈希算法
let md5 = data.md5()                                      // "b10a8db164e0754105b7a99be72e3fe5"
let sha1 = data.sha1()                                    // "0a0a9f2a6772942557ab5355d76af442f8f65e01"
let sha256 = data.sha256()                                // "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e"
let sha512 = data.sha512()                                // "2c74fd17edafd80e8447b0d46741ee243b7eb74dd2149a0ab1b9246fb30382f27e853d8585719e0e67cbda0daa8f51671064615d645ae27acb15bfb1447f459b"
```

#### 文件操作

```swift
let data = "Hello World".data(using: .utf8)!
let url = URL(fileURLWithPath: "/path/to/file.txt")

// 写入文件
let success = data.writeToFile(at: url)

// 从文件读取
let fileData = Data.fromFile(at: url)
let pathData = Data.fromFile(path: "/path/to/file.txt")
```

#### 数据大小

```swift
let data = Data(count: 1024 * 1024) // 1MB

// 获取数据大小
let bytes = data.sizeInBytes                              // 1048576
let kb = data.sizeInKB                                    // 1024.0
let mb = data.sizeInMB                                    // 1.0
let gb = data.sizeInGB                                    // 0.0009765625

// 格式化大小字符串
let formatted = data.formattedSize()                      // "1.0 MB"
```

#### 数据压缩

```swift
let originalData = "Hello World".data(using: .utf8)!

// 压缩数据
if let compressedData = originalData.compressed() {
    print("压缩后大小: \(compressedData.count)")
    
    // 解压数据
    if let decompressedData = compressedData.decompressed(expectedSize: originalData.count) {
        print("解压成功: \(String(data: decompressedData, encoding: .utf8)!)")
    }
}
```

#### 数据验证

```swift
let data = "Hello World".data(using: .utf8)!

// 数据验证
let isEmpty = data.isEmpty                                // false
let isValidUTF8 = data.isValidUTF8                        // true
let isValidJSON = data.isValidJSON                        // false
```

#### 数据操作

```swift
let data = "Hello World".data(using: .utf8)!

// 截取子数据
let subData = data.subdata(from: 6, length: 5)            // "World"

// 分割数据
let chunks = data.chunked(into: 3)                        // [Data, Data, Data, Data]
```

#### String 编码转换扩展

```swift
let text = "Hello World"

// Base64 编码解码
let base64 = text.st_toBase64()                           // "SGVsbG8gV29ybGQ="
let decoded = base64.st_fromBase64()                      // "Hello World"

// URL 安全的 Base64
let urlSafeBase64 = text.st_toBase64URLSafe()             // "SGVsbG8gV29ybGQ"
let urlSafeDecoded = urlSafeBase64.st_fromBase64URLSafe() // "Hello World"

// 十六进制编码解码
let hex = text.st_toHex()                                 // "48656c6c6f20576f726c64"
let hexDecoded = hex.st_fromHex()                         // "Hello World"

// 验证编码格式
let isValidBase64 = base64.st_isValidBase64()             // true
let isValidHex = hex.st_isValidHex()                      // true
```

#### 实际应用示例

```swift
class DataUtils {
    
    // 安全的文件传输
    static func secureFileTransfer(data: Data, to url: URL) -> Bool {
        // 计算校验和
        let checksum = data.sha256()
        
        // 压缩数据
        guard let compressedData = data.compressed() else { return false }
        
        // 写入文件
        guard compressedData.writeToFile(at: url) else { return false }
        
        // 保存校验和
        let checksumURL = url.appendingPathExtension("checksum")
        return checksum.data(using: .utf8)?.writeToFile(at: checksumURL) ?? false
    }
    
    // 验证文件完整性
    static func verifyFileIntegrity(at url: URL) -> Bool {
        guard let data = Data.fromFile(at: url),
              let checksumData = Data.fromFile(at: url.appendingPathExtension("checksum")),
              let expectedChecksum = checksumData.toString() else { return false }
        
        let actualChecksum = data.sha256()
        return actualChecksum == expectedChecksum
    }
    
    // 生成安全的随机令牌
    static func generateSecureToken(length: Int = 32) -> String {
        let randomData = STDataUtils.randomData(length: length)
        return randomData.toBase64URLSafeString()
    }
    
    // 数据加密传输
    static func encryptAndEncode(data: Data) -> String {
        // 这里可以添加实际的加密逻辑
        return data.toBase64String()
    }
    
    // 数据解密
    static func decodeAndDecrypt(encodedString: String) -> Data? {
        return Data.fromBase64String(encodedString)
    }
}

// 在视图控制器中使用
class FileViewController: UIViewController {
    
    @IBAction func uploadFile(_ sender: UIButton) {
        guard let fileData = getSelectedFileData() else { return }
        
        // 生成上传 URL
        let uploadURL = generateUploadURL()
        
        // 安全传输文件
        if DataUtils.secureFileTransfer(data: fileData, to: uploadURL) {
            showAlert(title: "上传成功", message: "文件已安全传输")
        } else {
            showAlert(title: "上传失败", message: "文件传输过程中出现错误")
        }
    }
    
    @IBAction func verifyFile(_ sender: UIButton) {
        let fileURL = getSelectedFileURL()
        
        if DataUtils.verifyFileIntegrity(at: fileURL) {
            showAlert(title: "验证成功", message: "文件完整性验证通过")
        } else {
            showAlert(title: "验证失败", message: "文件可能已损坏或被篡改")
        }
    }
}
```

### 十五、STThreadSafe

`STThreadSafe` 是一个功能强大的线程安全工具类，提供了各种线程安全的数据结构、操作和模式。它帮助开发者在多线程环境中安全地处理数据，避免竞态条件和数据竞争问题。

#### 主要特性

- **线程安全调用**：提供主线程和后台线程的安全调用方法
- **属性包装器**：使用 `@propertyWrapper` 实现线程安全的属性
- **线程安全集合**：提供线程安全的数组和字典实现
- **线程安全单例**：提供线程安全的单例模式基类
- **线程安全缓存**：提供带容量限制的线程安全缓存
- **线程安全计数器**：提供线程安全的计数器实现
- **延迟执行**：支持延迟执行和定时任务

#### 线程安全调用

```swift
// 主线程安全调用
STThreadSafe.dispatchMainAsyncSafe {
    // 在主线程执行 UI 更新
    self.updateUI()
}

// 主线程同步调用
STThreadSafe.dispatchMainSyncSafe {
    // 同步在主线程执行
    self.syncUpdate()
}

// 主线程同步调用并返回结果
let result = STThreadSafe.dispatchMainSyncSafe {
    return self.calculateResult()
}

// 后台线程异步调用
STThreadSafe.dispatchBackgroundAsync(qos: .userInitiated) {
    // 在后台线程执行耗时操作
    self.performHeavyTask()
}

// 指定队列调用
let customQueue = DispatchQueue(label: "com.example.queue")
STThreadSafe.dispatchAsync(on: customQueue) {
    // 在指定队列执行
    self.customTask()
}

// 延迟执行
STThreadSafe.dispatchAfter(delay: 2.0) {
    // 2秒后执行
    self.delayedTask()
}

STThreadSafe.dispatchMainAfter(delay: 1.0) {
    // 1秒后在主线程执行
    self.delayedUITask()
}
```

#### 线程安全属性包装器

```swift
class DataManager {
    // 使用线程安全属性包装器
    @STThreadSafeProperty var counter: Int = 0
    @STThreadSafeProperty var data: [String] = []
    @STThreadSafeProperty var settings: [String: Any] = [:]
    
    func updateData() {
        // 线程安全地更新属性
        counter += 1
        data.append("新数据")
        settings["lastUpdate"] = Date()
        
        // 使用 update 方法进行复杂更新
        _data.update { data in
            data.append("批量数据1")
            data.append("批量数据2")
        }
    }
}
```

#### 线程安全集合

```swift
// 线程安全数组
let safeArray = STThreadSafeArray<String>()

// 添加元素
safeArray.append("元素1")
safeArray.append("元素2")
safeArray.insert("插入元素", at: 1)

// 获取元素
let count = safeArray.count
let isEmpty = safeArray.isEmpty
let firstElement = safeArray[0]
let allElements = safeArray.getAll()

// 查找和过滤
let found = safeArray.first { $0.contains("元素") }
let filtered = safeArray.filter { $0.count > 3 }
let mapped = safeArray.map { $0.uppercased() }

// 移除元素
let removed = safeArray.remove(at: 0)
safeArray.removeAll()

// 线程安全字典
let safeDict = STThreadSafeDictionary<String, Int>()

// 设置和获取值
safeDict.set(100, forKey: "score")
safeDict.set(200, forKey: "level")

let score = safeDict.get(forKey: "score")
let allKeys = safeDict.keys
let allValues = safeDict.values
let allPairs = safeDict.getAll()

// 检查包含
let hasScore = safeDict.contains(key: "score")

// 移除值
let removedValue = safeDict.remove(forKey: "score")
safeDict.removeAll()
```

#### 线程安全单例

```swift
// 创建线程安全单例类
class UserManager: STThreadSafeSingleton {
    var currentUser: User?
    
    func login(_ user: User) {
        currentUser = user
    }
    
    func logout() {
        currentUser = nil
    }
}

// 使用单例
let userManager = STThreadSafeSingleton.shared(UserManager.self)
userManager.login(User(name: "张三"))

// 重置单例
STThreadSafeSingleton.reset(UserManager.self)

// 重置所有单例
STThreadSafeSingleton.resetAll()
```

#### 线程安全缓存

```swift
// 创建线程安全缓存
let cache = STThreadSafeCache<String, Data>(maxCount: 50)

// 设置缓存
let imageData = Data()
cache.set(imageData, forKey: "image1")
cache.set(imageData, forKey: "image2")

// 获取缓存
let cachedData = cache.get(forKey: "image1")

// 检查缓存
let hasImage = cache.contains(key: "image1")
let cacheCount = cache.count
let isEmpty = cache.isEmpty

// 移除缓存
let removedData = cache.remove(forKey: "image1")

// 清空缓存
cache.clear()
```

#### 线程安全计数器

```swift
// 创建线程安全计数器
let counter = STThreadSafeCounter(initialValue: 0)

// 增加计数
let newValue1 = counter.increment()        // 1
let newValue2 = counter.increment(by: 5)   // 6

// 减少计数
let newValue3 = counter.decrement()        // 5
let newValue4 = counter.decrement(by: 2)   // 3

// 获取当前值
let currentValue = counter.value           // 3

// 重置计数
counter.reset()                            // 0
```

#### 实际应用示例

```swift
class NetworkManager: STThreadSafeSingleton {
    private let cache = STThreadSafeCache<String, Data>(maxCount: 100)
    private let requestCounter = STThreadSafeCounter()
    
    func downloadImage(from url: String, completion: @escaping (Data?) -> Void) {
        // 检查缓存
        if let cachedData = cache.get(forKey: url) {
            STThreadSafe.dispatchMainAsyncSafe {
                completion(cachedData)
            }
            return
        }
        
        // 增加请求计数
        let requestId = requestCounter.increment()
        
        // 在后台线程下载
        STThreadSafe.dispatchBackgroundAsync(qos: .userInitiated) { [weak self] in
            guard let self = self else { return }
            
            // 模拟网络请求
            let imageData = self.performDownload(url: url)
            
            // 缓存数据
            if let data = imageData {
                self.cache.set(data, forKey: url)
            }
            
            // 在主线程返回结果
            STThreadSafe.dispatchMainAsyncSafe {
                completion(imageData)
            }
        }
    }
    
    private func performDownload(url: String) -> Data? {
        // 模拟网络下载
        return "模拟图片数据".data(using: .utf8)
    }
}

// 在视图控制器中使用
class ImageViewController: UIViewController {
    private let networkManager = STThreadSafeSingleton.shared(NetworkManager.self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadImage()
    }
    
    private func loadImage() {
        let imageURL = "https://example.com/image.jpg"
        
        networkManager.downloadImage(from: imageURL) { [weak self] data in
            guard let data = data else { return }
            
            // 更新 UI
            self?.displayImage(data: data)
        }
    }
    
    private func displayImage(data: Data) {
        // 显示图片
        print("显示图片数据: \(data.count) 字节")
    }
}

// 数据管理器示例
class DataManager {
    @STThreadSafeProperty var userData: [String: Any] = [:]
    @STThreadSafeProperty var isLoaded: Bool = false
    
    private let dataArray = STThreadSafeArray<String>()
    private let dataCache = STThreadSafeCache<String, String>(maxCount: 20)
    
    func loadData() {
        // 在后台线程加载数据
        STThreadSafe.dispatchBackgroundAsync { [weak self] in
            guard let self = self else { return }
            
            // 模拟数据加载
            let loadedData = ["数据1", "数据2", "数据3"]
            
            // 线程安全地更新数据
            self._dataArray.update { array in
                array.append(contentsOf: loadedData)
            }
            
            self._userData.update { data in
                data["loadedAt"] = Date()
                data["count"] = loadedData.count
            }
            
            self._isLoaded.update { isLoaded in
                isLoaded = true
            }
            
            // 缓存数据
            for (index, item) in loadedData.enumerated() {
                self.dataCache.set(item, forKey: "item_\(index)")
            }
            
            // 在主线程通知完成
            STThreadSafe.dispatchMainAsyncSafe {
                NotificationCenter.default.post(name: .dataLoaded, object: nil)
            }
        }
    }
    
    func getData(at index: Int) -> String? {
        return dataArray[index]
    }
    
    func getCachedData(for key: String) -> String? {
        return dataCache.get(forKey: key)
    }
}

extension Notification.Name {
    static let dataLoaded = Notification.Name("dataLoaded")
}
```

#### 性能优化建议

```swift
class OptimizedDataManager {
    // 使用自定义队列优化性能
    private let dataQueue = DispatchQueue(label: "com.example.data", attributes: .concurrent)
    private let cacheQueue = DispatchQueue(label: "com.example.cache", attributes: .concurrent)
    
    @STThreadSafeProperty(queue: DispatchQueue(label: "com.example.userdata", attributes: .concurrent))
    var userData: [String: Any] = [:]
    
    private let optimizedArray = STThreadSafeArray<String>(queue: dataQueue)
    private let optimizedCache = STThreadSafeCache<String, Data>(maxCount: 50, queue: cacheQueue)
    
    // 批量操作优化
    func batchUpdateData(_ items: [String]) {
        optimizedArray.update { array in
            array.append(contentsOf: items)
        }
    }
    
    // 异步批量缓存
    func batchCacheData(_ data: [(String, Data)]) {
        STThreadSafe.dispatchBackgroundAsync { [weak self] in
            guard let self = self else { return }
            
            for (key, value) in data {
                self.optimizedCache.set(value, forKey: key)
            }
        }
    }
}
```

### 十六、STHTTPSession

`STHTTPSession` 是一个功能完整的网络请求封装类，基于 `URLSession` 构建，提供了便捷的网络请求操作、参数编码、请求头管理等功能。

#### 主要特性

- **便捷的请求方法**：GET、POST、PUT、DELETE 等 HTTP 方法
- **参数编码**：URL、JSON、Form Data、Multipart 编码支持
- **请求头管理**：统一的请求头设置和管理
- **错误处理**：完善的错误类型和处理机制
- **响应处理**：状态码检查、数据解码、响应头获取
- **统一响应处理**：HTTP 和业务响应统一处理
- **网络管理**：请求取消、缓存管理、认证管理

#### 基础配置

```swift
// 全局默认配置（可选）
STHTTPSession.shared.defaultRequestHeaders.st_setAuthorization("default_token")
STHTTPSession.shared.defaultRequestConfig = STRequestConfig(
    timeoutInterval: 30,
    retryCount: 2,
    retryDelay: 1.0
)

// 每个 ViewModel 的独立配置
class UserViewModel: STBaseViewModel {
    override init() {
        super.init()
        
        // 设置独立的请求配置
        requestConfig = STRequestConfig(
            timeoutInterval: 30,
            retryCount: 3,
            showLoading: true
        )
        
        // 设置独立的请求头
        requestHeaders.st_setAuthorization("user_token")
        requestHeaders.st_setCustomHeaders([
            "X-Client-Version": "1.0.0",
            "X-Platform": "iOS"
        ])
    }
}
```

#### GET 请求

```swift
// 简单 GET 请求
STHTTPSession.shared.st_get(url: "https://api.example.com/users") { response in
    if response.isSuccess {
        if let userList = response.st_decode(UserListResponse.self) {
            print("获取用户列表成功: \(userList.data.count) 个用户")
        }
    } else {
        print("获取用户列表失败: \(response.error?.localizedDescription ?? "")")
    }
}

// 带参数的 GET 请求
let parameters = [
    "page": 1,
    "pageSize": 20,
    "status": "active"
]

STHTTPSession.shared.st_get(url: "https://api.example.com/users", parameters: parameters) { response in
    // 处理响应
}

#### 业务响应处理

```swift
// 处理标准业务响应
STHTTPSession.shared.st_get(url: "https://api.example.com/users") { response in
    if response.businessIsSuccess {
        print("业务成功: \(response.businessMessage)")
        if let userData = response.businessData as? [String: Any] {
            print("用户数据: \(userData)")
        }
    } else {
        print("业务失败: \(response.businessMessage)")
    }
}

// 处理分页响应
STHTTPSession.shared.st_get(url: "https://api.example.com/users?page=1&pageSize=20") { response in
    if response.businessIsSuccess {
        // 获取分页信息
        if let paginationInfo = response.st_paginationInfo {
            print("当前页: \(paginationInfo.page)")
            print("总数量: \(paginationInfo.totalCount)")
            print("是否有下一页: \(paginationInfo.hasNextPage)")
        }
        
        // 获取数据列表
        if let data = response.businessData as? [String: Any],
           let list = data["list"] as? [Any] {
            print("数据列表: \(list.count) 条")
        }
    }
}
```
```

#### POST 请求

```swift
// JSON 编码的 POST 请求
let parameters = [
    "name": "张三",
    "email": "zhangsan@example.com",
    "password": "123456"
]

STHTTPSession.shared.st_post(url: "https://api.example.com/users", parameters: parameters) { response in
    if response.isSuccess {
        if let userResponse = response.st_decode(UserResponse.self) {
            print("创建用户成功: \(userResponse.data.name)")
        }
    } else {
        print("创建用户失败: \(response.error?.localizedDescription ?? "")")
    }
}

// Form Data 编码的 POST 请求
STHTTPSession.shared.st_post(
    url: "https://api.example.com/login",
    parameters: parameters,
    encodingType: .formData
) { response in
    if response.isSuccess {
        if let json = response.json as? [String: Any],
           let token = json["token"] as? String {
            STHTTPSession.shared.st_setAuthToken(token)
        }
    }
}
```

#### PUT 和 DELETE 请求

```swift
// PUT 请求
STHTTPSession.shared.st_put(url: "https://api.example.com/users/123", parameters: parameters) { response in
    if response.isSuccess {
        print("更新用户成功")
    }
}

// DELETE 请求
STHTTPSession.shared.st_delete(url: "https://api.example.com/users/123") { response in
    if response.isSuccess {
        print("删除用户成功")
    }
}
```

#### 通用请求方法

```swift
// 自定义请求
STHTTPSession.shared.st_request(
    url: "https://api.example.com/search",
    method: .post,
    parameters: parameters,
    encodingType: .json
) { response in
    if response.isSuccess {
        if let json = response.json {
            print("搜索成功: \(json)")
        }
    }
}
```

#### 参数编码

```swift
let parameters = [
    "name": "张三",
    "age": 25,
    "isActive": true,
    "tags": ["iOS", "Swift", "Developer"],
    "profile": [
        "bio": "iOS 开发者",
        "location": "北京"
    ]
]

// URL 编码
let urlEncoded = STParameterEncoder.st_encodeURL(parameters)

// JSON 编码
if let jsonData = STParameterEncoder.st_encodeJSON(parameters) {
    let jsonString = String(data: jsonData, encoding: .utf8)
}

// Form Data 编码
if let formData = STParameterEncoder.st_encodeFormData(parameters) {
    let formString = String(data: formData, encoding: .utf8)
}
```

#### 响应处理

```swift
STHTTPSession.shared.st_get(url: "https://api.example.com/status") { response in
    // 检查状态码
    print("状态码: \(response.statusCode)")
    
    // 检查是否为成功响应
    if response.isSuccess {
        print("请求成功")
    } else if response.st_isClientError {
        print("客户端错误")
    } else if response.st_isServerError {
        print("服务器错误")
    }
    
    // 获取响应头
    if let contentType = response.st_getHeader("Content-Type") {
        print("Content-Type: \(contentType)")
    }
    
    // 获取响应数据
    if let json = response.json {
        print("JSON 数据: \(json)")
    }
    
    if let string = response.string {
        print("字符串数据: \(string)")
    }
    
    // 解码为指定类型
    if let userResponse = response.st_decode(UserResponse.self) {
        print("解码成功: \(userResponse.data.name)")
    }
}
```

#### 错误处理

```swift
STHTTPSession.shared.st_get(url: "https://invalid-url.com/api") { response in
    if let error = response.error as? STHTTPError {
        switch error {
        case .invalidURL:
            print("URL 无效")
        case .networkError(let networkError):
            print("网络错误: \(networkError.localizedDescription)")
        case .httpError(let code, let message):
            print("HTTP 错误 [\(code)]: \(message)")
        case .noData:
            print("无数据返回")
        case .encodingError:
            print("参数编码失败")
        case .decodingError:
            print("数据解码失败")
        }
    } else {
        print("其他错误: \(response.error?.localizedDescription ?? "")")
    }
}
```

#### 文件上传和下载

```swift
// 上传图片
STHTTPSession.shared.st_uploadImage(
    url: "https://api.example.com/upload",
    image: selectedImage,
    parameters: ["description": "用户头像"]
) { response in
    if response.isSuccess {
        print("图片上传成功")
    }
}

// 上传文件
let uploadFile = STUploadFile(
    data: fileData,
    fileName: "document.pdf",
    mimeType: "application/pdf"
)

STHTTPSession.shared.st_upload(
    url: "https://api.example.com/upload",
    parameters: ["category": "document"],
    files: [uploadFile],
    progress: { progress in
        print("上传进度: \(progress.progress * 100)%")
    }
) { response in
    if response.isSuccess {
        print("文件上传成功")
    }
}

// 下载文件
STHTTPSession.shared.st_download(
    url: "https://api.example.com/download/file.pdf",
    progress: { progress in
        print("下载进度: \(progress.progress * 100)%")
    }
) { localURL, response in
    if let localURL = localURL {
        print("文件下载成功: \(localURL)")
    }
}
```

#### 网络状态监控

```swift
// 检查网络状态
let networkStatus = STHTTPSession.shared.st_checkNetworkStatus()
switch networkStatus {
case .reachable(let connectionType):
    switch connectionType {
    case .ethernetOrWiFi:
        print("WiFi 或以太网连接")
    case .cellular:
        print("蜂窝网络连接")
    }
case .notReachable:
    print("网络不可用")
case .unknown:
    print("网络状态未知")
}

// 等待网络可用
STHTTPSession.shared.st_waitForNetwork {
    print("网络已可用，可以执行请求")
}

// 监听网络状态变化
STHTTPSession.shared.networkReachability.status
    .sink { status in
        switch status {
        case .reachable:
            print("网络已连接")
        case .notReachable:
            print("网络已断开")
        case .unknown:
            print("网络状态未知")
        }
    }
    .store(in: &cancellables)
```

#### 请求链和验证

```swift
// 带验证的请求链
STHTTPSession.shared.st_requestChain(
    url: "https://api.example.com/users",
    method: .get,
    validate: { response in
        // 自定义验证逻辑
        return response.statusCode == 200 && response.json != nil
    }
) { response in
    if response.isSuccess {
        print("请求成功并通过验证")
    } else {
        print("请求失败或验证失败")
    }
}
```

#### 网络管理

```swift
// 取消所有请求
STHTTPSession.shared.st_cancelAllRequests()

// 清除缓存
STHTTPSession.shared.st_clearCache()

// 清除认证信息
STHTTPSession.shared.st_clearAuth()

// 设置新的认证 token
STHTTPSession.shared.st_setAuthToken("new_token_here")

// 设置自定义请求头
STHTTPSession.shared.st_setCustomHeaders([
    "X-Request-ID": UUID().uuidString,
    "X-Timestamp": "\(Date().timeIntervalSince1970)"
])
```

#### 网络安全功能

STBaseProject 提供了完整的网络安全解决方案，有效防止抓包攻击：

##### SSL证书绑定 (SSL Pinning)

```swift
// 配置SSL证书绑定
let sslConfig = STSSLPinningConfig(
    enabled: true,
    certificates: [certificateData], // 服务器证书数据
    publicKeyHashes: [publicKeyHash], // 公钥哈希
    validateHost: true,
    allowInvalidCertificates: false
)

// 保存SSL配置
try STNetworkSecurityConfig.shared.st_saveSSLPinningConfig(sslConfig)
```

##### 数据加密传输

```swift
// 配置加密请求
let requestConfig = STRequestConfig(
    enableEncryption: true,
    encryptionKey: "your-encryption-key",
    enableRequestSigning: true,
    signingSecret: "your-signing-secret"
)

// 发送加密请求
STHTTPSession.shared.st_post(
    url: "https://api.example.com/secure",
    parameters: ["data": "sensitive information"],
    requestConfig: requestConfig
) { response in
    if response.isSuccess {
        print("加密请求成功")
    }
}
```

##### 安全环境检测

```swift
// 执行完整的安全检测
let result = STNetworkSecurityConfig.shared.st_performSecurityCheck()

if result.isSecure {
    print("✅ 环境安全")
} else {
    print("⚠️ 检测到安全问题:")
    for issue in result.issues {
        print("  - \(issue.description)")
    }
}

// 检测特定威胁
if STNetworkSecurityDetector.st_detectProxy() {
    print("⚠️ 检测到代理环境")
}

if STNetworkSecurityDetector.st_detectDebugging() {
    print("⚠️ 检测到调试环境")
}

if STNetworkSecurityDetector.st_detectJailbreak() {
    print("⚠️ 检测到越狱环境")
}
```

##### 反调试监控

```swift
// 启动反调试监控
let monitor = STAntiDebugMonitor()
monitor.st_startMonitoring()

// 配置反调试
let antiDebugConfig = STAntiDebugConfig(
    enabled: true,
    checkInterval: 5.0,
    enableAntiDebugging: true,
    enableAntiHooking: true,
    enableAntiTampering: true
)

try STNetworkSecurityConfig.shared.st_saveAntiDebugConfig(antiDebugConfig)
```

##### 完整的安全初始化

```swift
// 一键初始化所有安全功能
STNetworkSecurityExample.st_initializeSecurity()

// 或分步配置
STNetworkSecurityExample.st_setupSSLPinning()
STNetworkSecurityExample.st_setupEncryption()
STNetworkSecurityExample.st_setupAntiDebug()
```

##### 生物识别保护

```swift
// 使用生物识别保护敏感数据
let sensitiveData = "敏感数据".data(using: .utf8)!

try STKeychainHelper.st_saveWithBiometric(
    "sensitive_data",
    data: sensitiveData,
    reason: "使用生物识别保护您的数据"
)

// 使用生物识别读取数据
let data = try STKeychainHelper.st_loadWithBiometric(
    "sensitive_data",
    reason: "使用生物识别访问您的数据"
)
```

##### 安全最佳实践

```swift
// 查看安全最佳实践指南
STNetworkSecurityExample.st_securityBestPractices()

// 生成安全的API密钥
let apiKey = STEncryptionUtils.st_generateSecureToken(length: 32)

// 验证数据完整性
let isValid = STNetworkSecurityExample.st_verifyDataIntegrity(
    data: responseData,
    expectedHash: expectedHash
)
```

##### 数据加密解密

STBaseProject 在 Security 模块中提供了完整的端到端加密解决方案：

```swift
// 基础加密解密
let testData = "敏感数据".data(using: .utf8)!
let key = "your-encryption-key"

// 加密数据
let encryptedData = try STNetworkCrypto.st_encryptData(testData, keyString: key)

// 解密数据
let decryptedData = try STNetworkCrypto.st_decryptData(encryptedData, keyString: key)

// 字符串加密解密
let encryptedString = try STNetworkCrypto.st_encryptString("敏感字符串", keyString: key)
let decryptedString = try STNetworkCrypto.st_decryptToString(encryptedString, keyString: key)

// 字典加密解密
let dictionary = ["username": "user123", "password": "password123"]
let encryptedDict = try STNetworkCrypto.st_encryptDictionary(dictionary, keyString: key)
let decryptedDict = try STNetworkCrypto.st_decryptToDictionary(encryptedDict, keyString: key)
```

##### 签名验证

```swift
// 生成数据签名
let data = "需要签名的数据".data(using: .utf8)!
let secret = "signing-secret"
let timestamp = Date().timeIntervalSince1970

let signature = STNetworkCrypto.st_signData(data, secret: secret, timestamp: timestamp)

// 验证签名
let isValid = STNetworkCrypto.st_verifySignature(data, signature: signature, secret: secret, timestamp: timestamp)
```

##### 异步加密解密

```swift
// 异步加密
STNetworkCrypto.st_encryptDataAsync(testData, keyString: key) { result in
    switch result {
    case .success(let encryptedData):
        print("加密成功: \(encryptedData.count) 字节")
    case .failure(let error):
        print("加密失败: \(error)")
    }
}

// 异步解密
STNetworkCrypto.st_decryptDataAsync(encryptedData, keyString: key) { result in
    switch result {
    case .success(let decryptedData):
        print("解密成功")
    case .failure(let error):
        print("解密失败: \(error)")
    }
}
```

##### 服务器端配合使用

```swift
// 客户端发送加密请求
let requestConfig = STRequestConfig(
    enableEncryption: true,
    encryptionKey: "shared-secret-key",
    enableRequestSigning: true,
    signingSecret: "signing-secret"
)

STHTTPSession.shared.st_post(
    url: "https://api.example.com/secure-endpoint",
    parameters: ["data": "sensitive information"],
    requestConfig: requestConfig
) { response in
    // 响应数据已自动解密
    if response.isSuccess {
        print("加密通信成功")
    }
}
```

##### 批量加密解密

```swift
// 批量加密
let dataArray = [
    "数据1".data(using: .utf8)!,
    "数据2".data(using: .utf8)!,
    "数据3".data(using: .utf8)!
]

let encryptedArray = try STNetworkCrypto.st_encryptBatch(dataArray, keyString: key)

// 批量解密
let decryptedArray = try STNetworkCrypto.st_decryptBatch(encryptedArray, keyString: key)
```

##### 数据完整性验证

```swift
// 验证加密前后数据完整性
let originalData = "原始数据".data(using: .utf8)!
let encryptedData = try STNetworkCrypto.st_encryptData(originalData, keyString: key)

let isIntegrityValid = STNetworkCrypto.st_verifyDataIntegrity(
    originalData,
    encryptedData,
    keyString: key
)

print("数据完整性: \(isIntegrityValid ? "通过" : "失败")")
```

### 十七、STTimer

#### 主要特性

- ⏰ **高精度计时**：使用 `DispatchSourceTimer` 和 `.strict` 标志，避免 runloop mode 影响
- 🛡️ **内存安全**：使用 `weak self` 避免循环引用，自动资源释放
- 🎯 **精确控制**：毫秒级精度，支持倒计时和重复任务
- 🧹 **资源管理**：完善的定时器生命周期管理，防止内存泄露
- 📱 **线程安全**：使用信号量保护共享资源，支持多线程环境

#### 基础使用

##### 倒计时功能

```swift
// 创建10秒倒计时，每秒更新一次
let timer = STTimer(seconds: 10, repeating: 1.0)

timer.st_countdownTimerStart { remaining, isFinished in
    if isFinished {
        print("倒计时完成！")
    } else {
        print("剩余时间：\(remaining) 秒")
    }
}

// 手动取消倒计时
timer.st_countdownTimerCancel()
```

##### 重复执行任务

```swift
// 创建每2秒执行一次的重复任务
let timerName = STTimer.st_scheduledTimer(
    withTimeInterval: 2,
    repeats: true,
    async: false
) { name in
    print("重复任务执行：\(name)")
}

// 取消指定任务
STTimer.st_cancelTask(name: timerName)
```

##### 延迟执行任务

```swift
// 3秒后执行一次任务
let timerName = STTimer.st_scheduledTimer(
    afterDelay: 3,
    withTimeInterval: 1,
    repeats: false,
    async: true
) { name in
    print("延迟任务执行：\(name)")
}
```

#### 高级功能

##### 批量管理

```swift
// 取消所有定时器任务
STTimer.st_cancelAllTasks()
```

##### 内存安全特性

```swift
class MyViewController: UIViewController {
    private var timer: STTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 创建定时器，会自动处理内存释放
        timer = STTimer(seconds: 30, repeating: 1.0)
        timer?.st_countdownTimerStart { remaining, isFinished in
            // 处理倒计时逻辑
        }
    }
    
    // 无需手动释放，deinit 会自动调用
    deinit {
        timer?.st_countdownTimerCancel()
    }
}
```

#### 优化特性

1. **高精度计时**：使用 `.strict` 标志和 `userInteractive` QoS，确保精确计时
2. **内存安全**：所有闭包都使用 `[weak self]`，避免循环引用
3. **资源管理**：提供 `deinit` 方法自动清理资源
4. **线程安全**：使用信号量保护静态字典，支持并发访问
5. **错误处理**：完善的参数验证和错误日志

#### 实际应用示例

```swift
class CountdownViewController: UIViewController {
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    private var timer: STTimer?
    
    @IBAction func startCountdown(_ sender: UIButton) {
        startButton.isEnabled = false
        
        timer = STTimer(seconds: 60, repeating: 1.0)
        timer?.st_countdownTimerStart { [weak self] remaining, isFinished in
            DispatchQueue.main.async {
                if isFinished {
                    self?.countdownLabel.text = "时间到！"
                    self?.startButton.isEnabled = true
                } else {
                    self?.countdownLabel.text = "剩余：\(remaining) 秒"
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.st_countdownTimerCancel()
    }
}
```

### 七、STBtn

> Button title text and image position settings;

### 六、STDeviceInfo

> Device information and system version detection;

## API 参考

### STBaseViewController

#### 导航栏样式枚举
```swift
public enum STNavBarStyle {
    case light              // 浅色导航栏
    case dark               // 深色导航栏
    case custom             // 自定义导航栏
}
```

#### 按钮显示类型枚举
```swift
public enum STNavBtnShowType {
    case none               // 不显示导航栏
    case showBothBtn        // 显示左右按钮和标题
    case showLeftBtn        // 显示左按钮和标题
    case showRightBtn       // 显示右按钮和标题
    case onlyShowTitle      // 只显示标题
}
```

#### 主要方法
```swift
// 设置导航栏样式
func st_setNavigationBarStyle(_ style: STNavBarStyle)

// 设置导航栏背景色
func st_setNavigationBarBackgroundColor(_ color: UIColor)

// 设置导航栏标题颜色
func st_setNavigationBarTitleColor(_ color: UIColor)

// 设置导航栏标题字体
func st_setNavigationBarTitleFont(_ font: UIFont)

// 设置按钮
func st_setLeftButton(image: UIImage?, title: String? = nil)
func st_setRightButton(image: UIImage?, title: String? = nil)

// 设置标题
func st_setTitle(_ title: String)
func st_setTitleView(_ titleView: UIView)

// 显示导航栏
func st_showNavBtnType(type: STNavBtnShowType)

// 状态栏控制
func st_setStatusBarHidden(_ hidden: Bool)
```

### STBaseWKViewController

#### 数据结构
```swift
public struct STWebInfo {
    var url: String?                           // 要加载的 URL
    var titleText: String?                     // 页面标题
    var htmlString: String?                    // HTML 内容
    var bgColor: String?                       // 背景颜色
    var userAgent: String?                     // 自定义用户代理
    var allowsBackForwardNavigationGestures: Bool = true    // 前进后退手势
    var allowsLinkPreview: Bool = false        // 链接预览
    var isScrollEnabled: Bool = true           // 滚动启用
    var showProgressView: Bool = true          // 进度条显示
    var enableJavaScript: Bool = true          // JavaScript 启用
    var enableZoom: Bool = true                // 缩放启用
}

public struct STWebViewConfig {
    var allowsInlineMediaPlayback: Bool = true
    var mediaTypesRequiringUserActionForPlayback: WKAudiovisualMediaTypes = []
    var suppressesIncrementalRendering: Bool = false
    var allowsAirPlayForMediaPlayback: Bool = true
    var allowsPictureInPictureMediaPlayback: Bool = true
    var applicationNameForUserAgent: String?
    var customUserAgent: String?
    var websiteDataStore: WKWebsiteDataStore = .default()
    var processPool: WKProcessPool = WKProcessPool()
    var preferences: WKPreferences = WKPreferences()
    var userContentController: WKUserContentController = WKUserContentController()
}
```

#### 主要方法
```swift
// 加载控制
func st_loadWebInfo()
func st_reload()
func st_stopLoading()

// 导航控制
func st_goBack()
func st_goForward()

// JavaScript 交互
func st_evaluateJavaScript(_ script: String, completion: ((Any?, Error?) -> Void)? = nil)
func st_addScriptMessageHandler(name: String)
func st_removeScriptMessageHandler(name: String)

// 可重写方法
func st_handleLoadError(_ error: Error)
func st_handleScriptMessage(_ message: WKScriptMessage)
```

#### 协议
```swift
public protocol STWebViewMessageHandler: AnyObject {
    func webView(_ webView: WKWebView, didReceiveMessage message: WKScriptMessage)
}
```

## 最佳实践

### 1. 统一导航栏样式
```swift
class AppBaseViewController: STBaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置统一的导航栏样式
        self.st_setNavigationBarStyle(.light)
        self.st_setNavigationBarTitleFont(UIFont.boldSystemFont(ofSize: 18))
        self.st_setButtonTitleFont(UIFont.systemFont(ofSize: 16))
    }
}
```

### 2. 主题适配
```swift
override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    if #available(iOS 13.0, *) {
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            if self.traitCollection.userInterfaceStyle == .dark {
                self.st_setNavigationBarStyle(.dark)
            } else {
                self.st_setNavigationBarStyle(.light)
            }
        }
    }
}
```

### 3. WebView 内存管理
```swift
override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    // 移除消息处理器
    self.st_removeScriptMessageHandler(name: "myHandler")
}
```

### 4. 错误处理
```swift
override func st_handleLoadError(_ error: Error) {
    super.st_handleLoadError(error)
    
    // 记录错误日志
    STLog("WebView load error: \(error.localizedDescription)")
    
    // 发送错误报告
    // Analytics.trackError(error)
}
```

### 5. 图片管理最佳实践
```swift
// 配置图片管理器
var imageConfig = STImageManagerConfiguration()
imageConfig.allowsEditing = true
imageConfig.maxFileSize = 500
STImageManager.shared.updateConfiguration(imageConfig)

// 处理图片选择结果
STImageManager.shared.selectImage(from: self, source: .photoLibrary) { model in
    if let error = model.error {
        // 显示错误提示
        self.showErrorAlert(error.localizedDescription)
        return
    }
    
    if let image = model.editedImage {
        // 更新 UI
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
}
```

#### 图片上传（统一 API）
```swift
// 使用 STImageManager 统一上传接口
STImageManager.shared.uploadImage(
    model: model, // 来自 selectImage 的回调 model
    toURL: "https://api.example.com/upload",
    fieldName: "avatar",
    parameters: ["userId": "123"]
) { result in
    switch result {
    case .success(let responseString):
        print("上传成功: \(responseString)")
    case .failure(let error):
        print("上传失败: \(error.localizedDescription)")
    }
}

// 也可直接上传 Data（自定义文件名与 mimeType）
if let data = model.imageData {
    STImageManager.shared.upload(
        data: data,
        fileName: model.fileName ?? "image.jpg",
        mimeType: model.mimeType ?? "image/jpeg",
        fieldName: "avatar",
        toURL: "https://api.example.com/upload",
        parameters: ["userId": "123"]
    ) { result in
        // 处理结果
    }
}
```

#### 迁移与废弃项

- STImageManager 为统一图片选取与上传入口，推荐使用：
  - 选取：`STImageManager.shared.selectImage(...)` / `showImagePicker(...)`
  - 上传：`STImageManager.shared.uploadImage(...)` / `upload(data:...)`
- 以下旧类已移除（v2.1.0+）：
  - `STBaseProject/Classes/STBaseModule/STExtensionTools/STCameraManager.swift` **已删除**
  - `STBaseProject/Classes/STBaseModule/STExtensionTools/STImagePickerManager.swift` **已删除**
- STScanManager 已重构：移除对 STImagePickerManager 的依赖，现使用 STImageManager 进行图片选取
- 如果你的项目使用了旧 API：
  - `STCameraManager.openCamera/openPhotoLibrary` -> `STImageManager.selectImage`
  - `STCameraManager.uploadImage(...)` -> `STImageManager.uploadImage(...)`
  - `STImagePickerManager.openCamera/openPhotoLibrary` -> `STImageManager.selectImage`

### 6. 扫码模块使用

#### 基础扫码
```swift
import AVFoundation

class ScanViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化扫码管理器
        let scanManager = STScanManager(presentViewController: self)
        
        // 设置扫码回调
        scanManager.scanResultCallBack = { [weak self] result in
            print("扫码结果: \(result)")
            // 处理扫码结果
            self?.handleScanResult(result)
        }
        
        // 开始扫码
        scanManager.st_startScan()
    }
    
    private func handleScanResult(_ result: String) {
        // 处理二维码内容
        if result.hasPrefix("http") {
            // 是网址，可以打开浏览器
            openWebView(url: result)
        } else {
            // 其他类型内容
            showAlert(message: result)
        }
    }
}
```

#### 从相册选择图片识别二维码
```swift
class ScanViewController: UIViewController {
    private let scanManager = STScanManager(presentViewController: self)
    
    @IBAction func selectImageAndScan(_ sender: UIButton) {
        // 使用 STScanManager 新增的方法从相册选择图片并识别二维码
        scanManager.pickImageAndRecognize(
            from: .photoLibrary,
            viewController: self
        ) { [weak self] result in
            switch result {
            case .success(let qrContent):
                print("识别到二维码: \(qrContent)")
                self?.handleScanResult(qrContent)
            case .failure(let error):
                print("识别失败: \(error.localizedDescription)")
                self?.showError(error)
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "识别失败",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
```

#### 权限处理和错误处理
```swift
class ScanViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission()
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // 已授权，可以开始扫码
            startScanning()
        case .notDetermined:
            // 请求权限
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startScanning()
                    } else {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            // 权限被拒绝
            showPermissionDeniedAlert()
        @unknown default:
            break
        }
    }
    
    private func startScanning() {
        let scanManager = STScanManager(presentViewController: self)
        scanManager.scanResultCallBack = { [weak self] result in
            // 处理扫码结果
            self?.handleScanResult(result)
        }
        scanManager.st_startScan()
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "需要相机权限",
            message: "请在设置中允许相机权限以使用扫码功能",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }
}
```

#### 自定义扫码界面
```swift
class CustomScanViewController: UIViewController {
    private let scanManager = STScanManager(presentViewController: self)
    private var scanView: STScanView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomScanView()
        setupScanManager()
    }
    
    private func setupCustomScanView() {
        view.backgroundColor = .black
        
        // 使用自定义配置创建扫码视图
        var customConfig = STScanViewConfiguration()
        customConfig.tipText = "将二维码/条码放入框内，即可自动扫描"
        customConfig.tipTextFont = UIFont.systemFont(ofSize: 16)
        customConfig.cornerColor = UIColor.systemBlue
        customConfig.maskAlpha = 0.5
        customConfig.animationDuration = 2.0
        
        scanView = STScanView(frame: view.bounds, configuration: customConfig)
        scanView.scanType = .STScanTypeQrCode
        view.addSubview(scanView)
        
        // 也可以使用主题
        // scanView = STScanView(frame: view.bounds, theme: .light)
    }
    
    private func setupScanManager() {
        scanManager.scanResultCallBack = { [weak self] result in
            // 震动反馈
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // 停止扫码线动画
            self?.scanView.st_stopAnimating()
            
            // 处理结果
            self?.handleScanResult(result)
        }
        
        // 开始扫码
        scanManager.st_startScan()
        
        // 开始扫码线动画
        scanView.st_startAnimating()
    }
}
```

#### STScanView 配置选项
```swift
// 创建自定义配置
var config = STScanViewConfiguration()
config.scanAreaMargin = 80.0           // 扫码区域边距
config.scanLineHeight = 3.0            // 扫码线高度
config.maskAlpha = 0.7                 // 遮罩透明度
config.borderColor = .white            // 边框颜色
config.cornerColor = .systemBlue       // 角标颜色
config.cornerSize = CGSize(width: 20, height: 20)  // 角标尺寸
config.cornerLineWidth = 5.0           // 角标线宽
config.tipText = "自定义提示文字"        // 提示文字
config.tipTextColor = .yellow          // 提示文字颜色
config.tipTextFont = UIFont.boldSystemFont(ofSize: 14)  // 提示文字字体
config.animationDuration = 1.0         // 动画持续时间
config.animationInterval = 0.5         // 动画间隔
config.automaticSafeAreaAdaptation = true  // 自动适配安全区域

// 应用配置
let scanView = STScanView(frame: view.bounds, configuration: config)

// 或使用预设主题
let lightScanView = STScanView(frame: view.bounds, theme: .light)
let darkScanView = STScanView(frame: view.bounds, theme: .dark)

// 动态更新
scanView.updateTipText("请扫描二维码")
scanView.theme = .light
scanView.scanType = .STScanTypeBarCode

// 安全区域适配控制
scanView.setSafeAreaAdaptation(enabled: true)   // 启用自动适配（默认启用）
scanView.setSafeAreaAdaptation(enabled: false)  // 禁用自动适配
```

### 7. 本地化配置
```swift
// 在 AppDelegate 中配置本地化
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // 设置默认语言
    STLanguageManager.shared.st_setLanguage(.chinese)
    
    // 或者根据系统语言自动设置
    let preferredLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
    if preferredLanguage.hasPrefix("zh") {
        STLanguageManager.shared.st_setLanguage(.chinese)
    } else {
        STLanguageManager.shared.st_setLanguage(.english)
    }
    
    return true
}
```

### 7. 弹窗使用
```swift
// 使用统一的弹窗 API
STAlertController.st_showSystemAlert(
    title: "提示",
    message: "操作成功",
    actions: [
        STAlertActionItem(title: "确定", style: .default)
    ]
)

// 自定义弹窗
STAlertController.st_showCustomAlert(
    title: "自定义标题",
    message: "自定义消息",
    actions: [
        STAlertActionItem(title: "取消", style: .cancel),
        STAlertActionItem(title: "确定", style: .default) {
            // 处理确定操作
        }
    ]
)
```

## 注意事项

1. **继承关系**：确保你的视图控制器继承自 `STBaseViewController` 或 `STBaseWKViewController`
2. **生命周期**：在 `viewDidLoad` 中配置样式和加载内容
3. **内存管理**：及时移除消息处理器，避免内存泄漏
4. **网络安全**：注意 URL 验证和内容安全策略
5. **兼容性**：深色模式功能需要 iOS 13+ 支持

## 更新日志

### v2.1.8
- **STThreadSafe.swift 全面重构**：优化线程安全功能，新增以下特性：
  - 重构线程安全工具类：提供主线程和后台线程的安全调用方法
  - 新增线程安全属性包装器：使用 `@propertyWrapper` 实现线程安全的属性访问
  - 新增线程安全集合：提供 `STThreadSafeArray` 和 `STThreadSafeDictionary` 实现
  - 新增线程安全单例：提供 `STThreadSafeSingleton` 基类，支持线程安全的单例模式
  - 新增线程安全缓存：提供 `STThreadSafeCache` 类，支持容量限制的缓存机制
  - 新增线程安全计数器：提供 `STThreadSafeCounter` 类，支持线程安全的计数操作
  - 新增延迟执行功能：支持延迟执行和定时任务
  - 保持向后兼容性：旧方法标记为废弃但保持可用，支持渐进式升级
  - 优化代码结构：使用 MARK 注释分组，提高代码可读性和维护性
  - 完善文档注释：为所有方法添加详细的参数说明、返回值说明和使用示例
  - 提供性能优化建议：包含自定义队列、批量操作等优化方案

### v2.1.7
- **STString.swift 全面重构**：优化字符串处理功能，新增以下特性：
  - 优化类型转换逻辑：重构 `st_returnStr` 方法，增强与 `STJSONValue` 的集成
  - 新增多种类型支持：支持数组、字典、STJSONValue 等复杂类型的字符串转换
  - 新增数字格式化功能：支持 Int 转换、百分比格式、文件大小格式化等
  - 增强 URL 处理：新增 URL 验证、域名提取、路径获取、参数移除等功能
  - 新增掩码处理：支持邮箱、身份证号掩码，增强手机号掩码功能
  - 新增字符串处理：支持首字母大小写、驼峰命名、蛇形命名转换等
  - 增强工具方法：优化随机字符串生成，新增剪贴板操作、空白字符处理等
  - 移动 JSON 相关方法：将 `st_jsonStringToPrettyPrintedJson` 和 `st_dictToJSON` 迁移到 `STJSONValue` 类
  - 移动编码转换功能：将 Base64 编码解码等编码转换功能迁移到 `STData.swift` 中，提供更专业的实现
  - 优化代码结构：使用 MARK 注释分组，提高代码可读性和维护性
  - 完善文档注释：为所有方法添加详细的参数说明、返回值说明和使用示例

### v2.1.6
- **STPredicateCheck.swift 全面重构**：优化字符串验证功能，新增以下特性：
  - 新增正则表达式常量：`STRegexPattern` 结构体，预定义常用正则表达式模式
  - 增强密码验证：新增强密码、中等密码、弱密码验证，支持特殊字符检测
  - 新增多种验证类型：身份证号、邮政编码、银行卡号、信用卡号、URL、IP地址等
  - 新增时间验证：支持日期、时间、日期时间格式验证
  - 新增长度验证：支持字符串长度范围、最小长度、最大长度验证
  - 新增密码强度检测：支持密码强度评估（0-5级）和描述获取
  - 新增组合验证：支持表单数据的批量验证，返回详细错误信息
  - 新增 String 扩展：为 String 类型提供便捷的验证属性
  - 优化代码结构：使用 MARK 注释分组，提高代码可读性和维护性
  - 完善文档注释：为所有方法添加详细的参数说明、返回值说明和使用示例
  - 改进验证逻辑：统一使用私有验证方法，提高代码复用性和性能

### v2.1.5
- **STJSONValue.swift 全面重构**：统一管理项目中所有 JSON 相关方法，新增以下特性：
  - 整合所有 JSON 方法：将 STData、STDictionary、STBaseViewModel 等类中的 JSON 相关方法统一迁移
  - 增强 STJSONValue 枚举：新增 null 值支持，完善编码解码功能，提供值获取方法
  - 新增多类型扩展：为 Data、String、Dictionary、Array、Encodable 等类型提供完整的 JSON 扩展
  - 新增 JSON 工具类：提供验证、比较、合并、文件操作等实用工具方法
  - 新增 Codable 支持：完整的编码解码功能，支持错误处理和结果类型
  - 改进向后兼容性：旧方法标记为废弃但保持可用，支持渐进式升级
  - 优化代码结构：使用 MARK 注释分组，提高代码可读性和维护性
  - 完善文档注释：为所有方法添加详细的参数说明、返回值说明和使用示例
  - 新增文件操作支持：支持从文件、Bundle 读取和写入 JSON 数据
  - 统一错误处理：提供 STJSONError 枚举，统一 JSON 相关错误类型

### v2.1.4
- **STHexColor.swift 全面优化**：重构颜色管理功能，新增以下特性：
  - 增强暗黑模式支持：新增 `st_dynamicColor` 方法，支持 iOS 13+ 动态颜色创建
  - 新增 Interface Builder 支持：`STDynamicColorView` 类支持在 Storyboard 中设置暗黑模式颜色
  - 新增多种颜色创建方式：RGB 值创建、随机颜色、图片主色调提取等
  - 新增颜色操作工具：透明度调整、颜色混合、对比色获取、亮度计算等
  - 新增系统颜色预设：常用系统颜色的暗黑模式适配版本
  - 改进向后兼容性：保持旧版本 API 的兼容性，确保现有代码正常运行
  - 优化代码结构：使用 MARK 注释分组，提高代码可读性和维护性
  - 完善文档注释：为所有方法添加详细的参数说明、返回值说明和使用示例
  - 新增 JSON 配置支持：支持从配置文件动态加载颜色主题
  - 增强错误处理：改进颜色解析的健壮性和错误处理机制

### v2.1.3
- **STFileManager.swift 全面优化**：重构文件管理功能，新增以下特性：
  - 遵循项目命名规范：所有方法名添加 `st_` 前缀，确保代码一致性
  - 新增多种文件写入模式：支持覆盖写入、追加写入、编码格式自定义
  - 新增文件数据读取：支持读取文件为 Data 类型，便于二进制文件处理
  - 新增应用支持目录路径：获取 ApplicationSupport 目录路径
  - 新增文件属性管理：获取文件大小、创建时间、修改时间等详细信息
  - 新增目录大小计算：递归计算目录总大小，支持大目录管理
  - 新增文件类型检查：自动识别图片、视频、音频、文档等文件类型
  - 新增文件监控功能：实时监控文件变化，支持回调处理
  - 新增 URL 操作支持：从 URL 读取和写入文件内容
  - 改进错误处理：所有方法返回操作结果，便于错误处理
  - 优化代码结构：使用 MARK 注释分组，提高代码可读性
  - 完善文档注释：为所有方法添加详细的参数说明和返回值说明

### v2.1.2
- **STDeviceInfo.swift 全面优化**：重构设备信息获取功能，新增以下特性：
  - 移除使用苹果未开放API的代码（如CNCopySupportedInterfaces等），确保App Store审核通过
  - 新增设备型号名称映射：支持iPhone 13/14/15系列、iPad Pro/Air等最新设备
  - 新增设备类型和性能等级判断：自动识别设备类型并评估性能等级
  - 优化网络信息获取：使用Network框架替代已废弃的API，支持WiFi/蜂窝网络检测
  - 新增屏幕信息获取：屏幕尺寸、分辨率、比例、亮度、刘海屏检测等
  - 新增存储和内存监控：总容量、可用空间、使用率等详细信息
  - 改进设备安全检测：更全面的越狱检测和模拟器识别
  - 优化隐私信息处理：支持iOS 14+ AppTrackingTransparency框架
  - 新增运营商信息获取：支持双卡双待设备
  - 提供完整的使用示例和最佳实践

## 十六、STEncrypt

`STEncrypt` 是一个功能强大的加密工具类，提供了完整的加密、哈希、HMAC 和密钥派生功能。它基于 Apple 的 CryptoKit 框架，提供了安全可靠的加密解决方案。

### 主要特性

- **多种哈希算法**：支持 MD5、SHA1、SHA256、SHA384、SHA512
- **HMAC 认证**：支持 HMAC-SHA256、HMAC-SHA384、HMAC-SHA512
- **对称加密**：支持 AES-256-GCM 加密算法
- **密钥派生**：支持 PBKDF2 密钥派生算法
- **随机数生成**：提供安全的随机数和令牌生成
- **密钥管理**：提供密钥强度验证和安全比较
- **错误处理**：完善的错误处理机制
- **向后兼容**：保持与旧版本的兼容性

### 基本用法

#### 哈希算法

```swift
let text = "Hello World"

// 基本哈希
let md5Hash = text.st_md5()                    // MD5 哈希
let sha1Hash = text.st_sha1()                  // SHA1 哈希
let sha256Hash = text.st_sha256()              // SHA256 哈希
let sha384Hash = text.st_sha384()              // SHA384 哈希
let sha512Hash = text.st_sha512()              // SHA512 哈希

// 通用哈希方法
let hash = text.st_hash(algorithm: .sha256)    // 指定算法哈希
```

#### HMAC 认证

```swift
let message = "Hello World"
let key = "secret_key"

// HMAC 计算
let hmacSha256 = message.st_hmacSha256(key: key)    // HMAC-SHA256
let hmacSha512 = message.st_hmacSha512(key: key)    // HMAC-SHA512

// 通用 HMAC 方法
let hmac = message.st_hmac(key: key, algorithm: .sha256)
```

#### 对称加密

```swift
let plaintext = "Hello World"
let key = "12345678901234567890123456789012" // 32字节密钥

do {
    // 加密
    let (ciphertext, nonce) = try plaintext.st_encryptAES256GCM(key: key)
    
    // 解密
    let decrypted = try plaintext.st_decryptAES256GCM(
        ciphertext: ciphertext, 
        key: key, 
        nonce: nonce
    )
    
    print("解密结果: \(decrypted)") // "Hello World"
} catch {
    print("加密/解密失败: \(error)")
}
```

#### 密码派生

```swift
let password = "my_password"
let salt = "random_salt"

do {
    // PBKDF2 密钥派生
    let derivedKey = try password.st_pbkdf2(
        salt: salt, 
        iterations: 10000, 
        keyLength: 32
    )
    
    print("派生密钥: \(derivedKey.toHexString())")
} catch {
    print("密钥派生失败: \(error)")
}
```

#### 随机数生成

```swift
// 生成随机字符串
let randomString = String.st_randomString(length: 16)
let randomHex = String.st_randomHexString(length: 32)

// 生成随机密钥和盐值
let randomKey = STEncryptionUtils.st_generateRandomKey(length: 32)
let randomSalt = STEncryptionUtils.st_generateRandomSalt(length: 16)

// 生成安全令牌
let secureToken = STEncryptionUtils.st_generateSecureToken(length: 32)
```

#### 密钥管理

```swift
let password = "MyPassword123!"

// 验证密钥强度
let strength = STEncryptionUtils.st_validateKeyStrength(password)
print("密钥强度: \(strength)/100")

// 安全字符串比较（防止时序攻击）
let isEqual = STEncryptionUtils.st_secureCompare("password1", "password2")
```

### 实际应用示例

```swift
class SecurityManager {
    
    // 用户密码加密存储
    static func encryptPassword(_ password: String) -> (encrypted: Data, salt: Data) {
        let salt = STEncryptionUtils.st_generateRandomSalt()
        
        do {
            let derivedKey = try password.st_pbkdf2(
                salt: salt.toStringUTF8(), 
                iterations: 10000, 
                keyLength: 32
            )
            
            let keyString = derivedKey.toHexString()
            let (ciphertext, nonce) = try password.st_encryptAES256GCM(key: keyString)
            
            // 将 nonce 和 ciphertext 组合存储
            var encryptedData = Data()
            encryptedData.append(nonce.withUnsafeBytes { Data($0) })
            encryptedData.append(ciphertext)
            
            return (encryptedData, salt)
        } catch {
            fatalError("密码加密失败: \(error)")
        }
    }
    
    // 验证用户密码
    static func verifyPassword(_ password: String, encrypted: Data, salt: Data) -> Bool {
        do {
            let derivedKey = try password.st_pbkdf2(
                salt: salt.toStringUTF8(), 
                iterations: 10000, 
                keyLength: 32
            )
            
            let keyString = derivedKey.toHexString()
            
            // 分离 nonce 和 ciphertext
            let nonceData = encrypted.prefix(12) // AES-GCM nonce 长度为 12 字节
            let ciphertext = encrypted.dropFirst(12)
            
            let nonce = try AES.GCM.Nonce(data: nonceData)
            let decrypted = try password.st_decryptAES256GCM(
                ciphertext: ciphertext, 
                key: keyString, 
                nonce: nonce
            )
            
            return STEncryptionUtils.st_secureCompare(password, decrypted)
        } catch {
            return false
        }
    }
    
    // 生成 API 签名
    static func generateAPISignature(message: String, secretKey: String) -> String {
        return message.st_hmacSha256(key: secretKey)
    }
    
    // 验证 API 签名
    static func verifyAPISignature(message: String, signature: String, secretKey: String) -> Bool {
        let expectedSignature = generateAPISignature(message: message, secretKey: secretKey)
        return STEncryptionUtils.st_secureCompare(signature, expectedSignature)
    }
}

// 在视图控制器中使用
class LoginViewController: UIViewController {
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let password = passwordTextField.text else { return }
        
        // 加密密码
        let (encrypted, salt) = SecurityManager.encryptPassword(password)
        
        // 存储到 Keychain
        STKeychainHelper.st_save("user_password", value: encrypted.toBase64String())
        STKeychainHelper.st_save("user_salt", value: salt.toBase64String())
        
        // 验证密码
        if SecurityManager.verifyPassword(password, encrypted: encrypted, salt: salt) {
            showAlert(title: "登录成功", message: "密码验证通过")
        } else {
            showAlert(title: "登录失败", message: "密码验证失败")
        }
    }
}
```

### 安全建议

1. **密钥管理**：
   - 使用强密码（至少 12 位，包含大小写字母、数字和特殊字符）
   - 定期更换密钥
   - 使用安全的密钥存储方案（如 Keychain）

2. **加密算法选择**：
   - 优先使用 SHA256 或更高版本的哈希算法
   - 使用 AES-256-GCM 进行对称加密
   - 使用 PBKDF2 进行密钥派生

3. **随机数生成**：
   - 使用系统提供的安全随机数生成器
   - 确保随机数的熵值足够高

4. **错误处理**：
   - 始终处理加密/解密过程中的异常
   - 不要在错误信息中泄露敏感信息

5. **性能考虑**：
   - PBKDF2 迭代次数建议设置为 10000 或更高
   - 对于大量数据，考虑使用流式加密

## 十七、STNetworkCrypto

`STNetworkCrypto` 是一个专门用于网络通信加密的工具类，提供了完整的端到端加密解决方案。它支持多种加密算法、签名验证、批量操作和异步处理，确保网络传输数据的安全性。

### 主要特性

- **多种加密算法**：支持 AES-256-GCM 和 AES-256-CBC 算法
- **签名验证**：支持 HMAC-SHA256 签名生成和验证
- **批量操作**：支持批量加密解密操作
- **异步处理**：支持异步加密解密，避免阻塞主线程
- **数据完整性**：内置数据完整性验证功能
- **密钥管理**：支持密钥生成、缓存和管理
- **便捷方法**：提供字符串、字典等类型的便捷加密方法

### 基本用法

#### 数据加密解密

```swift
// 基础加密解密
let testData = "敏感数据".data(using: .utf8)!
let key = "your-encryption-key"

// 加密数据
let encryptedData = try STNetworkCrypto.st_encryptData(testData, keyString: key)

// 解密数据
let decryptedData = try STNetworkCrypto.st_decryptData(encryptedData, keyString: key)
```

#### 字符串加密解密

```swift
// 字符串加密
let encryptedString = try STNetworkCrypto.st_encryptString("敏感字符串", keyString: key)

// 字符串解密
let decryptedString = try STNetworkCrypto.st_decryptToString(encryptedString, keyString: key)
```

#### 字典加密解密

```swift
// 字典加密
let dictionary = ["username": "user123", "password": "password123"]
let encryptedDict = try STNetworkCrypto.st_encryptDictionary(dictionary, keyString: key)

// 字典解密
let decryptedDict = try STNetworkCrypto.st_decryptToDictionary(encryptedDict, keyString: key)
```

#### 签名验证

```swift
// 生成数据签名
let data = "需要签名的数据".data(using: .utf8)!
let secret = "signing-secret"
let timestamp = Date().timeIntervalSince1970

let signature = STNetworkCrypto.st_signData(data, secret: secret, timestamp: timestamp)

// 验证签名
let isValid = STNetworkCrypto.st_verifySignature(data, signature: signature, secret: secret, timestamp: timestamp)
```

#### 异步处理

```swift
// 异步加密
STNetworkCrypto.st_encryptDataAsync(testData, keyString: key) { result in
    switch result {
    case .success(let encryptedData):
        print("加密成功: \(encryptedData.count) 字节")
    case .failure(let error):
        print("加密失败: \(error)")
    }
}

// 异步解密
STNetworkCrypto.st_decryptDataAsync(encryptedData, keyString: key) { result in
    switch result {
    case .success(let decryptedData):
        print("解密成功")
    case .failure(let error):
        print("解密失败: \(error)")
    }
}
```

#### 批量操作

```swift
// 批量加密
let dataArray = [
    "数据1".data(using: .utf8)!,
    "数据2".data(using: .utf8)!,
    "数据3".data(using: .utf8)!
]

let encryptedArray = try STNetworkCrypto.st_encryptBatch(dataArray, keyString: key)

// 批量解密
let decryptedArray = try STNetworkCrypto.st_decryptBatch(encryptedArray, keyString: key)
```

#### 数据完整性验证

```swift
// 验证加密前后数据完整性
let originalData = "原始数据".data(using: .utf8)!
let encryptedData = try STNetworkCrypto.st_encryptData(originalData, keyString: key)

let isIntegrityValid = STNetworkCrypto.st_verifyDataIntegrity(
    originalData,
    encryptedData,
    keyString: key
)

print("数据完整性: \(isIntegrityValid ? "通过" : "失败")")
```

### 实际应用示例

```swift
class SecureAPIManager {
    
    // 发送加密请求
    static func sendSecureRequest(url: String, parameters: [String: Any]) {
        let requestConfig = STRequestConfig(
            enableEncryption: true,
            encryptionKey: "shared-secret-key",
            enableRequestSigning: true,
            signingSecret: "signing-secret"
        )
        
        STHTTPSession.shared.st_post(
            url: url,
            parameters: parameters,
            requestConfig: requestConfig
        ) { response in
            if response.isSuccess {
                print("加密请求成功")
            } else {
                print("请求失败: \(response.error?.localizedDescription ?? "")")
            }
        }
    }
    
    // 本地数据加密存储
    static func encryptAndStoreData(_ data: [String: Any], key: String) throws {
        let encryptedData = try STNetworkCrypto.st_encryptDictionary(data, keyString: key)
        try STKeychainHelper.st_saveData("encrypted_data", data: encryptedData)
    }
    
    // 本地数据解密读取
    static func loadAndDecryptData(key: String) throws -> [String: Any]? {
        guard let encryptedData = try STKeychainHelper.st_loadData("encrypted_data") else {
            return nil
        }
        return try STNetworkCrypto.st_decryptToDictionary(encryptedData, keyString: key)
    }
}
```

## 十八、STKeychainHelper

`STKeychainHelper` 是一个功能强大的 Keychain 工具类，提供了安全可靠的数据存储解决方案。它基于 iOS 的 Security 框架，支持多种数据类型、访问控制、生物识别保护和 iCloud 同步功能。

### 主要特性

- **多种数据类型支持**：支持 String、Data、Bool、Int、Double 等类型
- **访问控制**：支持多种访问权限设置，包括生物识别保护
- **生物识别集成**：支持 Touch ID 和 Face ID 保护
- **iCloud 同步**：支持 Keychain 数据在设备间同步
- **批量操作**：支持批量保存、删除和查询
- **错误处理**：完善的错误处理机制
- **向后兼容**：保持与旧版本的兼容性

### 基本用法

#### 字符串操作

```swift
// 保存字符串
try STKeychainHelper.st_save("username", value: "john_doe")

// 加载字符串
let username = try STKeychainHelper.st_load("username")

// 检查是否存在
let exists = STKeychainHelper.st_exists("username")

// 删除项目
try STKeychainHelper.st_delete("username")
```

#### 数据类型操作

```swift
// 布尔值
try STKeychainHelper.st_saveBool("isFirstLaunch", value: true)
let isFirstLaunch = try STKeychainHelper.st_loadBool("isFirstLaunch", defaultValue: false)

// 整数
try STKeychainHelper.st_saveInt("userAge", value: 25)
let userAge = try STKeychainHelper.st_loadInt("userAge", defaultValue: 0)

// 浮点数
try STKeychainHelper.st_saveDouble("userScore", value: 95.5)
let userScore = try STKeychainHelper.st_loadDouble("userScore", defaultValue: 0.0)

// 数据
let imageData = UIImage(named: "avatar")?.jpegData(compressionQuality: 0.8)
try STKeychainHelper.st_saveData("userAvatar", data: imageData!)
let avatarData = try STKeychainHelper.st_loadData("userAvatar")
```

#### 访问控制

```swift
// 设备解锁时访问
try STKeychainHelper.st_save("sensitiveData", 
                            value: "secret", 
                            accessControl: .whenUnlocked)

// 仅本设备访问
try STKeychainHelper.st_save("deviceOnlyData", 
                            value: "device_specific", 
                            accessControl: .whenUnlockedThisDeviceOnly)

// 生物识别保护
try STKeychainHelper.st_save("biometricData", 
                            value: "protected", 
                            accessControl: .biometricCurrentSet)
```

#### iCloud 同步

```swift
// 启用 iCloud 同步
try STKeychainHelper.st_save("syncData", 
                            value: "will_sync", 
                            sync: .iCloud)

// 不同步到 iCloud
try STKeychainHelper.st_save("localData", 
                            value: "local_only", 
                            sync: .none)
```

#### 生物识别功能

```swift
// 检查生物识别是否可用
let isBiometricAvailable = STKeychainHelper.st_isBiometricAvailable()

// 获取生物识别类型
let biometricType = STKeychainHelper.st_getBiometricType()
switch biometricType {
case .faceID:
    print("支持 Face ID")
case .touchID:
    print("支持 Touch ID")
case .none:
    print("不支持生物识别")
@unknown default:
    print("未知生物识别类型")
}

// 使用生物识别保存数据
let sensitiveData = "highly_sensitive_info".data(using: .utf8)!
try STKeychainHelper.st_saveWithBiometric("secureData", 
                                         data: sensitiveData, 
                                         reason: "保护您的敏感数据")

// 使用生物识别加载数据
let loadedData = try STKeychainHelper.st_loadWithBiometric("secureData", 
                                                          reason: "访问您的敏感数据")
```

#### 批量操作

```swift
// 批量保存
let batchData: [String: Any] = [
    "username": "john_doe",
    "email": "john@example.com",
    "isPremium": true,
    "loginCount": 42,
    "lastScore": 95.5
]
try STKeychainHelper.st_saveBatch(batchData)

// 批量删除
let keysToDelete = ["username", "email", "isPremium"]
try STKeychainHelper.st_deleteBatch(keysToDelete)

// 获取所有键名
let allKeys = try STKeychainHelper.st_getAllKeys()
print("所有 Keychain 键名: \(allKeys)")

// 获取项目数量
let itemCount = try STKeychainHelper.st_getItemCount()
print("Keychain 项目数量: \(itemCount)")
```

### 实际应用示例

```swift
class UserManager {
    
    // 用户登录信息管理
    static func saveUserCredentials(username: String, password: String) throws {
        // 保存用户名（普通存储）
        try STKeychainHelper.st_save("username", value: username)
        
        // 保存密码（生物识别保护）
        let passwordData = password.data(using: .utf8)!
        try STKeychainHelper.st_saveWithBiometric("password", 
                                                 data: passwordData, 
                                                 reason: "保护您的登录密码")
    }
    
    static func loadUserCredentials() throws -> (username: String?, password: String?) {
        let username = try STKeychainHelper.st_load("username")
        let passwordData = try STKeychainHelper.st_loadWithBiometric("password", 
                                                                    reason: "访问您的登录密码")
        let password = passwordData?.toStringUTF8()
        
        return (username, password)
    }
    
    // 用户偏好设置
    static func saveUserPreferences(_ preferences: [String: Any]) throws {
        try STKeychainHelper.st_saveBatch(preferences)
    }
    
    static func loadUserPreferences() throws -> [String: Any] {
        let allKeys = try STKeychainHelper.st_getAllKeys()
        var preferences: [String: Any] = [:]
        
        for key in allKeys {
            if key.hasPrefix("pref_") {
                if let stringValue = try STKeychainHelper.st_load(key) {
                    preferences[key] = stringValue
                } else if let boolValue = try? STKeychainHelper.st_loadBool(key) {
                    preferences[key] = boolValue
                } else if let intValue = try? STKeychainHelper.st_loadInt(key) {
                    preferences[key] = intValue
                } else if let doubleValue = try? STKeychainHelper.st_loadDouble(key) {
                    preferences[key] = doubleValue
                }
            }
        }
        
        return preferences
    }
    
    // 清除用户数据
    static func clearUserData() throws {
        try STKeychainHelper.st_clearAll()
    }
}

// 在视图控制器中使用
class LoginViewController: UIViewController {
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let username = usernameTextField.text,
              let password = passwordTextField.text else { return }
        
        do {
            // 保存用户凭据
            try UserManager.saveUserCredentials(username: username, password: password)
            
            // 保存登录状态
            try STKeychainHelper.st_saveBool("isLoggedIn", value: true)
            try STKeychainHelper.st_saveInt("loginCount", value: 1)
            
            showAlert(title: "登录成功", message: "用户凭据已安全保存")
        } catch {
            showAlert(title: "登录失败", message: "保存凭据时出错: \(error.localizedDescription)")
        }
    }
    
    @IBAction func autoLoginButtonTapped(_ sender: UIButton) {
        do {
            let (username, password) = try UserManager.loadUserCredentials()
            
            if let username = username, let password = password {
                // 自动填充登录表单
                usernameTextField.text = username
                passwordTextField.text = password
                
                showAlert(title: "自动登录", message: "已加载保存的凭据")
            } else {
                showAlert(title: "自动登录失败", message: "未找到保存的凭据")
            }
        } catch {
            showAlert(title: "自动登录失败", message: "加载凭据时出错: \(error.localizedDescription)")
        }
    }
}

// 设置页面
class SettingsViewController: UIViewController {
    
    @IBAction func saveSettings(_ sender: UIButton) {
        let settings: [String: Any] = [
            "pref_notifications": true,
            "pref_darkMode": false,
            "pref_autoSync": true,
            "pref_cacheSize": 100
        ]
        
        do {
            try UserManager.saveUserPreferences(settings)
            showAlert(title: "设置已保存", message: "您的偏好设置已安全保存")
        } catch {
            showAlert(title: "保存失败", message: "保存设置时出错: \(error.localizedDescription)")
        }
    }
    
    @IBAction func clearAllData(_ sender: UIButton) {
        let alert = UIAlertController(title: "清除数据", 
                                    message: "确定要清除所有保存的数据吗？此操作不可撤销。", 
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { _ in
            do {
                try UserManager.clearUserData()
                self.showAlert(title: "数据已清除", message: "所有用户数据已成功清除")
            } catch {
                self.showAlert(title: "清除失败", message: "清除数据时出错: \(error.localizedDescription)")
            }
        })
        
        present(alert, animated: true)
    }
}
```

### 安全建议

1. **访问控制选择**：
   - 敏感数据使用生物识别保护
   - 设备特定数据使用 `.thisDeviceOnly` 选项
   - 根据数据敏感程度选择合适的访问控制

2. **数据类型选择**：
   - 密码和令牌使用 Data 类型存储
   - 用户偏好使用对应的类型化方法
   - 避免存储大量数据到 Keychain

3. **错误处理**：
   - 始终处理 Keychain 操作可能出现的异常
   - 提供用户友好的错误信息
   - 考虑生物识别失败的情况

4. **性能考虑**：
   - 避免频繁的 Keychain 操作
   - 使用批量操作处理多个项目
   - 缓存经常访问的数据

5. **隐私保护**：
   - 不要在 Keychain 中存储明文密码
   - 使用加密存储敏感信息
   - 定期清理不需要的数据

## 十八、STIBInspectable

`STIBInspectable` 是一个专门用于 XIB/Storyboard 布局的约束自动适配工具。它允许开发者在 Interface Builder 中直接设置约束的自动适配属性，实现不同屏幕尺寸下的自动布局适配。

### 主要特性

- **XIB/Storyboard 集成**：直接在 Interface Builder 中设置适配属性
- **多种适配类型**：支持宽度、高度、间距、边距、字体大小等适配
- **自动适配**：根据屏幕尺寸自动调整约束值
- **批量操作**：支持批量适配和重置约束
- **递归适配**：支持整个视图层次结构的约束适配
- **原始值保存**：自动保存原始约束值，支持重置

### 基本用法

#### 在 Interface Builder 中使用

1. **选择约束**：在 XIB 或 Storyboard 中选择需要适配的约束
2. **设置属性**：在 Attributes Inspector 中设置以下属性：
   - `Auto Constant`：是否启用自动适配
   - `Adapt Type`：适配类型（0-5）
   - `Custom Adapt Ratio`：自定义适配比例

#### 适配类型说明

```swift
// 适配类型枚举
public enum STConstraintAdaptType {
    case width           // 0 - 宽度适配
    case height          // 1 - 高度适配
    case both            // 2 - 宽高都适配
    case spacing         // 3 - 间距适配
    case margin          // 4 - 边距适配
    case fontSize        // 5 - 字体大小适配
    case custom(CGFloat) // 自定义比例适配
}
```

#### 代码中使用

```swift
// 手动触发约束适配
constraint.st_triggerAdapt()

// 重置约束为原始值
constraint.st_resetToOriginal()

// 获取原始约束值
let originalValue = constraint.st_getOriginalConstant()

// 获取适配后的约束值
let adaptedValue = constraint.st_getAdaptedConstant()

// 检查是否已适配
let isAdapted = constraint.st_isAdapted()
```

#### 批量操作

```swift
// 批量适配约束
let constraints = [constraint1, constraint2, constraint3]
STConstraintAdapter.st_adaptConstraints(constraints)

// 批量重置约束
STConstraintAdapter.st_resetConstraints(constraints)

// 获取已适配的约束
let adaptedConstraints = STConstraintAdapter.st_getAdaptedConstraints(constraints)

// 获取未适配的约束
let unadaptedConstraints = STConstraintAdapter.st_getUnadaptedConstraints(constraints)
```

#### 视图层次结构适配

```swift
// 适配所有子视图的约束
view.st_adaptAllConstraints()

// 重置所有子视图的约束
view.st_resetAllConstraints()

// 获取所有已适配的约束
let allAdaptedConstraints = view.st_getAllAdaptedConstraints()
```

### 实际应用示例

```swift
class AdaptiveViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var button: UIButton!
    
    // 约束出口
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var contentHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAdaptiveConstraints()
    }
    
    private func setupAdaptiveConstraints() {
        // 手动设置约束适配
        titleTopConstraint.st_triggerAdapt()
        contentHeightConstraint.st_triggerAdapt()
        buttonWidthConstraint.st_triggerAdapt()
        buttonHeightConstraint.st_triggerAdapt()
    }
    
    // 响应屏幕旋转
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // 屏幕旋转时重新适配约束
            self.view.st_adaptAllConstraints()
        })
    }
    
    // 动态调整约束
    @IBAction func adjustConstraints(_ sender: UIButton) {
        // 获取当前约束值
        let currentHeight = contentHeightConstraint.st_getAdaptedConstant()
        let originalHeight = contentHeightConstraint.st_getOriginalConstant()
        
        if currentHeight > originalHeight {
            // 重置为原始值
            contentHeightConstraint.st_resetToOriginal()
        } else {
            // 重新适配
            contentHeightConstraint.st_triggerAdapt()
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}

// 约束管理工具类
class ConstraintManager {
    
    /// 批量管理视图约束
    static func manageConstraints(for view: UIView, adaptType: STConstraintAdaptType) {
        let constraints = view.constraints
        
        for constraint in constraints {
            // 根据约束类型设置适配
            switch constraint.firstAttribute {
            case .width:
                if case .width = adaptType {
                    constraint.st_triggerAdapt()
                }
            case .height:
                if case .height = adaptType {
                    constraint.st_triggerAdapt()
                }
            default:
                if case .both = adaptType {
                    constraint.st_triggerAdapt()
                }
            }
        }
    }
    
    /// 检查约束适配状态
    static func checkAdaptationStatus(for view: UIView) -> (adapted: Int, total: Int) {
        let allConstraints = view.st_getAllAdaptedConstraints()
        let totalConstraints = view.constraints.count
        
        return (adapted: allConstraints.count, total: totalConstraints)
    }
    
    /// 导出约束信息
    static func exportConstraintInfo(for view: UIView) -> [String: Any] {
        let constraints = view.constraints
        var constraintInfo: [String: Any] = [:]
        
        for (index, constraint) in constraints.enumerated() {
            let key = "constraint_\(index)"
            constraintInfo[key] = [
                "original": constraint.st_getOriginalConstant(),
                "adapted": constraint.st_getAdaptedConstant(),
                "isAdapted": constraint.st_isAdapted()
            ]
        }
        
        return constraintInfo
    }
}

// 在视图控制器中使用
class SettingsViewController: UIViewController {
    
    @IBOutlet weak var settingsView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 检查约束适配状态
        let status = ConstraintManager.checkAdaptationStatus(for: settingsView)
        print("已适配约束: \(status.adapted)/\(status.total)")
        
        // 导出约束信息
        let constraintInfo = ConstraintManager.exportConstraintInfo(for: settingsView)
        print("约束信息: \(constraintInfo)")
    }
    
    @IBAction func toggleAdaptation(_ sender: UISwitch) {
        if sender.isOn {
            // 启用适配
            settingsView.st_adaptAllConstraints()
        } else {
            // 禁用适配
            settingsView.st_resetAllConstraints()
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}
```

### 使用建议

1. **设计基准**：
   - 在 `STDeviceAdapter` 中设置正确的设计基准尺寸
   - 确保约束值基于设计稿的尺寸设置

2. **适配类型选择**：
   - 宽度约束使用 `.width` 类型
   - 高度约束使用 `.height` 类型
   - 间距和边距使用 `.spacing` 或 `.margin` 类型
   - 字体大小约束使用 `.fontSize` 类型

3. **性能考虑**：
   - 避免在 `viewDidLoad` 中频繁调用适配方法
   - 使用批量操作处理多个约束
   - 在屏幕旋转时重新适配约束

4. **调试技巧**：
   - 使用 `st_getOriginalConstant()` 和 `st_getAdaptedConstant()` 检查适配结果
   - 使用 `st_isAdapted()` 检查约束是否已适配
   - 使用 `ConstraintManager` 工具类管理约束

5. **最佳实践**：
   - 在 Interface Builder 中设置适配属性
   - 使用代码进行动态调整
   - 保持约束的原始值，便于重置和调试

## 十九、STLogView

`STLogView` 是一个功能强大的日志查看和管理工具。它提供了现代化的日志显示界面，支持日志级别分类、搜索过滤、主题切换、导出分享等功能，是开发和调试过程中的得力助手。

### 主要特性

- **日志级别分类**：支持 DEBUG、INFO、WARNING、ERROR、FATAL 五个级别
- **智能搜索**：支持按消息内容、文件名、函数名搜索
- **级别过滤**：可按日志级别过滤显示
- **主题切换**：支持明暗主题切换
- **导出分享**：支持导出日志到文件或分享
- **实时更新**：支持实时接收和显示新日志
- **现代化 UI**：采用现代化的界面设计
- **自定义 Cell**：美观的日志条目显示

### 基本用法

#### 创建日志视图

```swift
// 创建日志视图
let logView = STLogView(frame: view.bounds)
view.addSubview(logView)

// 设置代理
logView.mDelegate = self

// 设置主题
logView.st_setTheme(.dark) // 或 .light
```

#### 日志级别使用

```swift
// 使用不同级别的日志
STLog("这是一条调试信息")           // DEBUG 级别
STLogP("这是一条持久化日志")        // 持久化到文件

// 日志会自动解析并显示在 STLogView 中
```

#### 搜索和过滤

```swift
// 设置搜索文本
logView.st_setSearchText("error")

// 设置日志级别过滤
logView.st_setLogLevelFilter([.error, .fatal])

// 获取当前过滤状态
let isFiltering = logView.st_isFiltering()
let searchText = logView.st_getSearchText()
let selectedLevels = logView.st_getSelectedLogLevels()
```

#### 日志管理

```swift
// 获取日志数量
let totalCount = logView.st_getAllLogCount()
let filteredCount = logView.st_getFilteredLogCount()
let currentCount = logView.st_getLogCount()

// 清空所有日志
logView.st_clearAllLogs()

// 导出当前显示的日志
logView.st_exportCurrentLogs()
```

### 实际应用示例

```swift
class LogViewController: UIViewController {
    
    private var logView: STLogView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLogView()
    }
    
    private func setupLogView() {
        // 创建日志视图
        logView = STLogView(frame: view.bounds)
        logView.mDelegate = self
        view.addSubview(logView)
        
        // 设置约束
        logView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            logView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            logView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            logView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 设置主题
        if traitCollection.userInterfaceStyle == .dark {
            logView.st_setTheme(.dark)
        } else {
            logView.st_setTheme(.light)
        }
    }
    
    // 测试日志功能
    @IBAction func testLogging(_ sender: UIButton) {
        STLog("这是一条调试信息")
        STLogP("这是一条持久化日志")
        
        // 模拟不同级别的日志
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            STLogP("网络请求开始")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            STLogP("网络请求成功")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            STLogP("用户登录失败")
        }
    }
    
    // 响应主题变化
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            let newTheme: STLogViewTheme = traitCollection.userInterfaceStyle == .dark ? .dark : .light
            logView.st_setTheme(newTheme)
        }
    }
}

// MARK: - STLogViewDelegate
extension LogViewController: STLogViewDelegate {
    
    func logViewBackBtnClick() {
        navigationController?.popViewController(animated: true)
    }
    
    func logViewShowDocumentInteractionController() {
        // 显示文档交互控制器
        let documentController = UIDocumentInteractionController(url: URL(fileURLWithPath: STLogView.st_outputLogPath()))
        documentController.presentOpenInMenu(from: view.bounds, in: view, animated: true)
    }
    
    func logViewDidSelectLog(_ logEntry: STLogEntry) {
        // 显示日志详情
        let alert = UIAlertController(title: "日志详情", message: logEntry.rawContent, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    func logViewDidFilterLogs(with results: [STLogEntry]) {
        // 过滤结果回调
        print("过滤结果: \(results.count) 条日志")
    }
}

// 日志管理工具类
class LogManager {
    
    /// 配置日志系统
    static func configureLogging() {
        // 设置日志输出路径
        let logPath = STLogView.st_outputLogPath()
        print("日志文件路径: \(logPath)")
    }
    
    /// 记录网络请求日志
    static func logNetworkRequest(_ request: URLRequest) {
        let message = """
        网络请求: \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")
        请求头: \(request.allHTTPHeaderFields ?? [:])
        """
        STLogP(message)
    }
    
    /// 记录网络响应日志
    static func logNetworkResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        if let error = error {
            STLogP("网络请求失败: \(error.localizedDescription)")
        } else if let httpResponse = response as? HTTPURLResponse {
            let message = """
            网络响应: \(httpResponse.statusCode)
            响应头: \(httpResponse.allHeaderFields)
            响应数据大小: \(data?.count ?? 0) 字节
            """
            STLogP(message)
        }
    }
    
    /// 记录用户操作日志
    static func logUserAction(_ action: String, parameters: [String: Any]? = nil) {
        var message = "用户操作: \(action)"
        if let params = parameters {
            message += "\n参数: \(params)"
        }
        STLogP(message)
    }
    
    /// 记录错误日志
    static func logError(_ error: Error, context: String = "") {
        let message = """
        错误: \(error.localizedDescription)
        上下文: \(context)
        错误详情: \(error)
        """
        STLogP(message)
    }
    
    /// 记录性能日志
    static func logPerformance(_ operation: String, duration: TimeInterval) {
        let message = "性能: \(operation) 耗时 \(String(format: "%.3f", duration)) 秒"
        STLogP(message)
    }
}

// 在应用中使用
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 配置日志系统
        LogManager.configureLogging()
        
        // 记录应用启动
        STLogP("应用启动完成")
        
        return true
    }
}
```

### 日志级别说明

- **DEBUG** 🔍：调试信息，用于开发过程中的调试
- **INFO** ℹ️：一般信息，记录程序运行状态
- **WARNING** ⚠️：警告信息，表示可能的问题
- **ERROR** ❌：错误信息，表示程序错误
- **FATAL** 💀：致命错误，表示严重问题

### 主题配置

```swift
// 浅色主题
let lightTheme = STLogViewTheme.light

// 深色主题
let darkTheme = STLogViewTheme.dark

// 自定义主题
var customTheme = STLogViewTheme()
customTheme.backgroundColor = .systemBackground
customTheme.textColor = .label
customTheme.buttonTintColor = .systemBlue
// ... 其他配置

logView.st_setTheme(customTheme)
```

### 使用建议

1. **日志级别使用**：
   - DEBUG：开发调试时使用
   - INFO：记录重要的程序状态
   - WARNING：记录可能的问题
   - ERROR：记录程序错误
   - FATAL：记录致命错误

2. **性能考虑**：
   - 避免在生产环境中使用过多的 DEBUG 日志
   - 使用 STLogP 记录重要的持久化日志
   - 定期清理日志文件

3. **搜索技巧**：
   - 使用关键词搜索特定功能的日志
   - 结合日志级别过滤提高效率
   - 利用文件名和函数名快速定位问题

4. **导出分享**：
   - 导出日志用于问题分析
   - 分享给团队成员进行协作调试
   - 保存重要的日志记录

5. **主题选择**：
   - 根据系统主题自动切换
   - 根据个人喜好选择主题
   - 考虑长时间使用的舒适度

### v2.1.1
- **STDate.swift 全面优化**：重构日期处理功能，新增以下特性：
  - 新增 Date 扩展：提供丰富的日期操作方法（时间戳转换、格式化、比较、计算等）
  - 优化字符串日期扩展：支持多种常见日期格式的智能解析
  - 新增相对时间显示：提供"几分钟前"、"几小时前"等人性化时间显示
  - 简化日期比较逻辑：使用更优雅和高效的实现
  - 新增日期计算功能：支持日期加减、范围生成等操作
  - 优化性能：使用 STDateManager 管理 DateFormatter 缓存，减少重复创建
  - 添加时区和本地化支持：更好的国际化体验
  - 提供使用示例：包含详细的 API 使用演示和最佳实践

### v2.1.0
- 新增统一图片管理器 (STImageManager)
- 整合相机、照片库和图片处理功能
- 新增图片压缩、裁剪、旋转等功能
- 优化 STCameraManager 和 STImagePickerManager
- 改进 STImage 扩展，添加更多图片处理功能
- 新增本地化支持和错误处理机制
- 统一弹窗 API，支持系统和自定义样式
- 优化代码结构，提高可维护性

### v2.0.0
- 新增完整的导航栏样式配置
- 新增 WebView 控制器功能
- 新增 JavaScript 交互支持
- 新增错误处理和状态管理
- 优化用户界面和用户体验
- 重构代码结构，提高可维护性

### v1.0.0
- 基础导航栏定制功能
- 基础 WebView 加载功能
- 支持左右按钮配置
- 支持多种显示模式
