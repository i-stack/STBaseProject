//
//  STKeyboardAdjustmentBehavior.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit

final class STKeyboardAdjustmentBehavior {

    weak var hostView: UIView?
    /// 用闭包而不是直接持有实例：`STBaseView.scrollView` 是 `open` 的，子类可能重写该 getter
    /// 在不同时机返回不同实例，这里每次都要取"当前"值，不能在 start() 时固定快照一份。
    var scrollViewProvider: () -> UIScrollView? = { nil }
    var isActive: () -> Bool = { false }
    /// 是否启用键盘 contentInset 自动调整（默认 true）
    var isEnabled: Bool = true

    private var tokens: [NSObjectProtocol] = []
    private var baseContentInset: UIEdgeInsets?
    private var baseVerticalIndicatorInsets: UIEdgeInsets?
    private var baseHorizontalIndicatorInsets: UIEdgeInsets?

    deinit {
        self.stop()
    }

    func start() {
        let nc = NotificationCenter.default
        let willShow = nc.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] note in
            self?.keyboardWillShow(note)
        }
        let willHide = nc.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] note in
            self?.keyboardWillHide(note)
        }
        let willChange = nc.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) { [weak self] note in
            self?.keyboardWillChangeFrame(note)
        }
        self.tokens = [willShow, willHide, willChange]
    }

    func stop() {
        let nc = NotificationCenter.default
        self.tokens.forEach { nc.removeObserver($0) }
        self.tokens.removeAll()
    }

    func restoreIfNeeded() {
        guard self.baseContentInset != nil else { return }
        self.restoreBaseInsets()
    }

    private func keyboardWillShow(_ note: Notification) {
        self.adjustForKeyboard(using: note, appearing: true)
    }

    private func keyboardWillHide(_ note: Notification) {
        self.adjustForKeyboard(using: note, appearing: false)
    }

    private func keyboardWillChangeFrame(_ note: Notification) {
        guard self.isActive(), self.isEnabled, let hostView = self.hostView, note.userInfo != nil else { return }
        let keyboardFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        let converted = hostView.convert(keyboardFrame, from: nil)
        let insetBottom = max(0, hostView.bounds.maxY - converted.minY)
        guard insetBottom > 0 else { return }
        self.adjustForKeyboard(using: note, appearing: true)
    }

    private func adjustForKeyboard(using note: Notification, appearing: Bool) {
        guard self.isActive() else { return }
        guard appearing || self.baseContentInset != nil else { return }
        guard let hostView = self.hostView, let scrollView = self.scrollViewProvider() else { return }
        guard let userInfo = note.userInfo, self.isEnabled else {
            if !appearing, self.baseContentInset != nil {
                self.restoreBaseInsets()
            }
            return
        }

        // 首次响应键盘前保存基准 inset（一次键盘周期内捕获，隐藏后清空）
        if self.baseContentInset == nil {
            self.baseContentInset = scrollView.contentInset
        }
        if self.baseVerticalIndicatorInsets == nil {
            self.baseVerticalIndicatorInsets = scrollView.verticalScrollIndicatorInsets
        }
        if self.baseHorizontalIndicatorInsets == nil {
            self.baseHorizontalIndicatorInsets = scrollView.horizontalScrollIndicatorInsets
        }
        let baseContent = self.baseContentInset ?? scrollView.contentInset
        var verticalIndicator = self.baseVerticalIndicatorInsets ?? scrollView.verticalScrollIndicatorInsets
        var horizontalIndicator = self.baseHorizontalIndicatorInsets ?? scrollView.horizontalScrollIndicatorInsets

        let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
        let converted = hostView.convert(keyboardFrame, from: nil)
        let overlay = appearing ? max(0, hostView.bounds.maxY - converted.minY) : 0
        let delta = max(0, overlay - baseContent.bottom)

        var contentInset = baseContent
        contentInset.bottom = baseContent.bottom + delta
        verticalIndicator.bottom += delta
        horizontalIndicator.bottom += delta

        let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let curveRaw = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            scrollView.contentInset = contentInset
            scrollView.verticalScrollIndicatorInsets = verticalIndicator
            scrollView.horizontalScrollIndicatorInsets = horizontalIndicator
            if !appearing {
                self.baseContentInset = nil
                self.baseVerticalIndicatorInsets = nil
                self.baseHorizontalIndicatorInsets = nil
            }
        }
    }

    private func restoreBaseInsets() {
        guard let scrollView = self.scrollViewProvider() else { return }
        let baseContent = self.baseContentInset ?? scrollView.contentInset
        let verticalIndicator = self.baseVerticalIndicatorInsets ?? scrollView.verticalScrollIndicatorInsets
        let horizontalIndicator = self.baseHorizontalIndicatorInsets ?? scrollView.horizontalScrollIndicatorInsets
        scrollView.contentInset = baseContent
        scrollView.verticalScrollIndicatorInsets = verticalIndicator
        scrollView.horizontalScrollIndicatorInsets = horizontalIndicator
        self.baseContentInset = nil
        self.baseVerticalIndicatorInsets = nil
        self.baseHorizontalIndicatorInsets = nil
    }
}