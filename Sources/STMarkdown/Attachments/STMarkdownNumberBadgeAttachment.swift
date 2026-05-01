//
//  STMarkdownNumberBadgeAttachment.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import UIKit

/// 数字角标 NSTextAttachment，用于在富文本中渲染带圆圈背景的数字标记（如引用角标）。
/// 所有引用角标使用统一的直径（可随正文字体放大），避免不同数字（如 1 vs 12）因文本宽度差异导致圆圈大小不一致。
public final class STMarkdownNumberBadgeAttachment: NSTextAttachment {

    /// 默认角标直径，对应 17pt 正文下的视觉基线。`renderBadgeImage` 的
    /// `diameter` 默认值引用此常量，确保两条渲染路径（TextKit 内联 / CoreGraphics 表格）
    /// 视觉一致。实际内联渲染会随正文字体线性放大，下限保持该值。
    public static let fixedDiameter: CGFloat = 18

    /// - Parameters:
    ///   - numberText: 显示的数字文本
    ///   - font: 正文字体，用于计算直径与基线对齐（支持 Dynamic Type 自动缩放）
    ///   - textColor: 数字文本颜色
    ///   - backgroundColor: 圆圈背景颜色
    public init(numberText: String, font: UIFont, textColor: UIColor, backgroundColor: UIColor) {
        super.init(data: nil, ofType: nil)

        // 直径随正文字体线性缩放：以 17pt 正文对应 18pt 直径为基准，大字体辅助模式下
        // 角标同步放大；低于默认 pointSize 时保持 `fixedDiameter` 下限，保证小字号可读性。
        let baseFontPointSize: CGFloat = 17
        let scaled = font.pointSize / baseFontPointSize * Self.fixedDiameter
        let diameter = max(Self.fixedDiameter, ceil(scaled))
        let size = CGSize(width: diameter, height: diameter)

        let image = Self.drawBadge(
            number: numberText,
            textColor: textColor,
            backgroundColor: backgroundColor,
            diameter: diameter
        )
        image.accessibilityLabel = Self.accessibilityLabel(for: numberText)
        self.image = image

        // 将圆圈角标与正文文字垂直居中对齐：
        // bounds.origin.y 以基线为原点，正值向上。
        // font.ascender（正值）到 font.descender（负值）是文字的完整垂直范围，
        // 取其中点再减去角标半高，使圆圈中心与文字视觉中心对齐。
        let baselineOffset = (font.ascender + font.descender - size.height) / 2
        self.bounds = CGRect(x: 0, y: baselineOffset, width: size.width, height: size.height)
    }

    /// 本类型不设计为可归档。若整个富文本仍被 `NSKeyedArchiver` 序列化，
    /// 我们退化为一个普通 `NSTextAttachment`（保留 `image` 字段），
    /// 避免 `fatalError` 让外部归档链路整体崩溃。
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /// 直接渲染圆形数字角标图片，供 CoreGraphics 绘制上下文（如表格渲染）调用。
    /// - Parameters:
    ///   - number: 显示的数字文本
    ///   - textColor: 数字文本颜色
    ///   - backgroundColor: 圆圈背景颜色
    ///   - diameter: 圆圈直径，默认与 `fixedDiameter` 一致
    /// - Returns: 固定尺寸的圆形角标图片（带无障碍 label，形如 "引用 1"）
    public static func renderBadgeImage(
        number: String,
        textColor: UIColor,
        backgroundColor: UIColor,
        diameter: CGFloat = STMarkdownNumberBadgeAttachment.fixedDiameter
    ) -> UIImage {
        let image = drawBadge(
            number: number,
            textColor: textColor,
            backgroundColor: backgroundColor,
            diameter: diameter
        )
        image.accessibilityLabel = accessibilityLabel(for: number)
        return image
    }
}

/// 旧名称兼容：后续新代码请使用 `STMarkdownNumberBadgeAttachment`。
public typealias STMarkdownCircleNumberAttachment = STMarkdownNumberBadgeAttachment

private extension STMarkdownNumberBadgeAttachment {
    /// 缓存 key：四元组（数字文本、前景色、背景色、直径）全匹配才能命中。
    /// 颜色通过 `UIColor.cgColor` 的 `CFHash` 生成稳定 hash，避免 `UIColor.==`
    /// 在动态颜色下的不确定性（`UIColor.systemBlue` 在 light/dark 下是两个底层颜色）。
    struct BadgeCacheKey: Hashable {
        let number: String
        let textColorHash: Int
        let backgroundColorHash: Int
        let diameter: CGFloat
    }

    /// 同模块共享的 badge 图片缓存。一张文本中出现 N 个相同参数的角标时只渲染一次。
    /// 64 个 slot 足以覆盖常见（10 位数 × 3 种颜色 × 2 种直径）组合。
    static let badgeCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 64
        return cache
    }()

    /// 内联 init 与静态 `renderBadgeImage` 共用的绘制逻辑，避免字体阶梯 / 居中逻辑
    /// 在两条路径之间漂移。
    ///
    /// 注意：当前字号阶梯仅对 1–3 位数字做了视觉校准，引用角标一般不会超过 3 位；
    /// 若传入 4 位及以上，文字可能在圆圈内偏紧或溢出，调用方需自行截断。
    static func drawBadge(
        number: String,
        textColor: UIColor,
        backgroundColor: UIColor,
        diameter: CGFloat
    ) -> UIImage {
        assert(number.count <= 3, "STMarkdownNumberBadgeAttachment 当前仅为 1-3 位数字做了视觉校准，传入 \(number) 可能溢出圆圈")
        let key = BadgeCacheKey(
            number: number,
            textColorHash: colorFingerprint(textColor),
            backgroundColorHash: colorFingerprint(backgroundColor),
            diameter: diameter
        )
        let cacheKey = cacheKeyString(for: key)
        if let cached = badgeCache.object(forKey: cacheKey) {
            return cached
        }

        let size = CGSize(width: diameter, height: diameter)
        // 字号按直径线性缩放，保留原 11/10/9 的比例（17/18 ≈ 0.611）。
        let ratio: CGFloat = number.count <= 1 ? 11.0 / 18.0 : (number.count == 2 ? 10.0 / 18.0 : 9.0 / 18.0)
        let badgeFont = UIFont.st_systemFont(ofSize: diameter * ratio, weight: .semibold)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: badgeFont,
            .foregroundColor: textColor,
        ]
        let textSize = (number as NSString).size(withAttributes: textAttributes)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
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
        badgeCache.setObject(image, forKey: cacheKey)
        return image
    }

    /// 生成 VoiceOver 友好的 label；调用方可通过 `UIAccessibility.isVoiceOverRunning`
    /// 自己决定是否读出。
    static func accessibilityLabel(for number: String) -> String {
        return "引用 \(number)"
    }

    static func cacheKeyString(for key: BadgeCacheKey) -> NSString {
        return "\(key.number)|\(key.textColorHash)|\(key.backgroundColorHash)|\(key.diameter)" as NSString
    }

    /// 将 UIColor 压成稳定 Int 以用作 cache key 组件。
    /// 动态颜色的底层组件在不同 traitCollection 下不同，这里取当前 trait 下 resolved 值，
    /// 避免 light/dark 相互污染。
    static func colorFingerprint(_ color: UIColor) -> Int {
        let resolved = color.resolvedColor(with: UITraitCollection.current)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // 量化到 0...255，避免浮点误差命中不到缓存
        let q = { (c: CGFloat) -> Int in Int((c * 255).rounded()) & 0xFF }
        return (q(red) << 24) | (q(green) << 16) | (q(blue) << 8) | q(alpha)
    }
}
