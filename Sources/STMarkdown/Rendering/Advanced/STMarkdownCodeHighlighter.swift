//
//  STMarkdownCodeHighlighter.swift
//  STBaseProject
//

import UIKit
import JavaScriptCore

/// JavaScriptCore + highlight.js 语法高亮渲染器。
///
/// 将代码串交给 highlight.js 转换为带颜色标记的 HTML，再解析为 `NSAttributedString`。
/// 结果按 `"\(language ?? "")|\(code)"` 为 key 存入 `NSCache`（10 MB 上限）。
///
/// - 线程安全：JSContext 通过私有串行队列 `jsQueue` 独占访问；缓存读写通过 `NSLock` 保护。
/// - 调用方最好从后台线程调用，在缓存未命中时 `jsQueue.sync` 会阻塞当前线程直到高亮完成。
public final class STMarkdownCodeHighlighter: STMarkdownCodeBlockRendering {

    // MARK: - Supported Languages

    /// highlight.js 内置且经过验证的语言标识符（均为小写）。
    public static let supportedLanguages: Set<String> = [
        "bash", "c", "cpp", "csharp", "css", "go", "java",
        "javascript", "json", "kotlin", "latex", "markdown",
        "objectivec", "php", "python", "ruby", "sql",
        "swift", "typescript", "xml"
    ]

    // MARK: - JS Infrastructure

    private let vm: JSVirtualMachine
    private let jsContext: JSContext
    private let stylesheet: String
    /// JSContext 不是线程安全的，所有 JS 调用都必须通过此串行队列序列化。
    private let jsQueue = DispatchQueue(label: "com.stmarkdown.code-highlighter.js", qos: .userInitiated)

    // MARK: - Cache

    private let cache: NSCache<NSString, NSAttributedString> = {
        let c = NSCache<NSString, NSAttributedString>()
        c.name = "STMarkdownCodeHighlighter"
        c.totalCostLimit = 10 * 1024 * 1024
        return c
    }()
    private let cacheLock = NSLock()

    // MARK: - Init

    public init() {
        let bundle = Self.resourceBundle()
        let jsCode = bundle.url(forResource: "highlight.min", withExtension: "js")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
        stylesheet = bundle.url(forResource: "default.min", withExtension: "css")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""

        vm = JSVirtualMachine()
        jsContext = JSContext(virtualMachine: vm)
        jsContext.exceptionHandler = { _, exception in
            print("[STMarkdownCodeHighlighter] JS exception: \(exception?.toString() ?? "unknown")")
        }
        if !jsCode.isEmpty {
            jsContext.evaluateScript(jsCode)
        }
    }

    // MARK: - STMarkdownCodeBlockRendering

    public func renderCodeBlock(language: String?, code: String, style: STMarkdownStyle) -> NSAttributedString? {
        let key = "\(language ?? "")|\(code)" as NSString

        cacheLock.lock()
        let cached = cache.object(forKey: key)
        cacheLock.unlock()
        if let cached { return cached }

        var result: NSAttributedString?
        jsQueue.sync { [self] in
            result = highlight(code: code, language: language, style: style)
        }

        if let result {
            let cost = result.length * MemoryLayout<unichar>.stride
            cacheLock.lock()
            cache.setObject(result, forKey: key, cost: cost)
            cacheLock.unlock()
        }
        return result
    }

    // MARK: - Private

    private func highlight(code: String, language: String?, style: STMarkdownStyle) -> NSAttributedString? {
        guard let hljs = jsContext.objectForKeyedSubscript("hljs"),
              !hljs.isUndefined else { return nil }

        let normalizedLang = language?.lowercased() ?? ""
        let jsResult: JSValue?
        if !normalizedLang.isEmpty, Self.supportedLanguages.contains(normalizedLang) {
            jsResult = hljs.invokeMethod("highlight", withArguments: [code, ["language": normalizedLang]])
        } else {
            jsResult = hljs.invokeMethod("highlightAuto", withArguments: [code])
        }

        guard let htmlTokens = jsResult?.objectForKeyedSubscript("value")?.toString(),
              !htmlTokens.isEmpty else { return nil }

        let fontSize = max(style.font.pointSize - 1, 12)
        // 覆盖 hljs 默认背景色，由外层容器（STMarkdownStyle.codeBlockBackgroundColor）控制背景。
        let html = String(
            format: "<style>code{font-size:%.2fpx}.hljs{background:transparent}%@</style>"
                + "<pre><code class=\"hljs\">%@</code></pre>",
            fontSize, stylesheet, htmlTokens
        )

        guard let data = html.data(using: .utf8),
              let attributed = try? NSMutableAttributedString(
                  data: data,
                  options: [
                      .documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)
                  ],
                  documentAttributes: nil
              ) else { return nil }

        if attributed.mutableString.hasSuffix("\n") {
            attributed.mutableString.deleteCharacters(
                in: NSRange(location: attributed.length - 1, length: 1)
            )
        }
        return attributed.copy() as? NSAttributedString
    }

    private static func resourceBundle() -> Bundle {
#if SWIFT_PACKAGE
        return Bundle.module
#else
        let containing = Bundle(for: STMarkdownCodeHighlighter.self)
        if let url = containing.url(forResource: "STBaseProject_STMarkdown", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return containing
#endif
    }
}
