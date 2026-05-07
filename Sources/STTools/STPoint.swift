//
//  STPoint.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2017/10/14.
//

import Foundation
import UIKit

public enum STGeometry {
    /// 两点之间的直线距离
    public static func distance(between start: CGPoint, and end: CGPoint) -> CGFloat {
        hypot(abs(start.x - end.x), abs(start.y - end.y))
    }

    /// 圆上两点相对于圆心的夹角，返回角度制数值
    public static func angle(
        onCircleWithRadius radius: CGFloat,
        center: CGPoint,
        start: CGPoint,
        end: CGPoint
    ) -> CGFloat {
        let startVector = CGVector(dx: start.x - center.x, dy: start.y - center.y)
        let endVector = CGVector(dx: end.x - center.x, dy: end.y - center.y)
        let startAngle = atan2(startVector.dy, startVector.dx)
        let endAngle = atan2(endVector.dy, endVector.dx)
        let angle = (endAngle - startAngle) * 180 / .pi
        return angle >= 0 ? angle : angle + 360
    }
}
