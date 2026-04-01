//
//  STScrollPerfDiagnostics.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/06/12.
//

import os
import UIKit

// 滑动/布局等主线程性能诊断工具
// 通过 os_signpost 在 Instruments 的 Points of Interest 中标记区间
// 仅在 DEBUG 下启用，Release 下为零成本空实现
public enum STScrollPerfDiagnostics {

    /// 使用 PointsOfInterest category，Instruments 选 "Points of Interest" 模板即可看到区间
    private static let log = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "app",
        category: "PointsOfInterest"
    )

    /// 超过此毫秒数打日志，便于发现主线程长任务（一帧约 16ms）
    private static let thresholdMs: Double = 16

    /// 是否打印超时日志（可在调试时改为 true）
    private static let logSlowBlocks = true

    /// 测量一段主线程耗时，并用 os_signpost 记录；超过 thresholdMs 时打日志
    /// - Parameters:
    ///   - name: 区间名称（在 Instruments Points of Interest / os_signpost 中显示）
    ///   - block: 要测量的闭包
    /// - Returns: block 的返回值
    @inline(__always)
    public static func measure<T>(name: StaticString, block: () -> T) -> T {
        #if DEBUG
        let start = CFAbsoluteTimeGetCurrent()
        os_signpost(.begin, log: log, name: name)
        defer {
            os_signpost(.end, log: log, name: name)
            let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
            if logSlowBlocks, ms > thresholdMs {
                os_log(
                    .default,
                    log: log,
                    "[STScrollPerf] %{public}s %.1f ms",
                    "\(name)",
                    ms
                )
            }
        }
        return block()
        #else
        return block()
        #endif
    }

    /// 无返回值版本
    @inline(__always)
    public static func measure(name: StaticString, block: () -> Void) {
        #if DEBUG
        let start = CFAbsoluteTimeGetCurrent()
        os_signpost(.begin, log: log, name: name)
        block()
        os_signpost(.end, log: log, name: name)
        let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
        if logSlowBlocks, ms > thresholdMs {
            os_log(.default, log: log, "[STScrollPerf] %{public}s %.1f ms", "\(name)", ms)
        }
        #else
        block()
        #endif
    }
}

