//
//  STMarkdownFootnoteDeepLink.swift
//  STBaseProject
//
//  脚注引用在富文本上使用自定义 URL scheme，与正文 ``onLinkTap`` 分流，避免与表格 Citation 角标语义混用。
//

import Foundation

enum STMarkdownFootnoteDeepLink {
    static let scheme = "stmarkdown-footnote"

    static func url(label: String) -> URL? {
        guard let encoded = label.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return nil
        }
        return URL(string: "\(Self.scheme)://\(encoded)")
    }

    static func label(from url: URL) -> String? {
        guard url.scheme == Self.scheme else { return nil }
        guard let host = url.host, host.isEmpty == false else { return nil }
        return host.removingPercentEncoding
    }
}
