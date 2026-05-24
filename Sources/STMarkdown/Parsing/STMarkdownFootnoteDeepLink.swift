//
//  STMarkdownFootnoteDeepLink.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
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
