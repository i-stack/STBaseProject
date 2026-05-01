//
//  STMarkdownRefreshableAttachment.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

/// 具备"就绪后需刷新宿主 TextView"能力的异步 attachment。
/// 约束所有多播逻辑统一走 `addDisplayObserver` / `removeDisplayObserver`，
/// 而不是直接赋值某个闭包属性，避免多消费者（同一 attachment 被多个 TextView 挂载）
/// 场景下后绑者覆盖前绑者。
protocol STMarkdownRefreshableAttachment: NSTextAttachment {
    /// 注册一个刷新观察者。返回的 token 被销毁或显式 `invalidate()` 时自动解除注册。
    /// - Parameter observer: 可能在任意线程触发，接收方需自己派发回主线程（通常由
    ///   `STMarkdownAttachmentRefreshSupport` 完成）。
    func addDisplayObserver(_ observer: @escaping () -> Void) -> STMarkdownRefreshObservation
}

/// `addDisplayObserver` 返回的订阅凭证。
/// 销毁/失效后对应 observer 不再收到通知，可用于跨 TextView 切换时的解绑。
final class STMarkdownRefreshObservation {
    private let invalidateHandler: () -> Void
    private var isInvalidated = false
    private let lock = NSLock()

    init(invalidate: @escaping () -> Void) {
        self.invalidateHandler = invalidate
    }

    func invalidate() {
        self.lock.lock()
        let shouldRun = self.isInvalidated == false
        self.isInvalidated = true
        self.lock.unlock()
        if shouldRun {
            self.invalidateHandler()
        }
    }

    deinit {
        self.invalidate()
    }
}

/// 多播订阅容器，线程安全。`STMarkdownAsyncImageAttachment` 内部持有一份。
final class STMarkdownRefreshObserverRegistry {
    private struct Entry {
        let id: UUID
        let observer: () -> Void
    }

    private let lock = NSLock()
    private var entries: [Entry] = []

    /// 注册观察者，返回用于移除的 token。
    func add(_ observer: @escaping () -> Void) -> STMarkdownRefreshObservation {
        let id = UUID()
        self.lock.lock()
        self.entries.append(Entry(id: id, observer: observer))
        self.lock.unlock()
        return STMarkdownRefreshObservation { [weak self] in
            self?.remove(id: id)
        }
    }

    /// 通知所有观察者。持锁时只拷贝数组，实际回调在锁外触发，避免重入死锁。
    func notify() {
        self.lock.lock()
        let snapshot = self.entries
        self.lock.unlock()
        for entry in snapshot {
            entry.observer()
        }
    }

    private func remove(id: UUID) {
        self.lock.lock()
        self.entries.removeAll { $0.id == id }
        self.lock.unlock()
    }
}
