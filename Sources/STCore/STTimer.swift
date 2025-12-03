//
//  STTimer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/01/22.
//

import UIKit

public class STTimer: NSObject {

    private weak var target: AnyObject?
    private var timer: DispatchSourceTimer?
    private var isTimerActive: Bool = false
    private var secondsRemaining: Int = 10
    private var secondsRepeating: Double = 1.0
    private static let semaphore = DispatchSemaphore(value: 1)
    private static var timerDict: [String: DispatchSourceTimer] = [:]
    private let queue = DispatchQueue(label: "com.STBaseProject.timer", qos: .userInteractive)

    public init(aTarget: AnyObject) {
        super.init()
        self.target = aTarget
    }
    
    public init(seconds: Int, repeating: Double) {
        super.init()
        self.secondsRemaining = seconds
        self.secondsRepeating = repeating
    }
    
    deinit {
        st_countdownTimerCancel()
    }
    
    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return self.target
    }
    
    /// 开始倒计时
    public func st_countdownTimerStart(completion: @escaping (Int, Bool) -> Void) {
        st_countdownTimerCancel()
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer?.schedule(deadline: .now(), repeating: .milliseconds(Int(secondsRepeating * 1000)))
        timer?.setEventHandler { [weak self] in
            guard let strongSelf = self, strongSelf.isTimerActive else { return }
            if strongSelf.secondsRemaining > 0 {
                DispatchQueue.main.async {
                    completion(strongSelf.secondsRemaining, false)
                }
                strongSelf.secondsRemaining -= 1
            } else {
                strongSelf.st_countdownTimerCancel()
                DispatchQueue.main.async {
                    completion(0, true)
                }
            }
        }
        isTimerActive = true
        timer?.resume()
    }
    
    /// 取消倒计时并释放资源
    public func st_countdownTimerCancel() {
        guard isTimerActive else { return }
        isTimerActive = false
        timer?.cancel()
        timer = nil
    }

    /// 创建高精度定时器，避免 runloop mode 影响
    @discardableResult
    public class func st_scheduledTimer(withTimeInterval interval: Double, repeats: Bool, async: Bool, block: @escaping (String) -> Void) -> String {
        return self.st_scheduledTimer(afterDelay: 0, withTimeInterval: interval, repeats: repeats, async: async, block: block)
    }
    
    /// 创建延迟执行的高精度定时器
    @discardableResult
    public class func st_scheduledTimer(afterDelay: Double, withTimeInterval interval: Double, repeats: Bool, async: Bool, block: @escaping (String) -> Void) -> String {
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
        timer.schedule(deadline: .now() + .milliseconds(Int(afterDelay * 1000)),
                      repeating: .milliseconds(Int(interval * 1000)))
        timer.setEventHandler {
            DispatchQueue.main.async {
                block(name)
                if !repeats {
                    self.st_cancelTask(name: name)
                }
            }
        }
        timer.resume()
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
        } else {
            STLog("⚠️ 未找到指定定时器：\(name)")
        }
    }
    
    /// 取消所有定时器任务
    public class func st_cancelAllTasks() {
        self.semaphore.wait()
        defer { self.semaphore.signal() }
        for (_, timer) in self.timerDict {
            timer.cancel()
        }
        self.timerDict.removeAll()
        STLog("🧹 所有定时器已清理完成")
    }
}
