//
//  STMarkdownCitationProcessor.swift
//  STMarkdown
//

import UIKit
import STBaseProject

/// Citation 渲染样式
public enum STMarkdownCitationRenderStyle {
    /// 圆圈数字角标
    case circleNumber
    /// 网页标签文本
    case webpageLabel
}

/// Citation 处理器：在文本中查找 [Citation N] / [Citation:N] / webpage N 等模式，
/// 替换为指定样式的富文本（圆圈角标或网页标签）。
public enum STMarkdownCitationProcessor {

    // MARK: - Text → Attributed String (plain text input)

    /// 将文本中的 [Citation N] / [Citation:N] / webpage N 替换为指定样式，返回富文本。
    public static func processCitationReferences(
        in text: String,
        font: UIFont,
        textColor: UIColor,
        kern: CGFloat,
        paragraphStyle: NSParagraphStyle,
        renderStyle: STMarkdownCitationRenderStyle,
        linkURL: String? = nil,
        citationGroupIDs: [Int]? = nil,
        citationBadgeBgColor: UIColor? = nil,
        citationBadgeTextColor: UIColor? = nil,
        linkColor: UIColor? = nil
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let ns = text as NSString
        var lastEnd = 0
        let textRange = NSRange(location: 0, length: ns.length)
        let resolvedCitationGroupIDs = normalizedCitationIDs(citationGroupIDs ?? extractCitationIDs(from: text))
        var allMatches: [(range: NSRange, number: String)] = []
        for regex in [STMarkdownCitationRegex.citationBracketSpace, STMarkdownCitationRegex.citationBracketColon, STMarkdownCitationRegex.webpageVariants] as [NSRegularExpression] {
            let matches = regex.matches(in: text, range: textRange)
            for match in matches where match.numberOfRanges >= 2 {
                let numberRange = match.range(at: 1)
                let numberText = ns.substring(with: numberRange)
                allMatches.append((match.range, numberText))
            }
        }
        allMatches.sort { $0.range.location < $1.range.location }
        var att: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .kern: kern,
            .paragraphStyle: paragraphStyle,
        ]
        if let url = linkURL.flatMap({ URL(string: $0) }) {
            att[.link] = url
        }
        for (range, number) in allMatches {
            if range.location > lastEnd {
                let beforeText = ns.substring(with: NSRange(location: lastEnd, length: range.location - lastEnd))
                result.append(NSAttributedString(string: beforeText, attributes: att))
            }
            let citationAttr = NSMutableAttributedString(
                attributedString: Self.renderCitationReference(
                    number: number,
                    font: font,
                    textColor: textColor,
                    kern: kern,
                    paragraphStyle: paragraphStyle,
                    renderStyle: renderStyle,
                    citationGroupIDs: resolvedCitationGroupIDs,
                    citationBadgeBgColor: citationBadgeBgColor,
                    citationBadgeTextColor: citationBadgeTextColor,
                    linkColor: linkColor
                )
            )
            result.append(citationAttr)
            lastEnd = range.location + range.length
        }
        if lastEnd < ns.length {
            let remainingText = ns.substring(with: NSRange(location: lastEnd, length: ns.length - lastEnd))
            result.append(NSAttributedString(string: remainingText, attributes: att))
        }
        if allMatches.isEmpty {
            return NSAttributedString(string: text, attributes: att)
        }
        return result
    }

    // MARK: - Attributed String → Attributed String (post-processing)

    public static func processCitationReferences(
        in attributedText: NSAttributedString,
        renderStyle: STMarkdownCitationRenderStyle,
        fallbackFont: UIFont,
        fallbackTextColor: UIColor,
        citationBadgeBgColor: UIColor? = nil,
        citationBadgeTextColor: UIColor? = nil,
        linkColor: UIColor? = nil
    ) -> NSAttributedString {
        let source = NSMutableAttributedString(attributedString: attributedText)
        let text = source.string
        guard containsCitationReference(in: text) else { return source }

        let ns = text as NSString
        let textRange = NSRange(location: 0, length: ns.length)
        let resolvedCitationGroupIDs = normalizedCitationIDs(extractCitationIDs(from: text))
        var allMatches: [(range: NSRange, number: String)] = []
        for regex in [STMarkdownCitationRegex.citationBracketSpace, STMarkdownCitationRegex.citationBracketColon, STMarkdownCitationRegex.webpageVariants] as [NSRegularExpression] {
            let matches = regex.matches(in: text, range: textRange)
            for match in matches where match.numberOfRanges >= 2 {
                let numberText = ns.substring(with: match.range(at: 1))
                allMatches.append((match.range, numberText))
            }
        }

        allMatches.sort { $0.range.location > $1.range.location }
        for (range, number) in allMatches {
            let baseLocation = min(range.location, max(source.length - 1, 0))
            let baseAttributes = source.length > 0 ? source.attributes(at: baseLocation, effectiveRange: nil) : [:]
            let font = (baseAttributes[.font] as? UIFont) ?? fallbackFont
            let textColor = (baseAttributes[.foregroundColor] as? UIColor) ?? fallbackTextColor
            let kern = (baseAttributes[.kern] as? CGFloat) ?? 0
            let paragraphStyle = (baseAttributes[.paragraphStyle] as? NSParagraphStyle) ?? NSParagraphStyle.default

            let replacement = renderCitationReference(
                number: number,
                font: font,
                textColor: textColor,
                kern: kern,
                paragraphStyle: paragraphStyle,
                renderStyle: renderStyle,
                citationGroupIDs: resolvedCitationGroupIDs,
                citationBadgeBgColor: citationBadgeBgColor,
                citationBadgeTextColor: citationBadgeTextColor,
                linkColor: linkColor
            )
            source.replaceCharacters(in: range, with: replacement)
        }

        return source
    }

    public static func containsCitationReference(in text: String) -> Bool {
        let ns = text as NSString
        let textRange = NSRange(location: 0, length: ns.length)
        for regex in [STMarkdownCitationRegex.citationBracketSpace, STMarkdownCitationRegex.citationBracketColon, STMarkdownCitationRegex.webpageVariants] as [NSRegularExpression] {
            if regex.firstMatch(in: text, range: textRange) != nil {
                return true
            }
        }
        return false
    }

    // MARK: - Unbracketed Citation Post-Processing

    /// 对 attributed string 进行 citation 后处理。可选匹配方括号，同时从全文提取所有 citation IDs 作为引用组。
    public static func processUnbracketedCitationReferences(
        in attributedText: NSAttributedString,
        renderStyle: STMarkdownCitationRenderStyle,
        fallbackFont: UIFont,
        fallbackTextColor: UIColor,
        citationBadgeBgColor: UIColor? = nil,
        citationBadgeTextColor: UIColor? = nil,
        linkColor: UIColor? = nil
    ) -> NSAttributedString {
        let source = NSMutableAttributedString(attributedString: attributedText)
        let text = source.string
        let ns = text as NSString
        let textRange = NSRange(location: 0, length: ns.length)

        // Step 1: 收集残留的 Citation:N / [Citation:N] 匹配
        var allMatches: [(range: NSRange, number: String)] = []
        for regex in [STMarkdownCitationRegex.unbracketedCitationSpace, STMarkdownCitationRegex.unbracketedCitationColon] as [NSRegularExpression] {
            let matches = regex.matches(in: text, range: textRange)
            for match in matches where match.numberOfRanges >= 2 {
                let numberText = ns.substring(with: match.range(at: 1))
                let isDuplicate = allMatches.contains { existing in
                    NSIntersectionRange(existing.range, match.range).length > 0
                }
                guard !isDuplicate else { continue }
                allMatches.append((match.range, numberText))
            }
        }

        // Step 2: 扫描已有的 citation:// link attribute
        var existingCitationLinkRanges: [(range: NSRange, number: Int, url: URL)] = []
        if source.length > 0 {
            source.enumerateAttribute(.link, in: NSRange(location: 0, length: source.length), options: []) { value, subrange, _ in
                let url: URL?
                if let u = value as? URL { url = u }
                else if let s = value as? String { url = URL(string: s) }
                else { url = nil }
                guard let resolvedURL = url, resolvedURL.scheme == "citation",
                      let host = resolvedURL.host, let number = Int(host) else { return }
                existingCitationLinkRanges.append((subrange, number, resolvedURL))
            }
        }

        guard !allMatches.isEmpty || !existingCitationLinkRanges.isEmpty else { return source }

        // Step 3: 合并所有 citation IDs
        var allIDs: [Int] = allMatches.compactMap { Int($0.number) }
        for existing in existingCitationLinkRanges {
            allIDs.append(existing.number)
        }
        let allCitationIDs = normalizedCitationIDs(allIDs)

        // Step 4: 替换残留 citation 引用
        if !allMatches.isEmpty {
            allMatches.sort { $0.range.location > $1.range.location }
            for (range, number) in allMatches {
                let baseLocation = min(range.location, max(source.length - 1, 0))
                let baseAttributes = source.length > 0 ? source.attributes(at: baseLocation, effectiveRange: nil) : [:]
                let font = (baseAttributes[.font] as? UIFont) ?? fallbackFont
                let textColor = (baseAttributes[.foregroundColor] as? UIColor) ?? fallbackTextColor
                let kern = (baseAttributes[.kern] as? CGFloat) ?? 0
                let paragraphStyle = (baseAttributes[.paragraphStyle] as? NSParagraphStyle) ?? NSParagraphStyle.default

                let replacement = renderCitationReference(
                    number: number,
                    font: font,
                    textColor: textColor,
                    kern: kern,
                    paragraphStyle: paragraphStyle,
                    renderStyle: renderStyle,
                    citationGroupIDs: allCitationIDs,
                    citationBadgeBgColor: citationBadgeBgColor,
                    citationBadgeTextColor: citationBadgeTextColor,
                    linkColor: linkColor
                )
                source.replaceCharacters(in: range, with: replacement)
            }
        }

        // Step 5: 补全已有 citation attachment 的 URL
        if !existingCitationLinkRanges.isEmpty, allCitationIDs.count > 1 {
            let updatedLength = source.length
            if updatedLength > 0 {
                source.enumerateAttribute(.link, in: NSRange(location: 0, length: updatedLength), options: []) { value, subrange, _ in
                    let url: URL?
                    if let u = value as? URL { url = u }
                    else if let s = value as? String { url = URL(string: s) }
                    else { url = nil }
                    guard let resolvedURL = url, resolvedURL.scheme == "citation",
                          let host = resolvedURL.host, let _ = Int(host) else { return }
                    if let components = URLComponents(url: resolvedURL, resolvingAgainstBaseURL: false),
                       components.queryItems?.first(where: { $0.name == "ids" }) != nil {
                        return
                    }
                    if let fullURL = makeCitationURL(number: host, citationGroupIDs: allCitationIDs) {
                        source.addAttribute(.link, value: fullURL, range: subrange)
                    }
                }
            }
        }

        return source
    }

    // MARK: - Streaming Plain Text

    public static func transformedMarkdownForStreaming(
        in text: String,
        renderStyle: STMarkdownCitationRenderStyle,
        citationGroupIDs: [Int]? = nil
    ) -> String {
        let ns = text as NSString
        let textRange = NSRange(location: 0, length: ns.length)
        let resolvedCitationGroupIDs = normalizedCitationIDs(citationGroupIDs ?? extractCitationIDs(from: text))
        var replacements: [(range: NSRange, replacement: String)] = []
        for regex in [STMarkdownCitationRegex.citationBracketSpace, STMarkdownCitationRegex.citationBracketColon, STMarkdownCitationRegex.webpageVariants] as [NSRegularExpression] {
            let matches = regex.matches(in: text, range: textRange)
            for match in matches where match.numberOfRanges >= 2 {
                let numberText = ns.substring(with: match.range(at: 1))
                replacements.append((
                    range: match.range,
                    replacement: Self.streamingReplacementText(
                        for: numberText,
                        renderStyle: renderStyle,
                        citationGroupIDs: resolvedCitationGroupIDs
                    )
                ))
            }
        }
        guard !replacements.isEmpty else { return text }
        let result = NSMutableString(string: text)
        replacements.sort { $0.range.location > $1.range.location }
        for replacement in replacements {
            result.replaceCharacters(in: replacement.range, with: replacement.replacement)
        }
        return result as String
    }

    public static func extractCitationIDs(from text: String) -> [Int] {
        let ns = text as NSString
        let textRange = NSRange(location: 0, length: ns.length)
        var ids: [Int] = []
        for regex in [STMarkdownCitationRegex.citationBracketSpace, STMarkdownCitationRegex.citationBracketColon] as [NSRegularExpression] {
            let matches = regex.matches(in: text, range: textRange)
            for match in matches where match.numberOfRanges >= 2 {
                let numberText = ns.substring(with: match.range(at: 1))
                if let number = Int(numberText) {
                    ids.append(number)
                }
            }
        }
        return normalizedCitationIDs(ids)
    }

    // MARK: - Rendering Helpers

    /// 渲染单个 citation 编号为富文本 attachment。
    public static func renderCitationAttachment(
        number: String,
        font: UIFont,
        textColor: UIColor,
        kern: CGFloat,
        paragraphStyle: NSParagraphStyle,
        renderStyle: STMarkdownCitationRenderStyle,
        citationGroupIDs: [Int] = [],
        citationBadgeBgColor: UIColor? = nil,
        citationBadgeTextColor: UIColor? = nil,
        linkColor: UIColor? = nil
    ) -> NSAttributedString {
        return Self.renderCitationReference(
            number: number,
            font: font,
            textColor: textColor,
            kern: kern,
            paragraphStyle: paragraphStyle,
            renderStyle: renderStyle,
            citationGroupIDs: citationGroupIDs,
            citationBadgeBgColor: citationBadgeBgColor,
            citationBadgeTextColor: citationBadgeTextColor,
            linkColor: linkColor
        )
    }

    public static func streamingReplacementText(
        for number: String,
        renderStyle: STMarkdownCitationRenderStyle,
        citationGroupIDs: [Int]
    ) -> String {
        switch renderStyle {
        case .webpageLabel:
            return "网页[\(number)]"
        case .circleNumber:
            return STMarkdownCitationRegex.circledNumberText(for: number) ?? "[\(number)]"
        }
    }

    // MARK: - Private

    private static func renderCitationReference(
        number: String,
        font: UIFont,
        textColor: UIColor,
        kern: CGFloat,
        paragraphStyle: NSParagraphStyle,
        renderStyle: STMarkdownCitationRenderStyle,
        citationGroupIDs: [Int],
        citationBadgeBgColor: UIColor? = nil,
        citationBadgeTextColor: UIColor? = nil,
        linkColor: UIColor? = nil
    ) -> NSAttributedString {
        switch renderStyle {
        case .circleNumber:
            let attachment = STMarkdownNumberBadgeAttachment(
                numberText: number,
                font: font,
                textColor: citationBadgeTextColor ?? textColor,
                backgroundColor: citationBadgeBgColor ?? UIColor.systemGray
            )
            let citationAttr = NSMutableAttributedString(attachment: attachment)
            if let link = Self.makeCitationURL(number: number, citationGroupIDs: citationGroupIDs) {
                citationAttr.addAttribute(.link, value: link, range: NSRange(location: 0, length: citationAttr.length))
            }
            citationAttr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: citationAttr.length))
            return citationAttr
        case .webpageLabel:
            var attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor,
                .kern: kern,
                .paragraphStyle: paragraphStyle,
            ]
            if let link = Self.makeCitationURL(number: number, citationGroupIDs: citationGroupIDs) {
                attributes[.link] = link
                attributes[.foregroundColor] = linkColor ?? textColor
            }
            return NSAttributedString(string: "网页[\(number)]", attributes: attributes)
        }
    }

    private static func normalizedCitationIDs(_ ids: [Int]) -> [Int] {
        var seen = Set<Int>()
        var result: [Int] = []
        for id in ids where id > 0 {
            if seen.insert(id).inserted {
                result.append(id)
            }
        }
        return result
    }

    private static func makeCitationURL(number: String, citationGroupIDs: [Int]) -> URL? {
        guard !number.isEmpty else { return nil }
        var components = URLComponents()
        components.scheme = "citation"
        components.host = number
        if !citationGroupIDs.isEmpty {
            components.queryItems = [
                URLQueryItem(
                    name: "ids",
                    value: citationGroupIDs.map(String.init).joined(separator: ",")
                )
            ]
        }
        return components.url
    }
}