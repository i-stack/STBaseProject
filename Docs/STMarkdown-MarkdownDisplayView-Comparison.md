# STMarkdown 与 MarkdownDisplayView（Vendor）对比说明

> 对照基准（Vendor 源码路径）：  
> `/Users/song/Downloads/MarkdownDisplayView/MarkdownDisplayView/Sources/MarkdownDisplayView`  
> 对照对象（本仓库）：  
> `Sources/STMarkdown/`  
> 文档生成日期：2026-05-14

本文汇总架构、文件映射、能力差异及在 Cursor 中的对比方式，便于后续按模块对齐或迁移。

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

| 维度 | MarkdownDisplayView（Vendor） | STMarkdown |
|------|--------------------------------|------------|
| Swift 文件量 | 约 **21** 个 + `Resources/` | **45** 个 + `Resources/` |
| 代码组织 | **少量超大文件**（如 `MarkdownDisplayView.swift`、`MarkdownParser.swift`） | **分层**、职责拆分 |
| 最低 iOS（以各自 Package/podspec 为准） | iOS **15+**（`@available(iOS 15.0, *)` 等） | iOS **16+**（工程配置） |
| 解析依赖 | **swift-markdown**（`import Markdown`） | **swift-markdown**（SPM `Markdown`） |
| CocoaPods 差异（若用 Pod） | 可能经 **AppleSwiftMDWrapper** 等桥接 | **swift-markdown-pod** + CAtomic modulemap |
| 数学公式 | **KaTeX**（字体 + `LaTeXAttachment` / `LatexMathView` 等） | **SwiftMath** + `STMarkdownMathNormalizer` |
| **SPM 产品名** | `MarkdownDisplayView` | 合在 **`STBaseProject`** 的 `STMarkdown` 源码目录（非独立 SwiftPM 产品名） |
| **CocoaPods 产品名** | **`MarkdownDisplayKit`**（与 SPM 名不同） | **`STBaseProject/STMarkdown`** subspec |
| **swift-markdown 版本** | SPM：`from: "0.7.3"`（随解析器升级行为可能变） | 本仓库 `Package.swift` **固定 revision**；与 vendor 的 cmark/扩展差异需升级时单独回归 |

---

## 2.1 对外 API 入口（便于宿主对照）

| 场景 | Vendor（典型） | STMarkdown（典型） |
|------|----------------|-------------------|
| 可滚动整页预览 | `ScrollableMarkdownViewTextKit`（`UIScrollView` + 内嵌 `MarkdownViewTextKit`） | 自嵌 `UIScrollView` + `STMarkdownTextView` / `STMarkdownStreamingTextView`，或 `STMarkdownSwiftUIView` |
| 流式打字机 | `startStreaming(...)`、`StreamingUnit`（如 `.word`）等 | `beginSmartMarkdownStreaming()`、`appendSmartMarkdownStreamingChunk(_:)`、`endSmartMarkdownStreaming()`；或 `setMarkdown(_:animated:)` |
| 配置对象 | `MarkdownConfiguration`（大结构体，含 `MarkdownLineSpacingConfiguration`、`SyntaxHighlightColors` 等） | `STMarkdownStyle` + `STMarkdownEngine` / `STMarkdownPipelineConfiguration` 等拆分配置 |
| 流式触感 | `StreamingHapticFeedbackStyle` 等 | **无**同名 API；需宿主自行 `UIImpactFeedbackGenerator` |
| Mermaid / 自定义代码块 | 协议 **`MarkdownCodeBlockRenderer`**（示例工程 `MermaidRenderer`） | **`STMarkdownCodeBlockRendering`**、`STMarkdownMermaidRenderer` 等 |

---

## 3. 文件级映射（Vendor → STMarkdown）

| Vendor 文件 | 角色 | STMarkdown 对应 / 说明 |
|-------------|------|-------------------------|
| `MarkdownParser.swift` | swift-markdown 遍历、`IncrementalParseResult`、`parseLock`、产出 `MarkdownRenderElement`、TOC、图片附件等 | `STMarkdownStructureParser`、`STMarkdownMathNormalizer`、`STMarkdownPipeline`、`STMarkdownRenderAdapter`、`STMarkdownInputSanitizer`、`STMarkdownMalformedTableNormalizer`。ST 以 **整段管线 `process(_:)`** 为主，**无** vendor 同款「增量 `safePosition` / `replaceCount` / 元素级回溯」公开形态 |
| `MarkdownRenderElement.swift` | 渲染树枚举、`MarkdownConfiguration`、`MarkdownTOCItem`、`MarkdownTypewriterTextMode` 等 | `STMarkdownAST` / `STMarkdownRenderAST`、`STMarkdownStyle`。已核对：ST **有** heading/list/table/math/image 等核心块；**无** vendor 同级的 `details`、`rawHTML`、`footnote`、`TOC item` 块模型 |
| `MarkdownRender.swift` | 元素 → 属性串 / 展示逻辑 | `STMarkdownAttributedStringRenderer` + `Rendering/Default/*`、`Rendering/Advanced/*` |
| `MarkdownDisplayView.swift` | 总装、与 TextKit 视图协作（体量很大） | `STMarkdownBaseTextView`、`STMarkdownTextView`、`STMarkdownStreamingTextView` 等拆分 |
| `MarkdownTextViewTK2.swift` | **TextKit 2**：`NSTextContentStorage`、`NSTextLayoutManager`、附件 Provider、`typewriterTextMode` 等 | `UITextView` / `STShimmerTextView`，**`usingTextLayoutManager: false`**（经典 TextKit 路径） |
| `TypewriterEngine.swift` | 对子视图树（`MarkdownTextViewTK2` / `UILabel` / `UIStackView`）队列动画、`onLayoutChange` | `STShimmerTextView` + `STMarkdownStreamingTextView` 动画/增量更新；**无** vendor 同款整棵 block UI 队列 + watchdog |
| `MarkdownStreamBuffer.swift` | `Int` 型 `lastSafePosition`、`containerWidth`、可选 `onModuleReady`（带预解析元素）、调试日志 | `STMarkdownStreamBuffer`：字符偏移持久化、`streamMinModuleLength`、**纯字符串**模块切分；**无** `containerWidth` / **无**模块内解析回调 |
| `ScrollableMarkdownViewTextKit.swift` | `UIScrollView` 包装、`markdown`/`configuration`、`onTOCItemTap`、`tableOfContents`、`generateTOCView` 等 | **无**同名一体化控件；滚动与 TOC 由宿主或 `STMarkdownSwiftUIView` 等组合实现 |
| `MarkdownTableSupport.swift` | 表格与 TextKit2 / 附件协作 | `Table/STMarkdownTable*.swift`、CollectionView 表格附件；与 CHANGELOG 中 **UILabel 表格 cell + `onLinkTap`** 链路不同 |
| `CodeBlockAttachment.swift` | 代码块附件 | `STMarkdownCodeBlockAttachmentRenderer`、`STMarkdownDefaultCodeBlockRenderer` 等 |
| `LaTeXAttachment.swift`、`LatexMathView.swift`、`LateXParser.swift`、`LateXNodeSets.swift` | KaTeX 渲染链 | `STMarkdownDefaultMathRenderer` + SwiftMath + `STMarkdownMathNormalizer` |
| `FontLoader.swift` | KaTeX 字体注册 | ST 使用 SwiftMath / Bundle 资源，无同一套 `FontLoader` |
| `ImageCacheManager.swift`、`ImageLoader.swift`、`ImageView.swift` | 图片缓存与展示 | `STMarkdownAsyncImageRenderer`、`STMarkdownDefaultImageRenderer` 等 |
| `MarkdownCustomExtension.swift` | 自定义扩展元素 | `STMarkdownAdvancedRenderers`、各类 `*Rendering` 协议 |
| `ArraySafe.swift` | 安全下标等工具 | ST 内散见于各文件，无同名单文件 |

---

## 4. 能力差异摘要

1. **渲染引擎**：Vendor 为 **TextKit 2**；ST 主路径为 **`UITextView` + TextKit 1**（`usingTextLayoutManager: false`）。
2. **解析与并发**：Vendor **`MarkdownParser` 内 `parseLock` 串行化 swift-markdown**，并在视图层配合 `renderQueue`/版本锁做增量渲染保护；ST `STMarkdownEngine` / `STMarkdownPipeline` 已按 `Sendable` 设计，但**没有** vendor 同款 parser 级串行锁与增量回溯保护，是否需要补锁应以并发压测结论为准。
3. **流式**：Vendor 缓冲器可 **`onModuleReady` 带 `MarkdownRenderElement`**，并与 **Typewriter 视图树** 配合；ST 为 **字符串级 `STMarkdownStreamBuffer`** + **富文本侧 Shimmer/增量 `setMarkdown`**。
4. **目录 TOC**：Vendor **内置 `MarkdownTOCItem`、生成目录视图、跳转 API**；ST **无对等的一体式 TOC 公共面**（需业务自建或后续扩展）。
5. **块级模型**：Vendor `MarkdownRenderElement` 含 **`details`、`rawHTML`**，并把 **heading/TOC/footnote** 等信息留在统一块级模型附近；ST 当前 `STMarkdownBlockNode` / `STMarkdownRenderBlock` **未定义** `details`、`rawHTML`、`footnote`、`TOC` 对等节点。
6. **公式**：Vendor **KaTeX**；ST **SwiftMath**，命令集与排版不必一致。
7. **表格**：Vendor 与 TextKit2 附件、手势、（文档所述）**表格内链接走 cell 选择 + `onLinkTap`** 等；ST 为 **独立表格 Collection + overlay**，交互模型不同。
8. **脚注 / 角标**：Vendor 有 **独立脚注模型 + 延迟渲染脚注视图**；ST 侧当前更偏向 **Citation 角标**（如 `STMarkdownNumberBadgeAttachment`、表格内 citation 流程），**不能等价视为 footnote 支持**。

## 4.3 已从源码核对的结论

以下条目是本次直接对照源码后确认的结果，可视为比前文更高置信度的“实现级”结论：

| 维度 | Vendor 结论 | ST 结论 | 判断 |
|------|-------------|---------|------|
| 流式增量解析 | `MarkdownParser.parseIncremental(...)` 返回 `safePosition`、`replaceCount`、`newElements` | `STMarkdownStreamBuffer` 只负责**字符串模块切分**，真正渲染仍走整段 `engine.process(...)` | ST **弱于** vendor |
| 流式模块回调 | `MarkdownStreamBuffer.onModuleReady` 可回传预解析 `MarkdownRenderElement` | `STMarkdownStreamBuffer` 无模块内预解析回调 | ST **弱于** vendor |
| 块级能力 | `MarkdownRenderElement` 含 `details`、`rawHTML`、`heading(id:...)`、`table`、`latex`、`list` | `STMarkdownBlockNode` / `STMarkdownRenderBlock` 仅含 paragraph/heading/quote/list/code/table/math/image/thematicBreak | ST **缺少** `details` / `rawHTML` / `footnote` |
| TOC | 视图层公开 `tableOfContents`、`onTOCItemTap`、`generateTOCView()`、`scrollToTOCItem(...)` | 未检出对等公共 API；heading 仅作为普通 block 渲染 | ST **缺少一体化 TOC 面** |
| 脚注 | 预处理 footnote，缓存并延迟渲染 footnote view | 未检出 footnote 模型/渲染链；存在 citation badge 流程 | ST **缺少 footnote** |
| TextKit 栈 | 核心视图基于 `NSTextLayoutManager` / `NSTextContentStorage` / TK2 attachment provider | `UITextView(usingTextLayoutManager: false)` 明确走 TextKit 1 路线 | 路线不同 |
| HTML | Vendor 存在 `rawHTML(String)` 元素与对应渲染分支 | ST `STHtmlNormalizeRule` 注释明确写明 downstream **no handling for raw HTML** | ST **明确不支持 raw HTML** |
| 交互能力 | `onLinkTap`、`onImageTap`、TOC tap、脚注视图 | `onLinkTap`、`onSelectionChange`、`onCitationTap` | 各有侧重 |
| 表格交互 | 表格与 TK2 attachment 深度耦合 | 表格为独立 View/Attachment + overlay/citation 区域 | 路线不同 |

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

| 项目 | Vendor | STMarkdown |
|------|--------|------------|
| 单测位置 | `MarkdownDisplayView/Tests/MarkdownDisplayViewTests/`（Swift `Testing` 等） | `Example/STBaseProjectExampleTests/` 下 `STMarkdown*`、`STMarkdownStreamBufferTests` 等 |
| 调试输出 | `MarkdownStreamBuffer` 等路径存在 **`print`** 日志 | ST 侧一般 **无** 同等控制台噪声；排障依赖宿主或自行埋点 |

---

## 5. 已在 ST 侧做过的对齐方向（会话内实现，供对照）

以下属于 STMarkdown 演进中与「常见流式 Markdown 组件」接近的行为，**不等同**于 vendor 逐行一致：

- `STMarkdownStreamBuffer`：围栏闭合处切分、段落模式 EOF 尾段、**字符偏移**持久化 `lastSafeUpperBoundOffset`（避免 `String.Index` 跨 `+=` 失效）。
- `STMarkdownBaseTextView`：`resolvedMarkdownMeasurementWidth()`、高度回退、`contentLayoutHeightNotificationMinInterval` 等。
- `STMarkdownPipeline` / `STMarkdownMalformedTableNormalizer`：与 vendor 文档中的「坏表修复」类似语义。

单测可参考：`STMarkdownStreamBufferTests`、`STMarkdownBaseTextViewLayoutTests`、`STMarkdownPipelineTests` 中流式相关用例。

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
| P0 | **流式增量渲染链补强** | 当前 ST 已有 `STMarkdownStreamBuffer`，但渲染仍偏“整段重跑”。最优先补的是 **增量 parse / replaceCount / 安全回溯窗口**，否则长文本流式时 CPU、重排和闪动都不占优。 |
| P0 | **流式专项测试补齐** | 继续补围栏、表格、公式、标题切换、列表/引用未闭合、Unicode chunk 边界、长文多轮 append 的单测。这个成本低，但能直接兜住后续重构。 |
| P1 | **目录 TOC 抽取能力** | ST 已有 heading block，但缺少 heading id、TOC 数据结构、滚动定位 API。若业务里有“长文导航/知识库/AI 报告”场景，这一项收益很高。 |
| P1 | **脚注与引用语义拆分** | 当前 citation badge 更像业务增强，不等于 CommonMark footnote。若要对齐通用 Markdown 能力，应补 `footnote definition/reference` 语义模型，而不是继续堆 UI 角标。 |
| P1 | **并发压测与线程模型定稿** | 不是先机械照搬 `parseLock`，而是先验证 `STMarkdownEngine` 在并发 `process(_:)`、流式 append、异步 attachment 刷新下是否有竞态/崩溃/性能退化，再决定是否引入 parser 级锁或 actor。 |
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

---

## 8. 参考链接

- Vendor 仓库：<https://github.com/zjc19891106/MarkdownDisplayView.git>
- Vendor `Package.swift` 中 target path：`MarkdownDisplayView/Sources/MarkdownDisplayView`

---

## 9. 仍可深入补充的维度（未在文中逐条展开）

若要做「实现级」迁移清单，建议后续按需补小节或链接到具体行号：

- **`MarkdownConfiguration` 全字段** 与 **`STMarkdownStyle` + Pipeline** 的逐项字段映射表（体量最大）。
- **`MarkdownViewTextKit` / `MarkdownDisplayView.swift`** 内生命周期、高度通知（vendor `notifyHeightChange` 命名）与 **`STMarkdownBaseTextView.publishContentLayoutHeightNotificationIfNeeded`** 的逐项对照。
- **增量解析**：`IncrementalParseResult.replaceCount` 回溯策略与 ST **全量重渲染** 的等价性与性能差异。
- **无障碍**：Vendor TK2 栈与 ST `UITextView` 的 **accessibility** 差异。
- **许可证**：若从 vendor 复制 **KaTeX 字体文件**，需单独核对字体与 KaTeX 的许可条款；ST 当前以 **SwiftMath** 为主。

---

*本文描述基于当时仓库快照与目录结构；Vendor 后续版本若变更路径或 API，请以仓库为准更新本节。*
