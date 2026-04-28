# STBaseProject 业务接入指南

本文档面向业务开发同学，按“从 0 到 1 接入页面能力”的顺序组织，帮助你快速把 `STBaseProject` 用在新业务模块中。

---

## 目录

- [接入目标](#接入目标)
- [1. 启动阶段配置](#1-启动阶段配置)
- [2. 新页面接入（Controller + ViewModel）](#2-新页面接入controller--viewmodel)
- [3. 网络请求接入](#3-网络请求接入)
- [4. Markdown 消息接入](#4-markdown-消息接入)
- [5. 安全能力接入](#5-安全能力接入)
- [6. 日志与排障接入](#6-日志与排障接入)
- [7. 业务接入清单（上线前）](#7-业务接入清单上线前)
- [常见接入误区](#常见接入误区)

---

## 接入目标

业务接入的核心目标是：

- 页面层：统一页面基类、交互反馈和状态管理方式
- 网络层：统一请求入口、重试/鉴权/日志策略
- 展示层：按需接入 Markdown 等复杂渲染能力
- 安全层：统一敏感数据存储与网络安全策略

---

## 1. 启动阶段配置

建议在 `AppDelegate` 或 `SceneDelegate` 完成基础配置初始化。

```swift
import STBaseProject

func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
    // 基础全局配置
    STBaseConfig.shared.st_setDefaultConfig()

    // 可选：按设计稿基准切换适配策略
    // STBaseConfig.shared.st_configForIPhoneX()

    return true
}
```

如果业务有全局外观主题或生命周期监听需求，统一在 `STConfig` 相关能力中接入，不建议分散在各业务模块单独初始化。

---

## 2. 新页面接入（Controller + ViewModel）

### 2.1 Controller 基类接入

页面优先继承 `STBaseViewController`，统一导航栏和常规页面行为：

```swift
import STBaseProject

final class OrderListViewController: STBaseViewController {

    private lazy var viewModel = OrderListViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.st_setTitle("订单")
        self.st_setNavigationBarStyle(.light)
        self.st_showNavBtnType(type: .showLeftBtn)

        self.bindViewModel()
        self.viewModel.loadInitial()
    }

    private func bindViewModel() {
        // 根据业务模式（回调 / 绑定 / 通知）绑定状态
    }
}
```

### 2.2 ViewModel 基类接入

页面状态和异步流程优先收敛到 `STBaseViewModel` 子类中，避免控制器直接拼网络逻辑：

```swift
import STBaseProject

final class OrderListViewModel: STBaseViewModel {

    func loadInitial() {
        // 业务请求编排写在 ViewModel
    }
}
```

---

## 3. 网络请求接入

业务请求统一通过 `STHTTPSession` 发起，鉴权、重试、日志策略放到会话级配置。

### 3.1 推荐：封装业务 API 层

```swift
import STBaseProject

enum OrderAPI {
    static func fetchOrders() -> STDataRequest {
        STHTTPSession.shared.request(
            "https://api.example.com/orders",
            method: .get
        )
    }
}
```

### 3.2 ViewModel 调用

```swift
OrderAPI.fetchOrders()
    .responseDecodable(of: [OrderDTO].self) { result in
        switch result {
        case .success(let list):
            print(list)
        case .failure(let error):
            print(error)
        }
    }
```

### 3.3 何时看详细文档

涉及以下场景时，直接查 `STDocument/STHTTPSession.md`：

- 上传下载（含断点续传）
- SSE / chunked 流式响应
- 拦截器（adapter + retrier）
- SSL Pinning 与日志策略

---

## 4. Markdown 消息接入

如果业务场景有富文本消息（机器人回复、知识卡片、说明文档等），推荐通过 `STMarkdown` 模块接入。

### UIKit 场景

优先使用 `STMarkdownTextView` 或渲染管线产物承载展示，业务仅负责输入原始 Markdown 字符串。

### SwiftUI 场景

优先使用 `STMarkdownSwiftUIView` 作为展示入口，减少业务层重复实现解析和渲染细节。

---

## 5. 安全能力接入

### 5.1 本地敏感信息

Token、密钥等敏感信息统一使用 `STKeychainHelper` 存取，不落地到明文文件或 `UserDefaults`。

### 5.2 网络安全

涉及高安全要求接口时，使用 `STSecurityConfig` / `STSSLPinningConfig` 完成证书校验策略配置。

### 5.3 数据加解密

业务若有请求签名或数据加密要求，优先走 `STEncrypt` / `STCryptoService` 统一能力，避免各业务线各自实现。

---

## 6. 日志与排障接入

### 6.1 请求日志

调试阶段可开启：

```swift
STHTTPSession.shared.logging = .default
```

线上建议按环境和开关控制日志级别，避免敏感数据暴露和日志膨胀。

### 6.2 事件监控

有埋点需求时，接入 `STEventMonitor` 旁路监听，不污染业务请求代码。

---

## 7. 业务接入清单（上线前）

- 页面是否统一继承基础控制器与基础 ViewModel
- 网络请求是否统一走 `STHTTPSession`
- 鉴权与重试是否放在拦截器层，而非散落业务代码
- 敏感数据是否统一走 Keychain
- Markdown 渲染是否复用现有组件，而非自建解析链路
- 请求日志是否按环境分级配置
- 文档是否已补充到 `STDocument`

---

## 常见接入误区

- 在 Controller 直接写完整请求流程，导致状态管理分散
- 每个页面单独创建网络配置，导致全局策略不一致
- 业务自己维护 Markdown 解析逻辑，重复造轮子
- 明文保存 token 或在日志中打印敏感请求头
- 新增公共接入方式但未同步更新文档索引

---

如需按你们业务再细化一版，可继续扩展为：

- 电商业务接入模板（列表/详情/下单）
- IM 业务接入模板（会话/消息流/输入框）
- AI 助手业务接入模板（流式响应/Markdown/引用卡片）
