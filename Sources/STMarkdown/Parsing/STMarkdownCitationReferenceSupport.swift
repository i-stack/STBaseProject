//
//  STMarkdownCitationReferenceSupport.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public enum STMarkdownCitationReferenceSupport {
    private static let citationLinkChildrenRegex = try! NSRegularExpression(
        pattern: #"^citation\s*:?\s*(\d+)$"#,
        options: [.caseInsensitive]
    )
    private static let webpageLinkChildrenRegex = try! NSRegularExpression(
        pattern: #"^webpage\s*:?\s*(\d+)$"#,
        options: [.caseInsensitive]
    )

    public static func extractCitationNumber(from children: [STMarkdownInlineNode]) -> String? {
        guard children.count == 1, case .text(let text) = children[0] else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        for regex in [Self.citationLinkChildrenRegex, Self.webpageLinkChildrenRegex] {
            if let match = regex.firstMatch(in: trimmed, options: [], range: range),
               match.numberOfRanges >= 2 {
                return (trimmed as NSString).substring(with: match.range(at: 1))
            }
        }
        if !trimmed.isEmpty, trimmed.allSatisfy(\.isNumber) {
            return trimmed
        }
        return nil
    }
}
