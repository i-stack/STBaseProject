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
        let _ = center
        let chordLength = distance(between: start, and: end)
        let cosine = (2 * pow(radius, 2) - pow(chordLength, 2)) / (2 * pow(radius, 2))
        var angle = 180 / Double.pi * Double(acosf(Float(cosine)))
        if start.x > end.x {
            angle = 360 - angle
        }
        return CGFloat(angle)
    }
}
