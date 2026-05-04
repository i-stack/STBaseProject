//
//  STMarkdownMermaidRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit
import WebKit

/// WKWebView 离屏渲染 Mermaid 图表，结果缓存为 UIImage。
/// - 全局单例，序列化渲染队列（避免并发冲突），缓存复用
/// - Mermaid.js 优先从 STMarkdown 资源包加载（SPM：`Bundle.module`；CocoaPods：`STBaseProject_STMarkdown.bundle`）
@MainActor
public class STMarkdownMermaidRenderer: NSObject {

    public static let shared = STMarkdownMermaidRenderer()

    private var webView: WKWebView?
    /// 改为 `NSCache` 以便在内存紧张时自动释放，并显式限制条目数。
    /// 早期用 `Dictionary<String, UIImage>` 无上限，长会话进程会把几十 MB 图片留到进程结束。
    private let imageCacheStore: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 64
        return cache
    }()
    private var imageCacheSnapshot: [String: UIImage] = [:]
    private var imageCacheSnapshotOrder: [String] = []
    private var pendingCallbacks: [String: [@Sendable (UIImage?) -> Void]] = [:]
    private var renderQueue: [(code: String, width: CGFloat, isDark: Bool, key: String)] = []
    private var isWebViewReady = false
    private var isRendering = false

    private override init() { super.init() }

    @available(*, deprecated, message: "Use cachedImage(for:isDark:) instead. NSCache storage no longer exposes a complete dictionary snapshot.")
    public var imageCache: [String: UIImage] {
        self.imageCacheSnapshot
    }

    public func cachedImage(for code: String, isDark: Bool) -> UIImage? {
        self.imageCacheStore.object(forKey: self.cacheKey(code, isDark) as NSString)
    }

    /// 异步渲染 Mermaid 图表。若已缓存立即回调；否则入队等待 WKWebView 渲染完成后回调。
    /// 回调闭包在主线程触发；标注 `@Sendable` 是为兼容 Swift6 严格并发调用方。
    public func renderAsync(code: String, width: CGFloat, isDark: Bool, completion: @escaping @Sendable (UIImage?) -> Void) {
        let key = self.cacheKey(code, isDark)
        if let img = self.imageCacheStore.object(forKey: key as NSString) {
            completion(img)
            return
        }
        if self.pendingCallbacks[key] != nil {
            self.pendingCallbacks[key]!.append(completion)
        } else {
            self.pendingCallbacks[key] = [completion]
            self.renderQueue.append((code: code, width: width, isDark: isDark, key: key))
        }
        self.ensureWebViewReady()
        self.drainQueue()
    }

    // 宽度不纳入 key：Mermaid 输出 SVG 可自适应宽度，截图时用实际 webView.frame.width
    // internal 而非 private：允许 @testable import 的单元测试验证键唯一性
    func cacheKey(_ code: String, _ isDark: Bool) -> String {
        "\(isDark ? "1" : "0")_\(code)"
    }

    private func ensureWebViewReady() {
        guard webView == nil else { return }
        let controller = WKUserContentController()
        controller.add(STMarkdownWeakScriptHandler(self), name: "mermaidDone")
        controller.add(STMarkdownWeakScriptHandler(self), name: "mermaidError")
        let config = WKWebViewConfiguration()
        config.userContentController = controller
        let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: 375, height: 1), configuration: config)
        wv.navigationDelegate = self
        wv.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.backgroundColor = .clear
        self.webView = wv
        wv.loadHTMLString(self.scaffoldHTML(), baseURL: nil)
    }

    // MARK: - Render Queue
    private func drainQueue() {
        guard self.isWebViewReady, !self.isRendering, !self.renderQueue.isEmpty else { return }
        let next = self.renderQueue.removeFirst()
        self.isRendering = true
        self.renderOne(next.code, width: next.width, isDark: next.isDark, key: next.key)
    }

    private func renderOne(_ code: String, width: CGFloat, isDark: Bool, key: String) {
        guard let wv = webView else { finalize(key: key, image: nil); return }
        let renderWidth = max(width, 200)
        wv.frame = CGRect(x: 0, y: 0, width: renderWidth, height: 1)
        let theme = isDark ? "dark" : "default"
        // 反引号模板里只需要转义 `\`、`` ` ``、`$` 三类字符即可。
        let escapedCode = code
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        // key 可能包含用户输入（cacheKey 里拼了 code），若直接放单引号里会被 JS 解释器注入。
        // 用 JSON 序列化一次拿到安全字面量，既转义引号也处理换行/反斜杠。
        let encodedKey = Self.jsStringLiteral(for: key)
        let encodedTheme = Self.jsStringLiteral(for: theme)
        let js = "renderMermaid(`\(escapedCode)`, \(encodedTheme), \(encodedKey));"
        wv.evaluateJavaScript(js) { [weak self] _, error in
            if let error = error {
                print("[STMarkdownMermaidRenderer] JS eval error: \(error.localizedDescription)")
                self?.finalize(key: key, image: nil)
            }
        }
    }

    /// 以 JSON 字面量方式把 Swift 字符串编码成 JS 可直接嵌入的字符串（含首尾引号）。
    /// 兜底采用最保守的字符转义，保证在任何输入下都不会构成 JS 注入。
    private static func jsStringLiteral(for value: String) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: [value], options: []),
           let json = String(data: data, encoding: .utf8),
           json.count >= 2 {
            // JSONSerialization 输出形如 `["..."]`，去掉外层方括号即得字符串字面量。
            let inner = json.dropFirst().dropLast()
            return String(inner)
        }
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        return "'\(escaped)'"
    }

    // MARK: - Snapshot
    private func takeSnapshot(key: String, height: CGFloat) {
        guard let wv = self.webView else { self.finalize(key: key, image: nil); return }
        // 渲染任务被 `isRendering` 互斥串行化，在本次 takeSnapshot 结束前不会有新
        // `renderOne` 重设 frame，因此直接读取 `wv.frame.width` 是安全的。
        // 若未来放宽并发度，需要改为 `renderOne` 阶段捕获 width 到实例变量。
        let renderWidth = wv.frame.width
        let renderHeight = max(height + 16, 40) // 16pt body padding
        wv.frame = CGRect(x: 0, y: 0, width: renderWidth, height: renderHeight)
        let snapshotConfig = WKSnapshotConfiguration()
        snapshotConfig.rect = CGRect(x: 0, y: 0, width: renderWidth, height: renderHeight)
        wv.takeSnapshot(with: snapshotConfig) { [weak self] image, _ in
            self?.finalize(key: key, image: image)
        }
    }

    private func finalize(key: String, image: UIImage?) {
        if let img = image {
            self.imageCacheStore.setObject(img, forKey: key as NSString)
            self.storeCompatibilityCacheSnapshot(image: img, key: key)
        }
        let callbacks = self.pendingCallbacks.removeValue(forKey: key) ?? []
        self.isRendering = false
        callbacks.forEach { $0(image) }
        self.drainQueue()
    }

    private static func markdownResourcesBundle() -> Bundle {
#if SWIFT_PACKAGE
        return Bundle.module
#else
        let containing = Bundle(for: STMarkdownMermaidRenderer.self)
        if let url = containing.url(forResource: "STBaseProject_STMarkdown", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return containing
#endif
    }

    private func scaffoldHTML() -> String {
        // 将 mermaid.js 内容内联到 HTML 中，避免 loadHTMLString(baseURL:nil) 的
        // file:// 跨 origin 限制导致脚本加载被 WebKit 安全策略阻断。
        let mermaidScript: String
        if let url = Self.markdownResourcesBundle().url(forResource: "mermaid.min", withExtension: "js"),
           let content = try? String(contentsOf: url, encoding: .utf8) {
            mermaidScript = "<script>\(content)</script>"
        } else {
            // CDN 降级：需要网络，仅 baseURL 非 nil 时生效
            mermaidScript = "<script src=\"https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js\"></script>"
        }
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          * { box-sizing: border-box; }
          body { margin: 0; padding: 8px; background: transparent; overflow: hidden; }
          #output { width: 100%; }
          #output svg { max-width: 100%; height: auto; display: block; }
        </style>
        \(mermaidScript)
        </head>
        <body>
        <div id="output"></div>
        <script>
        async function renderMermaid(code, theme, key) {
          try {
            // 使用 antiscript 禁用 <script> 注入；flowchart click 仍可用纯文本/URL。
            mermaid.initialize({ startOnLoad: false, theme: theme, securityLevel: 'antiscript' });
            const id = 'mg' + Date.now();
            const { svg } = await mermaid.render(id, code);
            document.getElementById('output').innerHTML = svg;
            const height = document.getElementById('output').scrollHeight;
            window.webkit.messageHandlers.mermaidDone.postMessage({ key: key, height: height });
          } catch (e) {
            window.webkit.messageHandlers.mermaidError.postMessage({ key: key, error: e.message || String(e) });
          }
        }
        </script>
        </body>
        </html>
        """
    }
}

private extension STMarkdownMermaidRenderer {
    func storeCompatibilityCacheSnapshot(image: UIImage, key: String) {
        if self.imageCacheSnapshot[key] == nil {
            self.imageCacheSnapshotOrder.append(key)
        }
        self.imageCacheSnapshot[key] = image
        while self.imageCacheSnapshotOrder.count > 64 {
            let oldest = self.imageCacheSnapshotOrder.removeFirst()
            self.imageCacheSnapshot.removeValue(forKey: oldest)
        }
    }
}

// MARK: - WKNavigationDelegate
extension STMarkdownMermaidRenderer: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.isWebViewReady = true
        self.drainQueue()
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("[STMarkdownMermaidRenderer] Navigation failed: \(error.localizedDescription)")
        self.failAllPendingCallbacks()
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("[STMarkdownMermaidRenderer] Provisional navigation failed: \(error.localizedDescription)")
        self.failAllPendingCallbacks()
    }
}

// MARK: - Failure Handling
private extension STMarkdownMermaidRenderer {
    /// HTML/资源加载失败时，把所有挂起的回调以 `nil` 兜底通知，避免调用方永远等待。
    /// 同时清空渲染队列与就绪标记，下一次 `renderAsync` 仍会尝试重建 WebView。
    func failAllPendingCallbacks() {
        let snapshots = self.pendingCallbacks
        self.pendingCallbacks.removeAll()
        self.renderQueue.removeAll()
        self.isRendering = false
        self.isWebViewReady = false
        self.webView = nil
        for callbacks in snapshots.values {
            callbacks.forEach { $0(nil) }
        }
    }
}

// MARK: - WKScriptMessageHandler
extension STMarkdownMermaidRenderer: WKScriptMessageHandler {
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let key = body["key"] as? String else { return }
        if message.name == "mermaidDone" {
            let height = CGFloat((body["height"] as? Double) ?? 200)
            takeSnapshot(key: key, height: height)
        } else if message.name == "mermaidError" {
            let errMsg = body["error"] as? String ?? "unknown"
            print("[STMarkdownMermaidRenderer] Mermaid render error for key \(key): \(errMsg)")
            finalize(key: key, image: nil)
        }
    }
}

// MARK: - Weak Script Message Handler (避免 WKWebView retain cycle)
private final class STMarkdownWeakScriptHandler: NSObject, WKScriptMessageHandler {
    weak var target: (WKScriptMessageHandler & AnyObject)?
    init(_ target: WKScriptMessageHandler & AnyObject) { self.target = target }
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(ucc, didReceive: message)
    }
}
