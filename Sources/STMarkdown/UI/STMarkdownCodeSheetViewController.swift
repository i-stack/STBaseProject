//
//  STMarkdownCodeSheetViewController.swift
//  STMarkdown
//

import UIKit
import STBaseProject

/// 代码弹窗通用底部容器 VC。
/// 提供 dimming view、sheet view、grabber、close/copy 按钮和标题布局，以及弹出/收起动画。
/// 子类只需在 viewDidLoad 中调用 setupBottomSheetLayout、layoutCommonGrabberAndClose、layoutCommonCopyAndTitle
/// 即可获得完整的底部弹窗交互。
open class STMarkdownCodeSheetViewController: UIViewController {
    public enum LayoutMetrics {
        public static let initialSheetBottomOffset: CGFloat = 900
        public static let grabberTop: CGFloat = 8
        public static let grabberWidth: CGFloat = 40
        public static let grabberHeight: CGFloat = 4
        public static let closeTop: CGFloat = 12
        public static let closeTrailing: CGFloat = 12
        public static let closeSize: CGFloat = 25
        public static let copyTrailingToRightAnchor: CGFloat = 18
        public static let copySize: CGFloat = 18
        public static let titleLeading: CGFloat = 16
        public static let titleTrailingToCopy: CGFloat = 10
        public static let contentTopSpacing: CGFloat = 12
    }

    private weak var managedDimmingView: UIView?
    private var managedSheetBottomConstraint: NSLayoutConstraint?
    private var didAnimateIn = false
    public var onCopyTapped: (() -> Void)?
    public var onCloseTapped: (() -> Void)?
    public var headerTitle: String = "" {
        didSet {
            self.titleLabel.text = self.headerTitle
        }
    }

    /// 可注入的关闭/复制图标
    public var closeImage: UIImage? {
        didSet { self.closeButton.setImage(self.closeImage, for: .normal) }
    }
    public var copyImage: UIImage? {
        didSet { self.copyButton.setImage(self.copyImage?.withRenderingMode(.alwaysTemplate), for: .normal) }
    }

    /// 配置底部弹窗布局。
    public func setupBottomSheetLayout(heightRatio: CGFloat = 0.88, dimmingView: UIView, sheetView: UIView) {
        self.managedDimmingView = dimmingView
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(dimmingView)
        NSLayoutConstraint.activate([
            dimmingView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            dimmingView.topAnchor.constraint(equalTo: self.view.topAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])
        self.view.addSubview(sheetView)
        NSLayoutConstraint.activate([
            sheetView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            sheetView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: heightRatio),
        ])
        self.managedSheetBottomConstraint = sheetView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: LayoutMetrics.initialSheetBottomOffset)
        self.managedSheetBottomConstraint?.isActive = true
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !self.didAnimateIn else { return }
        self.didAnimateIn = true
        self.animateBottomSheetIn()
    }

    /// 弹出动画
    public func animateBottomSheetIn() {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.managedDimmingView?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            self.managedSheetBottomConstraint?.constant = 0
            self.view.layoutIfNeeded()
        }
    }

    /// 收起并 dismiss
    public func dismissBottomSheet() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.managedDimmingView?.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.managedSheetBottomConstraint?.constant = 900
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }

    /// 应用公共 header 主题
    public func applyCommonHeaderTheme(separatorColor: UIColor, titleColor: UIColor, bottomMenuColor: UIColor) {
        self.grabberView.backgroundColor = separatorColor
        self.titleLabel.textColor = titleColor
        self.copyButton.tintColor = bottomMenuColor
    }

    /// 布局 grabber 和 close 按钮到 sheetView
    public func layoutCommonGrabberAndClose(in sheetView: UIView) {
        self.grabberView.translatesAutoresizingMaskIntoConstraints = false
        self.closeButton.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(self.grabberView)
        NSLayoutConstraint.activate([
            self.grabberView.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: LayoutMetrics.grabberTop),
            self.grabberView.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            self.grabberView.widthAnchor.constraint(equalToConstant: LayoutMetrics.grabberWidth),
            self.grabberView.heightAnchor.constraint(equalToConstant: LayoutMetrics.grabberHeight),
        ])
        sheetView.addSubview(self.closeButton)
        NSLayoutConstraint.activate([
            self.closeButton.topAnchor.constraint(equalTo: self.grabberView.bottomAnchor, constant: LayoutMetrics.closeTop),
            self.closeButton.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -LayoutMetrics.closeTrailing),
            self.closeButton.widthAnchor.constraint(equalToConstant: LayoutMetrics.closeSize),
            self.closeButton.heightAnchor.constraint(equalToConstant: LayoutMetrics.closeSize),
        ])
    }

    /// 布局 copy 按钮和 title 到 sheetView
    public func layoutCommonCopyAndTitle(in sheetView: UIView, copyRightAnchor: UIView, copyCenterYAnchor: UIView, titleCenterYAnchor: UIView) {
        self.copyButton.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(self.copyButton)
        NSLayoutConstraint.activate([
            self.copyButton.centerYAnchor.constraint(equalTo: copyCenterYAnchor.centerYAnchor),
            self.copyButton.trailingAnchor.constraint(equalTo: copyRightAnchor.leadingAnchor, constant: -LayoutMetrics.copyTrailingToRightAnchor),
            self.copyButton.widthAnchor.constraint(equalToConstant: LayoutMetrics.copySize),
            self.copyButton.heightAnchor.constraint(equalToConstant: LayoutMetrics.copySize),
        ])
        sheetView.addSubview(self.titleLabel)
        NSLayoutConstraint.activate([
            self.titleLabel.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: LayoutMetrics.titleLeading),
            self.titleLabel.centerYAnchor.constraint(equalTo: titleCenterYAnchor.centerYAnchor),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.copyButton.leadingAnchor, constant: -LayoutMetrics.titleTrailingToCopy),
        ])
    }

    @objc private func handleCloseAction() {
        if let onCloseTapped {
            onCloseTapped()
        } else {
            self.dismissBottomSheet()
        }
    }

    @objc private func handleCopyAction() {
        self.onCopyTapped?()
    }

    public lazy var grabberView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        return view
    }()

    public lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = self.headerTitle
        label.lineBreakMode = .byTruncatingTail
        label.font = UIFont.st_systemFont(ofSize: 14, weight: .semibold)
        return label
    }()

    public lazy var copyButton: UIButton = {
        let button = UIButton(type: .custom)
        if let image = self.copyImage {
            button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
        } else {
            button.setImage(UIImage(named: "复制")?.withRenderingMode(.alwaysTemplate), for: .normal)
        }
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(self.handleCopyAction), for: .touchUpInside)
        return button
    }()

    public lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        if let image = self.closeImage {
            button.setImage(image, for: .normal)
        } else {
            button.setImage(UIImage(named: "close_x"), for: .normal)
        }
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(self.handleCloseAction), for: .touchUpInside)
        return button
    }()
}