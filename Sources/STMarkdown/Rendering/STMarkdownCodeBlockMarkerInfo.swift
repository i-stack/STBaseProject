//
//  STMarkdownCodeBlockMarkerInfo.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

public final class STMarkdownCodeBlockMarkerInfo: NSObject {
    public let language: String?
    public let code: String
    public let style: STMarkdownStyle
    public let headerHeight: CGFloat
    public let contentInsets: UIEdgeInsets

    public init(language: String?, code: String, style: STMarkdownStyle) {
        self.language = language?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.code = code
        self.style = style
        self.contentInsets = style.codeBlockContentInsets
        let autoHeight = max(
            ceil(UIFont.st_monospacedSystemFont(
                ofSize: max(style.font.pointSize - 2, 12),
                weight: .semibold
            ).lineHeight),
            18
        )
        self.headerHeight = style.codeBlockHeaderHeight > 0 ? style.codeBlockHeaderHeight : autoHeight
        super.init()
    }
}

public extension NSAttributedString.Key {
    static let stCodeBlockMarker = NSAttributedString.Key("com.stbaseproject.stCodeBlockMarker")
}
