//
//  STTimer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2024/01/01.
//

import Foundation

/// 基于 DispatchSourceTimer 的周期性定时器
///
/// 特性：
/// - 不依赖 RunLoop，滚动期间正常触发
/// - 不持有调用方（无循环引用）
/// - 支持暂停 / 恢复 / 停止
/// - 回调默认派发到主线程
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

    /// 已触发次数（仅在回调线程读取时保证准确）
    public private(set) var fireCount: Int = 0

    // MARK: - Init

    /// - Parameters:
    ///   - interval: 触发间隔（秒）
    ///   - leeway: 系统允许的最大延迟抖动，默认 10ms（越小精度越高，越耗电）
    ///   - queue: 内部 GCD 队列，默认创建独立串行队列
    public init(
        interval: TimeInterval,
        leeway: DispatchTimeInterval = .milliseconds(10),
        queue: DispatchQueue = DispatchQueue(label: "com.st.timer.queue", qos: .userInteractive)
    ) {
        precondition(interval > 0, "STTimer: interval 必须大于 0")
        self.interval = interval
        self.leeway = leeway
        self.queue = queue
    }

    deinit {
        if state == .paused {
            timer?.resume()
        }
        timer?.cancel()
    }

    // MARK: - Public API

    /// 启动定时器
    /// - Parameters:
    ///   - immediately: 是否立即触发一次，默认 false（等待第一个 interval 后触发）
    ///   - handler: 触发回调，在主线程执行，参数为定时器自身
    public func start(immediately: Bool = false, handler: @escaping STTimerHandler) {
        queue.async { [weak self] in
            guard let self, self.state == .idle else { return }
            self.handler = handler
            self.fireCount = 0
            self.createAndResumeTimer(immediately: immediately)
            self.state = .running
        }
    }

    /// 暂停（可通过 resume 恢复）
    public func pause() {
        queue.async { [weak self] in
            guard let self, self.state == .running else { return }
            self.timer?.suspend()
            self.state = .paused
        }
    }

    /// 恢复已暂停的定时器
    public func resume() {
        queue.async { [weak self] in
            guard let self, self.state == .paused else { return }
            self.timer?.resume()
            self.state = .running
        }
    }

    /// 停止并重置
    public func stop() {
        queue.async { [weak self] in
            self?.internalStop()
        }
    }

    public var isRunning: Bool {
        queue.sync { state == .running }
    }

    public var isPaused: Bool {
        queue.sync { state == .paused }
    }

    // MARK: - Private

    private func createAndResumeTimer(immediately: Bool) {
        timer?.cancel()
        let source = DispatchSource.makeTimerSource(flags: [], queue: queue)
        let deadline: DispatchTime = immediately ? .now() : .now() + interval
        source.schedule(
            deadline: deadline,
            repeating: .milliseconds(Int(interval * 1000)),
            leeway: leeway
        )
        source.setEventHandler { [weak self] in
            self?.handleFire()
        }
        timer = source
        source.resume()
    }

    private func handleFire() {
        guard state == .running else { return }
        fireCount += 1
        let handler = self.handler
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            handler?(self)
        }
    }

    private func internalStop() {
        if state == .paused {
            timer?.resume()
        }
        timer?.cancel()
        timer = nil
        state = .idle
        fireCount = 0
    }
}
