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

    /// highlight.js 内置且经过验证的语言标识符（均为小写）。
    public static let supportedLanguages: Set<String> = [
        "bash", "c", "cpp", "csharp", "css", "go", "java",
        "javascript", "json", "kotlin", "latex", "markdown",
        "objectivec", "php", "python", "ruby", "sql",
        "swift", "typescript", "xml"
    ]

    private let vm: JSVirtualMachine
    private let jsContext: JSContext
    private let stylesheet: String
    private let cacheLock = NSLock()
    private let jsQueue = DispatchQueue(label: "com.stmarkdown.code-highlighter.js", qos: .userInitiated)

    private let cache: NSCache<NSString, NSAttributedString> = {
        let c = NSCache<NSString, NSAttributedString>()
        c.name = "STMarkdownCodeHighlighter"
        c.totalCostLimit = 10 * 1024 * 1024
        return c
    }()

    public init() {
        let bundle = Self.resourceBundle()
        let jsCode = bundle.url(forResource: "highlight.min", withExtension: "js").flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
        self.stylesheet = bundle.url(forResource: "default.min", withExtension: "css").flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ""
        self.vm = JSVirtualMachine()
        self.jsContext = JSContext(virtualMachine: self.vm)
        self.jsContext.exceptionHandler = { _, exception in
            print("[STMarkdownCodeHighlighter] JS exception: \(exception?.toString() ?? "unknown")")
        }
        if !jsCode.isEmpty {
            self.jsContext.evaluateScript(jsCode)
        }
    }
    
    public func renderCodeBlock(language: String?, code: String, style: STMarkdownStyle) -> NSAttributedString? {
        let key = "\(language ?? "")|\(code)" as NSString
        self.cacheLock.lock()
        let cached = self.cache.object(forKey: key)
        self.cacheLock.unlock()
        if let cached { return cached }

        var result: NSAttributedString?
        self.jsQueue.sync { [self] in
            result = self.highlight(code: code, language: language, style: style)
        }

        if let result {
            let cost = result.length * MemoryLayout<unichar>.stride
            self.cacheLock.lock()
            self.cache.setObject(result, forKey: key, cost: cost)
            self.cacheLock.unlock()
        }
        return result
    }

    private func highlight(code: String, language: String?, style: STMarkdownStyle) -> NSAttributedString? {
        guard let hljs = self.jsContext.objectForKeyedSubscript("hljs"), !hljs.isUndefined else { return nil }
        let normalizedLang = language?.lowercased() ?? ""
        let jsResult: JSValue?
        if !normalizedLang.isEmpty, Self.supportedLanguages.contains(normalizedLang) {
            jsResult = hljs.invokeMethod("highlight", withArguments: [code, ["language": normalizedLang]])
        } else {
            jsResult = hljs.invokeMethod("highlightAuto", withArguments: [code])
        }
        guard let htmlTokens = jsResult?.objectForKeyedSubscript("value")?.toString(), !htmlTokens.isEmpty else { return nil }
        let fontSize = max(style.font.pointSize - 1, 12)
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
