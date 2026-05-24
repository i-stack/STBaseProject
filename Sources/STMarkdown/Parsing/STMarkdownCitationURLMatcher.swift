//
//  STMarkdownCitationURLMatcher.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public struct STMarkdownCitationURLMatcher: Sendable {
    private static let markdownLinkRegex = try! NSRegularExpression(
        pattern: #"\[([^\]]+)\]\(([^)]+)\)"#,
        options: []
    )

    private let citationURLMapping: [String: Int]
    private let citationHostMapping: [String: [Int]]
    private let citationRegisteredDomainMapping: [String: [Int]]

    public init(citationURLMapping: [String: Int]) {
        self.citationURLMapping = citationURLMapping
        let maps = Self.makeCitationHostMaps(from: citationURLMapping)
        self.citationHostMapping = maps.host
        self.citationRegisteredDomainMapping = maps.registeredDomain
    }

    public func resolveCitationID(for url: String) -> Int? {
        if let id = self.citationURLMapping[url] { return id }
        let trimmed = url.hasSuffix("/") ? String(url.dropLast()) : url + "/"
        if let id = self.citationURLMapping[trimmed] { return id }

        let normalized: String
        if url.hasPrefix("https://") {
            normalized = "http://" + url.dropFirst("https://".count)
        } else if url.hasPrefix("http://") {
            normalized = "https://" + url.dropFirst("http://".count)
        } else {
            normalized = url
        }
        if normalized != url {
            if let id = self.citationURLMapping[normalized] { return id }
            let normalizedTrimmed = normalized.hasSuffix("/") ? String(normalized.dropLast()) : normalized + "/"
            if let id = self.citationURLMapping[normalizedTrimmed] { return id }
        }

        if var comps = URLComponents(string: url), (comps.query != nil || comps.fragment != nil) {
            comps.query = nil
            comps.fragment = nil
            if let strippedURL = comps.string {
                if let id = self.citationURLMapping[strippedURL] { return id }
                let strippedTrimmed = strippedURL.hasSuffix("/") ? String(strippedURL.dropLast()) : strippedURL + "/"
                if let id = self.citationURLMapping[strippedTrimmed] { return id }
            }
        }

        for (mappingURL, citationID) in self.citationURLMapping {
            if var mappingComps = URLComponents(string: mappingURL),
               (mappingComps.query != nil || mappingComps.fragment != nil) {
                mappingComps.query = nil
                mappingComps.fragment = nil
                if let strippedMappingURL = mappingComps.string,
                   strippedMappingURL == url || strippedMappingURL == trimmed {
                    return citationID
                }
            }
        }

        if let comps = URLComponents(string: url), let host = comps.host?.lowercased() {
            if let ids = self.citationHostMapping[host], ids.count == 1 {
                return ids[0]
            }
            let registeredDomain = Self.extractRegisteredDomain(from: host)
            if registeredDomain != host,
               let ids = self.citationRegisteredDomainMapping[registeredDomain],
               let firstID = ids.first {
                return firstID
            }
        }
        return nil
    }

    public func replaceMarkdownLinksWithCitations(in text: String) -> String {
        guard !self.citationURLMapping.isEmpty else { return text }
        let ns = text as NSString
        let fullRange = NSRange(location: 0, length: ns.length)
        let matches = Self.markdownLinkRegex.matches(in: text, range: fullRange)
        guard !matches.isEmpty else { return text }
        let result = NSMutableString(string: text)
        for match in matches.reversed() {
            guard match.numberOfRanges >= 3 else { continue }
            let urlRange = match.range(at: 2)
            var linkURL = ns.substring(with: urlRange)
            linkURL = linkURL.replacingOccurrences(of: "\\/", with: "/")
            if let citationID = self.resolveCitationID(for: linkURL) {
                result.replaceCharacters(in: match.range, with: "[Citation:\(citationID)]")
            }
        }
        return result as String
    }

    private static func extractRegisteredDomain(from host: String) -> String {
        let parts = host.split(separator: ".").map(String.init)
        guard parts.count >= 2 else { return host }
        let doubleSuffixTLDs: Set<String> = [
            "co.uk", "co.jp", "co.kr", "co.nz", "co.za", "co.in",
            "com.cn", "com.hk", "com.tw", "com.au", "com.br", "com.sg",
            "net.cn", "org.cn", "gov.cn", "ac.uk", "org.uk",
        ]
        if parts.count >= 3 {
            let lastTwo = parts.suffix(2).joined(separator: ".")
            if doubleSuffixTLDs.contains(lastTwo) {
                return parts.suffix(3).joined(separator: ".")
            }
        }
        return parts.suffix(2).joined(separator: ".")
    }

    private static func makeCitationHostMaps(
        from citationURLMapping: [String: Int]
    ) -> (host: [String: [Int]], registeredDomain: [String: [Int]]) {
        var hostMap: [String: [Int]] = [:]
        var domainMap: [String: [Int]] = [:]
        for (urlString, citationID) in citationURLMapping {
            guard let comps = URLComponents(string: urlString), let host = comps.host?.lowercased() else { continue }
            hostMap[host, default: []].append(citationID)
            let registeredDomain = Self.extractRegisteredDomain(from: host)
            domainMap[registeredDomain, default: []].append(citationID)
        }
        for host in hostMap.keys {
            if let ids = hostMap[host] {
                hostMap[host] = Array(Set(ids)).sorted()
            }
        }
        for domain in domainMap.keys {
            if let ids = domainMap[domain] {
                domainMap[domain] = Array(Set(ids)).sorted()
            }
        }
        return (hostMap, domainMap)
    }
}
