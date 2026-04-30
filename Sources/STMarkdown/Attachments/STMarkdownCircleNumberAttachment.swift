//
//  STMarkdownCircleNumberAttachment.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

/// 圆形数字角标 NSTextAttachment，用于在富文本中渲染带圆圈背景的数字标记（如引用角标）。
/// 所有引用角标使用统一的固定直径，避免不同数字（如 1 vs 12）因文本宽度差异导致圆圈大小不一致。
public final class STMarkdownCircleNumberAttachment: NSTextAttachment {

    private static let fixedDiameter: CGFloat = 18

    /// - Parameters:
    ///   - numberText: 显示的数字文本
    ///   - font: 正文字体，用于计算基线对齐
    ///   - textColor: 数字文本颜色
    ///   - backgroundColor: 圆圈背景颜色
    public init(numberText: String, font: UIFont, textColor: UIColor, backgroundColor: UIColor) {
        super.init(data: nil, ofType: nil)

        let diameter = Self.fixedDiameter
        let size = CGSize(width: diameter, height: diameter)
        // 根据数字位数动态调整字体大小，确保多位数字能在固定直径内清晰显示
        let baseFontSize: CGFloat = numberText.count <= 1 ? 11 : (numberText.count == 2 ? 10 : 9)
        let badgeFont = UIFont.st_systemFont(ofSize: baseFontSize, weight: .semibold)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: badgeFont,
            .foregroundColor: textColor,
        ]
        let textSize = (numberText as NSString).size(withAttributes: textAttributes)

        let renderer = UIGraphicsImageRenderer(size: size)
        self.image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            backgroundColor.setFill()
            UIBezierPath(ovalIn: rect).fill()
            let textRect = CGRect(
                x: (size.width - textSize.width) * 0.5,
                y: (size.height - textSize.height) * 0.5,
                width: textSize.width,
                height: textSize.height
            )
            (numberText as NSString).draw(in: textRect, withAttributes: textAttributes)
        }

        // 将圆圈角标与正文文字垂直居中对齐：
        // bounds.origin.y 以基线为原点，正值向上。
        // font.ascender（正值）到 font.descender（负值）是文字的完整垂直范围，
        // 取其中点再减去角标半高，使圆圈中心与文字视觉中心对齐。
        let baselineOffset = (font.ascender + font.descender - size.height) / 2
        self.bounds = CGRect(x: 0, y: baselineOffset, width: size.width, height: size.height)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 直接渲染圆形数字角标图片，供 CoreGraphics 绘制上下文（如表格渲染）调用。
    /// - Parameters:
    ///   - number: 显示的数字文本
    ///   - textColor: 数字文本颜色
    ///   - backgroundColor: 圆圈背景颜色
    ///   - diameter: 圆圈直径，默认与 fixedDiameter 一致
    /// - Returns: 固定尺寸的圆形角标图片
    public static func renderBadgeImage(
        number: String,
        textColor: UIColor,
        backgroundColor: UIColor,
        diameter: CGFloat = 18
    ) -> UIImage {
        let size = CGSize(width: diameter, height: diameter)
        let baseFontSize: CGFloat = number.count <= 1 ? 11 : (number.count == 2 ? 10 : 9)
        let badgeFont = UIFont.st_systemFont(ofSize: baseFontSize, weight: .semibold)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: badgeFont,
            .foregroundColor: textColor,
        ]
        let textSize = (number as NSString).size(withAttributes: textAttributes)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            backgroundColor.setFill()
            UIBezierPath(ovalIn: rect).fill()
            let textRect = CGRect(
                x: (size.width - textSize.width) * 0.5,
                y: (size.height - textSize.height) * 0.5,
                width: textSize.width,
                height: textSize.height
            )
            (number as NSString).draw(in: textRect, withAttributes: textAttributes)
        }
    }
}
