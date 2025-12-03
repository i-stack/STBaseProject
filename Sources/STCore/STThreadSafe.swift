//
//  STThreadSafe.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation
import Dispatch

// MARK: - 线程安全工具类
public class STThreadSafe {
        
    /// 安全地在主线程执行代码
    /// - Parameter callback: 要执行的代码块
    public static func dispatchMainAsyncSafe(_ callback: @escaping () -> Void) {
        if Thread.isMainThread {
            callback()
        } else {
            DispatchQueue.main.async { callback() }
        }
    }
    
    /// 安全地在主线程同步执行代码
    /// - Parameter callback: 要执行的代码块
    public static func dispatchMainSyncSafe(_ callback: @escaping () -> Void) {
        if Thread.isMainThread {
            callback()
        } else {
            DispatchQueue.main.sync { callback() }
        }
    }
    
    /// 安全地在主线程执行代码并返回结果
    /// - Parameter callback: 要执行的代码块
    /// - Returns: 执行结果
    public static func dispatchMainSyncSafe<T>(_ callback: @escaping () -> T) -> T {
        if Thread.isMainThread {
            return callback()
        } else {
            return DispatchQueue.main.sync { callback() }
        }
    }
    
    // MARK: - 后台线程安全调用
    
    /// 在后台队列异步执行代码
    /// - Parameters:
    ///   - qos: 服务质量等级
    ///   - callback: 要执行的代码块
    public static func dispatchBackgroundAsync(qos: DispatchQoS.QoSClass = .default, _ callback: @escaping () -> Void) {
        DispatchQueue.global(qos: qos).async { callback() }
    }
    
    /// 在指定队列异步执行代码
    /// - Parameters:
    ///   - queue: 目标队列
    ///   - callback: 要执行的代码块
    public static func dispatchAsync(on queue: DispatchQueue, _ callback: @escaping () -> Void) {
        queue.async { callback() }
    }
    
    /// 在指定队列同步执行代码
    /// - Parameters:
    ///   - queue: 目标队列
    ///   - callback: 要执行的代码块
    public static func dispatchSync(on queue: DispatchQueue, _ callback: @escaping () -> Void) {
        queue.sync { callback() }
    }
    
    // MARK: - 延迟执行
    
    /// 延迟执行代码
    /// - Parameters:
    ///   - delay: 延迟时间（秒）
    ///   - queue: 执行队列，默认为主队列
    ///   - callback: 要执行的代码块
    public static func dispatchAfter(delay: TimeInterval, queue: DispatchQueue = .main, _ callback: @escaping () -> Void) {
        queue.asyncAfter(deadline: .now() + delay) { callback() }
    }
    
    /// 延迟在主线程执行代码
    /// - Parameters:
    ///   - delay: 延迟时间（秒）
    ///   - callback: 要执行的代码块
    public static func dispatchMainAfter(delay: TimeInterval, _ callback: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { callback() }
    }
}