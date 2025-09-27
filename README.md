# STBaseProject

[![Version](https://img.shields.io/cocoapods/v/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![License](https://img.shields.io/cocoapods/l/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![Platform](https://img.shields.io/cocoapods/p/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![Swift](https://img.shields.io/badge/Swift-5.9_5.10_6.0-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.9_5.10_6.0-Orange?style=flat-square)

STBaseProject 是一个功能强大的 iOS 基础组件库，提供了丰富的 UI 组件和工具类，帮助开发者快速构建高质量的 iOS 应用。

## 📋 目录

- [安装方式](#安装方式)
- [快速开始](#快速开始)
- [目录介绍](#目录介绍)
- [主要功能](#主要功能)
- [使用示例](#使用示例)
- [系统要求](#系统要求)
- [许可证](#许可证)

## 🚀 安装方式

### CocoaPods

在 `Podfile` 中添加：

```ruby
pod 'STBaseProject', '~> 1.1.4'
```

然后运行：

```bash
pod install
```

### Swift Package Manager

在 Xcode 中添加包依赖：

1. 打开 Xcode 项目
2. 选择 `File` > `Add Package Dependencies...`
3. 输入仓库 URL：`https://github.com/i-stack/STBaseProject.git`
4. 选择版本 `1.1.4` 或更高版本并添加到项目

或在 `Package.swift` 中：

```swift
dependencies: [
    .package(url: "https://github.com/i-stack/STBaseProject.git", from: "1.1.4")
]
```

### 手动集成

1. 下载项目源码
2. 将 `Sources` 文件夹拖入你的项目
3. 确保所有文件都添加到 target 中

## ⚡ 快速开始

### 基础配置

```swift
import STBaseProject

// 在 AppDelegate 或 SceneDelegate 中配置
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    // 设置默认配置（推荐）
    STBaseConfig.shared.st_setDefaultConfig()
    
    // 或者使用 iPhone X 设计基准
    STBaseConfig.shared.st_configForIPhoneX()
    
    return true
}
```

### 基础视图控制器

```swift
import STBaseProject

class MyViewController: STBaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置导航栏样式
        st_setNavigationBarStyle(.light)
        st_setTitle("我的页面")
        
        // 显示导航栏按钮
        st_showNavBtnType(type: .showLeftBtn)
        st_setLeftButton(image: UIImage(named: "back_icon"))
    }
    
    override func st_leftBarBtnClick() {
        // 自定义返回按钮点击事件
        navigationController?.popViewController(animated: true)
    }
}
```

### 自定义按钮

```swift
import STBaseProject

let button = STBtn()
button.setTitle("按钮", for: .normal)
button.setImage(UIImage(named: "icon"), for: .normal)

// 设置图片在上、文字在下的布局
button.st_setImageTopTitleBottom(spacing: 8)

// 设置圆角
button.st_roundedButton(cornerRadius: 8)
```

### 颜色工具

```swift
import STBaseProject

// 从十六进制创建颜色
let color = UIColor.st_color(hexString: "#FF6B6B")

// 支持暗黑模式的动态颜色
let dynamicColor = UIColor.st_dynamicColor(lightHex: "#FFFFFF", darkHex: "#000000")

// 从 RGB 创建颜色
let rgbColor = UIColor.st_color(red: 255, green: 107, blue: 107)
```

### HUD 提示

```swift
import STBaseProject

// 显示成功提示
STHUD.showSuccess("操作成功")

// 显示加载中
STHUD.showLoading("加载中...")

// 显示错误提示
STHUD.showError("操作失败")

// 隐藏 HUD
STHUD.hide()
```

## 📁 目录介绍

### STAnimation - 动画组件
- `STBaseAnimation.swift` - 基础动画类
- `STImageViewAnimation.swift` - 图片视图动画
- `STMultiImageViewAnimation.swift` - 多图片视图动画

### STBaseModel - 基础模型
- `STBaseModel.swift` - 基础数据模型类

### STBaseView - 基础视图
- `STBaseView.swift` - 基础视图类

### STBaseViewController - 基础控制器
- `STBaseViewController.swift` - 基础视图控制器，提供自定义导航栏

### STBaseViewModel - 基础视图模型
- `STBaseViewModel.swift` - 基础视图模型类

### STConfig - 配置管理
- `STBaseConfig.swift` - 基础配置管理类
- `STDeviceAdapter.swift` - 设备适配器

### STCore - 核心工具
- `STColor.swift` - 颜色工具类
- `STData.swift` - 数据处理工具
- `STDate.swift` - 日期处理工具
- `STDeviceInfo.swift` - 设备信息工具
- `STDictionary.swift` - 字典工具
- `STFileManager.swift` - 文件管理工具
- `STFontManager.swift` - 字体管理工具
- `STHTTPSession.swift` - 网络请求工具
- `STJSONValue.swift` - JSON 处理工具
- `STLocalizableProtocol.swift` - 本地化协议
- `STLocalizationManager.swift` - 本地化管理器
- `STLogManager.swift` - 日志管理工具
- `STNetworkMonitoring.swift` - 网络监控工具
- `STNetworkTypes.swift` - 网络类型定义
- `STPoint.swift` - 点坐标工具
- `STPredicateCheck.swift` - 谓词检查工具
- `STSSLPinningConfig.swift` - SSL 证书锁定配置
- `STString.swift` - 字符串工具
- `STThreadSafe.swift` - 线程安全工具
- `STTimer.swift` - 定时器工具
- `STWindowManager.swift` - 窗口管理工具

### STDialog - 对话框组件
- `STHUD.swift` - HUD 提示组件
- `STProgressHUD.swift` - 进度 HUD 组件
- `STProgressView.swift` - 进度视图组件

### STSecurity - 安全组件
- `STEncrypt.swift` - 加密工具
- `STKeychainHelper.swift` - Keychain 助手
- `STNetworkCrypto.swift` - 网络加密工具
- `STNetworkSecurityConfig.swift` - 网络安全配置
- `STNetworkSecurityDetector.swift` - 网络安全检测器

### STTabBar - 标签栏组件
- `STCustomTabBar.swift` - 自定义标签栏
- `STCustomTabBarController.swift` - 自定义标签栏控制器
- `STCustomUITabBarController.swift` - 自定义 UI 标签栏控制器
- `STTabBarItemModel.swift` - 标签栏项模型
- `STTabBarItemView.swift` - 标签栏项视图
- `STTabBarMixedSupport.swift` - 标签栏混合支持

### STUI - UI 组件
- `STAlertController.swift` - 自定义警告控制器
- `STBaseViewControllerLocalization.swift` - 基础控制器本地化
- `STBaseWKViewController.swift` - 基础 WebKit 控制器
- `STBtn.swift` - 自定义按钮组件
- `STGradientLabel.swift` - 渐变标签组件
- `STIBInspectable.swift` - IB 可检查属性
- `STLabel.swift` - 自定义标签组件
- `STLogView.swift` - 日志视图组件
- `STTextField.swift` - 自定义文本输入框
- `STVerificationCodeBtn.swift` - 验证码按钮组件
- `STView.swift` - 自定义视图组件

## 🎯 主要功能

### 🎨 UI 组件
- **自定义导航栏** - 支持多种样式和自定义配置
- **自定义按钮** - 支持图片文字多种布局方式
- **HUD 提示** - 丰富的提示组件，支持多种类型
- **标签栏** - 自定义标签栏组件
- **渐变标签** - 支持渐变效果的标签组件

### 🛠 工具类
- **颜色工具** - 支持十六进制、RGB、暗黑模式等
- **字符串工具** - 丰富的字符串处理方法
- **日期工具** - 日期格式化和计算
- **网络工具** - HTTP 请求、网络监控
- **文件管理** - 文件操作和存储
- **设备信息** - 获取设备相关信息

### 🔒 安全功能
- **加密工具** - 数据加密和解密
- **Keychain 管理** - 安全存储敏感信息
- **网络安全** - SSL 证书锁定、安全检测

### 🌐 国际化支持
- **本地化管理** - 多语言支持
- **动态语言切换** - 运行时语言切换

### 📱 设备适配
- **屏幕适配** - 支持不同屏幕尺寸
- **安全区域适配** - 支持刘海屏等特殊设备
- **字体适配** - 动态字体大小调整

## 💡 使用示例

### 网络请求

```swift
import STBaseProject

// GET 请求
STHTTPSession.shared.st_get(url: "https://api.example.com/users") { result in
    switch result {
    case .success(let data):
        print("请求成功: \(data)")
    case .failure(let error):
        print("请求失败: \(error)")
    }
}

// POST 请求
let parameters = ["name": "张三", "age": 25]
STHTTPSession.shared.st_post(url: "https://api.example.com/users", parameters: parameters) { result in
    // 处理结果
}
```

### 本地化

```swift
import STBaseProject

// 设置本地化
STLocalizationManager.shared.st_setLanguage("zh-Hans")

// 获取本地化字符串
let localizedString = "hello_world".localized
```

### 文件操作

```swift
import STBaseProject

// 保存数据到文件
let data = "Hello World".data(using: .utf8)!
STFileManager.shared.st_saveData(data, toFile: "test.txt")

// 读取文件数据
if let fileData = STFileManager.shared.st_readData(fromFile: "test.txt") {
    let content = String(data: fileData, encoding: .utf8)
    print("文件内容: \(content ?? "")")
}
```

## 📋 系统要求

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

## 📄 许可证

本项目采用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目。

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue: [GitHub Issues](https://github.com/i-stack/STBaseProject/issues)
- 邮箱: songshoubing7664@163.com

---

⭐ 如果这个项目对你有帮助，请给它一个星标！
