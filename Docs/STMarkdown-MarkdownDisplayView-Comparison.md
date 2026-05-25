# STMarkdown 与 MarkdownDisplayView（Vendor）功能对比

> 对照基准：Vendor 库 [MarkdownDisplayView](https://github.com/zjc19891106/MarkdownDisplayView.git) 中 `MarkdownDisplayView` target 源码。  
> 对照对象：本仓库 `Sources/STMarkdown/`。  
> 文档生成日期：2026-05-14；**进度修订**：2026-05-14（P0 部分落地、P1 首轮落地，见 §0）。

## 0. 对齐进度快照（工程状态）

| 优先级 | 方向 | 状态 |
|--------|------|------|
| P0 流式增量渲染链 | `processIncremental` + `STMarkdownStreamBuffer` 偏移对齐；`setMarkdown` 动画路径抽取为 `applySetMarkdownAnimatedDiff`；`renderWithDocument` 统一 `process` 与 TOC 更新 | **【部分完成】** 视图层仍未用合并 AST 替代全文 `process`（合并与全文在部分 Markdown 上不一致，待修后再接） |
| P0 流式专项测试 | `STMarkdownIncrementalParseTests` 严格前缀增长（简单两步）与既有 StreamBuffer / Pipeline 测 | **【部分完成】** 表/公式/Unicode 等扩展用例仍待补 |
| P1 TOC 产品面 | `STScrollableMarkdownView.showsTableOfContents` 内置侧栏、`onTOCItemTap`、`onTableOfContentsChange`；`STMarkdownBaseTextView.scrollToTOCItem`、`onTableOfContentsChange` | **【已完成】**（Vendor 同名 API 不必一致） |
| P1 脚注与 citation | 脚注引用使用 `stmarkdown-footnote://` 深度链接触发 `onFootnoteTap`；表格 Citation 仍走 `onCitationTap` / badge | **【已完成】**（语义分流；脚注 AST 管线既有） |
| P1 并发压测 | `STMarkdownConcurrencyStressTests` 多队列 `process` 冒烟 | **【已完成】**（轻量冒烟，非性能基准） |

本文只保留**行为与能力**层面的差异与对齐说明，便于宿主选型与后续按能力补齐。

**对齐标注图例**（下文「对齐」列沿用同一套语义）：

| 标签 | 含义 |
|------|------|
| **【已对齐】** | 该维度上能力或依赖已等价覆盖（实现路径、API 名称可与 Vendor 不同）。 |
| **【部分对齐】** | 双方均有对应能力或同类入口，但栈、交互模型或公开面仍有明显差异。 |
| **【未对齐】** | ST 侧缺失、明确不支持或架构路线与 Vendor 不可直接等同。 |

---

## 1. 运行环境与依赖（影响行为与集成）

| 维度 | MarkdownDisplayView（Vendor） | STMarkdown | 对齐 |
|------|--------------------------------|------------|------|
| 最低 iOS（以 Package/podspec 为准） | iOS **15+** | iOS **16+** | **【未对齐】** |
| 解析依赖 | **swift-markdown**（`import Markdown`） | **swift-markdown**（SPM `Markdown`） | **【已对齐】** |
| CocoaPods（若用 Pod） | 可能经 **AppleSwiftMDWrapper** 等桥接 | **swift-markdown-pod** + CAtomic modulemap | **【部分对齐】** |
| 数学公式 | **KaTeX**（字体 + LaTeX 附件 / 视图链） | **SwiftMath** + `STMarkdownMathNormalizer` | **【部分对齐】**（引擎与命令集不必一致） |
| swift-markdown 版本策略 | SPM：`from: "0.7.3"`（随升级行为可能变） | 本仓库 **固定 revision**；升级需单独回归 | **【部分对齐】** |

---

## 2. 对外 API 与宿主场景

| 场景 | Vendor（典型） | STMarkdown（典型） | 对齐 |
|------|----------------|-------------------|------|
| 可滚动整页预览 | `ScrollableMarkdownViewTextKit`（`UIScrollView` + 内嵌 TextKit 视图） | `STScrollableMarkdownView`（可选内置 TOC 侧栏）或自嵌 `UIScrollView` + `STMarkdownTextView` / `STMarkdownStreamingTextView`，或 `STMarkdownSwiftUIView` | **【部分对齐】**（与 Vendor 仍非逐 API 同名） |
| 流式打字机 | `startStreaming(...)`、`StreamingUnit`（如 `.word`）等 | `beginSmartMarkdownStreaming()`、`appendSmartMarkdownStreamingChunk(_:)`、`endSmartMarkdownStreaming()`；或 `setMarkdown(_:animated:)` | **【部分对齐】**（粒度 API 不同） |
| 配置对象 | `MarkdownConfiguration`（大结构体，含行距、语法高亮色等） | `STMarkdownStyle` + `STMarkdownEngine` / `STMarkdownPipelineConfiguration` 等拆分配置 | **【部分对齐】** |
| 流式触感 | `StreamingHapticFeedbackStyle` 等 | **无**同名 API；需宿主自行 `UIImpactFeedbackGenerator` | **【未对齐】** |
| Mermaid / 自定义代码块 | 协议 **`MarkdownCodeBlockRenderer`**（示例 `MermaidRenderer`） | **`STMarkdownCodeBlockRendering`**、`STMarkdownMermaidRenderer` 等 | **【已对齐】**（协议化可插拔） |

---

## 3. 能力差异摘要

1. **渲染引擎**：Vendor 为 **TextKit 2**；ST 主路径为 **`UITextView` + TextKit 1**（`usingTextLayoutManager: false`）。**【未对齐】**
2. **解析与并发**：Vendor 在解析路径用 **`parseLock`** 串行化 swift-markdown，视图层另有 `renderQueue`/版本锁等增量保护；ST 在 **`STMarkdownStructureParser.parse`** 使用 **`parseLock`**；**无**视图层版本锁与 **无** Vendor 同款元素级增量回溯公开形态。**【部分对齐】**
3. **流式**：Vendor 缓冲器可 **`onModuleReady` 带预解析 `MarkdownRenderElement`**，并与 **Typewriter 子视图树** 配合；ST 为 **`STMarkdownStreamBuffer`**（可选 **`onCompleteModules`** 仅字符串）+ **Shimmer / 增量 `setMarkdown`**。**【部分对齐】**（预解析元素与视图树 **【未对齐】**）
4. **目录 TOC**：Vendor **内置目录视图、`onTOCItemTap`、跳转 API**；ST 提供 **`STMarkdownTOCItem`**、**`tableOfContents`**、**`scrollToHeadingAnchor`** / **`scrollToTOCItem`** / **`characterRangeForHeadingAnchor`**，以及 **`STScrollableMarkdownView`** 可选 **内置 TOC 侧栏** 与 **`onTOCItemTap`**、**`onTableOfContentsChange`**（流式同帧刷新宿主侧栏）。**【部分对齐】**（布局与 Vendor 组件仍不同）
5. **块级模型**：Vendor 含 **`details`、`rawHTML`、footnote** 等；ST 当前 **`STMarkdownBlockNode` / `STMarkdownRenderBlock`** 已定义 **`details` / `rawHTML`**，脚注也已进入 AST / 渲染链；但 **`rawHTML`** 默认仍不渲染为富文本 HTML、脚注 UI 形态也与 Vendor 不同。**【部分对齐】**
6. **公式**：KaTeX vs SwiftMath，排版与命令集不必一致。**【部分对齐】**
7. **表格**：Vendor 与 TextKit2 附件、手势、表格内链接等深度耦合；ST 为 **独立表格 Collection + overlay**，交互模型不同。**【部分对齐】**
8. **脚注 / 角标**：Vendor **脚注模型 + 延迟脚注视图**；ST 具备 **GFM 脚注 AST/管线**（`[^label]` + 定义行），正文中以 **`stmarkdown-footnote://` 链接触发 `onFootnoteTap`**，与表格 **Citation 角标**（`onCitationTap`）分流。**【部分对齐】**（延迟脚注视图 / Vendor 同款 UI 仍不同）
9. **链接与图片**：双方均有 **`onLinkTap`** 类回调与异步图片链路。**【已对齐】**（命名与 TK 细节不同，见 §4）

---

## 4. 源码级核对结论

以下条目为对照源码后的「实现级」结论，置信度高于 §3 条目概括。

| 维度 | Vendor 结论 | ST 结论 | 判断 | 对齐 |
|------|-------------|---------|------|------|
| 流式增量解析 | `parseIncremental(...)` → `safePosition`、`replaceCount`、`newElements` | 整段仍走 `process`；**`processIncremental`** → **`replaceTailCount`** + **`windowRenderDocument`**；安全上界由缓冲器提供 | ST **弱于** vendor 一体化 | **【部分对齐】** |
| 流式模块回调 | `onModuleReady` 可回传预解析元素 | **`onCompleteModules`** 仅完整模块字符串；无预解析 AST | ST **弱于** vendor | **【部分对齐】** |
| 块级能力 | `details`、`rawHTML`、`heading(id:...)`、`table`、`latex`、`list` 等 | AST / Render AST 已定义 **`details` / `rawHTML`**；脚注 **`[^]`** 与定义行已进管线；**`heading` 含 `anchorId`** | ST **已补齐块级建模**，主要差在 HTML 消费策略与 UI 形态 | **【部分对齐】** |
| TOC | `tableOfContents`、`onTOCItemTap`、`generateTOCView()`、`scrollToTOCItem(...)` | 管线 + **`STMarkdownBaseTextView`**：`tableOfContents`、`onTableOfContentsChange`、`scrollToHeadingAnchor` / **`scrollToTOCItem`**；**`STScrollableMarkdownView`** 可选内置侧栏 + **`onTOCItemTap`** | 一体布局与 Vendor 不同 | **【部分对齐】** |
| 脚注 | 预处理、缓存、延迟脚注视图 | 管线剥离定义 + 正文 `[^]` → **`onFootnoteTap`**（深度链接）；Citation 仍独立 | 脚注视图形态不同 | **【部分对齐】** |
| TextKit 栈 | `NSTextLayoutManager` / `NSTextContentStorage` / TK2 | `usingTextLayoutManager: false`（TextKit 1） | 路线不同 | **【未对齐】** |
| HTML | `rawHTML(String)` 与渲染分支 | AST / Renderer 已保留 **`rawHTML`** block；默认策略以 `STMarkdownStyle.rawHTMLPolicy` 控制（默认抑制，也可字面等宽显示），**不**把 HTML 渲染成富文本 DOM | ST **支持保留与字面显示**，但**不支持富 HTML 渲染** | **【部分对齐】** |
| 交互 | `onLinkTap`、`onImageTap`、TOC tap、脚注视图 | `onLinkTap`、`onFootnoteTap`、`onSelectionChange`、`onCitationTap`；TOC 侧栏 `onTOCItemTap`（见 `STScrollableMarkdownView`） | 各有侧重 | **【部分对齐】** |
| 表格交互 | 与 TK2 attachment 深度耦合 | 独立 View/Attachment + overlay/citation | 路线不同 | **【部分对齐】** |

---

## 5. 已在 ST 侧做过的对齐（实现备注）

> 语义接近 Vendor 常见流式 Markdown 组件，**非**逐行一致。

- **`STMarkdownStreamBuffer`** **【部分对齐】**：安全切分、字符偏移 **`lastSafeUpperBoundOffset`**、可选 **`onCompleteModules`**。与 Vendor 的差距见 §3 第 3 点。
- **`STMarkdownBaseTextView`** **【部分对齐】**：测量宽度、高度通知节流；**`tableOfContents`**、**`onTableOfContentsChange`**、**`scrollToHeadingAnchor`** / **`scrollToTOCItem`**、**`characterRangeForHeadingAnchor`**；**`onFootnoteTap`**（脚注链）与 **`onCitationTap`**（表格角标）分流。
- **`STScrollableMarkdownView`** **【部分对齐】**：可选 **`showsTableOfContents`** 内置目录侧栏、**`onTOCItemTap`**、**`onTableOfContentsChange`**（与流式刷新同帧）。
- **`STMarkdownFootnoteDeepLink`** + 渲染器脚注 **`NSTextAttribute.link`**：与 **`onLinkTap`** 分流（P1）。
- **`STMarkdownHTMLBlockClassifier`** + **`STMarkdownAttributedStringRenderer`** **【部分对齐】**：已支持 **`<details>`** 解析为独立 block，**`rawHTML`** 也可按 `rawHTMLPolicy` 选择抑制或字面等宽显示；差距主要在不执行富 HTML 渲染。
- **`STMarkdownStructureParser`**：**`parseLock`** 串行化解析路径（与 Vendor 动机一致）。
- **`STMarkdownPipeline`** / **`STMarkdownMalformedTableNormalizer`**：坏表修复；**`STMarkdownPipelineResult.tableOfContents`**；**`processIncremental(_:)`**（窗口 parse、**`replaceTailCount`**、**`mergedRenderDocument`**，见 §6.2.5）。
- **`STMarkdownRenderBlock.heading`** + **`NSAttributedString.Key.stMarkdownHeadingAnchor`**：锚点与 TOC 一致。

单测入口示例：`STMarkdownStreamBufferTests`、`STMarkdownBaseTextViewLayoutTests`、`STMarkdownPipelineTests`（流式）、**`STMarkdownTOCTests`**（含可滚动容器 TOC）、**`STMarkdownIncrementalParseTests`**、**`STMarkdownConcurrencyStressTests`**、**`STMarkdownFootnoteAndHTMLTests`**。

---

## 6. 当前更值得做的优化

按 **收益 / 风险 / 落地成本** 排序（不必与 Vendor 逐 API 一致）。

| 优先级 | 方向 | 说明 |
|--------|------|------|
| P0 | **流式增量渲染链补强** | **【部分完成】** 已有 **`processIncremental`** + **`STMarkdownStreamBuffer`** 偏移约定；TextKit 侧已抽 **`applySetMarkdownAnimatedDiff`** 便于与「预渲染富文本」对接。**仍缺**：用合并 AST 安全替代全文 `process`（合并语义待加强）、与缓冲二合一。 |
| P0 | **流式专项测试** | **【部分完成】** 增量前缀单测 + 既有流式/缓冲测。**仍缺**：围栏、表、公式、Unicode 分块、长文多轮 append 等系统化矩阵。 |
| P1 | **TOC 产品面** | **【已完成】** `STScrollableMarkdownView` 内置侧栏、`onTOCItemTap`、`onTableOfContentsChange`；`scrollToTOCItem`；SwiftUI 流式包装透传 **`onTableOfContentsChange`**。 |
| P1 | **脚注与 citation 语义拆分** | **【已完成】** AST/管线已有脚注；UI 上 **`stmarkdown-footnote://` + `onFootnoteTap`** 与 **`onCitationTap`** 分流。 |
| P1 | **并发压测** | **【已完成】** 轻量多队列 **`process`** 冒烟（**`STMarkdownConcurrencyStressTests`**）。**仍缺**：流式 append、异步 attachment、指标化基准。 |
| P2 | **`details` / `rawHTML`** | AST / Render AST 与基础渲染已具备；后续重点应放在**交互 UI 完整度**（如折叠/展开、宿主交互）与 **raw HTML 的白名单 / 独立容器策略**，而非重复补模型。 |
| P2 | **统一容器组件** | 评估官方「滚动 + 高度 + 目录 + 链接 + citation + 流式」一体化面，对标 `ScrollableMarkdownViewTextKit` 的宿主体验。 |
| P3 | **TextKit 2** | 仅在附件布局、选区、超长文性能等**明确瓶颈**时再评估；不宜与流式增量同一迭代混谈。 |

### 6.1 若只选三件事

1. **先做流式增量链**，不先迁 TextKit 2。  
2. **TOC / footnote 单独建模**，避免继续塞进 renderer。  
3. **用压测定并发保护范围**，避免过早全局锁。

### 6.2 P0：增量语义对照（Vendor 名词 → ST 缺口）

#### 6.2.1 Vendor：`IncrementalParseResult` 在解决什么

`parseIncremental` 大致：`detectPendingStructure` → **`findSafeBreakpoint` → `safePosition`** → 从 `lastSafePosition` 向前 **`contextWindowSize`** 得 `parseStart`，对 `[parseStart, safePosition)` **parse + render** → **`newElements`**；同次可 **`extractHeadings`** → **`tocItems`**。

**`replaceCount`**：窗口向前回溯后，新尾部块可能与上一轮 UI 尾部重叠，需从元素列表尾部按个数替换，避免重复或纠错失败（Vendor 用 `estimateReplaceCount(...)` 估算）。

**`parseLock`**：串行化 cmark/swift-markdown 路径，避免多线程下扩展挂载竞态；与视图侧 `renderQueue` 等为不同层级。

#### 6.2.2 概念对照

| 概念 | Vendor | ST（当前） |
|------|--------|------------|
| 流式安全切分 | `lastSafePosition` 与 parser 协同 | **`STMarkdownStreamBuffer`** 的 **`lastSafeUpperBoundOffset`**；与 **`STMarkdownIncrementalParameters`** 对齐 |
| 解析范围 | 回溯窗口 + 子串 parse | **`processIncremental`**：`parseStart = max(0, lastCommitted - window)`，`parseEnd = currentSafeExclusiveEnd` |
| 增量产物 | `newElements` + **`replaceCount`** + `tocItems` | **`STMarkdownIncrementalParseResult`**：`replaceTailCount`、`windowRenderDocument`、`windowTableOfContents`、`mergedRenderDocument` |
| 并发 | **`parseLock`** | **`STMarkdownStructureParser`** 内 **`parseLock`** |

#### 6.2.3 落地两层

1. **缓冲层**：`STMarkdownStreamBuffer` 给出本帧可安全提交的子串（UTF-16/字符偏移，避免 `String.Index` 失效）。  
2. **渲染块层**：**`processIncremental`** 产出窗口 **`STMarkdownRenderDocument`**、**`replaceTailCount`**、**`mergedRenderDocument(previous:)`**；与 TextKit 局部替换、缓冲内置断点一体化仍为后续工作。

仅有字符串 safe 切分、无 **元素级 tail replace** 时，长文流式仍会整段重跑。

#### 6.2.4 `parseLock`

ST 已在解析路径使用 **`parseLock`**（见 §3 第 2 点、§5）。若仍有竞态，再按压测加 **actor** 或更广临界区。

#### 6.2.5 ST 已暴露的增量 API

| 类型 / 方法 | 作用 |
|-------------|------|
| **`STMarkdownIncrementalParameters`** | `canonicalMarkdown`、`lastCommittedExclusiveEnd`、`currentSafeExclusiveEnd`、`contextWindowSize`（默认 200）、`previousTotalRenderBlockCount` |
| **`STMarkdownPipeline` / `STMarkdownEngine` `processIncremental(_:)`** | 对 `[parseStart, parseEnd)` 子串跑管线（**不**跑输入 sanitizer，见参数文档） |
| **`STMarkdownIncrementalParseResult`** | `replaceTailCount`、`windowRenderDocument`、`windowTableOfContents`、`mergedRenderDocument(previous:)` |
| **`mergedRenderBlocks`** | 纯函数尾部拼接，便于单测与实验 |

**局限**：未内置 `findSafeBreakpoint` / pending 结构与缓冲二合一；宿主需把缓冲安全上界喂给 `currentSafeExclusiveEnd`。合并后 **heading `anchorId`** 若要全局唯一，需全文 **`process(_:)`** 或自建 slug。

---

### 6.3 P1：TOC、footnote

**TOC**：Vendor 把 `tocItems` 放进增量结果并提供目录视图与 tap。ST 已提供 **`scrollToTOCItem(anchorId:)`**、**`onTableOfContentsChange`**，以及 **`STScrollableMarkdownView`** 内置侧栏与 **`onTOCItemTap`**。

**脚注**：AST 已区分 **`footnoteReference` / `footnoteDefinition`**；正文中脚注引用使用 **`stmarkdown-footnote://`** 链接，**`onFootnoteTap`** 与 **`onLinkTap`** 分流；表格 **Citation** 仍仅走 **`onCitationTap`**。

---

### 6.4 P2：`<details>`、rawHTML、TextKit 2

**`details`**：模型与基础渲染已在位；若继续补强，应聚焦可折叠交互、展开态状态管理与宿主可配置 API。

**rawHTML**：当前已支持保留为 block，并按 `rawHTMLPolicy` 抑制或字面显示；若强需求，再评估白名单或 `WKWebView` 沙箱，不宜默认并入 `NSAttributedString` 主路径。

**TextKit 2**：与当前表格 Collection + overlay 是否同迁需单独架构评估。

---

## 7. 参考链接

- Vendor：<https://github.com/zjc19891106/MarkdownDisplayView.git>

---

## 8. 可后续补充的功能向维度

- **`MarkdownConfiguration`** 与 **`STMarkdownStyle` + Pipeline** 的字段级映射（配置能力对齐）。  
- **生命周期与高度通知**：Vendor 高度回调与 **`STMarkdownBaseTextView.publishContentLayoutHeightNotificationIfNeeded`** 等行为对照。  
- **无障碍**：TK2 与 `UITextView` 主路径差异。  
- **许可证**：若引入 KaTeX 字体等资源，需单独核对许可；ST 以 SwiftMath 为主。

---

*Vendor 后续若变更 API 或行为，以对方仓库为准更新本文。*
