//
//  STURL.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/1/21.
//

import Foundation

public extension URL {

    /// 解析查询串为字典；支持无值参数（会得到空字符串）
    /// 例如：`https://a.com?x=1&y&z=%E4%B8%AD` -> `["x": "1", "y": "", "z": "中"]`
    var queryComponents: [String: String] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let items = components.queryItems, !items.isEmpty
        else {
            return [:]
        }
        var result: [String: String] = [:]
        for item in items where !item.name.isEmpty {
            result[item.name] = item.value ?? ""
        }
        return result
    }

    /// 追加查询参数并返回新 URL；已存在的同名参数会追加而不是覆盖
    /// - Parameter parameters: 要追加的键值对
    /// - Returns: 新 URL，解析失败返回 nil
    func appendingQueryParameters(_ parameters: [String: String]) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }
        var items = components.queryItems ?? []
        for (key, value) in parameters {
            items.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = items
        return components.url
    }

    /// 返回移除指定参数后的新 URL
    /// - Parameter names: 要移除的参数名集合
    func removingQueryParameters(named names: [String]) -> URL? {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }
        components.queryItems = components.queryItems?.filter { !names.contains($0.name) }
        return components.url
    }
}
