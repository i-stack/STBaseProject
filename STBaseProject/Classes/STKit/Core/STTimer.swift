//
//  STTimer.swift
//  STBaseProject
//
//  Created by stack on 2018/01/22.
//

import UIKit

public class STTimer: NSObject {
    
    // MARK: - Static Properties
    private static let semaphore = DispatchSemaphore(value: 1)
    private static var timerDict: [String: DispatchSourceTimer] = [:]
    
    // MARK: - Private Properties
    private weak var target: AnyObject?
    private var timer: DispatchSourceTimer?
    private var secondsRepeating: Double = 1.0
    private var secondsRemaining: Int = 10
    private let queue = DispatchQueue(label: "com.STBaseProject.timer", qos: .userInteractive)
    private var isTimerActive: Bool = false
    
    // MARK: - Initializers
    public init(aTarget: AnyObject) {
        super.init()
        self.target = aTarget
    }
    
    public init(seconds: Int, repeating: Double) {
        super.init()
        self.secondsRemaining = seconds
        self.secondsRepeating = repeating
    }
    
    // MARK: - Deinitializer
    deinit {
        st_countdownTimerCancel()
        STLog("🗑 STTimer deinit - 资源已释放")
    }
    
    // MARK: - Message Forwarding
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return self.target
    }
    
    /// 开始倒计时
    public func st_countdownTimerStart(completion: @escaping (Int, Bool) -> Void) {
        st_countdownTimerCancel()
        
        // 创建高精度定时器，使用 .userInteractive QoS 确保精确计时
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer?.schedule(deadline: .now(), repeating: .milliseconds(Int(secondsRepeating * 1000)))
        timer?.setEventHandler { [weak self] in
            guard let strongSelf = self, strongSelf.isTimerActive else { return }
            if strongSelf.secondsRemaining > 0 {
                DispatchQueue.main.async {
                    completion(strongSelf.secondsRemaining, false)
                }
                STLog("⏳ 倒计时：\(strongSelf.secondsRemaining) 秒")
                strongSelf.secondsRemaining -= 1
            } else {
                strongSelf.st_countdownTimerCancel()
                STLog("✅ 倒计时结束，执行后续操作...")
                DispatchQueue.main.async {
                    completion(0, true)
                }
            }
        }
        isTimerActive = true
        timer?.resume()
        STLog("🚀 倒计时开始，总时长：\(secondsRemaining) 秒，间隔：\(secondsRepeating) 秒")
    }
    
    /// 取消倒计时并释放资源
    public func st_countdownTimerCancel() {
        guard isTimerActive else { return }
        isTimerActive = false
        timer?.cancel()
        timer = nil
        STLog("⏹ 倒计时取消，资源已释放")
    }

    /// 创建高精度定时器，避免 runloop mode 影响
    @discardableResult
    public class func st_scheduledTimer(withTimeInterval interval: Int, repeats: Bool, async: Bool, block: @escaping (String) -> Void) -> String {
        return self.st_scheduledTimer(afterDelay: 0, withTimeInterval: interval, repeats: repeats, async: async, block: block)
    }
    
    /// 创建延迟执行的高精度定时器
    @discardableResult
    public class func st_scheduledTimer(afterDelay: Int, withTimeInterval interval: Int, repeats: Bool, async: Bool, block: @escaping (String) -> Void) -> String {
        guard interval > 0 else { 
            STLog("⚠️ 定时器间隔必须大于0")
            return "" 
        }
        let queue = async ? DispatchQueue.global(qos: .userInteractive) : DispatchQueue.main
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        self.semaphore.wait()
        let name = "timer_\(UUID().uuidString)"
        self.timerDict[name] = timer
        self.semaphore.signal()
        // 使用毫秒级精度
        timer.schedule(deadline: .now() + .milliseconds(afterDelay * 1000), 
                      repeating: .milliseconds(interval * 1000))
        timer.setEventHandler { [weak timer] in
            DispatchQueue.main.async {
                block(name)
                if !repeats {
                    self.st_cancelTask(name: name)
                }
            }
        }
        timer.resume()
        STLog("⏰ 定时器创建成功：\(name)，间隔：\(interval)秒，重复：\(repeats)")
        return name
    }
    
    /// 取消指定名称的定时器任务
    public class func st_cancelTask(name: String) {
        guard !name.isEmpty else { 
            STLog("⚠️ 定时器名称不能为空")
            return 
        }
        self.semaphore.wait()
        defer { self.semaphore.signal() }
        if let timer = self.timerDict[name] {
            timer.cancel()
            self.timerDict.removeValue(forKey: name)
            STLog("🗑 定时器已取消：\(name)")
        } else {
            STLog("⚠️ 未找到指定定时器：\(name)")
        }
    }
    
    /// 取消所有定时器任务
    public class func st_cancelAllTasks() {
        self.semaphore.wait()
        defer { self.semaphore.signal() }
        for (name, timer) in self.timerDict {
            timer.cancel()
            STLog("🗑 取消定时器：\(name)")
        }
        self.timerDict.removeAll()
        STLog("🧹 所有定时器已清理完成")
    }
}
