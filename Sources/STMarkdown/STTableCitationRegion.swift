//
//  STTableCitationRegion.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import CoreGraphics

/// 表格图片中一个 Citation 角标的位置与编号。
/// frame 坐标系为图片 UIKit 坐标系（origin 左上角，y 轴向下，单位为 points）。
public struct STTableCitationRegion {
    public let frame: CGRect
    public let number: String
    public init(frame: CGRect, number: String) {
        self.frame = frame
        self.number = number
    }
}
