# STBaseProject

> **iOS base components library for Swift** — page base classes, networking, security, UIKit components, localization and common utilities. Distributed via Swift Package Manager.

[![License](https://img.shields.io/badge/license-MIT-green?style=flat)](https://github.com/i-stack/STBaseProject/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-lightgrey?style=flat)](https://github.com/i-stack/STBaseProject)
[![Swift](https://img.shields.io/badge/Swift-5.9%20%7C%205.10%20%7C%206.0-orange?style=flat-square)](https://www.swift.org)
[![CI](https://github.com/i-stack/STBaseProject/actions/workflows/swift.yml/badge.svg)](https://github.com/i-stack/STBaseProject/actions/workflows/swift.yml)
[![SPM](https://img.shields.io/badge/SPM-supported-brightgreen?style=flat)](https://github.com/i-stack/STBaseProject)
[![iOS](https://img.shields.io/badge/iOS-16.0%2B-blue?style=flat)](https://github.com/i-stack/STBaseProject)
[![Xcode](https://img.shields.io/badge/Xcode-15%2B-147EFB?style=flat)](https://developer.apple.com/xcode/)

**STBaseProject** is an open-source **iOS base library** written in **Swift**, providing **UIKit components**, **networking**, **security (Keychain & crypto)**, **localization** and **common utilities** to help developers build high-quality iOS apps faster. Distributed via **Swift Package Manager (SPM)**.

STBaseProject 是一个 iOS 基础组件库，提供页面基类、网络、安全、UIKit 组件、本地化与通用工具，帮助开发者快速构建高质量的 iOS 应用。

## 📋 目录 | Table of Contents

- [安装方式 | Installation](#installation)
- [快速开始 | Getting Started](#quick-start)
- [模块与文档 | Modules & Docs](#modules-docs)
- [主要功能 | Features](#features)
- [许可证 | License](#license)
- [贡献 | Contributing](#contributing)
- [联系方式 | Contact](#contact)

<a id="installation"></a>
## 🚀 安装方式 | Installation

STBaseProject 是整包发布的库（SPM 单一 product），引入即包含全部核心能力：页面基类、网络、安全、UIKit、本地化、通用工具等。

### Swift Package Manager

在 Xcode 中依次选择 `File` -> `Add Package Dependencies...`，输入：

`https://github.com/i-stack/STBaseProject.git`

或在 `Package.swift` 中声明：

```swift
dependencies: [
    .package(url: "https://github.com/i-stack/STBaseProject.git", from: "1.3.0")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "STBaseProject", package: "STBaseProject")
        ]
    )
]
```

### 手动集成

1. 下载仓库源码
2. 将 `Sources` 目录拖入工程
3. 确认文件已加入目标 Target

<a id="quick-start"></a>
## ⚡ 快速开始 | Getting Started

### 1) 启动配置

在 `AppDelegate` / `SceneDelegate` 中完成全局配置初始化：

```swift
import STBaseProject

// 应用启动阶段集中初始化基础配置
STBaseConfig.setup()   // 全局配置与外观
```

### 2) 页面基类接入

页面优先基于 `STBaseViewController` 组织统一导航与通用交互，状态与异步流程落在 `STBaseViewModel`：

```swift
import STBaseProject

final class DemoViewController: STBaseViewController {
    private let viewModel = STBaseViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Demo"
    }
}
```

### 3) 常用组件

- UI 组件（按钮、标签、输入框、HUD）统一从 `STUIKit` 选择
- 全局配置与外观：`STConfig`
- 网络请求：`STNetwork`（`STHTTPSession`）
- 安全存储与加解密：`STSecurity`（`STKeychainHelper` / `STCryptoService`）

<a id="modules-docs"></a>
## 📚 模块与文档 | Modules & Docs

### 业务接入顺序

建议按「启动配置 → 页面接入 → 网络接入 → 展示能力 → 安全能力 → 上线检查」推进：

- 启动阶段：在 `AppDelegate`/`SceneDelegate` 完成基础配置
- 页面层：优先使用 `STBaseViewController` + `STBaseViewModel`
- 网络层：统一使用 `STHTTPSession`，策略放在会话与拦截器层
- 展示层：文本展示优先使用 `STUIKit`（`STLabel` / `STTextView` 等）
- 安全层：敏感数据统一使用 `STKeychainHelper`，高安全接口配合 `STSecurityConfig`/`STSSLPinningConfig`

### 模块入口

常用模块入口（点击可跳转源码）：

- 基础页面与状态：[STBaseViewController](Sources/STBaseViewController/) / [STBaseViewModel](Sources/STBaseViewModel/)
- 全局配置与外观：[STConfig](Sources/STConfig/)
- 网络能力：[STNetwork](Sources/STNetwork/) / [网络专题文档](Docs/STHTTPSession.md)
- 安全能力：[STSecurity](Sources/STSecurity/) / [安全专题文档](Docs/STSecurity.md)
- 国际化能力：[STLocalizable](Sources/STLocalizable/) / [本地化专题文档](Docs/STLocalizable.md)
- UIKit 组件：[STUIKit](Sources/STUIKit/)
- 通用工具：[STTools](Sources/STTools/)
- 动画与视觉：[STAnimation](Sources/STAnimation/)

### 专题文档

- [Docs/STHTTPSession.md](Docs/STHTTPSession.md)：网络会话、拦截器、流式响应、SSL Pinning
- [Docs/STSecurity.md](Docs/STSecurity.md)：加解密、Keychain、安全检测与策略
- [Docs/STLocalizable.md](Docs/STLocalizable.md)：本地化读取、语言切换、通知刷新

### 源码目录

- `STAnimation`：动画与视觉（含 shimmer 特效）
- `STBaseViewController` / `STBaseViewModel`：页面基类与状态管理
- `STConfig`：全局配置与外观
- `STNetwork`：网络会话、拦截器、WebSocket、SSL Pinning（详见 [Docs/STHTTPSession.md](Docs/STHTTPSession.md)）
- `STSecurity`：加解密、Keychain、安全检测（详见 [Docs/STSecurity.md](Docs/STSecurity.md)）
- `STLocalizable`：本地化管理与动态切换（详见 [Docs/STLocalizable.md](Docs/STLocalizable.md)）
- `STUIKit`：按钮、标签、输入框、TextView、TabBar、WebView、日志等组件
- `STTools`：颜色、字符串、日期、文件、设备、缓存等通用工具

### 本地 Demo

克隆后在仓库根目录执行 `open Example/STBaseProjectExample.xcodeproj`。Demo 通过本地 SPM 引用同仓根目录的 `Package.swift`，与发布到 GitHub 的集成方式一致。

<a id="features"></a>
## 🎯 主要功能 | Features

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

<a id="license"></a>
## 📄 许可证 | License

本项目采用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。

<a id="contributing"></a>
## 🤝 贡献 | Contributing

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目。

<a id="contact"></a>
## 📞 联系方式 | Contact

如有问题或建议，请通过以下方式联系：

- 提交 Issue: [GitHub Issues](https://github.com/i-stack/STBaseProject/issues)
- 邮箱: songshoubing7664@163.com

---

**STBaseProject** — an iOS & Swift base components library. Keywords: *iOS, Swift, UIKit, Swift Package Manager, base library, networking, security, Keychain, localization, UI components*.

⭐ 如果这个项目对你有帮助，请给它一个星标！
