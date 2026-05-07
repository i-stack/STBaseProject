//
//  STCALayer.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/1/21.
//

import QuartzCore
#if canImport(UIKit)
import UIKit
#endif

public extension CALayer {

    /// 递归移除当前图层及所有子图层上的动画
    /// 常用于在 reload/reset 前清理未结束的动画，避免视觉抖动
    func removeAllAnimationsRecursively() {
        CATransaction.begin()
        removeAllAnimationsRecursivelyInner()
        CATransaction.commit()
    }

    private func removeAllAnimationsRecursivelyInner() {
        (sublayers ?? []).forEach { $0.removeAllAnimationsRecursivelyInner() }
        removeAllAnimations()
    }
}

#if canImport(UIKit)
public extension UIView {
    /// 对视图树递归移除所有 CALayer 动画
    func removeAllLayerAnimationsRecursively() {
        layer.removeAllAnimationsRecursively()
    }
}
#endif
