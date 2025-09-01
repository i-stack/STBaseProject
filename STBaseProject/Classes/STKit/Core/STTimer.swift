//
//  STTimer.swift
//  STBaseProject
//
//  Created by stack on 2018/01/22.
//

import UIKit

public class STTimer: NSObject {

    static let semaphore = DispatchSemaphore.init(value: 1)
    static var timerDict: [String: DispatchSourceTimer] = [String: DispatchSourceTimer]()
    
    private weak var target: AnyObject?
    private var timer: DispatchSourceTimer?
    private var secondsRepeating: Double = 1
    private var secondsRemaining: Int = 10
    private let queue = DispatchQueue(label: "com.STBaseProject.timer")

    public init(aTarget: AnyObject) {
        super.init()
        self.target = aTarget
    }

    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return self.target
    }
    
    public init(seconds: Int, repeating: Double) {
        super.init()
        self.secondsRemaining = seconds
        self.secondsRepeating = repeating
    }
    
    public func st_countdownTimerStart(completion: @escaping (Int, Bool) -> Void) {
        timer?.cancel()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: self.secondsRepeating)
        timer?.setEventHandler { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.secondsRemaining > 0 {
                DispatchQueue.main.async {
                    completion(strongSelf.secondsRemaining, false)
                }
                STLog("⏳ 倒计时：\(strongSelf.secondsRemaining) 秒")
                strongSelf.secondsRemaining -= 1
            } else {
                strongSelf.timer?.cancel()
                STLog("✅ 倒计时结束，执行后续操作...")
                DispatchQueue.main.async {
                    completion(0, true)
                }
            }
        }
        timer?.resume()
    }
    
    public func st_countdownTimerCancel() {
        timer?.cancel()
        timer = nil
        STLog("⏹ 倒计时取消")
    }

    @discardableResult
    public class func st_scheduledTimer(withTimeInterval interval: Int, repeats: Bool, async: Bool, block: @escaping (String) -> Void) -> String {
        self.st_scheduledTimer(afterDelay: 0, withTimeInterval: interval, repeats: repeats, async: async, block: block)
    }
    
    @discardableResult
    public class func st_scheduledTimer(afterDelay: Int, withTimeInterval interval: Int, repeats: Bool, async: Bool, block: @escaping (String) -> Void) -> String {
        if interval <= 0, repeats == true { return "" }
       
        let queue = async ? DispatchQueue.global() : DispatchQueue.main
        let timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: queue)
        
        self.semaphore.wait()
        let name = timer.description
        self.timerDict[name] = timer
        self.semaphore.signal()
        timer.schedule(deadline: .now() + Double(afterDelay), repeating: .seconds(interval))
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
    
    public class func st_cancelTask(name: String) {
        if name.count > 0 {
            self.semaphore.wait()
            if let timer = self.timerDict[name] {
                timer.cancel()
                self.timerDict.removeValue(forKey: name)
            }
            self.semaphore.signal()
        }
    }
}
