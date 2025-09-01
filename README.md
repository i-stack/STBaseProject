# STBaseProject

[![Version](https://img.shields.io/cocoapods/v/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![License](https://img.shields.io/cocoapods/l/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![Platform](https://img.shields.io/cocoapods/p/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![Swift](https://img.shields.io/badge/Swift-5.9_5.10_6.0-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.9_5.10_6.0-Orange?style=flat-square)

STBaseProject 是一个功能强大的 iOS 基础组件库，提供了丰富的 UI 组件和工具类，帮助开发者快速构建高质量的 iOS 应用。

## 主要特性

- 🎨 **自定义导航栏**：支持多种样式和配置选项
- 🌐 **WebView 控制器**：完整的 WebView 功能，支持 JavaScript 交互
- 📱 **现代化设计**：支持深色模式，适配不同屏幕尺寸
- 🔧 **高度可配置**：丰富的配置选项，满足不同需求
- 🛡️ **错误处理**：完善的错误处理和状态管理

## Installation

```ruby
pod 'STBaseProject'
```

## Basic Configuration

Configure in AppDelegate:

**Custom navigation bar height**

```swift
private func customNavBar() {
    var model = STConstantBarHeightModel.init()
    model.navNormalHeight = 76
    model.navIsSafeHeight = 100
    STConstants.shared.st_customNavHeight(model: model)
}
```

**Design drawing baseline dimension configuration**

```swift
private func configBenchmarkDesign() {
    STConstants.shared.st_configBenchmarkDesign(size: CGSize.init(width: 375, height: 812))
}
```

## 组件使用指南

### 一、STBaseViewController

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

### 二、STBaseWKViewController

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

### 三、STBaseView

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

### 四、STBaseModel

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

### 五、STBtn

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

## 注意事项

1. **继承关系**：确保你的视图控制器继承自 `STBaseViewController` 或 `STBaseWKViewController`
2. **生命周期**：在 `viewDidLoad` 中配置样式和加载内容
3. **内存管理**：及时移除消息处理器，避免内存泄漏
4. **网络安全**：注意 URL 验证和内容安全策略
5. **兼容性**：深色模式功能需要 iOS 13+ 支持

## 更新日志

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
