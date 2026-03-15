//
//  STThreadSafe.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Dispatch
import Foundation

public enum STThreading {
    /// 在主线程异步执行；如果当前已经在主线程则立即执行
    public static func runOnMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    /// 在主线程同步执行
    public static func runOnMainSynchronously(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
    }

    /// 在主线程同步执行并返回结果
    public static func runOnMainSynchronously<T>(_ work: @escaping () -> T) -> T {
        if Thread.isMainThread {
            return work()
        } else {
            return DispatchQueue.main.sync(execute: work)
        }
    }

    /// 在全局后台队列异步执行
    public static func runInBackground(
        qos: DispatchQoS.QoSClass = .default,
        _ work: @escaping () -> Void
    ) {
        DispatchQueue.global(qos: qos).async(execute: work)
    }

    /// 在指定队列异步执行
    public static func runAsync(on queue: DispatchQueue, _ work: @escaping () -> Void) {
        queue.async(execute: work)
    }

    /// 在指定队列同步执行
    public static func runSync(on queue: DispatchQueue, _ work: @escaping () -> Void) {
        queue.sync(execute: work)
    }

    /// 在指定队列延迟执行
    public static func run(
        after delay: TimeInterval,
        on queue: DispatchQueue = .main,
        _ work: @escaping () -> Void
    ) {
        queue.asyncAfter(deadline: .now() + delay, execute: work)
    }

    /// 在主线程延迟执行
    public static func runOnMain(after delay: TimeInterval, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
}
