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

### 三、STLocalizationManager

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

### 十一、STHTTPSession

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
