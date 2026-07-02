//
//  UIView+FontRefresh.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/7/1.
//

import UIKit

extension UIView {

    /// 按比例缩放当前视图及所有子视图中的字体，不带动画（无闪烁）。
    ///
    /// 覆盖 UILabel、UIButton.titleLabel、UITextField、UITextView 的 `font` 属性，
    /// 以及 UILabel 的 `attributedText` 中内嵌的字体。
    ///
    /// - Parameter scaleRatio: 缩放比例，通常为 `newFontSizeScale / oldFontSizeScale`。
    ///   当 `abs(scaleRatio - 1.0) < 0.001` 时直接返回，不做任何操作。
    public func st_refreshFonts(scaleRatio: CGFloat) {
        guard abs(scaleRatio - 1.0) > 0.001 else { return }
        UIView.performWithoutAnimation {
            self._refreshFontsRecursively(scaleRatio: scaleRatio)
        }
    }

    private func _refreshFontsRecursively(scaleRatio: CGFloat) {
        if let label = self as? UILabel {
            _updateLabel(label, scaleRatio: scaleRatio)
        } else if let button = self as? UIButton {
            _updateButton(button, scaleRatio: scaleRatio)
        } else if let textField = self as? UITextField {
            _updateTextField(textField, scaleRatio: scaleRatio)
        } else if let textView = self as? UITextView {
            _updateTextView(textView, scaleRatio: scaleRatio)
        }

        for subview in subviews {
            subview._refreshFontsRecursively(scaleRatio: scaleRatio)
        }
    }

    // MARK: - Private Updaters

    private func _updateLabel(_ label: UILabel, scaleRatio: CGFloat) {
        if let font = label.font {
            label.font = font.withSize(round(font.pointSize * scaleRatio))
        }
        if let attributedText = label.attributedText, attributedText.length > 0 {
            let mutable = NSMutableAttributedString(attributedString: attributedText)
            mutable.enumerateAttribute(.font, in: NSRange(location: 0, length: mutable.length)) { value, range, _ in
                if let font = value as? UIFont {
                    mutable.addAttribute(.font, value: font.withSize(round(font.pointSize * scaleRatio)), range: range)
                }
            }
            label.attributedText = mutable
        }
    }

    private func _updateButton(_ button: UIButton, scaleRatio: CGFloat) {
        if let font = button.titleLabel?.font {
            button.titleLabel?.font = font.withSize(round(font.pointSize * scaleRatio))
        }
    }

    private func _updateTextField(_ textField: UITextField, scaleRatio: CGFloat) {
        if let font = textField.font {
            textField.font = font.withSize(round(font.pointSize * scaleRatio))
        }
    }

    private func _updateTextView(_ textView: UITextView, scaleRatio: CGFloat) {
        if let font = textView.font {
            textView.font = font.withSize(round(font.pointSize * scaleRatio))
        }
    }
}