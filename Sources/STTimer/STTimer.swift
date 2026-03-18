//
//  STTimer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import Foundation

public final class STTimer {

    public typealias STTimerHandler = (STTimer) -> Void

    private enum State {
        case idle
        case running
        case paused
    }

    private var timer: DispatchSourceTimer?
    private let queue: DispatchQueue
    private let interval: TimeInterval
    private let leeway: DispatchTimeInterval
    private var state: State = .idle
    private var handler: STTimerHandler?
    public private(set) var fireCount: Int = 0

    /// - Parameters:
    ///   - interval: 触发间隔（秒）
    ///   - leeway: 系统允许的最大延迟抖动，默认 10ms（越小精度越高，越耗电）
    ///   - queue: 内部 GCD 队列，默认创建独立串行队列
    public init(interval: TimeInterval, leeway: DispatchTimeInterval = .milliseconds(10), queue: DispatchQueue = DispatchQueue(label: "com.st.timer.queue", qos: .userInteractive)) {
        precondition(interval > 0, "STTimer: interval 必须大于 0")
        self.interval = interval
        self.leeway = leeway
        self.queue = queue
    }

    deinit {
        if self.state == .paused {
            self.timer?.resume()
        }
        self.timer?.cancel()
    }

    /// 启动定时器
    /// - Parameters:
    ///   - immediately: 是否立即触发一次，默认 false（等待第一个 interval 后触发）
    ///   - handler: 触发回调，在主线程执行，参数为定时器自身
    public func start(immediately: Bool = false, handler: @escaping STTimerHandler) {
        self.queue.async { [weak self] in
            guard let self, self.state == .idle else { return }
            self.handler = handler
            self.fireCount = 0
            self.createAndResumeTimer(immediately: immediately)
            self.state = .running
        }
    }

    /// 暂停（可通过 resume 恢复）
    public func pause() {
        self.queue.async { [weak self] in
            guard let self, self.state == .running else { return }
            self.timer?.suspend()
            self.state = .paused
        }
    }

    /// 恢复已暂停的定时器
    public func resume() {
        self.queue.async { [weak self] in
            guard let self, self.state == .paused else { return }
            self.timer?.resume()
            self.state = .running
        }
    }

    /// 停止并重置
    public func stop() {
        self.queue.async { [weak self] in
            self?.internalStop()
        }
    }

    public var isRunning: Bool {
        self.queue.sync { state == .running }
    }

    public var isPaused: Bool {
        self.queue.sync { state == .paused }
    }

    private func createAndResumeTimer(immediately: Bool) {
        self.timer?.cancel()
        let source = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
        let deadline: DispatchTime = immediately ? .now() : .now() + self.interval
        source.schedule(deadline: deadline, repeating: .milliseconds(Int(self.interval * 1000)), leeway: self.leeway)
        source.setEventHandler { [weak self] in
            self?.handleFire()
        }
        self.timer = source
        source.resume()
    }

    private func handleFire() {
        guard self.state == .running else { return }
        self.fireCount += 1
        let handler = self.handler
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            handler?(self)
        }
    }

    private func internalStop() {
        if self.state == .paused {
            self.timer?.resume()
        }
        self.timer?.cancel()
        self.timer = nil
        self.state = .idle
        self.fireCount = 0
    }
}
