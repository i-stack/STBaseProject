//
//  STConcurrentDictionary.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/3/16.
//

import Foundation

/// 线程安全的字典容器
///
/// - 读通过 `dispatch_sync` 并发执行
/// - 写通过 `dispatch_barrier_async` 串行化
public final class STConcurrentDictionary<Key: Hashable, Value> {

    private var store: [Key: Value]
    private let queue = DispatchQueue(
        label: "com.stbaseproject.concurrent-dictionary",
        attributes: .concurrent
    )

    public init(_ initial: [Key: Value] = [:]) {
        self.store = initial
    }

    public var count: Int {
        queue.sync { store.count }
    }

    public var isEmpty: Bool {
        queue.sync { store.isEmpty }
    }

    /// 获取当前内容快照（拷贝）
    public var snapshot: [Key: Value] {
        queue.sync { store }
    }

    public var keys: [Key] {
        queue.sync { Array(store.keys) }
    }

    public var values: [Value] {
        queue.sync { Array(store.values) }
    }

    public subscript(key: Key) -> Value? {
        get { queue.sync { store[key] } }
        set {
            queue.async(flags: .barrier) {
                if let newValue {
                    self.store[key] = newValue
                } else {
                    self.store.removeValue(forKey: key)
                }
            }
        }
    }

    public func removeValue(forKey key: Key) {
        queue.async(flags: .barrier) {
            self.store.removeValue(forKey: key)
        }
    }

    public func removeAll() {
        queue.async(flags: .barrier) {
            self.store.removeAll()
        }
    }

    /// 以只读方式遍历快照
    public func forEach(_ body: (Key, Value) -> Void) {
        let currentSnapshot = snapshot
        for (key, value) in currentSnapshot {
            body(key, value)
        }
    }

    /// 原子地更新一个值：回调内对字典的修改作为整个屏障执行
    /// - Parameter body: 接收可变字典
    public func modify(_ body: (inout [Key: Value]) -> Void) {
        queue.sync(flags: .barrier) {
            body(&store)
        }
    }
}
