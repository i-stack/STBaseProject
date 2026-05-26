//
//  STMarkdownLineNumberDrawView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/05/26.
//

import UIKit

public struct STMarkdownLineNumberEntry {
    public let text: String
    public let y: CGFloat
    public init(text: String, y: CGFloat) {
        self.text = text
        self.y = y
    }
}

/// 行号绘制视图，通过 `update(entries:font:color:rightInset:)` 驱动，无主题系统依赖。
public final class STMarkdownLineNumberDrawView: UIView {
    private var entries: [STMarkdownLineNumberEntry] = []
    private var drawFont: UIFont = UIFont.st_monospacedSystemFont(ofSize: 12, weight: .regular)
    private var drawColor: UIColor = .systemGray
    private var rightInset: CGFloat = 6
    private var lineHeight: CGFloat = UIFont.st_monospacedSystemFont(ofSize: 12, weight: .regular).lineHeight

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
        self.contentMode = .redraw
    }

    public required init?(coder: NSCoder) { nil }

    public func update(
        entries: [STMarkdownLineNumberEntry],
        font: UIFont,
        color: UIColor,
        rightInset: CGFloat
    ) {
        self.entries = entries
        self.drawFont = font
        self.drawColor = color
        self.rightInset = rightInset
        self.lineHeight = max(font.lineHeight, 1)
        self.setNeedsDisplay()
    }

    public override func draw(_ rect: CGRect) {
        self.drawEntries(in: rect)
    }

    public func drawEntries(in rect: CGRect) {
        guard !self.entries.isEmpty else { return }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        paragraphStyle.lineBreakMode = .byClipping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: self.drawFont,
            .foregroundColor: self.drawColor,
            .paragraphStyle: paragraphStyle,
        ]
        for entry in self.entries {
            let alignedY = self.alignToPixel(entry.y)
            let lineRect = CGRect(
                x: 0,
                y: alignedY,
                width: self.alignToPixel(max(self.bounds.width - self.rightInset, 1)),
                height: self.alignToPixel(self.lineHeight)
            )
            if lineRect.maxY < rect.minY || lineRect.minY > rect.maxY { continue }
            (entry.text as NSString).draw(in: lineRect, withAttributes: attributes)
        }
    }

    public func render(in context: CGContext, bounds: CGRect) {
        context.saveGState()
        context.translateBy(
            x: self.alignToPixel(bounds.minX),
            y: self.alignToPixel(bounds.minY)
        )
        self.drawEntries(in: CGRect(
            origin: .zero,
            size: CGSize(
                width: self.alignToPixel(bounds.size.width),
                height: self.alignToPixel(bounds.size.height)
            )
        ))
        context.restoreGState()
    }

    private func alignToPixel(_ value: CGFloat) -> CGFloat {
        let scale = max(UIScreen.main.scale, 1)
        return (value * scale).rounded(.toNearestOrAwayFromZero) / scale
    }
}
