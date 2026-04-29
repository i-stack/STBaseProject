# STBaseProject

[![Version](https://img.shields.io/badge/version-1.1.5-blue?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-lightgrey?style=flat)](https://cocoapods.org/pods/STBaseProject)
[![Swift](https://img.shields.io/badge/Swift-5.9%20%7C%205.10%20%7C%206.0-orange?style=flat-square)](https://www.swift.org)
[![CI](https://github.com/i-stack/STBaseProject/actions/workflows/swift.yml/badge.svg)](https://github.com/i-stack/STBaseProject/actions/workflows/swift.yml)
[![SPM](https://img.shields.io/badge/SPM-supported-brightgreen?style=flat)](https://github.com/i-stack/STBaseProject)
[![iOS](https://img.shields.io/badge/iOS-16.0%2B-blue?style=flat)](https://github.com/i-stack/STBaseProject)
[![Xcode](https://img.shields.io/badge/Xcode-15%2B-147EFB?style=flat)](https://developer.apple.com/xcode/)
[![Stars](https://img.shields.io/github/stars/i-stack/STBaseProject?style=flat)](https://github.com/i-stack/STBaseProject/stargazers)

STBaseProject 是一个功能强大的 iOS 基础组件库，提供了丰富的 UI 组件和工具类，帮助开发者快速构建高质量的 iOS 应用。

## 📋 目录

- [安装方式](#installation)
- [按需加载](#modular-import)
- [快速开始](#quick-start)
- [文档导航](#docs-navigation)
- [业务接入概览](#integration-overview)
- [模块使用概览](#module-overview)
- [目录介绍](#directory-overview)
- [主要功能](#features)
- [使用说明](#usage)
- [系统要求](#requirements)
- [Pod 发布脚本](#pod-release-script)
- [许可证](#license)
- [贡献](#contributing)
- [联系方式](#contact)

<a id="installation"></a>
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

<a id="modular-import"></a>
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

<a id="quick-start"></a>
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

<a id="docs-navigation"></a>
## 📚 文档导航

<a id="integration-overview"></a>
### 业务接入概览

建议按“启动配置 -> 页面接入 -> 网络接入 -> 展示能力 -> 安全能力 -> 上线检查”的顺序推进：

- 启动阶段：在 `AppDelegate`/`SceneDelegate` 完成基础配置
- 页面层：优先使用 `STBaseViewController` + `STBaseViewModel`
- 网络层：统一使用 `STHTTPSession`，策略放在会话与拦截器层
- 展示层：富文本场景优先使用 `STMarkdown`
- 安全层：敏感数据统一使用 `STKeychainHelper`，高安全接口配合 `STSecurityConfig`/`STSSLPinningConfig`

<a id="module-overview"></a>
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

<a id="directory-overview"></a>
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

<a id="features"></a>
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

<a id="usage"></a>
## 💡 使用说明

README 仅保留能力概览与模块入口。

具体实现、参数说明与完整示例请查看对应专题文档：

- 网络请求：`Docs/STHTTPSession.md`
- 安全能力：`Docs/STSecurity.md`
- 本地化能力：`Docs/STLocalizable.md`

<a id="requirements"></a>
## 📋 系统要求

- iOS 16.0+
- Xcode 12.0+
- Swift 5.0+

<a id="pod-release-script"></a>
## 🚀 Pod 发布脚本

仓库内提供自动发布脚本：

```bash
./scripts/release_pod.sh 1.1.6
```

推荐（自动创建并推送同名 tag）：

```bash
./scripts/release_pod.sh 1.1.6 --tag --push-tag
```

脚本会按顺序执行：

- 更新 `STBaseProject.podspec` 中的 `s.version`
- 检查工作区是否干净（可用 `--allow-dirty` 跳过）
- 检查或自动创建本地 tag（`--tag`）
- 检查或自动推送远端 tag（`--push-tag`）
- 校验 tag 是否指向当前 `HEAD`
- 执行 `pod spec lint STBaseProject.podspec --allow-warnings`（可用 `--skip-lint` 跳过）
- 执行 `pod trunk push STBaseProject.podspec --allow-warnings`

<a id="license"></a>
## 📄 许可证

本项目采用 MIT 许可证。详情请参阅 [LICENSE](LICENSE) 文件。

<a id="contributing"></a>
## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目。

<a id="contact"></a>
## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue: [GitHub Issues](https://github.com/i-stack/STBaseProject/issues)
- 邮箱: songshoubing7664@163.com

---

⭐ 如果这个项目对你有帮助，请给它一个星标！
