//
//  STMarkdownAsyncImageRenderer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public protocol STMarkdownImageLoading: AnyObject {
    func loadImage(from url: URL, completion: @escaping @Sendable (UIImage?) -> Void)
}

public protocol STMarkdownImageLoadCancellable: AnyObject {
    func cancel()
}

public protocol STMarkdownCancellableImageLoading: STMarkdownImageLoading {
    func loadCancellableImage(from url: URL, completion: @escaping @Sendable (UIImage?) -> Void) -> STMarkdownImageLoadCancellable?
}

public final class STMarkdownURLSessionImageLoader: STMarkdownImageLoading, @unchecked Sendable {

    public static let shared = STMarkdownURLSessionImageLoader()
    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession
    /// 进行中的请求表：同一 URL 在已有 dataTask 完成前，所有后续 caller 共享该任务结果，
    /// 避免同一图像被重复下载（流式 markdown 里复用图很常见）。
    private let lock = NSLock()
    private var inFlight: [URL: STMarkdownInFlightRequest] = [:]

    public init(session: URLSession = .shared) {
        self.session = session
        self.cache.countLimit = 64
    }

    public func loadImage(from url: URL, completion: @escaping @Sendable (UIImage?) -> Void) {
        _ = self.loadCancellableImage(from: url, completion: completion)
    }
}

/// 多消费者共享的进行中请求。每个消费者持有自己的 `STMarkdownImageLoadCancellable`，
/// 取消时只移除自己；只有全部消费者取消才会真正终止 dataTask。
private final class STMarkdownInFlightRequest {
    var task: URLSessionDataTask?
    var consumers: [UUID: @Sendable (UIImage?) -> Void] = [:]

    init() {}
}

private final class STMarkdownInFlightCancellable: STMarkdownImageLoadCancellable {
    private weak var loader: STMarkdownURLSessionImageLoader?
    private let url: URL
    private let id: UUID

    init(loader: STMarkdownURLSessionImageLoader, url: URL, id: UUID) {
        self.loader = loader
        self.url = url
        self.id = id
    }

    func cancel() {
        self.loader?.cancelConsumer(id: self.id, url: self.url)
    }
}

extension URLSessionDataTask: STMarkdownImageLoadCancellable {}

extension STMarkdownURLSessionImageLoader: STMarkdownCancellableImageLoading {
    public func loadCancellableImage(from url: URL, completion: @escaping @Sendable (UIImage?) -> Void) -> STMarkdownImageLoadCancellable? {
        if let cached = self.cache.object(forKey: url as NSURL) {
            completion(cached)
            return nil
        }
        let consumerId = UUID()

        self.lock.lock()
        if let existing = self.inFlight[url] {
            // 已有进行中请求，只追加 consumer。
            existing.consumers[consumerId] = completion
            self.lock.unlock()
            return STMarkdownInFlightCancellable(loader: self, url: url, id: consumerId)
        }
        let request = STMarkdownInFlightRequest()
        request.consumers[consumerId] = completion
        self.inFlight[url] = request
        self.lock.unlock()

        let task = self.session.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }
            let image: UIImage?
            if error == nil,
               let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode),
               let data,
               data.isEmpty == false,
               let decoded = UIImage(data: data) {
                image = decoded
            } else {
                image = nil
            }
            self.deliverInFlight(url: url, image: image)
        }
        self.lock.lock()
        // 中途可能所有 consumer 都取消：此时 `inFlight[url]` 已被清理，不应再启动任务。
        guard self.inFlight[url] != nil else {
            self.lock.unlock()
            return STMarkdownInFlightCancellable(loader: self, url: url, id: consumerId)
        }
        self.inFlight[url]?.task = task
        self.lock.unlock()
        task.resume()
        return STMarkdownInFlightCancellable(loader: self, url: url, id: consumerId)
    }

    /// 只有在所有消费者都取消后，才会真正取消底层 dataTask。
    fileprivate func cancelConsumer(id: UUID, url: URL) {
        self.lock.lock()
        guard let request = self.inFlight[url] else {
            self.lock.unlock()
            return
        }
        request.consumers.removeValue(forKey: id)
        if request.consumers.isEmpty {
            self.inFlight.removeValue(forKey: url)
            let task = request.task
            self.lock.unlock()
            task?.cancel()
            return
        }
        self.lock.unlock()
    }

    fileprivate func deliverInFlight(url: URL, image: UIImage?) {
        self.lock.lock()
        let request = self.inFlight.removeValue(forKey: url)
        self.lock.unlock()
        if let image {
            self.cache.setObject(image, forKey: url as NSURL)
        }
        request?.consumers.values.forEach { $0(image) }
    }
}

private final class STMarkdownImageLoadToken {
    private let lock = NSLock()
    private var isCancelled = false
    private var cancellable: STMarkdownImageLoadCancellable?

    func setCancellable(_ cancellable: STMarkdownImageLoadCancellable?) {
        self.lock.lock()
        if self.isCancelled {
            self.lock.unlock()
            cancellable?.cancel()
            return
        }
        self.cancellable = cancellable
        self.lock.unlock()
    }

    func cancel() {
        self.lock.lock()
        self.isCancelled = true
        let cancellable = self.cancellable
        self.cancellable = nil
        self.lock.unlock()
        cancellable?.cancel()
    }

    func shouldAcceptResult() -> Bool {
        self.lock.lock()
        let result = self.isCancelled == false
        self.lock.unlock()
        return result
    }
}

private final class STMarkdownLegacyImageLoadCancellable: STMarkdownImageLoadCancellable {
    private let token: STMarkdownImageLoadToken

    init(token: STMarkdownImageLoadToken) {
        self.token = token
    }

    func cancel() {
        self.token.cancel()
    }
}

private extension STMarkdownImageLoading {
    func loadImageWithCancellation(from url: URL, completion: @escaping @Sendable (UIImage?) -> Void) -> STMarkdownImageLoadCancellable? {
        if let loader = self as? STMarkdownCancellableImageLoading {
            return loader.loadCancellableImage(from: url, completion: completion)
        }
        let token = STMarkdownImageLoadToken()
        self.loadImage(from: url) { image in
            guard token.shouldAcceptResult() else { return }
            completion(image)
        }
        return STMarkdownLegacyImageLoadCancellable(token: token)
    }
}

final class STMarkdownAsyncImageAttachment: NSTextAttachment, STMarkdownRefreshableAttachment {

    private let refreshRegistry = STMarkdownRefreshObserverRegistry()
    private let loader: STMarkdownImageLoading
    private let style: STMarkdownStyle
    private let inline: Bool
    private let url: URL
    private let altText: String
    private let blockMaxSize: CGSize
    private let loadToken = STMarkdownImageLoadToken()

    init(
        url: URL,
        altText: String,
        style: STMarkdownStyle,
        inline: Bool,
        loader: STMarkdownImageLoading,
        blockMaxSize: CGSize? = nil
    ) {
        self.url = url
        self.altText = altText
        self.style = style
        self.inline = inline
        self.loader = loader
        self.blockMaxSize = Self.normalizedBlockMaxSize(blockMaxSize)
        super.init(data: nil, ofType: nil)
        self.configurePlaceholder()
        self.loadImage()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    deinit {
        self.loadToken.cancel()
    }

    func addDisplayObserver(_ observer: @escaping () -> Void) -> STMarkdownRefreshObservation {
        return self.refreshRegistry.add(observer)
    }

    /// 内部回调入口：图像就绪时通知所有观察者。
    /// 仅供本类 extension 中使用，对外通过 `addDisplayObserver` 订阅。
    fileprivate func notifyDisplayObservers() {
        self.refreshRegistry.notify()
    }
}

private extension STMarkdownAsyncImageAttachment {
    static func normalizedBlockMaxSize(_ size: CGSize?) -> CGSize {
        guard let size,
              size.width.isFinite,
              size.height.isFinite,
              size.width > 0,
              size.height > 0 else {
            return CGSize(width: 280, height: 220)
        }
        return size
    }

    func configurePlaceholder() {
        let tint = self.style.imagePlaceholderTextColor ?? self.style.textColor.withAlphaComponent(0.7)
        let placeholderImage = UIImage(systemName: self.inline ? "photo" : "photo.on.rectangle")?
            .withTintColor(tint, renderingMode: .alwaysOriginal)
        placeholderImage?.accessibilityLabel = self.accessibilityLabelForCurrentState(imageReady: false)
        self.image = placeholderImage
        self.bounds = self.placeholderBounds()
    }

    func loadImage() {
        let cancellable = self.loader.loadImageWithCancellation(from: self.url) { [weak self] image in
            guard let self, let image else { return }
            guard self.loadToken.shouldAcceptResult() else { return }
            DispatchQueue.main.async {
                guard self.loadToken.shouldAcceptResult() else { return }
                image.accessibilityLabel = self.accessibilityLabelForCurrentState(imageReady: true)
                self.image = image
                self.bounds = self.resolvedBounds(for: image.size)
                self.notifyDisplayObservers()
            }
        }
        self.loadToken.setCancellable(cancellable)
    }

    /// 为 `UIImage` 生成无障碍描述。优先使用 Markdown alt text，其次使用 URL。
    /// - Parameter imageReady: 当前是真实图像 (`true`) 还是占位符 (`false`)。
    func accessibilityLabelForCurrentState(imageReady: Bool) -> String {
        let fallback = self.url.lastPathComponent
        let primary = self.altText.isEmpty ? fallback : self.altText
        return imageReady ? primary : "\(primary) (loading)"
    }

    func placeholderBounds() -> CGRect {
        if self.inline {
            let side = max(self.style.font.capHeight, 14)
            let y = (self.style.font.capHeight - side) / 2
            return CGRect(x: 0, y: y, width: side, height: side)
        }
        // block 占位不应超过 blockMaxSize，更小时按比例缩
        let placeholderW = min(180, self.blockMaxSize.width)
        let placeholderH = min(120, self.blockMaxSize.height)
        return CGRect(x: 0, y: 0, width: placeholderW, height: placeholderH)
    }

    func resolvedBounds(for size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0 else {
            return self.placeholderBounds()
        }
        if self.inline {
            let targetHeight = max(self.style.font.capHeight, 14)
            let scale = targetHeight / size.height
            let targetWidth = size.width * scale
            let y = (self.style.font.capHeight - targetHeight) / 2
            return CGRect(x: 0, y: y, width: targetWidth, height: targetHeight)
        }
        let maxWidth = self.blockMaxSize.width
        let maxHeight = self.blockMaxSize.height
        let widthScale = maxWidth / size.width
        let heightScale = maxHeight / size.height
        let scale = min(widthScale, heightScale, 1)
        return CGRect(
            x: 0,
            y: 0,
            width: size.width * scale,
            height: size.height * scale
        )
    }
}

public struct STMarkdownAsyncImageRenderer: STMarkdownImageRendering {

    public let loader: STMarkdownImageLoading
    /// 用于解析相对路径的基准 URL。对 `./img.png`、`../assets/x.png`、或仅有路径的
    /// `foo/bar.png` 生效；绝对 URL（含 scheme）忽略该基准。
    public let baseURL: URL?
    /// 非 inline（block）图像的最大渲染尺寸。nil 时退回至内置 280×220 默认值。
    public let blockMaxSize: CGSize?

    public init(
        loader: STMarkdownImageLoading = STMarkdownURLSessionImageLoader.shared,
        baseURL: URL? = nil,
        blockMaxSize: CGSize? = nil
    ) {
        self.loader = loader
        self.baseURL = baseURL
        self.blockMaxSize = blockMaxSize
    }

    public func renderImage(url: String, altText: String, title: String?, style: STMarkdownStyle, inline: Bool) -> NSAttributedString? {
        guard let resolvedURL = self.resolveURL(from: url) else {
            return nil
        }
        let attachment = STMarkdownAsyncImageAttachment(
            url: resolvedURL,
            altText: altText,
            style: style,
            inline: inline,
            loader: self.loader,
            blockMaxSize: self.blockMaxSize
        )
        if inline {
            return NSAttributedString(attachment: attachment)
        }
        let result = NSMutableAttributedString(attachment: attachment)
        if altText.isEmpty == false || (title?.isEmpty == false) {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.minimumLineHeight = style.lineHeight
            paragraphStyle.maximumLineHeight = style.lineHeight
            paragraphStyle.paragraphSpacing = style.paragraphSpacing
            paragraphStyle.alignment = .center
            let caption = title.flatMap { $0.isEmpty ? nil : $0 } ?? altText
            result.append(
                NSAttributedString(
                    string: "\n\(caption)",
                    attributes: [
                        .font: UIFont.st_systemFont(ofSize: max(style.font.pointSize - 2, 12), weight: .regular),
                        .foregroundColor: style.imagePlaceholderCaptionColor ?? style.textColor.withAlphaComponent(0.72),
                        .paragraphStyle: paragraphStyle,
                    ]
                )
            )
        }
        return result
    }

    /// 把字符串形式的 URL 解析为可请求的 `URL`。
    /// - 绝对 URL（有 scheme）原样返回；
    /// - 以 `/` / `./` / `../` 开头或不含 scheme 的相对路径：若 `baseURL` 存在则 resolve，
    ///   否则返回 nil 让上层走占位文本兜底。
    private func resolveURL(from source: String) -> URL? {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        if let absolute = URL(string: trimmed), absolute.scheme?.isEmpty == false {
            return absolute
        }
        if let baseURL {
            return URL(string: trimmed, relativeTo: baseURL)?.absoluteURL
        }
        return nil
    }
}
