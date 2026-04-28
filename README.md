# STBaseProject

[![Version](https://img.shields.io/cocoapods/v/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![License](https://img.shields.io/cocoapods/l/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![Platform](https://img.shields.io/cocoapods/p/STBaseProject.svg?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![Swift](https://img.shields.io/badge/Swift-5.9_5.10_6.0-orange?style=flat-square)](https://img.shields.io/badge/Swift-5.9_5.10_6.0-Orange?style=flat-square)

STBaseProject 是一个功能强大的 iOS 基础组件库，提供了丰富的 UI 组件和工具类，帮助开发者快速构建高质量的 iOS 应用。

## 📋 目录

- [安装方式](#安装方式)
- [按需加载](#按需加载)
- [快速开始](#快速开始)
- [文档导航](#文档导航)
- [业务接入概览](#业务接入概览)
- [模块使用概览](#模块使用概览)
- [目录介绍](#目录介绍)
- [主要功能](#主要功能)
- [使用说明](#使用说明)
- [系统要求](#系统要求)
- [许可证](#许可证)

## 🚀 安装方式

### CocoaPods

在 `Podfile` 中添加：

```ruby
pod 'STBaseProject', '~> 1.1.5'
```

然后执行：

```bash
pod install
```

### Swift Package Manager

在 Xcode 中依次选择 `File` -> `Add Package Dependencies...`，输入：

`https://github.com/i-stack/STBaseProject.git`

或在 `Package.swift` 中声明：

```swift
dependencies: [
    .package(url: "https://github.com/i-stack/STBaseProject.git", from: "1.1.5")
]
```

### 手动集成

1. 下载仓库源码
2. 将 `Sources` 目录拖入工程
3. 确认文件已加入目标 Target

## 🧩 按需加载

如果只需要部分能力，建议按模块引入，减少编译与依赖负担。

### Swift Package Manager（按 Product 选择）

- `STBaseProject`：基础能力（UI、网络、安全、工具）
- `STContacts`：联系人权限与读取
- `STLocation`：定位与地理编码
- `STMedia`：图片处理、扫码、截图
- `STMarkdown`：Markdown 渲染

示例：

```swift
dependencies: [
    .package(url: "https://github.com/i-stack/STBaseProject.git", from: "1.1.5")
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "STBaseProject", package: "STBaseProject"),
            .product(name: "STContacts", package: "STBaseProject"),
            .product(name: "STLocation", package: "STBaseProject")
        ]
    )
]
```

### CocoaPods（按 Subspec 选择）

```ruby
pod 'STBaseProject/STBase', '~> 1.1.5'
pod 'STBaseProject/STContacts', '~> 1.1.5'
pod 'STBaseProject/STLocation', '~> 1.1.5'
# pod 'STBaseProject/STMedia', '~> 1.1.5'
# pod 'STBaseProject/STMarkdown', '~> 1.1.5'
```

## ⚡ 快速开始

### 1) 启动配置

- 在应用启动阶段完成基础配置初始化（`STBaseConfig`）
- 建议将全局配置集中在 `AppDelegate` 或 `SceneDelegate`

### 2) 页面基类接入

- 页面优先基于 `STBaseViewController` 组织统一导航与通用交互
- 状态和异步流程建议落在 `STBaseViewModel`

### 3) 常用组件示例

- UI 组件（按钮、标签、输入框、HUD）统一从 `STUIKit` / `STDialog` 选择
- 复杂渲染场景（如 Markdown）优先使用 `STMarkdown`

## 📚 文档导航

### 业务接入概览

建议按“启动配置 -> 页面接入 -> 网络接入 -> 展示能力 -> 安全能力 -> 上线检查”的顺序推进：

- 启动阶段：在 `AppDelegate`/`SceneDelegate` 完成基础配置
- 页面层：优先使用 `STBaseViewController` + `STBaseViewModel`
- 网络层：统一使用 `STHTTPSession`，策略放在会话与拦截器层
- 展示层：富文本场景优先使用 `STMarkdown`
- 安全层：敏感数据统一使用 `STKeychainHelper`，高安全接口配合 `STSecurityConfig`/`STSSLPinningConfig`

### 模块使用概览

常用模块入口（点击可直接跳转）：

- 基础页面与状态：[STBaseViewController](Sources/STBaseViewController/) / [STBaseViewModel](Sources/STBaseViewModel/)
- 全局配置与外观：[STConfig](Sources/STConfig/)
- 网络能力：[STNetwork](Sources/STNetwork/) / [网络专题文档](Docs/STHTTPSession.md)
- 安全能力：[STSecurity](Sources/STSecurity/) / [安全专题文档](Docs/STSecurity.md)
- 国际化能力：[STLocalizable](Sources/STLocalizable/) / [本地化专题文档](Docs/STLocalizable.md)
- 媒体能力：[STMedia](Sources/STMedia/)
- UIKit 组件：[STUIKit](Sources/STUIKit/)
- 通用工具：[STTools](Sources/STTools/)

### 专题文档

- [Docs/STHTTPSession.md](Docs/STHTTPSession.md)：网络会话、拦截器、流式响应、SSL Pinning
- [Docs/STSecurity.md](Docs/STSecurity.md)：加解密、Keychain、安全检测与策略
- [Docs/STLocalizable.md](Docs/STLocalizable.md)：本地化读取、语言切换、通知刷新

## 📁 目录介绍

仅列模块能力与入口，不在 README 展开具体实现细节：

- 动画与视觉：`STAnimation`
- 页面基类与状态：`STBaseViewController`、`STBaseViewModel`
- 全局配置：`STConfig`
- 网络：`STNetwork`（详见 [Docs/STHTTPSession.md](Docs/STHTTPSession.md)）
- 安全：`STSecurity`（详见 [Docs/STSecurity.md](Docs/STSecurity.md)）
- 国际化：`STLocalizable`（详见 [Docs/STLocalizable.md](Docs/STLocalizable.md)）
- 媒体能力：`STMedia`
- UIKit 组件：`STUIKit`
- 通用工具：`STTools`

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

## 💡 使用说明

README 仅保留能力概览与模块入口。

具体实现、参数说明与完整示例请查看对应专题文档：

- 网络请求：`Docs/STHTTPSession.md`
- 安全能力：`Docs/STSecurity.md`
- 本地化能力：`Docs/STLocalizable.md`

## 📋 系统要求

- iOS 16.0+
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
