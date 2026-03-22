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
/// - Mermaid.js 从 SPM Bundle 资源包加载（Bundle.module）
@MainActor
public final class STMarkdownMermaidRenderer: NSObject {

    public static let shared = STMarkdownMermaidRenderer()

    private var webView: WKWebView?
    private(set) public var imageCache: [String: UIImage] = [:]
    private var pendingCallbacks: [String: [(UIImage?) -> Void]] = [:]
    private var renderQueue: [(code: String, width: CGFloat, isDark: Bool, key: String)] = []
    private var isWebViewReady = false
    private var isRendering = false

    private override init() { super.init() }

    public func cachedImage(for code: String, isDark: Bool) -> UIImage? {
        self.imageCache[cacheKey(code, isDark)]
    }

    /// 异步渲染 Mermaid 图表。若已缓存立即回调；否则入队等待 WKWebView 渲染完成后回调。
    public func renderAsync(code: String, width: CGFloat, isDark: Bool, completion: @escaping (UIImage?) -> Void) {
        let key = self.cacheKey(code, isDark)
        if let img = self.imageCache[key] {
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
    private func cacheKey(_ code: String, _ isDark: Bool) -> String {
        "\(code.hashValue)_\(isDark)"
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
        let escaped = code
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
        let js = "renderMermaid(`\(escaped)`, '\(theme)', '\(key)');"
        wv.evaluateJavaScript(js) { [weak self] _, error in
            if let error = error {
                print("[STMarkdownMermaidRenderer] JS eval error: \(error.localizedDescription)")
                self?.finalize(key: key, image: nil)
            }
        }
    }

    // MARK: - Snapshot
    private func takeSnapshot(key: String, height: CGFloat) {
        guard let wv = self.webView else { self.finalize(key: key, image: nil); return }
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
            self.imageCache[key] = img
        }
        let callbacks = self.pendingCallbacks.removeValue(forKey: key) ?? []
        self.isRendering = false
        callbacks.forEach { $0(image) }
        self.drainQueue()
    }

    private func scaffoldHTML() -> String {
        // 将 mermaid.js 内容内联到 HTML 中，避免 loadHTMLString(baseURL:nil) 的
        // file:// 跨 origin 限制导致脚本加载被 WebKit 安全策略阻断。
        let mermaidScript: String
        if let url = Bundle.module.url(forResource: "mermaid.min", withExtension: "js"),
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
            mermaid.initialize({ startOnLoad: false, theme: theme, securityLevel: 'loose' });
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

// MARK: - WKNavigationDelegate
extension STMarkdownMermaidRenderer: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.isWebViewReady = true
        self.drainQueue()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("[STMarkdownMermaidRenderer] Navigation failed: \(error.localizedDescription)")
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("[STMarkdownMermaidRenderer] Provisional navigation failed: \(error.localizedDescription)")
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
