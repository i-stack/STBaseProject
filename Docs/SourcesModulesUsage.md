# Sources 模块使用说明

本文档按 `Sources` 目录中的文件夹进行归类，提供每个模块的定位、适用场景和使用建议，便于快速选型与接入。

---

## 目录

- [STAnimation](#stanimation)
- [STBaseModel](#stbasemodel)
- [STBaseView](#stbaseview)
- [STBaseViewController](#stbaseviewcontroller)
- [STBaseViewModel](#stbaseviewmodel)
- [STConfig](#stconfig)
- [Docs](#docs)
- [STHUD](#sthud)
- [STContacts](#stcontacts)
- [STLocation](#stlocation)
- [STMedia](#stmedia)
- [STLocalizable](#stlocalizable)
- [STMarkdown](#stmarkdown)
- [STNetwork](#stnetwork)
- [STSecurity](#stsecurity)
- [STTimer](#sttimer)
- [STTools](#sttools)
- [STUIKit](#stuikit)

---

## STAnimation

**模块定位**  
通用动画能力模块，提供基础动画封装、图片动画和 shimmer 动效能力。

**适用场景**  
- 骨架屏、加载态、占位态动效
- 多帧图片动画展示
- 自定义动画生命周期控制

**核心文件**  
- `STBaseAnimation.swift`
- `STImageViewAnimation.swift`
- `STMultiImageViewAnimation.swift`
- `STShimmerAnimation/`

**使用建议**  
先用基础动画组件完成通用能力，再在业务层组合 shimmer 或多图动画，避免业务页面直接散落 `CABasicAnimation` 配置。

---

## STBaseModel

**模块定位**  
基础数据模型能力，承接通用模型行为与扩展。

**适用场景**  
- 业务模型基类统一约束
- 模型层公共能力收敛

**核心文件**  
- `STBaseModel.swift`

**使用建议**  
将模型层公共逻辑放在此模块，避免 View 或 ViewModel 反向持有数据转换细节。

---

## STBaseView

**模块定位**  
基础 View 封装，提供可复用视图基类与刷新能力。

**适用场景**  
- 页面基础容器视图
- 统一刷新控件与视图初始化流程

**核心文件**  
- `STBaseView.swift`
- `STRefreshControl.swift`

**使用建议**  
业务自定义 View 优先继承基础视图，统一初始化流程与公共行为，降低重复代码。

---

## STBaseViewController

**模块定位**  
基础控制器能力，集中管理导航栏、页面生命周期扩展和通用交互行为。

**适用场景**  
- 需要统一导航栏行为的页面
- 页面基类能力沉淀

**核心文件**  
- `STBaseViewController.swift`

**使用建议**  
业务页面优先继承该基类，页面级通用配置（导航按钮、标题、样式）放在控制器层统一维护。

---

## STBaseViewModel

**模块定位**  
基础 ViewModel 模块，承接请求状态、任务管理和页面数据流编排。

**适用场景**  
- MVVM 页面状态管理
- 网络请求流程与状态联动
- 分页、刷新、错误提示等通用流程

**核心文件**  
- `STBaseViewModel.swift`

**使用建议**  
业务 ViewModel 在此基础上扩展，统一状态流与异步任务管理，避免在 ViewController 中直接拼装网络流程。

---

## STConfig

**模块定位**  
工程级配置与运行时外观管理模块。

**适用场景**  
- 应用启动阶段默认配置注入
- 全局主题/外观策略切换
- 生命周期事件统一管理

**核心文件**  
- `STBaseConfig.swift`
- `STAppearanceManager.swift`
- `STAppLifecycleManager.swift`

**使用建议**  
将全局配置收敛在 App 启动阶段集中初始化，避免业务模块内分散配置导致行为不一致。

---

## Docs

**模块定位**  
文档聚合目录，用于沉淀模块使用手册、协议说明与维护指南。

**当前文档**  
- `STHTTPSession.md`：网络层详细文档
- `SourcesModulesUsage.md`：`Sources` 全模块使用说明（本文）
- `README.md`：文档入口索引
- `STSecurity.md`：`STSecurity` 目录能力说明（配置、加密、Keychain、反调试）

**使用建议**  
新增模块或公共能力时，优先同步补齐此目录文档，保持“代码与文档同版本演进”。

---

## STHUD

**模块定位**  
提示与加载反馈组件模块，提供 HUD、进度展示和弹窗提示能力。

**适用场景**  
- 成功/失败/加载提示
- 页面级阻塞或非阻塞进度反馈
- 统一交互反馈风格

**核心文件**  
- `STHUD.swift`
- `STProgressHUD.swift`
- `STProgressView.swift`
- `STAlertController.swift`

**使用建议**  
将用户反馈统一走 HUD 模块，避免页面中直接散落 toast/alert 实现，保证一致性与可替换性。

---

## STContacts

**模块定位**  
联系人权限与通讯录读取模块。

**适用场景**  
- 联系人授权状态检查
- 请求联系人权限并读取联系人列表

**核心文件**  
- `STContactManager.swift`

---

## STLocation

**模块定位**  
定位权限、单次定位、持续定位与地理编码模块。

**适用场景**  
- 获取当前位置与地址信息
- 管理定位权限与定位缓存

**核心文件**  
- `STLocationManager.swift`

---

## STMedia

**模块定位**  
媒体能力模块，提供图片选择/压缩、扫码、截图能力。

**适用场景**  
- 相机或相册选图
- 二维码识别
- 页面截图处理

**核心文件**  
- `STImageManager.swift`
- `STImage.swift`
- `STScanManager.swift`
- `STScanView.swift`
- `STScreenshot.swift`

---

## STLocalizable

**模块定位**  
国际化能力模块，提供本地化协议、管理器与控制器层集成能力。

**适用场景**  
- 多语言切换
- 本地化文案读取
- 控制器级本地化刷新

**核心文件**  
- `STLocalizableProtocol.swift`
- `STLocalizationManager.swift`
- `STViewControllerLocalization.swift`

**使用建议**  
文案读取与语言切换统一通过管理器入口，避免多套语言管理并存。

---

## STMarkdown

**模块定位**  
Markdown 渲染模块，覆盖解析、语义归一化、AST、渲染管线与 UIKit/SwiftUI 组件。

**适用场景**  
- 富文本消息渲染
- 表格、代码块、数学公式、Mermaid 等扩展语法展示
- 流式 Markdown 渲染

**核心文件（分层）**  
- 解析与语义：`STMarkdownStructureParser.swift`、`STMarkdownSemanticNormalizer.swift`、`STMarkdownMathNormalizer.swift`
- 数据结构：`STMarkdownAST.swift`、`STMarkdownRenderAST.swift`
- 渲染管线：`STMarkdownPipeline.swift`、`STMarkdownEngine.swift`
- 组件层：`STMarkdownTextView.swift`、`STMarkdownSwiftUIView.swift`
- 扩展渲染：表格/代码块/图片/数学公式相关文件

**使用建议**  
优先通过渲染管线与预设配置接入，避免业务直接耦合到低层 parser 或 attachment 细节。

---

## STNetwork

**模块定位**  
网络请求基础模块，包含会话层、请求构建、拦截器、事件监控、WebSocket 与网络类型定义。

**适用场景**  
- HTTP 请求封装与统一拦截
- 请求日志与事件监听
- WebSocket 通信
- SSL Pinning / 网络安全策略对接

**核心文件**  
- `STHTTPSession.swift`
- `STRequest.swift`
- `STInterceptor.swift`
- `STEventMonitor.swift`
- `STWebSocket.swift`
- `STNetworkMonitoring.swift`

**关联文档**  
- `Docs/STHTTPSession.md`

**使用建议**  
业务请求统一走 `STHTTPSession` 和请求对象链路；鉴权、重试、日志放入拦截器与事件监听层集中治理。

---

## STSecurity

**模块定位**  
安全能力模块，覆盖加解密、Keychain、安全策略与网络安全检测。

**适用场景**  
- 本地敏感信息安全存储
- 请求签名或数据加解密
- 网络证书校验与安全风险检测

**核心文件**  
- `STEncrypt.swift`
- `STKeychainHelper.swift`
- `STCryptoService`
- `STSecurityConfig`
- `STDeviceInfo.swift`（运行环境与设备态检测）

**使用建议**  
敏感能力统一收敛在安全模块；不要在业务代码中自行实现加解密与密钥存储细节。

---

## STTimer

**模块定位**  
计时与性能计量模块，提供定时器、倒计时和耗时分析能力。

**适用场景**  
- 倒计时按钮/页面计时
- 任务执行耗时统计
- 轻量性能打点

**核心文件**  
- `STTimer.swift`
- `STCountdownTimer.swift`
- `STTimeProfiler.swift`

**使用建议**  
倒计时与性能计量优先复用现有组件，避免页面层重复创建难维护的 `Timer` 逻辑。

---

## STTools

**模块定位**  
通用工具库，提供颜色、字符串、日期、文件、线程安全、设备信息等基础能力。

**适用场景**  
- 跨模块共享工具能力
- 系统 API 的可读性封装
- 高频基础能力统一沉淀

**核心文件（示例）**  
- `STColor.swift`、`STString.swift`、`STDate.swift`
- `STFileManager.swift`、`STData.swift`、`STDictionary.swift`
- `STDeviceInfo.swift`、`STDeviceAdapter.swift`
- `STThreadSafe.swift`、`STCrashDetector.swift`

**使用建议**  
工具类按“单一职责”维持边界，业务逻辑不应下沉到工具层。

---

## STUIKit

**模块定位**  
UIKit 组件集合，覆盖 Button、Label、TextField、TextView、View、WebView、TabBar、Log 等子模块。

**适用场景**  
- 页面 UI 组件快速搭建
- TabBar 体系定制
- 日志面板/日志输出能力接入

**核心子目录**  
- `STButton/`
- `STLabel/`
- `STTextField/`
- `STTextView/`
- `STView/`
- `STWebView/`
- `STTabBar/`
- `STLog/`

**使用建议**  
优先在该模块已有组件基础上扩展样式与行为，避免业务侧重复造轮子或形成多套 UI 规范。

---

## 维护约定

- 新增 `Sources` 一级目录时，同步在本文档补齐模块说明。
- 模块发生明显职责变化时，同步更新“模块定位/适用场景/核心文件”三部分。
- 详细专题文档统一放入 `Docs`，并在 `Docs/README.md` 登记索引。
