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

    public init(session: URLSession = .shared) {
        self.session = session
        self.cache.countLimit = 64
    }

    public func loadImage(from url: URL, completion: @escaping @Sendable (UIImage?) -> Void) {
        _ = self.loadCancellableImage(from: url, completion: completion)
    }
}

extension URLSessionDataTask: STMarkdownImageLoadCancellable {}

extension STMarkdownURLSessionImageLoader: STMarkdownCancellableImageLoading {
    public func loadCancellableImage(from url: URL, completion: @escaping @Sendable (UIImage?) -> Void) -> STMarkdownImageLoadCancellable? {
        if let cached = self.cache.object(forKey: url as NSURL) {
            completion(cached)
            return nil
        }
        let task = self.session.dataTask(with: url) { [weak self] data, response, error in
            guard error == nil,
                  let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode),
                  let data,
                  data.isEmpty == false,
                  let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            self?.cache.setObject(image, forKey: url as NSURL)
            completion(image)
        }
        task.resume()
        return task
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
    private let loadToken = STMarkdownImageLoadToken()

    init(url: URL, altText: String, style: STMarkdownStyle, inline: Bool, loader: STMarkdownImageLoading) {
        self.url = url
        self.altText = altText
        self.style = style
        self.inline = inline
        self.loader = loader
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
    func configurePlaceholder() {
        let placeholderImage = UIImage(systemName: self.inline ? "photo" : "photo.on.rectangle")
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
        return CGRect(x: 0, y: 0, width: 180, height: 120)
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
        let maxWidth: CGFloat = 280
        let maxHeight: CGFloat = 220
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

    public init(loader: STMarkdownImageLoading = STMarkdownURLSessionImageLoader.shared) {
        self.loader = loader
    }

    public func renderImage(url: String, altText: String, title: String?, style: STMarkdownStyle, inline: Bool) -> NSAttributedString? {
        guard let resolvedURL = URL(string: url), resolvedURL.scheme?.isEmpty == false else {
            return nil
        }
        let attachment = STMarkdownAsyncImageAttachment(url: resolvedURL, altText: altText, style: style, inline: inline, loader: self.loader)
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
}
