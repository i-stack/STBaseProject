//
//  STShimmerTextView.swift
//  Bajoseek
//
//  Created by 寒江孤影 on 2026/2/3.
//

import UIKit

public class STShimmerTextView: UITextView {

    private struct AnimatingToken {
        let range: NSRange
        let startTime: CFTimeInterval
    }

    var tokenFadeDuration: TimeInterval = 0.3
    private var displayLink: CADisplayLink?
    private var animatingTokens: [AnimatingToken] = []
    private var buildingAttributedString: NSMutableAttributedString = NSMutableAttributedString()

    var defaultTextAttributes: [NSAttributedString.Key: Any] {
        return [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.label
        ]
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }

    private func setup() {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isEditable = false
        self.isSelectable = true
        self.isScrollEnabled = false
        self.backgroundColor = .clear
        self.textContainerInset = .zero
        self.textContainer.lineFragmentPadding = 0
        self.font = .systemFont(ofSize: 16)
        self.textColor = .label
    }

    func append(_ text: String) {
        let startLocation = self.buildingAttributedString.length
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.label.withAlphaComponent(0)
        ]
        let tokenAttr = NSAttributedString(string: text, attributes: attrs)
        self.buildingAttributedString.append(tokenAttr)
        self.attributedText = self.buildingAttributedString
        let token = AnimatingToken(
            range: NSRange(location: startLocation, length: text.utf16.count),
            startTime: CACurrentMediaTime()
        )
        self.animatingTokens.append(token)
        self.startDisplayLinkIfNeeded()
    }

    func reset() {
        self.stopDisplayLink()
        self.animatingTokens.removeAll()
        self.buildingAttributedString = NSMutableAttributedString()
        self.attributedText = nil
        self.text = ""
    }

    func finishAnimations() {
        self.stopDisplayLink()
        self.animatingTokens.removeAll()
        let fullRange = NSRange(location: 0, length: self.buildingAttributedString.length)
        if fullRange.length > 0 {
            self.buildingAttributedString.addAttribute(
                .foregroundColor,
                value: UIColor.label,
                range: fullRange
            )
            self.attributedText = self.buildingAttributedString
        }
    }

    func caretRect() -> CGRect? {
        guard self.buildingAttributedString.length > 0 else { return nil }
        let rect = self.caretRect(for: self.endOfDocument)
        if rect.isEmpty || rect.origin.x.isInfinite || rect.origin.y.isInfinite {
            return nil
        }
        return rect
    }

    private func startDisplayLinkIfNeeded() {
        guard self.displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(self.handleDisplayLink))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
    }

    private func stopDisplayLink() {
        self.displayLink?.invalidate()
        self.displayLink = nil
    }

    @objc private func handleDisplayLink() {
        let now = CACurrentMediaTime()
        var needsUpdate = false
        var completedIndices: [Int] = []
        for (index, token) in self.animatingTokens.enumerated() {
            let elapsed = now - token.startTime
            let progress = min(1.0, elapsed / self.tokenFadeDuration)
            let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
            let color = UIColor.label.withAlphaComponent(CGFloat(easedProgress))
            self.buildingAttributedString.addAttribute(.foregroundColor, value: color, range: token.range)
            needsUpdate = true
            if progress >= 1.0 {
                completedIndices.append(index)
            }
        }
        for index in completedIndices.reversed() {
            self.animatingTokens.remove(at: index)
        }
        if needsUpdate {
            let offset = self.contentOffset
            self.attributedText = self.buildingAttributedString
            self.setContentOffset(offset, animated: false)
        }
        if self.animatingTokens.isEmpty {
            self.stopDisplayLink()
        }
    }
}
