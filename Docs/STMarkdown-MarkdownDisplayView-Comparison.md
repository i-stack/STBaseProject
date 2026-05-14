# STMarkdown 与 MarkdownDisplayView（Vendor）对比说明

> 对照基准（Vendor 源码路径）：  
> `/Users/song/Downloads/MarkdownDisplayView/MarkdownDisplayView/Sources/MarkdownDisplayView`  
> 对照对象（本仓库）：  
> `Sources/STMarkdown/`  
> 文档生成日期：2026-05-14

本文汇总架构、文件映射、能力差异及在 Cursor 中的对比方式，便于后续按模块对齐或迁移。

**对齐标注图例**（下文表格「对齐」列或行内标签沿用同一套语义）：

| 标签 | 含义 |
|------|------|
| **【已对齐】** | 该维度上能力或依赖已等价覆盖（实现路径、API 名称可与 Vendor 不同）。 |
| **【部分对齐】** | 双方均有对应能力或同类入口，但栈、交互模型或公开面仍有明显差异。 |
| **【未对齐】** | ST 侧缺失、明确不支持或架构路线与 Vendor 不可直接等同。 |
| （留空或 **—**） | 属仓库形态类对比，不评「能力对齐」。 |

---

## 1. 仓库与路径

### 1.1 Vendor 仓库布局

- **仓库根**：例如 `MarkdownDisplayView/`（含顶层 `Package.swift`、`Example/` 等）。
- **SPM 库实现**：`MarkdownDisplayView/Sources/MarkdownDisplayView/`
- **资源**：`MarkdownDisplayView/Sources/MarkdownDisplayView/Resources/`（KaTeX 字体等，约 20 项）

### 1.2 STBaseProject 布局

- **模块根**：`Sources/STMarkdown/`
- **子目录**：`Core/`、`Parsing/`、`Rendering/`、`Table/`、`UI/`、`Attachments/`、`Resources/`

---

## 2. 形态对比

| 维度 | MarkdownDisplayView（Vendor） | STMarkdown | 对齐 |
|------|--------------------------------|------------|------|
| Swift 文件量 | 约 **21** 个 + `Resources/` | **45** 个 + `Resources/` | — |
| 代码组织 | **少量超大文件**（如 `MarkdownDisplayView.swift`、`MarkdownParser.swift`） | **分层**、职责拆分 | — |
| 最低 iOS（以各自 Package/podspec 为准） | iOS **15+**（`@available(iOS 15.0, *)` 等） | iOS **16+**（工程配置） | **【未对齐】**（系统版本门槛不同） |
| 解析依赖 | **swift-markdown**（`import Markdown`） | **swift-markdown**（SPM `Markdown`） | **【已对齐】** |
| CocoaPods 差异（若用 Pod） | 可能经 **AppleSwiftMDWrapper** 等桥接 | **swift-markdown-pod** + CAtomic modulemap | **【部分对齐】**（均为 Pod 集成路径，桥接方案不同） |
| 数学公式 | **KaTeX**（字体 + `LaTeXAttachment` / `LatexMathView` 等） | **SwiftMath** + `STMarkdownMathNormalizer` | **【部分对齐】**（均有公式渲染链，引擎与资源不同） |
| **SPM 产品名** | `MarkdownDisplayView` | 合在 **`STBaseProject`** 的 `STMarkdown` 源码目录（非独立 SwiftPM 产品名） | — |
| **CocoaPods 产品名** | **`MarkdownDisplayKit`**（与 SPM 名不同） | **`STBaseProject/STMarkdown`** subspec | — |
| **swift-markdown 版本** | SPM：`from: "0.7.3"`（随解析器升级行为可能变） | 本仓库 `Package.swift` **固定 revision**；与 vendor 的 cmark/扩展差异需升级时单独回归 | **【部分对齐】**（同为 swift-markdown，版本策略不同） |

---

## 2.1 对外 API 入口（便于宿主对照）

| 场景 | Vendor（典型） | STMarkdown（典型） | 对齐 |
|------|----------------|-------------------|------|
| 可滚动整页预览 | `ScrollableMarkdownViewTextKit`（`UIScrollView` + 内嵌 `MarkdownViewTextKit`） | 自嵌 `UIScrollView` + `STMarkdownTextView` / `STMarkdownStreamingTextView`，或 `STMarkdownSwiftUIView` | **【部分对齐】**（能力可用，无 Vendor 同名一体化控件） |
| 流式打字机 | `startStreaming(...)`、`StreamingUnit`（如 `.word`）等 | `beginSmartMarkdownStreaming()`、`appendSmartMarkdownStreamingChunk(_:)`、`endSmartMarkdownStreaming()`；或 `setMarkdown(_:animated:)` | **【部分对齐】**（均有流式/动画入口，粒度 API 不同） |
| 配置对象 | `MarkdownConfiguration`（大结构体，含 `MarkdownLineSpacingConfiguration`、`SyntaxHighlightColors` 等） | `STMarkdownStyle` + `STMarkdownEngine` / `STMarkdownPipelineConfiguration` 等拆分配置 | **【部分对齐】**（均有可配置样式与管线，结构拆分不同） |
| 流式触感 | `StreamingHapticFeedbackStyle` 等 | **无**同名 API；需宿主自行 `UIImpactFeedbackGenerator` | **【未对齐】** |
| Mermaid / 自定义代码块 | 协议 **`MarkdownCodeBlockRenderer`**（示例工程 `MermaidRenderer`） | **`STMarkdownCodeBlockRendering`**、`STMarkdownMermaidRenderer` 等 | **【已对齐】**（均为协议化可插拔代码块渲染） |

---

## 3. 文件级映射（Vendor → STMarkdown）

| Vendor 文件 | 角色 | STMarkdown 对应 / 说明 | 对齐 |
|-------------|------|-------------------------|------|
| `MarkdownParser.swift` | swift-markdown 遍历、`IncrementalParseResult`、`parseLock`、产出 `MarkdownRenderElement`、TOC、图片附件等 | `STMarkdownStructureParser`（解析路径 **`parseLock`** 串行化）、`STMarkdownMathNormalizer`、`STMarkdownPipeline`、`STMarkdownRenderAdapter`、`STMarkdownInputSanitizer`、`STMarkdownMalformedTableNormalizer`。ST 仍以 **整段管线 `process(_:)`** 为主，**无** vendor 同款「增量 `safePosition` / `replaceCount` / 元素级回溯」公开形态 | **【部分对齐】**（parser 级锁 **【已对齐】**；元素级增量 **【未对齐】**） |
| `MarkdownRenderElement.swift` | 渲染树枚举、`MarkdownConfiguration`、`MarkdownTOCItem`、`MarkdownTypewriterTextMode` 等 | `STMarkdownAST` / `STMarkdownRenderAST`、`STMarkdownStyle`。`STMarkdownRenderBlock.heading` 含 **`anchorId`**；**`STMarkdownTOCItem`** + 管线 **`tableOfContents`**。仍 **无** vendor 同级的 `details`、`rawHTML`、`footnote` 块模型 | **【部分对齐】**（核心块与 TOC 数据/锚点 **【已对齐】**；`details` / `rawHTML` / `footnote` **【未对齐】**） |
| `MarkdownRender.swift` | 元素 → 属性串 / 展示逻辑 | `STMarkdownAttributedStringRenderer` + `Rendering/Default/*`、`Rendering/Advanced/*` | **【已对齐】** |
| `MarkdownDisplayView.swift` | 总装、与 TextKit 视图协作（体量很大） | `STMarkdownBaseTextView`、`STMarkdownTextView`、`STMarkdownStreamingTextView` 等拆分 | **【部分对齐】**（职责已覆盖，拆分为多类型） |
| `MarkdownTextViewTK2.swift` | **TextKit 2**：`NSTextContentStorage`、`NSTextLayoutManager`、附件 Provider、`typewriterTextMode` 等 | `UITextView` / `STShimmerTextView`，**`usingTextLayoutManager: false`**（经典 TextKit 路径） | **【未对齐】**（TextKit 代际不同） |
| `TypewriterEngine.swift` | 对子视图树（`MarkdownTextViewTK2` / `UILabel` / `UIStackView`）队列动画、`onLayoutChange` | `STShimmerTextView` + `STMarkdownStreamingTextView` 动画/增量更新；**无** vendor 同款整棵 block UI 队列 + watchdog | **【部分对齐】**（均有打字机/流式观感；视图树队列 **【未对齐】**） |
| `MarkdownStreamBuffer.swift` | `Int` 型 `lastSafePosition`、`containerWidth`、可选 `onModuleReady`（带预解析元素）、调试日志 | `STMarkdownStreamBuffer`：字符偏移持久化、`streamMinModuleLength`、**纯字符串**模块切分；可选 **`onCompleteModules`**（仅模块字符串，**无**预解析 AST / **无** `containerWidth`） | **【部分对齐】**（安全切分思想 **【已对齐】**；`onModuleReady` 预解析 / `containerWidth` **【未对齐】**） |
| `ScrollableMarkdownViewTextKit.swift` | `UIScrollView` 包装、`markdown`/`configuration`、`onTOCItemTap`、`tableOfContents`、`generateTOCView` 等 | **无**同名一体化控件；管线产出 **`STMarkdownPipelineResult.tableOfContents`** + ``STMarkdownBaseTextView.tableOfContents`` / ``scrollToHeadingAnchor`` / ``characterRangeForHeadingAnchor``；侧栏目录与 `onTOCItemTap` 仍由宿主组合 | **【部分对齐】**（滚动+渲染可组合；TOC 一体面 **【未对齐】**） |
| `MarkdownTableSupport.swift` | 表格与 TextKit2 / 附件协作 | `Table/STMarkdownTable*.swift`、CollectionView 表格附件；与 CHANGELOG 中 **UILabel 表格 cell + `onLinkTap`** 链路不同 | **【部分对齐】**（均有表格能力；TK2 内嵌 vs Collection **【未对齐】**） |
| `CodeBlockAttachment.swift` | 代码块附件 | `STMarkdownCodeBlockAttachmentRenderer`、`STMarkdownDefaultCodeBlockRenderer` 等 | **【已对齐】** |
| `LaTeXAttachment.swift`、`LatexMathView.swift`、`LateXParser.swift`、`LateXNodeSets.swift` | KaTeX 渲染链 | `STMarkdownDefaultMathRenderer` + SwiftMath + `STMarkdownMathNormalizer` | **【部分对齐】**（公式附件链路 **【已对齐】**；KaTeX vs SwiftMath **【未对齐】**） |
| `FontLoader.swift` | KaTeX 字体注册 | ST 使用 SwiftMath / Bundle 资源，无同一套 `FontLoader` | **【部分对齐】**（均有字体/资源加载责任；实现文件 **【未对齐】**） |
| `ImageCacheManager.swift`、`ImageLoader.swift`、`ImageView.swift` | 图片缓存与展示 | `STMarkdownAsyncImageRenderer`、`STMarkdownDefaultImageRenderer` 等 | **【已对齐】** |
| `MarkdownCustomExtension.swift` | 自定义扩展元素 | `STMarkdownAdvancedRenderers`、各类 `*Rendering` 协议 | **【已对齐】** |
| `ArraySafe.swift` | 安全下标等工具 | ST 内散见于各文件，无同名单文件 | **【部分对齐】**（同类防御性用法内嵌，无 Vendor 同名文件） |

---

## 4. 能力差异摘要

1. **渲染引擎**：Vendor 为 **TextKit 2**；ST 主路径为 **`UITextView` + TextKit 1**（`usingTextLayoutManager: false`）。**【未对齐】**
2. **解析与并发**：Vendor **`MarkdownParser` 内 `parseLock` 串行化 swift-markdown**，并在视图层配合 `renderQueue`/版本锁做增量渲染保护；ST 在 **`STMarkdownStructureParser.parse`** 使用 **`parseLock`** 串行化 cmark 路径（对齐 vendor 核心动机）；**无**视图层版本锁与 **无** 增量元素级回溯。**【部分对齐】**（parser 级锁 **【已对齐】**；视图层与元素级增量 **【未对齐】**）
3. **流式**：Vendor 缓冲器可 **`onModuleReady` 带 `MarkdownRenderElement`**，并与 **Typewriter 视图树** 配合；ST 为 **字符串级 `STMarkdownStreamBuffer`**（可选 **`onCompleteModules`**）+ **富文本侧 Shimmer/增量 `setMarkdown`**。**【部分对齐】**（模块就绪回调 **【部分对齐】**；预解析元素与视图树 **【未对齐】**）
4. **目录 TOC**：Vendor **内置 `MarkdownTOCItem`、生成目录视图、跳转 API**；ST 提供 **`STMarkdownTOCItem`**、**`tableOfContents`**（管线 + TextView 缓存）与 **`scrollToHeadingAnchor`** / **`characterRangeForHeadingAnchor`**；**无**内置目录视图与 **`onTOCItemTap`**（宿主组合）。**【部分对齐】**（数据与跳转 **【已对齐】**；内置目录 UI / tap **【未对齐】**）
5. **块级模型**：Vendor `MarkdownRenderElement` 含 **`details`、`rawHTML`**，并把 **heading/TOC/footnote** 等信息留在统一块级模型附近；ST 当前 `STMarkdownBlockNode` **未定义** `details`、`rawHTML`、`footnote`；**`STMarkdownRenderBlock.heading` 含 `anchorId`** 并与 TOC 抽取一致。**【部分对齐】**（heading 锚点/TOC 数据 **【已对齐】**；扩展块与脚注 **【未对齐】**）
6. **公式**：Vendor **KaTeX**；ST **SwiftMath**，命令集与排版不必一致。**【部分对齐】**
7. **表格**：Vendor 与 TextKit2 附件、手势、（文档所述）**表格内链接走 cell 选择 + `onLinkTap`** 等；ST 为 **独立表格 Collection + overlay**，交互模型不同。**【部分对齐】**
8. **脚注 / 角标**：Vendor 有 **独立脚注模型 + 延迟渲染脚注视图**；ST 侧当前更偏向 **Citation 角标**（如 `STMarkdownNumberBadgeAttachment`、表格内 citation 流程），**不能等价视为 footnote 支持**。**【未对齐】**
9. **链接与图片点击**：双方均具备宿主回调链路（如 `onLinkTap`、图片异步渲染与点击）。**【已对齐】**（具体命名与 TK 栈细节不同，见 §4.3「交互能力」行）

## 4.3 已从源码核对的结论

以下条目是本次直接对照源码后确认的结果，可视为比前文更高置信度的“实现级”结论：

| 维度 | Vendor 结论 | ST 结论 | 判断 | 对齐 |
|------|-------------|---------|------|------|
| 流式增量解析 | `MarkdownParser.parseIncremental(...)` 返回 `safePosition`、`replaceCount`、`newElements` | **整段**仍走 `process`；**``processIncremental``** 提供回溯窗口子串 + **`replaceTailCount`** + ``windowRenderDocument``；安全上界仍由缓冲器提供 | ST **弱于** vendor 一体化 | **【部分对齐】** |
| 流式模块回调 | `MarkdownStreamBuffer.onModuleReady` 可回传预解析 `MarkdownRenderElement` | **`onCompleteModules`** 仅回传 **完整模块字符串**；无预解析 AST | ST **弱于** vendor | **【部分对齐】** |
| 块级能力 | `MarkdownRenderElement` 含 `details`、`rawHTML`、`heading(id:...)`、`table`、`latex`、`list` | `STMarkdownBlockNode` 仍为 paragraph/heading/…；**`STMarkdownRenderBlock.heading` 含 `anchorId`** | ST **仍缺** `details` / `rawHTML` / `footnote` | **【部分对齐】** |
| TOC | 视图层公开 `tableOfContents`、`onTOCItemTap`、`generateTOCView()`、`scrollToTOCItem(...)` | **`STMarkdownPipelineResult.tableOfContents`**、**`STMarkdownBaseTextView.tableOfContents`**、**`scrollToHeadingAnchor`** / **`characterRangeForHeadingAnchor`**；无内置目录 UI / `onTOCItemTap` | ST **弱于** vendor 一体面 | **【部分对齐】** |
| 脚注 | 预处理 footnote，缓存并延迟渲染 footnote view | 未检出 footnote 模型/渲染链；存在 citation badge 流程 | ST **缺少 footnote** | **【未对齐】** |
| TextKit 栈 | 核心视图基于 `NSTextLayoutManager` / `NSTextContentStorage` / TK2 attachment provider | `UITextView(usingTextLayoutManager: false)` 明确走 TextKit 1 路线 | 路线不同 | **【未对齐】** |
| HTML | Vendor 存在 `rawHTML(String)` 元素与对应渲染分支 | ST `STHtmlNormalizeRule` 注释明确写明 downstream **no handling for raw HTML** | ST **明确不支持 raw HTML** | **【未对齐】** |
| 交互能力 | `onLinkTap`、`onImageTap`、TOC tap、脚注视图 | `onLinkTap`、`onSelectionChange`、`onCitationTap` | 各有侧重 | **【部分对齐】**（链接/选区 **【已对齐】**；TOC tap / 脚注视图 **【未对齐】**；citation **Vendor 无对等**） |
| 表格交互 | 表格与 TK2 attachment 深度耦合 | 表格为独立 View/Attachment + overlay/citation 区域 | 路线不同 | **【部分对齐】**（均有表格与点击区域；耦合方式 **【未对齐】**） |

---

## 4.1 仓库根目录但未纳入上表的路径（Vendor）

以下在 **clone 根** 常见，与 `Sources/MarkdownDisplayView` 并列，对比「库能力」时可按需打开：

| 路径 | 说明 |
|------|------|
| `Example/`、`CocoapodsMDExample/` | 示例 App：调用方式、`startStreaming`、Mermaid 接入等 **集成参考** |
| `Effects/`、`Support/` | 动效/辅助资源等（**非** `Sources` 内核心 Swift 模块；具体以仓库为准） |
| `CHANGELOG.md`、`README_zh.md` | 版本行为、配置项、已知修复的 **文字级** 对照来源 |

---

## 4.2 测试与可观测性

| 项目 | Vendor | STMarkdown | 对齐 |
|------|--------|------------|------|
| 单测位置 | `MarkdownDisplayView/Tests/MarkdownDisplayViewTests/`（Swift `Testing` 等） | `Example/STBaseProjectExampleTests/` 下 `STMarkdown*`、`STMarkdownStreamBufferTests` 等 | **【已对齐】**（均有模块级单测落点） |
| 调试输出 | `MarkdownStreamBuffer` 等路径存在 **`print`** 日志 | ST 侧一般 **无** 同等控制台噪声；排障依赖宿主或自行埋点 | **【未对齐】**（可观测性策略不同） |

---

## 5. 已在 ST 侧做过的对齐方向（会话内实现，供对照）

> 本节条目相对 Vendor 文档/行为属于 **【部分对齐】** 或实现侧 **【已对齐】**（语义接近，非逐行一致）。

以下属于 STMarkdown 演进中与「常见流式 Markdown 组件」接近的行为，**不等同**于 vendor 逐行一致：

- **`STMarkdownStreamBuffer`** **【部分对齐】**：围栏闭合处切分、段落模式 EOF 尾段、**字符偏移**持久化 `lastSafeUpperBoundOffset`；可选 **`onCompleteModules`**（对照 vendor 模块就绪的字符串子集）。**【未对齐】** 项见 §3 `MarkdownStreamBuffer` 行。
- **`STMarkdownBaseTextView`** **【部分对齐】**：`resolvedMarkdownMeasurementWidth()`、高度回退、`contentLayoutHeightNotificationMinInterval`；**`tableOfContents`**、**`scrollToHeadingAnchor`**、**`characterRangeForHeadingAnchor`**（TOC 数据与跳转）。
- **`STMarkdownStructureParser`** **【部分对齐】**：**`parseLock`** 串行化 swift-markdown 解析路径（对照 vendor）。
- **`STMarkdownPipeline` / `STMarkdownMalformedTableNormalizer`** **【部分对齐】**：坏表修复语义；管线 **`STMarkdownPipelineResult.tableOfContents`**；**``processIncremental(_:)``**（回溯窗口子串 parse + **`replaceTailCount`** + ``mergedRenderDocument``，见 §7.2.5）。
- **`STMarkdownRenderBlock.heading`** + **`NSAttributedString.Key.stMarkdownHeadingAnchor`**：渲染侧锚点与 TOC 一致。

单测可参考：`STMarkdownStreamBufferTests`、`STMarkdownBaseTextViewLayoutTests`、`STMarkdownPipelineTests` 中流式相关用例；**`STMarkdownTOCTests`**、**`STMarkdownIncrementalParseTests`**。

---

## 6. 在 Cursor 中如何对比阅读

1. **将 Vendor 目录加入工作区**：`File → Add Folder to Workspace…` → 选择  
   `MarkdownDisplayView/MarkdownDisplayView/Sources/MarkdownDisplayView`。
2. **分栏**：左侧 `Sources/STMarkdown`，右侧 Vendor `Sources/MarkdownDisplayView`。
3. **按上表成对打开**：例如 `STMarkdownStreamBuffer.swift` ↔ `MarkdownStreamBuffer.swift`；`STMarkdownStructureParser.swift` ↔ `MarkdownParser.swift`。
4. **跨仓库搜索**：在两侧分别搜索 `TOC`、`details`、`parseLock`、`NSTextLayoutManager`、`Typewriter`、`onModuleReady`。

---

## 7. 当前更值得做的优化

下面不是“和 vendor 做到一模一样”的愿望清单，而是按 **收益 / 风险 / 落地成本** 排过序的优化方向。

| 优先级 | 方向 | 说明 |
|--------|------|------|
| P0 | **流式增量渲染链补强** | 已提供 **``STMarkdownPipeline/processIncremental``**（`replaceTailCount` + 窗口 ``STMarkdownRenderDocument`` + 合并 helper）；与 ``STMarkdownStreamBuffer`` 组合可逼近 Vendor 窗口策略。**仍缺**：与 TextKit 增量 `replaceCharacters` 的硬连接、内置 `findSafeBreakpoint` 与缓冲一体化。 |
| P0 | **流式专项测试补齐** | 继续补围栏、表格、公式、标题切换、列表/引用未闭合、Unicode chunk 边界、长文多轮 append 的单测。这个成本低，但能直接兜住后续重构。 |
| P1 | **目录 TOC 抽取能力** | 已落地 **`STMarkdownTOCItem`**、管线 **`tableOfContents`**、**`anchorId`** + **`stMarkdownHeadingAnchor`**、**`scrollToHeadingAnchor`**；可继续补内置目录 UI / `onTOCItemTap`、与流式增量同帧刷新。 |
| P1 | **脚注与引用语义拆分** | 当前 citation badge 更像业务增强，不等于 CommonMark footnote。若要对齐通用 Markdown 能力，应补 `footnote definition/reference` 语义模型，而不是继续堆 UI 角标。 |
| P1 | **并发压测与线程模型定稿** | 解析入口已加 **`parseLock`**；仍建议压测并发 `process(_:)`、流式 append、异步 attachment 刷新，再决定是否扩展 actor / 更广临界区。 |
| P2 | **块级 AST 能力补齐** | 如果产品确实需要折叠块与 HTML 片段，再考虑补 `details` / `rawHTML`。这类能力应先落 AST 和 render block，再落 UI；否则后面会继续把语义写死在 renderer。 |
| P2 | **统一公共组件面** | Vendor 的 `ScrollableMarkdownViewTextKit` 给了宿主一个“整页预览”入口。ST 现在偏散件组合，建议评估是否提供官方容器组件，统一滚动、高度通知、目录、链接、citation、流式入口。 |
| P3 | **TextKit 2 迁移评估** | 这不是当前第一优先级。只有在明确遇到 TextKit 1 的附件布局、选区、超长文档性能或复杂交互瓶颈时，才值得单独立项评估。 |

### 7.1 我对“当前先做什么”的建议

如果只选三件最该做的事，我建议顺序如下：

1. **先做流式增量渲染链，而不是先迁 TextKit 2。**  
   现在真正的能力差距主要在“流式解析与局部更新”，不是渲染后端名字。
2. **把 TOC/footnote 这类“内容语义能力”单独建模。**  
   这些能力一旦继续塞进 renderer 或业务层，后面只会更难补。
3. **用压测结论决定并发保护形态。**  
   若压测未暴露问题，不必急着引入全局锁；若暴露 parser 级竞态，再补最小串行化保护。

### 7.2 P0：增量 AST、`replaceCount`、parser 级锁（实现语义对照）

本节把 vendor 源码里的名词落到「ST 若要补齐，大致要做什么」，不等同于逐 API 抄过去。

#### 7.2.1 Vendor：`IncrementalParseResult` 在解决什么问题

`MarkdownParser.parseIncremental(...)` 大致顺序是：`detectPendingStructure` → `findSafeBreakpoint` 得到 **`safePosition`** → 从 `lastSafePosition` 向前取 **`contextWindowSize`** 字符得到 `parseStart`，对 `[parseStart, safePosition)` 子串 **`parseDocument` + `render`**，得到 **`newElements`**；同一次调用里还会 **`extractHeadings`** 得到 **`tocItems`**。

**`replaceCount`** 的含义（见 vendor 注释）：因为解析窗口**向前回溯**了 `contextWindowSize`，新解析出的块可能与「上一轮已挂到 UI 上的尾部块」在语义上重叠或已被修正，需要从**元素列表尾部**按个数丢掉/替换旧元素，避免尾部重复或结构纠错失败。实现上由 `estimateReplaceCount(previousElementCount:contextWindowSize:parseStart:lastSafePosition:)` 估算。

**`parseLock`**：vendor 在真正走 swift-markdown / cmark 的路径上用 **`NSLock()`** 包一层，注释写明用于避免 **swift-cmark 在多线程并发挂载语法扩展时崩溃**；与视图侧的 `renderQueue`、版本号等是不同层级的保护。

#### 7.2.2 ST：当前断点与差距

| 概念 | Vendor | ST（当前） |
|------|--------|------------|
| 流式安全切分 | `lastSafePosition` 与 parser 协同 | `STMarkdownStreamBuffer` 的 **`lastSafeUpperBoundOffset`**；与 ``STMarkdownIncrementalParameters`` 偏移对齐 | **【部分对齐】** |
| 解析范围 | 回溯窗口 + 子串 parse | ``STMarkdownPipeline/processIncremental``：``parseStart = max(0, lastCommitted - contextWindowSize)``，`parseEnd = currentSafeExclusiveEnd` | **【部分对齐】** |
| 增量产物 | `newElements` + **`replaceCount`** + `tocItems` | ``STMarkdownIncrementalParseResult``：**`replaceTailCount`** + **`windowRenderDocument`** + **`windowTableOfContents`** + ``mergedRenderDocument`` | **【部分对齐】** |
| 并发 | **`parseLock`** 串行化 cmark 路径 | ``STMarkdownStructureParser`` 内 **`parseLock`** | **【已对齐】** |

#### 7.2.3 ST 侧「增量 AST」若要落地，建议拆成两层

1. **缓冲层（已有方向）**：继续用 `STMarkdownStreamBuffer` 决定「这一帧可安全提交给渲染器的 markdown 子串」（对齐 vendor 的 safe 边界思想，但 ST 用 UTF-16/字符偏移持久化，避免 `String.Index` 失效）。
2. **AST / 渲染元素层（已提供公开入口）**：``STMarkdownPipeline/processIncremental(_:)`` 在管线内维护 **窗口子串 → `STMarkdownRenderDocument`**，并输出 **`replaceTailCount`**（与 Vendor ``estimateReplaceCount`` 同式）及 ``mergedRenderDocument(previous:)``；与 **TextKit `replaceCharacters`** 的硬连接、与缓冲器内置 `findSafeBreakpoint` 一体化仍为后续工作。

这样文档里说的「增量 AST」才名副其实：光有字符串 `safe` 切分没有 **元素级 tail replace**，长文流式仍会整段重跑，CPU 与闪动与 vendor 不在同一量级。

#### 7.2.4 `parseLock` 是否要在 ST 照搬

ST 已在 ``STMarkdownStructureParser`` 解析路径上使用 **`parseLock`**（见 §3 / §5）。若仍出现并发下的 cmark 竞态，再按压测结论考虑 **actor** 或更广临界区。

#### 7.2.5 ST 已提供的增量 API（`replaceTailCount` / 窗口 parse）

以下对应 Vendor ``IncrementalParseResult`` 的 **可编程子集**（子串仍走完整 parse → normalize → adapt，与 Vendor 对窗口片段调用 `parseDocument` 同构）：

| 类型 / 方法 | 作用 |
|-------------|------|
| ``STMarkdownIncrementalParameters`` | `canonicalMarkdown`、`lastCommittedExclusiveEnd`、`currentSafeExclusiveEnd`、`contextWindowSize`（默认 200）、`previousTotalRenderBlockCount` |
| ``STMarkdownPipeline/processIncremental(_:)`` / ``STMarkdownEngine/processIncremental(_:)`` | 计算 `parseStart = max(0, lastCommitted - window)`、`parseEnd = currentSafeEnd`，对 `[parseStart, parseEnd)` 子串跑管线（**不**跑输入 sanitizer，见参数文档） |
| ``STMarkdownIncrementalParseResult`` | `replaceTailCount`（与 Vendor ``estimateReplaceCount`` 相同启发式）、`windowRenderDocument`、`windowTableOfContents`、`mergedRenderDocument(previous:)` |
| ``STMarkdownIncrementalParseResult/mergedRenderBlocks`` | 纯函数尾部拼接，便于单元测试与宿主实验 |

**局限（与 Vendor 全量能力仍有差距）**：未内置 `findSafeBreakpoint` / `hasPendingStructure` 与缓冲器二合一；宿主需自行把 ``STMarkdownStreamBuffer`` 的安全上界喂给 `currentSafeExclusiveEnd`。合并后的 **标题 `anchorId`** 若需全局唯一，仍应对全文再跑一次 ``process(_:)`` 或自建 slug 策略。

---

### 7.3 P1：TOC、footnote（从「块里有标题」到「可导航产品能力」）

#### 7.3.1 TOC（目录）

Vendor 除 `MarkdownTOCItem` 数据结构外，还把 **`tocItems` 放进 `IncrementalParseResult`**，视图层有 **`onTOCItemTap`、`generateTOCView`、`scrollToTOCItem`** 等一体面。

ST 若要做到 **P1 可交付**：

- **模型**：为每个 heading 生成稳定 **锚点 id**（GitHub slug 规则或自定义），输出 **`STMarkdownTOCItem`（level、title、id、可选 sourceRange）**。
- **抽取**：在 `STMarkdownStructureParser` / AST 遍历中集中收集，避免散落在 `STMarkdownAttributedStringRenderer`。
- **宿主 API**：与 vendor 对齐的最小面可以是：`tableOfContents: [STMarkdownTOCItem]` + **`scrollToTOCItem(id:)`**（内部映射到 `NSRange` 或 layout fragment，驱动 `UITextView.scrollRangeToVisible` 或外层 `UIScrollView`）。

#### 7.3.2 Footnote（脚注）

Vendor 有 **脚注预处理、缓存、延迟脚注视图** 链路；ST 当前 **citation 角标**（如 `STMarkdownNumberBadgeAttachment`）是另一条产品语义，**不能**当作 CommonMark/GFM 风格 footnote 的完成态。

P1 建议：

- **AST**：增加 `footnoteReference` / `footnoteDefinition`（或扩展 swift-markdown 插件）与 **编号/反向链接** 规则。
- **渲染**：正文角标 + 文末脚注区（或侧栏）与 **citation** 分流配置，避免两套角标语义混在一个 attachment key 上。

---

### 7.4 P2：`<details>`、rawHTML、TextKit 2

#### 7.4.1 `details` / 折叠块

Vendor `MarkdownRenderElement` 级有 **`details`** 一类块。ST 若要做：

- 先 **`STMarkdownBlockNode` / `STMarkdownRenderBlock`** 扩展，再 UI（折叠态可升宿主状态，避免写死在单一 `UITextView`）。

#### 7.4.2 `rawHTML`

Vendor 有 **`rawHTML(String)`** 分支；ST 侧 `STHtmlNormalizeRule` 等已表明 **下游不消费原始 HTML**。若产品强需求，应单独做 **白名单标签 + 安全渲染**（甚至独立 `WKWebView` 沙箱），不宜默认并进 `NSAttributedString` 主路径。

#### 7.4.3 TextKit 2

Vendor 核心视图走 **`NSTextContentStorage` + `NSTextLayoutManager`**（`MarkdownTextViewTK2.swift`）；ST 主路径 **`usingTextLayoutManager: false`**（TextKit 1）。

**P2 迁移**适合在出现明确瓶颈时立项，例如：超长文档排版性能、复杂附件 provider、与系统选区/无障碍行为强绑定。与 ST 当前 **表格 Collection + attachment overlay** 的组合是否迁 TK2 需要 **单独架构评估**，不宜与「流式增量 AST」同一迭代混谈。

---

## 8. 参考链接

- Vendor 仓库：<https://github.com/zjc19891106/MarkdownDisplayView.git>
- Vendor `Package.swift` 中 target path：`MarkdownDisplayView/Sources/MarkdownDisplayView`

---

## 9. 仍可深入补充的维度（未在文中逐条展开）

若要做「实现级」迁移清单，建议后续按需补小节或链接到具体行号。**增量解析 / replaceCount / parser 锁 / TOC-footnote-TK2** 的落地顺序与语义已集中在 **第 7.2–7.4 节**。

- **`MarkdownConfiguration` 全字段** 与 **`STMarkdownStyle` + Pipeline** 的逐项字段映射表（体量最大）。
- **`MarkdownViewTextKit` / `MarkdownDisplayView.swift`** 内生命周期、高度通知（vendor `notifyHeightChange` 命名）与 **`STMarkdownBaseTextView.publishContentLayoutHeightNotificationIfNeeded`** 的逐项对照。
- **无障碍**：Vendor TK2 栈与 ST `UITextView` 的 **accessibility** 差异。
- **许可证**：若从 vendor 复制 **KaTeX 字体文件**，需单独核对字体与 KaTeX 的许可条款；ST 当前以 **SwiftMath** 为主。

---

*本文描述基于当时仓库快照与目录结构；Vendor 后续版本若变更路径或 API，请以仓库为准更新本节。*
