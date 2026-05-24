//
//  STMarkdownRegexPatterns.swift
//  STBaseProject
//
//  集中存放 STMarkdown 框架内所有业务正则，补充 STMarkdownRule.swift 中
//  STMarkdownRegex 已有的基础条目（HTML 链接、JSON 转义换行）。
//
//  分组：
//    - STMarkdownListRegex        列表结构匹配
//    - STMarkdownMathRegex        数学/LaTeX 处理
//    - STMarkdownCitationRegex    Citation / Webpage 标签识别与提取
//    - STMarkdownStreamingRegex   流式输出尾部标记裁剪
//    - STMarkdownHTMLCleanRegex   HTML 标签/注释清理
//

import Foundation

// MARK: - 列表

public enum STMarkdownListRegex {
    /// `1. text` / `1.text` → 补空格（多行模式）
    public static let numberList = STMarkdownRegexFactory.compile(
        pattern: #"(?m)^(\s*\d+\.)\s*(\S)"#,
        owner: "STMarkdownListRegex.numberList"
    )
    /// `- text` / `+ text`（非 `--`/`++`）→ 补空格（多行模式）
    public static let symbolList = STMarkdownRegexFactory.compile(
        pattern: #"(?m)^(\s*[-+])(?![-+])\s*(\S)"#,
        owner: "STMarkdownListRegex.symbolList"
    )
    /// `* text`（非 `**`）→ 补空格（多行模式）
    public static let starList = STMarkdownRegexFactory.compile(
        pattern: #"(?m)^(\s*)\*(?!\*)\s*(\S)"#,
        owner: "STMarkdownListRegex.starList"
    )
    /// 有序列表行（0-3 空格缩进，marker 后有内容）
    public static let orderedListLine = STMarkdownRegexFactory.compile(
        pattern: #"^\s{0,3}\d+\.\s+\S"#,
        owner: "STMarkdownListRegex.orderedListLine"
    )
    /// 受保护的 4+ 空格缩进块（列表嵌套 / 代码段 / 引用等不应 dedent）
    public static let protectedIndentedBlock = STMarkdownRegexFactory.compile(
        pattern: #"^\s{4,}(?:[-+*]|\d+\.|>|```|~~~|\|)"#,
        owner: "STMarkdownListRegex.protectedIndentedBlock"
    )
    /// 顶层无序列表行（0-3 空格缩进）
    public static let topLevelUnorderedListLine = STMarkdownRegexFactory.compile(
        pattern: #"^\s{0,3}[-+*]\s+\S"#,
        owner: "STMarkdownListRegex.topLevelUnorderedListLine"
    )
    /// 缩进 3+ 空格的无序列表行（嵌套子列表）
    public static let indentedUnorderedListLine = STMarkdownRegexFactory.compile(
        pattern: #"^\s{3,}[-+*]\s+\S"#,
        owner: "STMarkdownListRegex.indentedUnorderedListLine"
    )
}

// MARK: - 数学 / LaTeX

public enum STMarkdownMathRegex {
    /// `[expr]` 形式的内联数学（要求含 `=`、`+`、`_`、`^`、`\` 等数学符号，避免误伤链接）
    public static let mathInline = STMarkdownRegexFactory.compile(
        pattern: #"\[(?=[^\]]*[=+_^\\])([^\]]+)\]"#,
        owner: "STMarkdownMathRegex.mathInline"
    )
    /// 反引号包裹的内联代码段（非连续反引号）
    public static let inlineCodeSpan = STMarkdownRegexFactory.compile(
        pattern: #"(?<!`)`([^`\n]+)`(?!`)"#,
        owner: "STMarkdownMathRegex.inlineCodeSpan"
    )
    /// `VAR_name = ...` 形式的普通数学赋值表达式
    public static let plainMathFormula = STMarkdownRegexFactory.compile(
        pattern: #"(?<![$`\\])([A-Za-z]+_[A-Za-z0-9]+\s*=\s*(?:\\frac\{[^}]+\}\{[^}]+\}|[A-Za-z0-9_()+\-\*/\\\s]+))"#,
        owner: "STMarkdownMathRegex.plainMathFormula"
    )
    /// `a/b` 形式的简单分式（非 `\frac{` 前缀）
    public static let simpleMathFraction = STMarkdownRegexFactory.compile(
        pattern: #"(?<!\\frac\{)\b([A-Za-z0-9_]+)\s*/\s*([A-Za-z0-9_]+)\b"#,
        owner: "STMarkdownMathRegex.simpleMathFraction"
    )
    /// `\S * \S` 形式的乘法运算符（两侧需有非空白字符）
    public static let mathMultiply = STMarkdownRegexFactory.compile(
        pattern: #"(?<=\S)\s*\*\s*(?=\S)"#,
        owner: "STMarkdownMathRegex.mathMultiply"
    )
    /// `\frac{...}{...}` LaTeX 分式
    public static let latexFraction = STMarkdownRegexFactory.compile(
        pattern: #"\\frac\{([^{}]+)\}\{([^{}]+)\}"#,
        owner: "STMarkdownMathRegex.latexFraction"
    )
    /// `\\` 后跟字母/括号的重复反斜线（JSON 序列化残留）
    public static let duplicatedLatexBackslash = STMarkdownRegexFactory.compile(
        pattern: #"\\\\(?=[A-Za-z()\[\]])"#,
        owner: "STMarkdownMathRegex.duplicatedLatexBackslash"
    )
    /// `$...$` 形式的内联 Dollar 数学（不匹配已转义 `\$`）
    public static let inlineDollarMath = STMarkdownRegexFactory.compile(
        pattern: #"(?<!\\)\$(.+?)(?<!\\)\$"#,
        owner: "STMarkdownMathRegex.inlineDollarMath"
    )
    /// `（URL）` → 全角括号包裹的裸链接
    public static let bracketLink = STMarkdownRegexFactory.compile(
        pattern: "（(https?://[^）]+)）",
        owner: "STMarkdownMathRegex.bracketLink"
    )
}

// MARK: - CJK 强调边界

public enum STMarkdownCJKRegex {
    /// 全角/中文**关闭**标点后紧跟 `*`：用于补 ZWNJ 使 right-flanking delimiter 生效
    public static let cjkEmphasisBoundary = STMarkdownRegexFactory.compile(
        pattern: "([）】」』》\u{201D}\u{2019}，。！？；：…—])(?=\\*)",
        owner: "STMarkdownCJKRegex.cjkEmphasisBoundary"
    )
    /// `*+` 后紧跟全角/中文**开放**标点：用于补 ZWNJ 使 left-flanking delimiter 生效
    public static let cjkOpenQuoteAfterEmphasis = STMarkdownRegexFactory.compile(
        pattern: "(\\*+)([\u{201C}\u{2018}\u{FF08}\u{3010}\u{300C}\u{300E}\u{300A}])",
        owner: "STMarkdownCJKRegex.cjkOpenQuoteAfterEmphasis"
    )
}

// MARK: - Citation / Webpage 标签

public enum STMarkdownCitationRegex {
    /// `[Citation N]`（数字与 Citation 之间有空格）
    public static let citationBracketSpace = STMarkdownRegexFactory.compile(
        pattern: "\\[Citation\\s+(\\d+)\\]",
        options: .caseInsensitive,
        owner: "STMarkdownCitationRegex.citationBracketSpace"
    )
    /// `[Citation:N]`（冒号可选空格）
    public static let citationBracketColon = STMarkdownRegexFactory.compile(
        pattern: "\\[Citation\\s*:\\s*(\\d+)\\]",
        options: .caseInsensitive,
        owner: "STMarkdownCitationRegex.citationBracketColon"
    )
    /// `[webpage N]` / `webpage N` / `[webpage:N]` 等各种 Webpage 引用形态
    public static let webpageVariants = STMarkdownRegexFactory.compile(
        pattern: "(?:\\[\\s*)?webpage\\s*:?[ \\t]*(\\d+)(?:\\s*\\])?",
        options: .caseInsensitive,
        owner: "STMarkdownCitationRegex.webpageVariants"
    )
    /// 无括号的 `Citation N`（用于宽松匹配，捕获编号）
    public static let unbracketedCitationSpace = STMarkdownRegexFactory.compile(
        pattern: #"\[?Citation\s+(\d+)\]?"#,
        options: .caseInsensitive,
        owner: "STMarkdownCitationRegex.unbracketedCitationSpace"
    )
    /// 无括号的 `Citation:N`（用于宽松匹配，捕获编号）
    public static let unbracketedCitationColon = STMarkdownRegexFactory.compile(
        pattern: #"\[?Citation\s*:\s*(\d+)\]?"#,
        options: .caseInsensitive,
        owner: "STMarkdownCitationRegex.unbracketedCitationColon"
    )
    /// link children 为 `citation:N` 的内链（用于渲染层识别 citation 链接子节点）
    public static let citationLinkChildren = STMarkdownRegexFactory.compile(
        pattern: #"^citation\s*:?\s*(\d+)$"#,
        options: .caseInsensitive,
        owner: "STMarkdownCitationRegex.citationLinkChildren"
    )
    /// link children 为 `webpage:N` 的内链（用于渲染层识别 webpage 链接子节点）
    public static let webpageLinkChildren = STMarkdownRegexFactory.compile(
        pattern: #"^webpage\s*:?\s*(\d+)$"#,
        options: .caseInsensitive,
        owner: "STMarkdownCitationRegex.webpageLinkChildren"
    )
    /// `[webpage N]` → 替换为 "网页 N"（本地化显示）
    public static let webpageDisplayReplace = STMarkdownRegexFactory.compile(
        pattern: #"\[webpage\s+(\d+)\]"#,
        options: .caseInsensitive,
        owner: "STMarkdownCitationRegex.webpageDisplayReplace"
    )
    /// `[link](url) [Citation:N]` → 去重，保留 citation 部分
    public static let linkCitationDeduplicate = STMarkdownRegexFactory.compile(
        pattern: #"\[[^\]]+\]\([^)]+\)\s*(\[(?i:citation)\s*:?\s*\d+\])"#,
        owner: "STMarkdownCitationRegex.linkCitationDeduplicate"
    )
}

// MARK: - 流式尾部标记裁剪

public enum STMarkdownStreamingRegex {
    /// 行尾不完整 Heading（`# ` / `## `）或 Blockquote（`> `）标记
    ///
    /// 用于流式 drip 阶段裁剪尚未闭合的块级语法标记，防止提前渲染造成布局抖动。
    /// `dripSafe` 变体额外排除 `[[` 双括号标签（由 safeDripCursor 处理），避免与
    /// citation/node 标签的正则叠加触发连续 stall。
    public static let dripSafeTrailingMarkers: [NSRegularExpression] = [
        STMarkdownRegexFactory.compile(
            pattern: #"(?s)\n?[ \t]{0,3}#{1,6}[ \t]*$"#,
            owner: "STMarkdownStreamingRegex.dripSafe[0]"
        ),
        STMarkdownRegexFactory.compile(
            pattern: #"(?s)\n?[ \t]{0,3}#{2,6}\S*$"#,
            owner: "STMarkdownStreamingRegex.dripSafe[1]"
        ),
        STMarkdownRegexFactory.compile(
            pattern: #"(?s)\n?[ \t]{0,3}>[ \t]*$"#,
            owner: "STMarkdownStreamingRegex.dripSafe[2]"
        ),
        STMarkdownRegexFactory.compile(
            pattern: #"(?is)webpage\s*\d*$"#,
            owner: "STMarkdownStreamingRegex.dripSafe[3]"
        ),
        STMarkdownRegexFactory.compile(
            pattern: #"(?is)citation\s*:?\s*\d*$"#,
            owner: "STMarkdownStreamingRegex.dripSafe[4]"
        ),
        // 标准 Markdown 链接 `[text`：`(?<!\[)` 排除 `[[` 开头，`(?!Citation|Webpage)` 排除 citation 标签
        STMarkdownRegexFactory.compile(
            pattern: #"(?s)(?<!\[)\[(?!(?:Citation|Webpage)\s*:?\s*\d)[^\[\]]{0,40}$"#,
            owner: "STMarkdownStreamingRegex.dripSafe[5]"
        ),
        // `[text](url` 链接语法，同上排除规则
        STMarkdownRegexFactory.compile(
            pattern: #"(?s)(?<!\[)\[(?!(?:Citation|Webpage)\s*:?\s*\d)[^\[\]]{0,40}\]\([^)]{0,80}$"#,
            owner: "STMarkdownStreamingRegex.dripSafe[6]"
        ),
    ]

    /// 行尾不完整 HTML 标签：`<tag`、`<tag attr="val`、`</tag`
    public static let trailingIncompleteHtmlTag = STMarkdownRegexFactory.compile(
        pattern: #"</?[a-zA-Z][a-zA-Z0-9]*(?:\s[^>]{0,100})?$"#,
        owner: "STMarkdownStreamingRegex.trailingIncompleteHtmlTag"
    )
    /// 行尾不完整 HTML 注释：`<!--` 或 `<!-- partial`
    public static let trailingIncompleteHtmlComment = STMarkdownRegexFactory.compile(
        pattern: #"<!--[^>]{0,100}$"#,
        owner: "STMarkdownStreamingRegex.trailingIncompleteHtmlComment"
    )
    /// 流式帧末尾"悬挂 list 行前缀"：`\n` 后只有空白或 marker，无正文内容
    public static let danglingListMarkerSuffix = STMarkdownRegexFactory.compile(
        pattern: #"\n[ \t]*([-*+][ \t]*)?$"#,
        owner: "STMarkdownStreamingRegex.danglingListMarkerSuffix"
    )
    /// 流式帧中有缩进但正文尚未到达的无序列表行（用于消除闪烁）
    public static let streamingPartialIndentedUnorderedList = STMarkdownRegexFactory.compile(
        pattern: #"^([ \t]{2,})([-+*])[ \t]*$"#,
        owner: "STMarkdownStreamingRegex.streamingPartialIndentedUnorderedList"
    )
    /// 流式帧中仅有数字 marker（`1` 或 `1.`）尚无内容的有序列表行
    public static let streamingPartialOrderedListMarker = STMarkdownRegexFactory.compile(
        pattern: #"^\d+\.?$"#,
        owner: "STMarkdownStreamingRegex.streamingPartialOrderedListMarker"
    )
    /// 缩进 2+ 空格的无序列表行（有正文）
    public static let streamingIndentedUnorderedList = STMarkdownRegexFactory.compile(
        pattern: #"^([ \t]{2,})([-+*])\s+\S"#,
        owner: "STMarkdownStreamingRegex.streamingIndentedUnorderedList"
    )
    /// 任意列表行（有序或无序，0-3 空格缩进，有正文）
    public static let streamingAnyList = STMarkdownRegexFactory.compile(
        pattern: #"^[ \t]{0,3}(?:[-+*]|\d+\.)\s+\S"#,
        owner: "STMarkdownStreamingRegex.streamingAnyList"
    )
    /// 任意无序列表行（有正文）
    public static let streamingAnyUnorderedList = STMarkdownRegexFactory.compile(
        pattern: #"^[ \t]*[-+*]\s+\S"#,
        owner: "STMarkdownStreamingRegex.streamingAnyUnorderedList"
    )
    /// 有序列表 marker 后紧跟 2+ 空格（规范化为单空格）
    public static let streamingOrderedListDoubleSpace = STMarkdownRegexFactory.compile(
        pattern: #"^(\d+\.)[ \t]{2,}"#,
        options: .anchorsMatchLines,
        owner: "STMarkdownStreamingRegex.streamingOrderedListDoubleSpace"
    )
    /// 流式 active 阶段 CJK 关闭标点后紧跟 `*`（补 ZWNJ）
    public static let streamingActiveCjkEmphasisBoundary = STMarkdownRegexFactory.compile(
        pattern: #"([）】」』》\u{201D}\u{2019}，。！？；：…—])(?=\*)"#,
        owner: "STMarkdownStreamingRegex.streamingActiveCjkEmphasisBoundary"
    )
    /// 流式帧中"刚萌发"的列表项行（marker 后只有 0-1 个正文字符，尚不稳定）
    public static let nascentListItem = STMarkdownRegexFactory.compile(
        pattern: #"\n([ \t]{0,3}(?:[-+*]|\d+\.)[ \t]+.{0,1})$"#,
        owner: "STMarkdownStreamingRegex.nascentListItem"
    )
}

// MARK: - HTML 清理

public enum STMarkdownHTMLCleanRegex {
    /// `[[node/reference/node_end/weather]]...[[/tag]]` 双括号协议标签（跨行）
    public static let nodeTagCleaner = STMarkdownRegexFactory.compile(
        pattern: "\\[\\[(node|reference|node_end|weather)\\]\\].*?\\[\\[/\\1\\]\\]",
        options: .dotMatchesLineSeparators,
        owner: "STMarkdownHTMLCleanRegex.nodeTagCleaner"
    )
    /// Heading 前的分割线（`---`/`***`/`___` 三个或以上，用于清理冗余分割线）
    public static let headingDividerCleaner = STMarkdownRegexFactory.compile(
        pattern: #"(?m)^(?:[ \t]*[-*_][ \t]*){3,}\n(?=[ \t]{0,3}#{1,6}[ \t]+\S)"#,
        owner: "STMarkdownHTMLCleanRegex.headingDividerCleaner"
    )
    /// `<a href="#...">...</a>` 锚点链接（用于清理本地页内锚点）
    public static let anchorCleanup = STMarkdownRegexFactory.compile(
        pattern: "<a\\s+[^>]*href=\"#([^\"]*)\"[^>]*>[^<]*</a>",
        options: .caseInsensitive,
        owner: "STMarkdownHTMLCleanRegex.anchorCleanup"
    )
    /// 3 个及以上连续换行压缩为 2 个换行
    public static let doubleNewline = STMarkdownRegexFactory.compile(
        pattern: #"\n{3,}"#,
        owner: "STMarkdownHTMLCleanRegex.doubleNewline"
    )
    /// 页码引用清理正则数组（预编译，.caseInsensitive）
    public static let pageReferenceCleanupRegexes: [NSRegularExpression] = {
        let patterns: [String] = [
            #"[（(]\s*\[(?:第\d+页|页面\d+|\d+页|P\d+|引用网页\d+|参考\d+|见\d+页|网页\d+|webpage\s+\d+)\]\(#[^)]*\)\s*[）)]"#,
            #"\[\s*\[(?:第\d+页|页面\d+|\d+页|P\d+|引用网页\d+|参考\d+|见\d+页|网页\d+|webpage\s+\d+)\]\(#[^)]*\)\s*\]"#,
            #"[【《「『]\s*\[(?:第\d+页|页面\d+|\d+页|P\d+|引用网页\d+|参考\d+|见\d+页|网页\d+|webpage\s+\d+)\]\(#[^)]*\)\s*[】》」』]"#,
            #"\[(?:第\d+页|页面\d+|\d+页|P\d+|引用网页\d+|参考\d+|见\d+页|网页\d+|webpage\s+\d+)\]\(#[^)]*\)"#,
            #"\[webpage\s+\d+\]"#,
            #"[（(]\s*\[webpage\s+\d+\]\s*[）)]"#,
            #"\[\s*\[webpage\s+\d+\]\s*\]"#,
            #"[【《「『]\s*\[webpage\s+\d+\]\s*[】》」』]"#,
        ]
        return patterns.map {
            STMarkdownRegexFactory.compile(pattern: $0, options: .caseInsensitive, owner: "STMarkdownHTMLCleanRegex.pageReferenceCleanup")
        }
    }()
}
