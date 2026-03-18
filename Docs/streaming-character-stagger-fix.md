# 流式渲染中间段落"成段输出"问题分析与修复

## 问题现象

深度思考（Think）流式输出时，**中间段落**会出现停顿，然后整段文字一次性渲染出来（所有字符同时从透明 fade-in 到不透明），之后又恢复正常的逐字输出效果。

用户感知：打字机效果中断 → 停顿 → 一整段文字突然"闪现" → 恢复逐字输出。

## 根因分析

### 直接原因

`STShimmerTextView.appendAttributedText` 将每次调用传入的 **整个 delta** 创建为 **一个 `AnimatingToken`**。`AnimatingToken` 内的所有字符共享同一个 `startTime`，在 `handleDisplayLink` 中同时从 alpha=0 fade-in 到 alpha=1。

当 delta 只有 1-2 个字符时，表现正常（逐字出现）。但当 delta 累积到 10+ 个字符时，所有字符同时淡入，视觉上就是"成段输出"。

### delta 累积的三个来源

#### 1. 双重异步派发导致 SSE chunks 累积

数据流经过两次 `DispatchQueue.main.async` 派发：

```
SSE chunk → ChatStreamHandler
  → ChatStreamIsolationCoordinator.prepareAndCommit (background queue → main.async)  ← 第1次
    → ChatViewModel.applyPreparedStreamMessageMutation
      → emitRenderRefresh(.streamingMessage) (main.async)  ← 第2次
        → UI 更新
```

两次 RunLoop 切换期间，后续 SSE chunks 持续到达但无法立即渲染，导致多个 chunks 在 main queue 上被合并为一个大 delta。

#### 2. Markdown 预处理裁剪与恢复

`NativeMarkdownView.trimIncompleteTrailingMarkdownSyntax` 会裁剪不完整的 Markdown 尾部语法（如 `[链接文字`、`## `、`` ``` ``、`**加粗`）。当下一个 SSE chunk 补全了语法时，之前被裁剪的内容 + 新内容一起作为大 delta 出现。

例如：
- 帧 1: 收到 `这是一个[链接` → 裁剪为 `这是一个` → 渲染 `这是一个`
- 帧 2: 收到 `这是一个[链接](url) 后续文字` → delta = `[链接](url) 后续文字`（10+ 字符）

#### 3. 属性前缀匹配失败导致无动画替换

`STMarkdownStreamingTextView.tryAppendRenderedDelta` 有三级 fallback：

1. **精确属性前缀匹配** (`hasStableAttributedPrefix`) — 走追加动画路径
2. **字符串前缀匹配** (`string hasPrefix`) — 仍走追加动画路径（容忍 paragraphStyle 差异）
3. **最长公共属性前缀** (`longestCommonAttributedPrefixLength`) — 走 `replaceTrailingAttributedText`（**完全无动画，瞬间替换**）

当 Markdown 渲染器因新段落出现而回溯修改前缀的 `NSParagraphStyle`（如 `paragraphSpacingAfter`）时，可能触发第 3 级 fallback，导致内容瞬间替换而非逐字淡入。

## 修复方案

### 修改文件

`STBaseProject/Sources/STAnimation/STShimmerAnimation/STShimmerTextView.swift`

### 具体改动

#### 1. 新增 `characterStaggerInterval` 属性

```swift
/// 逐字 stagger 间隔：每个字符的 fade-in 起始时间比前一个字符延迟此值，
/// 使多字符 delta 呈现"逐字出现"而非"整段同时出现"的效果。
/// 设为 0 则禁用 stagger（所有字符同时 fade-in）。
public var characterStaggerInterval: TimeInterval = 0.016
```

默认值 `0.016s` ≈ 1 帧 @60fps，每帧出现一个字符。

#### 2. 新增 `appendStaggeredTokens(for:)` 私有方法

将原来"一个 delta → 一个 AnimatingToken"的逻辑改为"一个 delta → N 个 AnimatingToken（每字符一个）"：

```swift
private func appendStaggeredTokens(for colorRuns: [AnimatingColorRun]) {
    guard !colorRuns.isEmpty else { return }
    let stagger = self.characterStaggerInterval
    let totalLength = colorRuns.reduce(0) { $0 + $1.range.length }

    // 字符数 ≤ 2 或 stagger 为 0 时，保持原有单 token 行为
    if stagger <= 0 || totalLength <= 2 {
        // ... 创建单个 AnimatingToken ...
        return
    }

    // 逐字符拆分，每个字符的 startTime 递增 stagger
    let baseTime = CACurrentMediaTime()
    var charIndex = 0
    for run in colorRuns {
        for offset in 0..<run.range.length {
            let loc = run.range.location + offset
            let charRun = AnimatingColorRun(
                range: NSRange(location: loc, length: 1),
                targetColor: run.targetColor
            )
            let token = AnimatingToken(
                range: NSRange(location: loc, length: 1),
                startTime: baseTime + Double(charIndex) * stagger,
                colorRuns: [charRun]
            )
            self.animatingTokens.append(token)
            charIndex += 1
        }
    }
}
```

#### 3. 替换 `appendAttributedText` 中的 token 创建逻辑

将两处直接创建 `AnimatingToken` 的代码替换为 `appendStaggeredTokens` 调用：

- **含换行符路径**（trailing runs）：最后一个 `\n` 之后的尾部内容
- **无换行符路径**：全量 colorRuns

### 设计要点

- **不影响布局**：文本已经一次性 append 到 `textStorage`（alpha=0）并完成布局。stagger 仅影响 `AnimatingToken.startTime`，不会引起任何布局变化、跳动或闪烁。
- **向后兼容**：`characterStaggerInterval = 0` 时退化为原有行为；字符数 ≤ 2 时也不拆分。
- **不修改上游**：不改动 `ChatStreamHandler`、`ChatStreamIsolationCoordinator`、`NativeMarkdownView` 等上游组件。修复在最终渲染层完成，对上游 delta 大小的波动具有鲁棒性。
- **不修改 `replaceTrailingAttributedText`**：该路径设计为无动画瞬间替换，用于 Markdown 属性重解析场景，保持不变。

## 数据流全景

```
Server SSE
  ↓
ChatStreamHandler (throttle: minNotifyCharDelta=1, maxNotifyInterval=0.03s)
  ↓
ChatStreamIsolationCoordinator (background queue → main.async)     ← 第1次异步
  ↓
ChatViewModel.applyPreparedStreamMessageMutation
  ↓
emitRenderRefresh(.streamingMessage) (main.async)                   ← 第2次异步
  ↓
NewHomeViewController → MainContentViewCollection.updateStreamingMessage
  ↓
ChatAIMessageCollectionCell.updateStreamingMessageDirectly
  ↓
AIMessageView.renderStreamingBodyContent
  ↓
ChatThinkViewUIKit.updateMessageDirectly → updateMarkdownView
  ↓
NativeMarkdownView.updateStreamingContent
  ├── trimIncompleteTrailingMarkdownSyntax (裁剪不完整语法)
  └── streamingRenderView.updateStreamingMarkdown(fullMarkdown)
        ↓
STMarkdownStreamingTextView.setMarkdown(animated: true)
  ├── tryAppendRenderedDelta (三级 fallback)
  │   ├── 精确属性前缀匹配 → appendRenderedDelta → appendAttributedText
  │   ├── 字符串前缀匹配   → appendRenderedDelta → appendAttributedText
  │   └── 最长公共前缀     → replaceTrailingAttributedText (无动画)
  └── appendAttributedText
        ↓
STShimmerTextView.appendAttributedText
  ├── finishAnimationsBeforeLastNewline (完成前一行动画)
  ├── textStorage.append (alpha=0, 布局完成)
  └── appendStaggeredTokens ← [修复点] 逐字符创建 AnimatingToken
        ↓
handleDisplayLink (CADisplayLink @60fps)
  └── 每帧检查每个 token: elapsed = now - token.startTime
      → alpha = min(1, elapsed / tokenFadeDuration)
      → 逐字符渐显
```
