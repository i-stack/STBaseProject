//
//  STMarkdownStreamingTextView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public final class STMarkdownStreamingTextView: STMarkdownBaseTextView {

    public var tokenFadeDuration: TimeInterval {
        get { self.shimmerTextView.tokenFadeDuration }
        set { self.shimmerTextView.tokenFadeDuration = newValue }
    }

    public var customDocumentRenderer: ((STMarkdownRenderDocument) -> NSAttributedString)?

    public var suppressSystemTextMenu: Bool {
        get { self.shimmerTextView.suppressSystemTextMenu }
        set { self.shimmerTextView.suppressSystemTextMenu = newValue }
    }

    public var animateAcrossNewlines: Bool {
        get { self.shimmerTextView.animateAcrossNewlines }
        set { self.shimmerTextView.animateAcrossNewlines = newValue }
    }

    private var shimmerTextView: STShimmerTextView {
        guard let textView = self.textView as? STShimmerTextView else {
            preconditionFailure("STMarkdownStreamingTextView requires STShimmerTextView")
        }
        return textView
    }

    public override var attributedText: NSAttributedString {
        self.shimmerTextView.renderedAttributedText
    }

    internal override var currentAttributedText: NSAttributedString {
        self.shimmerTextView.renderedAttributedText
    }

    public init(frame: CGRect) {
        super.init(
            textView: STShimmerTextView(usingTextLayoutManager: false),
            frame: frame,
            style: .default,
            advancedRenderers: .empty,
            engine: STMarkdownEngine(),
            accessibilityTraits: [.staticText, .updatesFrequently]
        )
    }

    public convenience init(
        style: STMarkdownStyle = .default,
        advancedRenderers: STMarkdownAdvancedRenderers = .empty,
        engine: STMarkdownEngine = STMarkdownEngine()
    ) {
        self.init(frame: .zero)
        self.applyConfigurationCommon(
            style: style,
            advancedRenderers: advancedRenderers,
            engine: engine
        )
    }

    public required init?(coder: NSCoder) {
        super.init(
            textView: STShimmerTextView(usingTextLayoutManager: false),
            coder: coder,
            style: .default,
            advancedRenderers: .empty,
            engine: STMarkdownEngine(),
            accessibilityTraits: [.staticText, .updatesFrequently]
        )
    }

    public func reset() {
        self.shimmerTextView.reset()
        self.resetBaseState()
    }

    public func finishStreaming() {
        self.shimmerTextView.finishAnimations()
    }

    public func setMarkdown(_ markdown: String, animated: Bool = false) {
        let markdownForRender = animated
            ? Self.stripUnclosedTailMarkers(in: markdown)
            : markdown
        let displayRendered = self.render(markdownForRender)
        guard animated, !self.rawMarkdown.isEmpty else {
            self.applyFullReplace(markdown: markdown, rendered: displayRendered)
            return
        }

        let current = self.shimmerTextView.renderedAttributedText
        let currentStr = current.string
        let renderedStr = displayRendered.string

        if renderedStr.count >= currentStr.count,
           (renderedStr as NSString).hasPrefix(currentStr) {
            let prefixChanged = current.length > 0
                && !displayRendered.attributedSubstring(
                    from: NSRange(location: 0, length: current.length)
                ).isEqual(to: current)
            if prefixChanged {
                self.applyFullReplace(markdown: markdown, rendered: displayRendered)
                return
            }
            let deltaLen = displayRendered.length - current.length
            if deltaLen > 0 {
                let delta = displayRendered.attributedSubstring(
                    from: NSRange(location: current.length, length: deltaLen)
                )
                self.applyAppendDelta(markdown: markdown, delta: delta)
            } else {
                self.rawMarkdown = markdown
                self.textView.accessibilityValue = self.shimmerTextView.renderedAttributedText.string
            }
            return
        }

        let commonLen = currentStr.commonPrefix(with: renderedStr).utf16.count
        if commonLen > 0 {
            let commonPrefixChanged = !current.attributedSubstring(
                from: NSRange(location: 0, length: commonLen)
            ).isEqual(to: displayRendered.attributedSubstring(
                from: NSRange(location: 0, length: commonLen)
            ))
            let listMarkerInvolved = self.shouldDisableAnimationForTrailingReplacement(
                current: current,
                rendered: displayRendered,
                commonLength: commonLen
            )
            if commonPrefixChanged {
                self.applyFullReplace(markdown: markdown, rendered: displayRendered)
            } else if listMarkerInvolved {
                let replaceStart = self.replacementStartForListTransition(
                    currentString: currentStr,
                    commonLength: commonLen
                )
                let trailing = displayRendered.attributedSubstring(
                    from: NSRange(location: replaceStart, length: displayRendered.length - replaceStart)
                )
                self.applyTrailingReplace(
                    markdown: markdown,
                    from: replaceStart,
                    trailing: trailing,
                    animate: false
                )
            } else {
                let trailing = displayRendered.attributedSubstring(
                    from: NSRange(location: commonLen, length: displayRendered.length - commonLen)
                )
                self.applyTrailingReplace(
                    markdown: markdown,
                    from: commonLen,
                    trailing: trailing,
                    animate: true
                )
            }
            return
        }

        self.applyFullReplace(markdown: markdown, rendered: displayRendered)
    }

    public func applyConfiguration(
        markdown: String,
        style: STMarkdownStyle,
        advancedRenderers: STMarkdownAdvancedRenderers,
        engine: STMarkdownEngine,
        animated: Bool
    ) {
        self.applyConfigurationCommon(
            style: style,
            advancedRenderers: advancedRenderers,
            engine: engine
        )
        self.setMarkdown(markdown, animated: animated)
    }

    public func appendMarkdownFragment(_ fragment: String, animated: Bool = true) {
        guard fragment.isEmpty == false else { return }
        self.setMarkdown(self.rawMarkdown + fragment, animated: animated)
    }

    public func updateStreamingMarkdown(_ fullMarkdown: String) {
        self.setMarkdown(fullMarkdown, animated: true)
    }

    internal override func configurationDidChangeRerender() {
        self.setMarkdown(self.rawMarkdown, animated: false)
    }

    private func applyFullReplace(markdown: String, rendered: NSAttributedString) {
        self.rawMarkdown = markdown
        self.shimmerTextView.setRenderedAttributedText(rendered)
        self.finalizeRenderUpdate(rendered: rendered)
    }

    private func applyAppendDelta(markdown: String, delta: NSAttributedString) {
        self.rawMarkdown = markdown
        self.shimmerTextView.appendAttributedText(delta, animated: true)
        self.finalizeRenderUpdate(rendered: self.shimmerTextView.renderedAttributedText)
    }

    private func applyTrailingReplace(
        markdown: String,
        from location: Int,
        trailing: NSAttributedString,
        animate: Bool
    ) {
        self.rawMarkdown = markdown
        self.shimmerTextView.replaceTrailingAttributedText(
            from: location,
            with: trailing,
            animateNewPortion: animate
        )
        self.finalizeRenderUpdate(rendered: self.shimmerTextView.renderedAttributedText)
    }

    private func render(_ markdown: String) -> NSAttributedString {
        let result = self.engine.process(markdown)
        if let customRenderer = self.customDocumentRenderer {
            return customRenderer(result.renderDocument)
        }
        return self.renderer.render(document: result.renderDocument)
    }

    /// 流式期间，若源 markdown 尾部存在**尚未闭合**的 delimiter token（例如只打了
    /// 开头的 `**`、`~~`、`$$`、` ``` `、`\(`，或 task list 的前缀 `- [ ]`），直接把
    /// 它们丢给渲染引擎会导致字面字符抖动。历史版本对最终 `NSAttributedString`
    /// 做全局字符串删除，会把代码块里展示的 `$$`、`**`，inline code 里的 `` ` ``，
    /// 以及正文里字面 `- [ ]` 等**合法内容**一起吞掉。
    ///
    /// 这里改为只裁剪源 markdown 的**尾部未闭合片段**，完全不触碰已渲染的正文：
    /// 1. 保留所有已完整闭合的代码块、公式块、inline 标记；
    /// 2. 若最末尾处于一个 fenced code block 未闭合（奇数个 ```），则删掉末尾那组 ```
    ///    所在行及之后的流式片段；
    /// 3. 只对最末一行做未闭合 inline delimiter（`**` / `__` / `~~` / `\(`）
    ///    的 opening marker 裁剪，且通过**成对计数**判定，不会误伤已闭合对；
    /// 4. task list 前缀 `- [ ]` / `- [x]` 仅当该行只有前缀、尚无实际文字时才暂时隐藏。
    private static func stripUnclosedTailMarkers(in markdown: String) -> String {
        guard markdown.isEmpty == false else { return markdown }

        var working = Self.stripUnclosedFencedCodeTail(in: markdown)
        working = Self.stripUnclosedDollarMathBlockTail(in: working)
        working = Self.stripUnclosedInlineTailMarkers(in: working)
        working = Self.stripBareTaskListPrefix(in: working)
        return working
    }

    /// 若源字符串包含奇数个 ``` fence，则截断到最后一个 fence 之前（保留其前的换行），
    /// 这样最后那个 "打开但未闭合" 的代码块在流式期间暂时不显示，等到下一帧闭合后再一起渲染。
    private static func stripUnclosedFencedCodeTail(in markdown: String) -> String {
        let ns = markdown as NSString
        let fenceMatches = Self.fencedCodeRegex.matches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: ns.length)
        )
        guard fenceMatches.count % 2 == 1, let last = fenceMatches.last else {
            return markdown
        }
        // 截到最后一个未闭合 fence 所在行的起点；找不到就截到 fence 之前。
        let lastLineStart: Int
        let prefixRange = NSRange(location: 0, length: last.range.location)
        let prefix = ns.substring(with: prefixRange) as NSString
        let newline = prefix.range(of: "\n", options: .backwards)
        lastLineStart = newline.location == NSNotFound ? 0 : newline.location + newline.length
        return ns.substring(to: lastLineStart)
    }

    /// 若源字符串包含奇数个 `$$`，说明末尾存在未闭合块公式。
    /// 流式阶段先隐藏从打开 `$$` 所在行起的尾段，避免 `$$` 或公式体以普通文本闪烁。
    private static func stripUnclosedDollarMathBlockTail(in markdown: String) -> String {
        let ns = markdown as NSString
        let matches = Self.dollarMathFenceRegex.matches(
            in: markdown,
            options: [],
            range: NSRange(location: 0, length: ns.length)
        )
        guard matches.count % 2 == 1, let last = matches.last else {
            return markdown
        }

        let prefix = ns.substring(to: last.range.location) as NSString
        let newline = prefix.range(of: "\n", options: .backwards)
        let lastLineStart = newline.location == NSNotFound ? 0 : newline.location + newline.length
        return ns.substring(to: lastLineStart)
    }

    /// 只处理最末一行的未闭合 inline delimiter：成对数量为奇数时裁剪最后一个 opening marker。
    /// 这样 "文本里已经成对闭合" 的 `**foo**` 不会被动到，代码块内已完整闭合的 token 也不会被动到。
    private static func stripUnclosedInlineTailMarkers(in markdown: String) -> String {
        let ns = markdown as NSString
        let newline = ns.range(of: "\n", options: .backwards)
        let lastLineStart = newline.location == NSNotFound ? 0 : newline.location + newline.length
        let lastLine = ns.substring(from: lastLineStart)
        guard lastLine.isEmpty == false else { return markdown }

        var trimmed = lastLine
        // 按“从长到短 / 从强到弱”的顺序，避免 `**` 被当成两个 `*`。
        for token in Self.inlinePairableTokens {
            trimmed = Self.trimUnclosedInlineToken(token, in: trimmed)
        }
        // `\(` 单独处理：无配对 `\)` 时，先隐藏 opening marker，保留已到达的公式体文本。
        trimmed = Self.trimUnclosedMathOpen(in: trimmed)

        if trimmed == lastLine {
            return markdown
        }
        let prefix = ns.substring(to: lastLineStart)
        return prefix + trimmed
    }

    /// 若该行 `token` 数量为奇数，说明最后一个 token 是未闭合 opener；
    /// 去掉 opener 本身但保留其后的流式正文，避免显示原始 Markdown 定界符。
    private static func trimUnclosedInlineToken(_ token: String, in line: String) -> String {
        let count = line.components(separatedBy: token).count - 1
        guard count % 2 == 1 else { return line }

        guard let range = line.range(of: token, options: .backwards) else {
            return line
        }
        var result = line
        result.removeSubrange(range)
        return result
    }

    private static func trimUnclosedMathOpen(in line: String) -> String {
        // `\(` 与 `\)` 成对；未闭合时移除最后一个 opening marker，
        // 避免流式中间态把 `\(` 直接暴露给用户。
        let opens = line.components(separatedBy: #"\("#).count - 1
        let closes = line.components(separatedBy: #"\)"#).count - 1
        guard opens > closes else { return line }

        guard let range = line.range(of: #"\("#, options: .backwards) else {
            return line
        }
        var result = line
        result.removeSubrange(range)
        return result
    }

    /// 末行仅为 task list 前缀（`- [ ] ` / `- [x] `）且无后续文字时，暂时隐藏，
    /// 避免流式过程中 "- [ ]" 字面字符闪一下。已包含任何可见文字则保留，
    /// 这样用户/模型想展示字面 `- [ ]` 也不会被吞。
    private static func stripBareTaskListPrefix(in markdown: String) -> String {
        let ns = markdown as NSString
        let newline = ns.range(of: "\n", options: .backwards)
        let lastLineStart = newline.location == NSNotFound ? 0 : newline.location + newline.length
        let lastLine = ns.substring(from: lastLineStart)
        let lineRange = NSRange(location: 0, length: (lastLine as NSString).length)
        guard Self.bareTaskPrefixRegex.firstMatch(in: lastLine, options: [], range: lineRange) != nil else {
            return markdown
        }
        return ns.substring(to: lastLineStart)
    }

    private static let fencedCodeRegex: NSRegularExpression = {
        // 行首（允许前置空白）出现至少三个反引号的 fence 标记。
        return try! NSRegularExpression(pattern: #"(?m)^[ \t]*`{3,}"#, options: [])
    }()

    private static let dollarMathFenceRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: #"\$\$"#, options: [])
    }()

    private static let bareTaskPrefixRegex: NSRegularExpression = {
        // 行首为 task list 前缀但没有任何可见正文。
        return try! NSRegularExpression(
            pattern: #"^[ \t]*[-*+][ \t]+\[[ xX]\][ \t]*$"#,
            options: []
        )
    }()

    private static let inlinePairableTokens: [String] = [
        "```",
        "**",
        "__",
        "~~"
    ]

    private func shouldDisableAnimationForTrailingReplacement(
        current: NSAttributedString,
        rendered: NSAttributedString,
        commonLength: Int
    ) -> Bool {
        let currentSuffix = current.length > commonLength
            ? current.attributedSubstring(
                from: NSRange(location: commonLength, length: current.length - commonLength)
            ).string
            : ""
        let renderedSuffix = rendered.length > commonLength
            ? rendered.attributedSubstring(
                from: NSRange(location: commonLength, length: rendered.length - commonLength)
            ).string
            : ""

        return Self.containsRenderedListMarker(in: currentSuffix)
            || Self.containsRenderedListMarker(in: renderedSuffix)
    }

    private func replacementStartForListTransition(currentString: String, commonLength: Int) -> Int {
        guard commonLength > 0 else { return 0 }
        let prefix = (currentString as NSString).substring(to: commonLength) as NSString
        let lastNewline = prefix.range(of: "\n", options: .backwards)
        guard lastNewline.location != NSNotFound else { return 0 }
        return lastNewline.location + lastNewline.length
    }

    private static func containsRenderedListMarker(in text: String) -> Bool {
        guard text.isEmpty == false else { return false }
        let range = NSRange(location: 0, length: text.utf16.count)
        return Self.unorderedListMarkerRegex.firstMatch(in: text, options: [], range: range) != nil
            || Self.orderedListMarkerRegex.firstMatch(in: text, options: [], range: range) != nil
    }

    private static let orderedListMarkerRegex = try! NSRegularExpression(
        pattern: #"(?m)^\t*\d+\.\t"#,
        options: []
    )

    private static let unorderedListMarkerRegex = try! NSRegularExpression(
        pattern: #"(?m)(?:^|\n)\t*[●▪]\t"#,
        options: []
    )
}
