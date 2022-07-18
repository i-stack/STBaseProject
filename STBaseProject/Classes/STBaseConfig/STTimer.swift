//
//  STTimer.swift
//  STBaseProject
//
//  Created by stack on 2018/01/22.
//  Copyright © 2018 ST. All rights reserved.
//

import UIKit

public class STTimer: NSObject {

    static var timerDict: [String: DispatchSourceTimer] = [String: DispatchSourceTimer]()
    static let semaphore = DispatchSemaphore.init(value: 1)
    private weak var target: AnyObject?

    public init(aTarget: AnyObject) {
        super.init()
        self.target = aTarget
    }

    public override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return self.target
    }
}

// MARK: - GCD
extension STTimer {

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
