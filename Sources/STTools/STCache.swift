//
//  STCache.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/3/16.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// 轻量级内存缓存
///
/// - 线程安全：基于并发队列+栅栏保护内部字典
/// - 自动在收到内存警告时清空（仅 iOS）
/// - 可选容量上限，达到上限时淘汰最近最少使用的元素
public final class STCache<Key: Hashable, Value> {

    private var store: [Key: Value] = [:]
    private var keysByRecentUse: [Key] = []
    private let queue = DispatchQueue(label: "com.stbaseproject.cache", attributes: .concurrent)
    private var limit: Int = 0

#if canImport(UIKit)
    private var memoryWarningObserver: NSObjectProtocol?
#endif

    /// 初始化
    /// - Parameter itemLimit: 元素数量上限，0 表示无限
    public init(itemLimit: Int = 0) {
        self.limit = itemLimit
        registerMemoryWarningObserver()
    }

    deinit {
#if canImport(UIKit)
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
#endif
    }

    /// 元素数量
    public var count: Int {
        queue.sync { store.count }
    }

    /// 元素上限（0 表示无限）
    public var itemLimit: Int {
        get { queue.sync { limit } }
        set {
            queue.async(flags: .barrier) {
                self.limit = max(0, newValue)
                self.trimToLimitIfNeeded()
            }
        }
    }

    public subscript(key: Key) -> Value? {
        get { object(forKey: key) }
        set {
            if let newValue {
                setObject(newValue, forKey: key)
            } else {
                removeObject(forKey: key)
            }
        }
    }

    public func object(forKey key: Key) -> Value? {
        queue.sync(flags: .barrier) {
            guard let value = store[key] else { return nil }
            markAsRecentlyUsed(key)
            return value
        }
    }

    public func setObject(_ object: Value, forKey key: Key) {
        queue.async(flags: .barrier) {
            self.store[key] = object
            self.markAsRecentlyUsed(key)
            self.trimToLimitIfNeeded()
        }
    }

    public func removeObject(forKey key: Key) {
        queue.async(flags: .barrier) {
            self.store.removeValue(forKey: key)
            self.keysByRecentUse.removeAll { $0 == key }
        }
    }

    public func removeAll() {
        queue.async(flags: .barrier) {
            self.store.removeAll()
            self.keysByRecentUse.removeAll()
        }
    }

    /// 获取当前内容的快照（拷贝）
    public var snapshot: [Key: Value] {
        queue.sync { store }
    }

    private func markAsRecentlyUsed(_ key: Key) {
        keysByRecentUse.removeAll { $0 == key }
        keysByRecentUse.append(key)
    }

    private func trimToLimitIfNeeded() {
        guard limit > 0 else { return }
        while store.count > limit, let key = keysByRecentUse.first {
            keysByRecentUse.removeFirst()
            store.removeValue(forKey: key)
        }
    }

    private func registerMemoryWarningObserver() {
#if canImport(UIKit) && !os(watchOS)
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.removeAll()
        }
#endif
    }
}
