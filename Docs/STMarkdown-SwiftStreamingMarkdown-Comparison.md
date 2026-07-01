# STMarkdown vs SwiftStreamingMarkdown — 流式 Markdown 实现对比

> 分析日期：2026-06-17
> 对比对象：`SwiftStreamingMarkdown`（Microsoft 开源，commit master）与 `STBaseProject/STMarkdown`
> 说明：本文档用于说明两套实现的关键机制、实现边界与可借鉴点。

---

## 1. 总体架构

| 维度 | SwiftStreamingMarkdown | STMarkdown |
|---|---|---|
| UI 框架 | SwiftUI，段落通过 `UIViewRepresentable` 桥接 `UITextView` | UIKit 原生 `UITextView`，另提供 SwiftUI 包装 |
| 解析引擎 | `swift-markdown` `Document(parsing:)` | `swift-markdown` `Document(parsing:)` |
| 渲染对象 | `MarkdownRenderable` -> SwiftUI View | `STMarkdownRenderBlock` -> `NSAttributedString` |
| 流式输入 | 上游每帧提供完整前缀快照 | 支持直接追加 fragment，也支持 `STMarkdownStreamBuffer` 智能缓冲 |
| 流式解析 | 每帧全量重解析 | 安全前缀提交 + 增量解析合并 |
| 推测重写 | AST 层 `MarkupPostParsingRewriter` | 可选 AST 推测重写 + 文本层尾部稳定化 |
| 字体模型 | `TextFonts` 变体包通过 attribute 传播 | `STMarkdownFontResolver` + `STMarkdownStyle` 样式字段 |
| LaTeX | 预处理为 code / attachment 渲染 | 数学占位符归一化 + LaTeX 语法降级 |
| 代码高亮 | 共享高亮实例，队列化处理 | `JavaScriptCore` + 私有串行队列 + `NSCache` |
| 流式动画 | iOS 18 `TextRenderer` 或 `ParagraphUIView` 按词淡入 | `STShimmerTextView` 按字符淡入，可切换行级 mask |
| 高度稳定 | SwiftUI proposal width + `sizeCache` + 只改 alpha | `preferredContentWidth` + TextKit 测量 + 回调防抖 + 只改 alpha |
| 视图复用 | `ParagraphUIViewCache` 复用最多 50 个闲置 `ParagraphUIView` | 由宿主持有 `STMarkdownTextView` / `STMarkdownStreamingTextView` 实例 |

STMarkdown 覆盖面更广，包含表格附件、Mermaid、脚注、HTML 降级、引用系统、代码块附件、目录锚点等能力。SwiftStreamingMarkdown 的主要借鉴价值集中在 AST 推测重写、文本 reveal 时序、测量缓存和字体变体传播模型。

---

## 2. 推测重写

### SwiftStreamingMarkdown

`MarkdownParserImpl` 解析完成后执行两个 `MarkupPostParsingRewriter`：

1. `PartialEmphasisRewriter`
   - `PartialEmphasisScanner` 查找最右侧 `Text` 或表格 cell 内最后一个非空 `Text`。
   - 末尾 Text 含未闭合 `**...` / `__...` / `*...` / `_...` 时，重写为 `Strong` 或 `Emphasis`。
   - 当 `*cool*` 前一个 Text 以单 `*` 结尾时，推测合并为 `Strong`。
2. `PartialTableRewriter`
   - `PartialTableScanner` 检查末尾 Paragraph 是否是表头候选。
   - 表头尚未形成完整 GFM table 时清空该 Paragraph，避免裸 `|` 表头行闪烁。

### STMarkdown

STMarkdown 在 `STMarkdownStructureParser` 中持有 `speculativeRewriters`，解析流程为：

```swift
let normalized = STMarkdownMathNormalizer.normalizeBlocks(in: working)
var document = Document(parsing: normalized.text)

for rewriter in speculativeRewriters {
    if let rewritten = rewriter.rewriteIfApplicable(document: document) {
        document = rewritten
    }
}

let blocks = makeBlocks(from: Array(document.children), mathMap: normalized.blockMap)
```

流式场景通过 `STMarkdownStructureParser.streamingParser()` 预配置：

- `STStreamingEmphasisRewriter`
- `STStreamingTableRewriter`

`STMarkdownStreamingTextView.beginSmartMarkdownStreaming()` 在 `streamSpeculativeRewriteEnabled == true` 时切换到 streaming parser。非流式 parser 保持默认空 rewriter，避免影响完整 Markdown 渲染语义。

### 文本层稳定化

AST 推测重写之外，STMarkdown 还有 `STMarkdownStreamingPresenter` / `STMarkdownStreamingTransforms` 处理流式尾部：

- 裁剪不完整引用标签。
- 稳定表格构造过程中的半截表头、半截数据行。
- 处理裸 list marker、裸 heading / quote marker。
- 对尾部 inline code、emphasis、CJK emphasis 边界做展示态修正。

AST 层用于保留结构语义；文本层用于避免流式中间态暴露未完成语法。

---

## 3. 字体与 Typography

### SwiftStreamingMarkdown

SST 使用 `TextFonts` 封装：

- `normal`
- `italic`
- `bold`
- `boldItalic`
- `preferredLetterSpacing`
- `preferredLineHeight`

该对象通过 `NSAttributedString.Key.typography` 进入 attribute container，嵌套 `Emphasis` / `Strong` 渲染时从父 attribute 读取当前字体上下文，再选择对应字体变体。

### STMarkdown

STMarkdown 使用 `STMarkdownStyle` 和 `STMarkdownFontResolver`：

- `font` 作为正文基础字体。
- `boldFont` 可显式指定加粗字体。
- `STMarkdownFontResolver.boldFont(from:)`、`italicFont(from:)`、`boldItalicFont(from:)` 基于 `fontDescriptor.withSymbolicTraits` 推导字体变体。
- 字体没有真实 italic / boldItalic 变体时，通过 `obliqueness` 做视觉补偿。
- `kern`、`lineHeight`、`bodyLineSpacing` 等由 `STMarkdownStyle` 统一控制。

当前 inline 渲染通过递归参数 `italic` / `bold` 组合出最终字体。SST 的 attribute container 传播模型更适合未来扩展为多字体上下文、局部 typography override 或复杂主题继承。

---

## 4. LaTeX 预处理

### SwiftStreamingMarkdown

`LaTexPreProcessorImpl` 会先把 block math 转成特殊 code block，把 inline math 包成 inline code，以降低 CommonMark 对 LaTeX 中 `[`、`*`、反引号等字符的干扰。

同时，`filteringUnsupportedSyntaxes()` 对常见不兼容命令做降级：

| 转换 | 效果 |
|---|---|
| `\boxed` | 移除命令，保留内容 |
| `\dfrac` / `\tfrac` | 降级为 `\frac` |
| `'` | 降级为 `^\prime` |
| `\overrightarrow` | 降级为 `\vec` |
| `\implies` | 降级为 `\Rightarrow` |
| `\rightleftharpoons` | 降级为 `\Leftrightarrow` |
| `\dots` | 降级为 `\ldots` |
| `\bigl` / `\Biggl` 等 | 移除尺寸命令 |

### STMarkdown

`STMarkdownMathNormalizer` 负责：

- 归一化 `\\(` / `\\[` 等转义分隔符。
- 将 block math 替换为 `{{ST_MATH_BLOCK:N}}` 占位符并保存 `blockMap`。
- 对 inline math 使用 sentinel 保护分隔符与数学内部的 Markdown 特殊字符。
- 在 block / inline math 进入渲染节点前调用 `STMarkdownLatexSyntaxNormalizer.normalize(_:)`。

`STMarkdownLatexSyntaxNormalizer` 对齐 SST 的 8 类降级转换，使下游 iosMath / KaTeX 渲染器收到更稳定的公式输入。

---

## 5. 流式逐字输出

### SwiftStreamingMarkdown

SST 的流式输入协议要求每次产出完整前缀快照：

```swift
public protocol StreamedMarkdownSource {
    var text: AsyncStream<String> { get }
}
```

`StreamedMarkdownController.start()` 对每个快照执行：

1. `parser.parse(text: config:)`
2. 主线程更新 `@Published markdownToRender`
3. SwiftUI 刷新 `DocumentView`
4. `ParagraphView.updateUIView` 更新底层 `ParagraphUIView`

主路径动画在 `ParagraphUIView.setParagraphContents` 中完成：

```swift
let newContentLength = attributedText.length - oldAttributedString.length
let newContentRange = NSRange(location: oldAttributedString.length, length: newContentLength)
let wordRanges = attributedText.splitIntoWords(withIn: newContentRange)
```

随后每个 word range 建立 `FadeAnimationData`：

- 每词 `duration = 0.5s`
- 词间延迟 `0.1 / wordCount`
- `CADisplayLink` 60fps 驱动
- 每帧只修改 `foregroundColor.alpha`

`ParagraphUIViewCache` 会缓存最多 50 个不在 `superview` / `window` 中的 `ParagraphUIView` 实例，用于降低 SwiftUI 更新中频繁创建 `UITextView` 的成本。该缓存是 view 级复用，不按 attributed string 内容建立测量结果缓存；尺寸缓存仍分别位于 `ParagraphUIView.cachedSize` 与 `ParagraphView.Coordinator.sizeCache`。

iOS 18 SwiftUI `Text` 路径还提供 `TextRenderer` 逐 glyph 渐现：

- `glyphDelay = 0.02s`
- `glyphDuration = 0.2s`
- 使用 `UnitCurve.easeOut`

### STMarkdown

STMarkdown 的流式输入有两条路径：

1. 直接追加：`appendMarkdownFragment(_:)`
   - 累加到 `rawMarkdown`
   - `setMarkdown(..., animated: true)`
   - 渲染后由 `applySetMarkdownAnimatedDiff` 做 attributed string diff
2. 智能缓冲：`beginSmartMarkdownStreaming()` + `appendSmartMarkdownStreamingChunk(_:)`
   - `STMarkdownStreamBuffer` 累积 chunk
   - 只提交 `committedSafePrefix`
   - `renderSmartStreamingDisplayMarkdown` 在前缀单调增长时走 `engine.processIncremental`

动画由 `STShimmerTextView` 执行：

- `_baseAttributedText` 保存最终全不透明 attributed string。
- 新增内容先以 `foregroundColor.alpha = 0` 插入 `textStorage`。
- `appendStaggeredTokens` 记录 range、targetColor、startTime、staggerInterval。
- `handleDisplayLink` 每帧按字符更新 alpha。
- `characterStaggerInterval = 0.016s`，`tokenFadeDuration` 默认 0.3s。
- `lineFadeMode` 可切换为 `CAGradientLayer` 水平扫入 mask。

`STShimmerTextView` 位于 `Sources/STUIKit/STTextView`，STMarkdown 通过 `STMarkdownStreamingTextView` 组合使用它。字符级 fade 会跳过 attachment 与 `STShimmerTextView.skipFadeIn` 标记的片段；行级 fade 使用 `CAGradientLayer` mask，并在 iOS 16+ 优先走 TextKit 2 的 `NSTextLayoutManager` 获取行 rect，低版本回退 TextKit 1。

### 参数对照

| 参数 | SST `ParagraphUIView` | STMarkdown `STShimmerTextView` |
|---|---|---|
| 默认粒度 | word / 分隔符 range | character |
| 每单位时长 | 0.5s | `tokenFadeDuration` 默认 0.3s |
| stagger | `0.1 / wordCount` | `characterStaggerInterval = 0.016s` |
| easing | cubic Bezier `(0.1, 1.0)` | `1 - (1 - t)^3` |
| 驱动 | `CADisplayLink` | `CADisplayLink` |
| 动画属性 | `foregroundColor.alpha` | `foregroundColor.alpha` 或 mask |
| 最终态缓存 | `paragraphContents` | `_baseAttributedText` |

---

## 6. 高度稳定

### SwiftStreamingMarkdown

SST 的高度稳定由以下机制组合完成：

1. `ParagraphUIView.intrinsicContentSize`
   - 使用当前 `bounds.width` 调用 `sizeThatFits`。
   - `bounds.width` 不可用时 fallback 到屏幕宽度。
   - 宽度变化时清空内部 `cachedSize`。
2. `ParagraphView.sizeThatFits`
   - 使用 SwiftUI proposal width。
   - `Coordinator.sizeCache` 按 width 缓存 `CGSize`。
   - width 四舍五入到 0.1pt，减少浮点误差造成的 cache miss。
   - 内容或 `lineSpacing` 变化时清空 cache。
3. SwiftUI 布局
   - 段落使用 `.fixedSize(horizontal: false, vertical: true)`。
   - 垂直方向依赖 UIKit 测量结果自适应。
4. 动画策略
   - reveal 只改颜色 alpha，不改文本、字体、段落样式或 attachment bounds。
   - `finishAnimationsBeforeLastNewline()` 在跨行时让最后一个换行前的内容立即全不透明。

### STMarkdown

STMarkdown 的高度稳定由 UIKit 测量、宽度契约和回调防抖组成：

1. `STMarkdownBaseTextView.intrinsicContentSize`
   - 使用 `resolvedMarkdownMeasurementWidth()` 得到测量宽度。
   - `sizeThatFits` 后进入 `resolvedTextViewContentHeight(...)`。
2. 宽度来源优先级
   - `preferredContentWidth`
   - `bounds.width`
   - `textView.bounds.width`
   - `textView.frame.width`
   - `window?.bounds.width`
   - `UIScreen.main.bounds.width`
3. 首帧高度兜底
   - 已有 attributedText 但 `sizeThatFits` 读到 0 时，回退 `contentSize.height`。
   - 仍为 0 时再回退 `textView.bounds.height`。
4. 测量工具
   - 默认 `intrinsicContentSize` 使用 `UITextView.sizeThatFits`，并在首帧 0 高度时回退 `contentSize.height` / `bounds.height`。
   - `STMarkdownTextViewMeasure.measure` 是独立 TextKit 1 测量工具，可由外部在需要固定网格高度时调用。
   - 该工具使用 `layoutManager.usedRect(for:)` 得到内容高度，并按 `gridSize` 向上取整，默认 2pt，用于减轻亚像素抖动。
5. 高度通知
   - `onContentLayoutHeightChange` 由 `publishContentLayoutHeightNotificationIfNeeded` 触发。
   - `contentLayoutHeightNotificationThreshold` 默认 9pt。
   - `contentLayoutHeightNotificationMinInterval` 可限制通知频率。
   - `suppressTransientZeroContentLayoutHeightNotification` 避免有内容时发布瞬时 0 高度。
6. 动画策略
   - 默认字符级 reveal 只改 `foregroundColor.alpha`。
   - 追加和替换内容时保存并恢复 `contentOffset`。
   - `animateAcrossNewlines == false` 时只保留最后一行动画。

### 对照

| 维度 | SwiftStreamingMarkdown | STMarkdown |
|---|---|---|
| 显式测量缓存 | `ParagraphUIView.cachedSize` + `ParagraphView.Coordinator.sizeCache` | 主要依赖 TextKit 缓存；可通过 `STMarkdownTextViewMeasure` 做外部测量 |
| 宽度来源 | SwiftUI proposal width | `preferredContentWidth` 优先，随后 fallback 到视图/屏幕宽度 |
| 高度粒度 | `ceil(height)` | 默认 `ceil(height)`；外部测量工具可按 `gridSize` 向上取整 |
| 跨行 reveal | 换行前内容立即完成动画 | `finishAnimationsBeforeLastNewline()` 同类策略 |
| 宿主通知 | SwiftUI layout 自动驱动 | `onContentLayoutHeightChange` + threshold / minInterval |

自适应高度 cell 使用 STMarkdown 时，建议由宿主设置 `preferredContentWidth`，让首帧测量宽度与最终 cell 宽度一致。

---

## 7. 代码高亮

### SwiftStreamingMarkdown

SST 的高亮任务通过 manager 聚合：

- 共享高亮实例。
- 保留 latest code。
- 避免并发创建多个高亮上下文。
- 串行处理高亮任务。

### STMarkdown

`STMarkdownCodeHighlighter` 使用：

- `JavaScriptCore`
- 单个 `JSVirtualMachine`
- 单个 `JSContext`
- 私有串行队列 `jsQueue`
- `NSCache<NSString, NSAttributedString>`，`totalCostLimit = 10MB`
- `NSLock` 保护缓存读写

该模型与 SST 的核心目标一致：复用 JS 上下文，串行访问高亮引擎，用缓存吸收重复代码块渲染。

---

## 8. 测量缓存扩展方向

SST 在 SwiftUI bridge 层直接按 proposal width 缓存 `CGSize`。STMarkdown 可以在 UIKit 层按以下维度扩展测量缓存：

- attributed text 版本或内容 hash
- width，建议 round 到 0.5pt 或 1pt
- textContainerInset
- font / Dynamic Type trait
- 影响 attachment bounds 的渲染配置

缓存适合放在 `STMarkdownBaseTextView` 或 `STMarkdownTextViewMeasure` 上层调用方中。对带异步 attachment 的内容，attachment 刷新后需要使对应缓存失效。
