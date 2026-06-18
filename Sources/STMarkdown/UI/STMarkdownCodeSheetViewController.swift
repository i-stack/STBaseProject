//
//  STMarkdownCodeSheetViewController.swift
//  STMarkdown
//

import UIKit
import SnapKit
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
    private var managedSheetBottomConstraint: Constraint?
    private var didAnimateIn = false
    public var onCopyTapped: (() -> Void)?
    public var onCloseTapped: (() -> Void)?
    public var headerTitle: String = "" {
        didSet {
            self.titleLabel.text = self.headerTitle
        }
    }

    /// 可注入的图片名称/资源，供子类或宿主层覆盖默认的关闭/复制图标。
    /// 默认值为 nil，此时使用内建图片名 fallback。
    public var closeImage: UIImage? {
        didSet { self.closeButton.setImage(self.closeImage, for: .normal) }
    }
    public var copyImage: UIImage? {
        didSet { self.copyButton.setImage(self.copyImage?.withRenderingMode(.alwaysTemplate), for: .normal) }
    }

    /// 配置底部弹窗布局。
    /// - Parameters:
    ///   - heightRatio: sheet 高度占父视图比例，默认 0.88
    ///   - dimmingView: 遮罩视图
    ///   - sheetView: 内容面板视图
    public func setupBottomSheetLayout(heightRatio: CGFloat = 0.88, dimmingView: UIView, sheetView: UIView) {
        self.managedDimmingView = dimmingView
        self.view.addSubview(dimmingView)
        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.view.addSubview(sheetView)
        sheetView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(heightRatio)
            self.managedSheetBottomConstraint = make.bottom.equalToSuperview().offset(LayoutMetrics.initialSheetBottomOffset).constraint
        }
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
            self.managedSheetBottomConstraint?.update(offset: 0)
            self.view.layoutIfNeeded()
        }
    }

    /// 收起并 dismiss
    public func dismissBottomSheet() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.managedDimmingView?.backgroundColor = UIColor.black.withAlphaComponent(0)
            self.managedSheetBottomConstraint?.update(offset: 900)
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
        sheetView.addSubview(self.grabberView)
        self.grabberView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(LayoutMetrics.grabberTop)
            make.centerX.equalToSuperview()
            make.width.equalTo(LayoutMetrics.grabberWidth)
            make.height.equalTo(LayoutMetrics.grabberHeight)
        }
        sheetView.addSubview(self.closeButton)
        self.closeButton.snp.makeConstraints { make in
            make.top.equalTo(self.grabberView.snp.bottom).offset(LayoutMetrics.closeTop)
            make.right.equalToSuperview().offset(-LayoutMetrics.closeTrailing)
            make.width.height.equalTo(LayoutMetrics.closeSize)
        }
    }

    /// 布局 copy 按钮和 title 到 sheetView
    public func layoutCommonCopyAndTitle(in sheetView: UIView, copyRightAnchor: UIView, copyCenterYAnchor: UIView, titleCenterYAnchor: UIView) {
        sheetView.addSubview(self.copyButton)
        self.copyButton.snp.makeConstraints { make in
            make.centerY.equalTo(copyCenterYAnchor)
            make.right.equalTo(copyRightAnchor.snp.left).offset(-LayoutMetrics.copyTrailingToRightAnchor)
            make.width.height.equalTo(LayoutMetrics.copySize)
        }

        sheetView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(LayoutMetrics.titleLeading)
            make.centerY.equalTo(titleCenterYAnchor)
            make.right.equalTo(self.copyButton.snp.left).offset(-LayoutMetrics.titleTrailingToCopy)
        }
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