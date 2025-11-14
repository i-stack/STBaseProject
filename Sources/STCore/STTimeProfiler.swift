//
//  STTimeProfiler.swift
//  STBaseProject
//
//  Created by stack on 2024/01/01.
//

import Foundation
import QuartzCore

// MARK: - 耗时打印工具类
public class STTimeProfiler {
    
    private static var startTimes: [String: CFTimeInterval] = [:]
    private static let lock = NSLock()
    
    /// 开始计时
    /// - Parameter tag: 计时任务标识，用于区分不同的计时任务
    public class func st_start(tag: String = "default") {
        lock.lock()
        defer { lock.unlock() }
        let startTime = CACurrentMediaTime()
        startTimes[tag] = startTime
        print("⏱️ [\(tag)] 开始计时")
    }
    
    /// 结束计时并打印耗时
    /// - Parameters:
    ///   - tag: 计时任务标识，默认为 "default"
    ///   - message: 自定义消息，会显示在耗时信息中
    public class func st_end(tag: String = "default", message: String? = nil) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let startTime = startTimes[tag] else {
            print("⚠️ [\(tag)] 未找到对应的开始时间，请先调用 st_start(tag:)")
            return
        }
        
        let endTime = CACurrentMediaTime()
        let duration = endTime - startTime
        startTimes.removeValue(forKey: tag)
        
        let messageText = message != nil ? " - \(message!)" : ""
        let durationText = st_formatDuration(duration)
        print("✅ [\(tag)] 耗时: \(durationText)\(messageText)")
    }
    
    /// 获取当前耗时（不结束计时）
    /// - Parameter tag: 计时任务标识，默认为 "default"
    /// - Returns: 耗时（秒），如果未找到开始时间则返回 nil
    public class func st_elapsedTime(tag: String = "default") -> Double? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let startTime = startTimes[tag] else {
            return nil
        }
        
        let currentTime = CACurrentMediaTime()
        return currentTime - startTime
    }
    
    /// 打印当前耗时（不结束计时）
    /// - Parameters:
    ///   - tag: 计时任务标识，默认为 "default"
    ///   - message: 自定义消息
    public class func st_printElapsed(tag: String = "default", message: String? = nil) {
        guard let elapsed = st_elapsedTime(tag: tag) else {
            print("⚠️ [\(tag)] 未找到对应的开始时间，请先调用 st_start(tag:)")
            return
        }
        
        let messageText = message != nil ? " - \(message!)" : ""
        let durationText = st_formatDuration(elapsed)
        print("⏳ [\(tag)] 当前耗时: \(durationText)\(messageText)")
    }
    
    /// 执行代码块并测量耗时
    /// - Parameters:
    ///   - tag: 计时任务标识，默认为 "default"
    ///   - message: 自定义消息
    ///   - block: 要执行的代码块
    /// - Returns: 代码块的返回值
    @discardableResult
    public class func st_measure<T>(tag: String = "default", message: String? = nil, block: () throws -> T) rethrows -> T {
        st_start(tag: tag)
        defer {
            st_end(tag: tag, message: message)
        }
        return try block()
    }
    
    /// 执行异步代码块并测量耗时
    /// - Parameters:
    ///   - tag: 计时任务标识，默认为 "default"
    ///   - message: 自定义消息
    ///   - block: 要执行的异步代码块
    public class func st_measureAsync(tag: String = "default", message: String? = nil, block: @escaping () async throws -> Void) {
        st_start(tag: tag)
        Task {
            do {
                try await block()
                st_end(tag: tag, message: message)
            } catch {
                st_end(tag: tag, message: "\(message ?? "") - 错误: \(error.localizedDescription)")
            }
        }
    }
    
    /// 清除所有计时任务
    public class func st_clearAll() {
        lock.lock()
        defer { lock.unlock() }
        startTimes.removeAll()
        print("🧹 已清除所有计时任务")
    }
    
    /// 清除指定标签的计时任务
    /// - Parameter tag: 计时任务标识
    public class func st_clear(tag: String) {
        lock.lock()
        defer { lock.unlock() }
        startTimes.removeValue(forKey: tag)
        print("🧹 已清除计时任务: \(tag)")
    }
    
    // MARK: - 私有方法
    
    /// 格式化耗时显示
    /// - Parameter duration: 耗时（秒）
    /// - Returns: 格式化后的字符串
    private class func st_formatDuration(_ duration: Double) -> String {
        if duration < 0.001 {
            // 小于1毫秒，显示微秒
            return String(format: "%.2f μs", duration * 1_000_000)
        } else if duration < 1.0 {
            // 小于1秒，显示毫秒
            return String(format: "%.2f ms", duration * 1000)
        } else if duration < 60.0 {
            // 小于1分钟，显示秒
            return String(format: "%.3f s", duration)
        } else {
            // 大于1分钟，显示分钟和秒
            let minutes = Int(duration / 60)
            let seconds = duration.truncatingRemainder(dividingBy: 60)
            return String(format: "%d m %.2f s", minutes, seconds)
        }
    }
}