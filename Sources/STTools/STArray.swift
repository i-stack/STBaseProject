//
//  STArray.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/1/21.
//

import Foundation

public extension Array {

    /// 安全下标访问：越界时返回 nil
    /// - Parameter index: 元素下标
    /// - Returns: 元素或 nil
    func safeElement(at index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }

    /// 安全下标访问：越界时返回默认值
    /// - Parameters:
    ///   - index: 元素下标
    ///   - defaultValue: 越界时使用的默认值
    func element(at index: Int, default defaultValue: Element) -> Element {
        safeElement(at: index) ?? defaultValue
    }

    /// 按索引提取多个元素；越界的索引会被忽略
    /// - Parameter indices: 要提取的下标集合
    /// - Returns: 新的数组
    func elements(at indices: [Int]) -> [Element] {
        indices.compactMap { safeElement(at: $0) }
    }

    /// 将数组切分为固定大小的子数组
    /// - Parameter size: 每段长度（必须 > 0）
    /// - Returns: 切分后的二维数组
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var chunks: [[Element]] = []
        chunks.reserveCapacity((count + size - 1) / size)
        var index = 0
        while index < count {
            let end = Swift.min(index + size, count)
            chunks.append(Array(self[index..<end]))
            index = end
        }
        return chunks
    }
}

public extension Array where Element: Equatable {
    /// 去除重复元素并保持顺序
    var uniqued: [Element] {
        var seen: [Element] = []
        seen.reserveCapacity(count)
        for element in self where !seen.contains(element) {
            seen.append(element)
        }
        return seen
    }
}

public extension RangeReplaceableCollection {
    /// 将 `fromIndex` 的元素移动到 `toIndex`
    /// - Parameters:
    ///   - fromIndex: 源下标（基于 startIndex 的偏移量）
    ///   - toIndex: 目标下标（基于 startIndex 的偏移量）
    mutating func moveElement(from fromIndex: Int, to toIndex: Int) {
        guard fromIndex != toIndex,
              fromIndex >= 0, fromIndex < count,
              toIndex >= 0, toIndex < count
        else {
            return
        }
        let fromIdx = index(startIndex, offsetBy: fromIndex)
        let element = remove(at: fromIdx)
        let toIdx = index(startIndex, offsetBy: toIndex)
        insert(element, at: toIdx)
    }
}
