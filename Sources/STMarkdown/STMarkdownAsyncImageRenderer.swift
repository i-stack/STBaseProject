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

public final class STMarkdownURLSessionImageLoader: STMarkdownImageLoading, @unchecked Sendable {
    
    public static let shared = STMarkdownURLSessionImageLoader()
    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
        self.cache.countLimit = 64
    }

    public func loadImage(from url: URL, completion: @escaping @Sendable (UIImage?) -> Void) {
        if let cached = self.cache.object(forKey: url as NSURL) {
            completion(cached)
            return
        }
        self.session.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            self?.cache.setObject(image, forKey: url as NSURL)
            completion(image)
        }.resume()
    }
}

final class STMarkdownAsyncImageAttachment: NSTextAttachment {
    
    var onNeedsDisplay: (() -> Void)?
    private let loader: STMarkdownImageLoading
    private let style: STMarkdownStyle
    private let inline: Bool
    private let url: URL

    init(url: URL, style: STMarkdownStyle, inline: Bool, loader: STMarkdownImageLoading) {
        self.url = url
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
}

private extension STMarkdownAsyncImageAttachment {
    func configurePlaceholder() {
        let placeholderImage = UIImage(systemName: self.inline ? "photo" : "photo.on.rectangle")
        self.image = placeholderImage
        self.bounds = self.placeholderBounds()
    }

    func loadImage() {
        self.loader.loadImage(from: self.url) { [weak self] image in
            guard let self, let image else { return }
            DispatchQueue.main.async {
                self.image = image
                self.bounds = self.resolvedBounds(for: image.size)
                self.onNeedsDisplay?()
            }
        }
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
        let attachment = STMarkdownAsyncImageAttachment(url: resolvedURL, style: style, inline: inline, loader: self.loader)
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
            let caption = title?.isEmpty == false ? title! : altText
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
