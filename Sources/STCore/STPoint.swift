//
//  STPoint.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2017/10/14.
//

import UIKit
import Foundation

public class STPoint: NSObject {

    /// Distance between two points
    ///
    /// The hypot(x, y) function calculates the length of the hypotenuse of a triangle
    ///
    /// - Parameters:
    ///   - pointA: Coordinates of point A.
    ///   - pointB: Coordinates of point B.
    ///
    /// - Returns: The distance between the two points.
    ///
    public static func st_distanceBetween(pointA: CGPoint, pointB: CGPoint) -> CGFloat {
        let x = abs(pointA.x - pointB.x)
        let y = abs(pointA.y - pointB.y)
        return hypot(x, y)
    }
    
    /// Calculate the angle between two points on a circle
    ///
    /// a^2 = b^2 + c^2 - 2bc*cosA
    ///
    /// - Parameters:
    ///   - radius: Radius
    ///   - center: Center of the circle
    ///   - startCenter: Starting point coordinates
    ///   - endCenter: Ending point coordinates
    ///
    /// - Returns: The angle between two points on the circle.
    ///
    public static func st_calculateAngle(radius: CGFloat, center: CGPoint, startCenter: CGPoint, endCenter: CGPoint) -> CGFloat {
        let distance = STPoint.st_distanceBetween(pointA: startCenter, pointB: endCenter)
        let cosA = (2 * pow(radius, 2) - pow(distance, 2)) / (2 * pow(radius, 2))
        var angle = 180 / Double.pi * Double(acosf(Float(cosA)))
        if startCenter.x > endCenter.x {
            angle = 360 - angle
        }
        return CGFloat(angle)
    }
}
