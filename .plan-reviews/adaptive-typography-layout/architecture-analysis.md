# 架构分析 — adaptive-typography-layout

## 涉及文件
- `/Users/song/Desktop/iOS/STBaseProject/Sources/STTools/STDeviceAdapter.swift` — 提供全局设计稿比例、屏幕和安全区指标。
- `/Users/song/Desktop/iOS/STBaseProject/Sources/STTools/STFontManager.swift` — 管理字体族、App 内字号比例及 UIFont 工厂方法。
- `/Users/song/Desktop/iOS/STBaseProject/Sources/STUIKit/STLabel/STLabel.swift` — UILabel 基础组件，消费字体工厂并开启 Dynamic Type 自动更新。
- `/Users/song/Desktop/iOS/STBaseProject/Sources/STUIKit/STButton/STBtn.swift` — UIButton 基础组件，消费字体工厂并开启 Dynamic Type 自动更新。
- `/Users/song/Desktop/iOS/STBaseProject/Sources/STUIKit/STView/STIBInspectable.swift` — 将 Interface Builder 约束常量映射到 STDeviceAdapter 的比例换算。
- `/Users/song/Desktop/iOS/STBaseProject/Sources/STHUD` — HUD 标题、详情和操作按钮的字体消费层。
- `/Users/song/Desktop/iOS/STBaseProject/Sources/STUIKit/STTabBar` — 自定义与系统 TabBar 标题、徽标字体消费层。
- `/Users/song/Desktop/iOS/STBaseProject/Sources/STUIKit/STWebView/STBaseWKViewController.swift` — WebView 错误状态标题、说明和重试按钮。
- `/Users/song/Desktop/iOS/STBaseProject/Sources/STUIKit/STTextView` — 普通、占位和流式富文本字体消费层。
- `/Users/song/Desktop/iOS/STBaseProject/Example/STBaseProjectExample` — 示例业务页面和主题配置。
- `/Users/song/Desktop/iOS/STMarkdown/Sources/STMarkdown` — Markdown 语义标题、正文、代码、表格和附件字体消费层。
- `/Users/song/Desktop/iOS/STBaseProject/Example/STBaseProjectExampleTests/STDeviceAdapterTests.swift` — 覆盖旧设备适配 API 的兼容行为。

## 调用链
```
业务或基础组件设置字体
  → UIFont.st_systemFont(...)
  → STFontManager.shared.fontSizeScale
  → STDeviceAdapter.scaledWidth(...)

业务或基础组件设置动态字体
  → UIFont.st_preferredFont(...)
  → STFontManager.shared.fontSizeScale
  → UIFontMetrics.scaledFont(...)

Storyboard/XIB 约束启用 autoConstant
  → NSLayoutConstraint.adaptConstraintIfNeeded()
  → STDeviceAdapter.scaledWidth/scaledHeight/scaledSpacing/scaledFontSize(...)

HUD/TabBar/WebView/TextView/Example 页面设置字体
  → STTypographyToken.font(...) 或 UIFont.st_preferredFont(...)
  → UIFontMetrics.scaledFont(...)
  → adjustsFontForContentSizeCategory
```

## 修改影响面
- 修改 `STFontManager.swift`：会影响所有 `st_systemFont`、`st_preferredFont` 调用方；兼容迁移要求旧工厂保持原结果，新语义入口独立增加。
- 修改 `STDeviceAdapter.swift`：会影响程序化布局和 XIB 约束适配；旧全局换算保持不变，新增 API 必须显式接收容器尺寸。
- 修改 `STLabel.swift` 与 `STBtn.swift`：会影响基础文本组件的默认字体更新；只迁移能明确映射到文本语义的入口。
- 修改测试：需要同时证明旧 API 未变和新 API 不依赖全局屏幕宽度。
- 修改 HUD、WebView 和 Example 页面：会改变系统内容字号调整时的显示尺寸，不改变默认内容字号下的设计基准字号。
- 修改 TabBar：自定义字体名继续保留，标题和徽标改用受上限保护的 Dynamic Type。
- 修改 TextView：默认字体、typing attributes、placeholder 和 shimmer attributed text 使用同一正文语义来源。
- 修改 STMarkdown：正文与标题使用语义字体；代码和行号保留等宽字体，并由对应 text style 驱动字号。

## 潜在风险（若有）
- `st_systemFont` 已广泛用于视觉敏感组件，若改变其缩放语义会产生无法由编译捕获的视觉回归。
- `fontSizeScale` 与 Dynamic Type 会叠乘；新 API 需将该行为写入契约并测试。
- XIB 的 `adaptType == fontSize` 实际作用于约束常量；只能兼容保留并提供弃用说明，不能在本轮改写存量 Storyboard 行为。
