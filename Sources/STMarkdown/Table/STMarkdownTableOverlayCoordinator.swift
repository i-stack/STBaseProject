//
//  STMarkdownTableOverlayCoordinator.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2025/04/29.
//

import UIKit

final class STMarkdownTableOverlayCoordinator {

    var onCitationTap: ((String) -> Void)?

    private weak var textView: UITextView?
    private var tableViewOverlays: [Int: STMarkdownTableView] = [:]
    private var tableOverlayNeedsUpdate = false
    private(set) var lastTableOverlayLayoutSize: CGSize = .zero

    init(textView: UITextView) {
        self.textView = textView
    }

    func markDirty() {
        self.tableOverlayNeedsUpdate = true
        self.textView?.setNeedsLayout()
    }

    func updateIfNeeded(attributedText: NSAttributedString, containerBounds: CGRect) {
        let sizeChanged = containerBounds.size != self.lastTableOverlayLayoutSize
        guard self.tableOverlayNeedsUpdate || sizeChanged else { return }
        self.lastTableOverlayLayoutSize = containerBounds.size
        self.tableOverlayNeedsUpdate = false
        self.updateTableViewOverlays(attributedText: attributedText)
    }

    func reset() {
        for (_, tableView) in self.tableViewOverlays {
            tableView.removeFromSuperview()
        }
        self.tableViewOverlays.removeAll()
        self.tableOverlayNeedsUpdate = false
        self.lastTableOverlayLayoutSize = .zero
    }

    private func updateTableViewOverlays(attributedText: NSAttributedString) {
        guard let textView = self.textView else {
            self.reset()
            return
        }
        guard attributedText.length > 0 else {
            self.reset()
            return
        }

        var foundKeys = Set<Int>()
        let fullRange = NSRange(location: 0, length: attributedText.length)

        attributedText.enumerateAttribute(.attachment, in: fullRange, options: []) { value, range, _ in
            guard let attachment = value as? STMarkdownTableViewAttachment else { return }
            let charIndex = range.location
            foundKeys.insert(charIndex)

            let glyphRange = textView.layoutManager.glyphRange(
                forCharacterRange: range,
                actualCharacterRange: nil
            )
            guard glyphRange.location != NSNotFound, glyphRange.length > 0 else { return }
            let glyphRect = textView.layoutManager.boundingRect(
                forGlyphRange: glyphRange,
                in: textView.textContainer
            )
            let frame = CGRect(
                x: glyphRect.origin.x + textView.textContainerInset.left,
                y: glyphRect.origin.y + textView.textContainerInset.top,
                width: attachment.containerWidth,
                height: glyphRect.height
            )

            if let existing = self.tableViewOverlays[charIndex] {
                if existing.tableData !== attachment.tableViewModel {
                    existing.tableData = attachment.tableViewModel
                }
                existing.frame = frame
            } else {
                let tableView = attachment.tableView
                tableView.onCitationTap = { [weak self] number in
                    self?.onCitationTap?(number)
                }
                tableView.frame = frame
                textView.addSubview(tableView)
                self.tableViewOverlays[charIndex] = tableView
            }
        }

        for (key, tableView) in self.tableViewOverlays where !foundKeys.contains(key) {
            tableView.removeFromSuperview()
            self.tableViewOverlays.removeValue(forKey: key)
        }
    }
}
