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
- 📐 **设备适配**：智能的设备判断和尺寸计算
- 🎯 **比例缩放**：基于设计稿的精确比例缩放

## Installation

```ruby
pod 'STBaseProject'
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
```

### 二、STBaseViewController

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

### 三、STBaseWKViewController

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

### 四、STBaseView

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

### 五、STBaseModel

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

### 六、STBaseViewModel

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

### 七、STHTTPSession

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
