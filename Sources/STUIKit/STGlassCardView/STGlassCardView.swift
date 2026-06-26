//
//  STGlassCardView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/6/26.
//

import UIKit

public class STGlassCardView: UIView {

    public struct ShadowConfiguration: Equatable {
        public var colorLight: UIColor
        public var colorDark: UIColor
        public var radiusLight: CGFloat
        public var radiusDark: CGFloat
        public var offsetLight: CGSize
        public var offsetDark: CGSize
        public var opacity: Float

        public static let `default` = ShadowConfiguration(
            colorLight: UIColor(hex: "000000").withAlphaComponent(0.08),
            colorDark: UIColor(hex: "000000").withAlphaComponent(0.35),
            radiusLight: 20.0,
            radiusDark: 8.0,
            offsetLight: CGSize(width: 0, height: 4),
            offsetDark: CGSize(width: 0, height: 2),
            opacity: 1.0
        )

        public static let none = ShadowConfiguration(
            colorLight: .clear,
            colorDark: .clear,
            radiusLight: 0,
            radiusDark: 0,
            offsetLight: .zero,
            offsetDark: .zero,
            opacity: 0
        )
    }

    private let effectView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.masksToBounds = true // 必须对毛玻璃强制裁剪，使其契合圆角
        return view
    }()

    public var contentView: UIView {
        return self.effectView.contentView
    }

    public override func addSubview(_ view: UIView) {
        if view === self.effectView {
            super.addSubview(view)
        } else {
            self.contentView.addSubview(view)
        }
    }

    public override func insertSubview(_ view: UIView, at index: Int) {
        if view === self.effectView {
            super.insertSubview(view, at: index)
        } else {
            self.contentView.insertSubview(view, at: index)
        }
    }

    public override func insertSubview(_ view: UIView, aboveSubview siblingSubview: UIView) {
        if view === self.effectView {
            super.insertSubview(view, aboveSubview: siblingSubview)
        } else {
            self.contentView.insertSubview(view, aboveSubview: siblingSubview)
        }
    }

    public override func insertSubview(_ view: UIView, belowSubview siblingSubview: UIView) {
        if view === self.effectView {
            super.insertSubview(view, belowSubview: siblingSubview)
        } else {
            self.contentView.insertSubview(view, belowSubview: siblingSubview)
        }
    }

    public var blurStyle: UIBlurEffect.Style = .systemUltraThinMaterial {
        didSet {
            self.effectView.effect = UIBlurEffect(style: self.blurStyle)
        }
    }

    public var cornerRadius: CGFloat = 16.0 {
        didSet {
            self.layer.cornerRadius = self.cornerRadius
            self.effectView.layer.cornerRadius = self.cornerRadius
            self.setNeedsLayout() // 圆角变化需重新计算 shadowPath
        }
    }

    public var shadowConfig: ShadowConfiguration = .default {
        didSet {
            self.applyShadowStyle(for: self.traitCollection.userInterfaceStyle)
        }
    }

    public var borderWidth: CGFloat = 0.0 {
        didSet {
            self.effectView.layer.borderWidth = self.borderWidth
        }
    }

    public var borderColor: UIColor? = nil {
        didSet {
            self.effectView.layer.borderColor = self.borderColor?.resolvedColor(with: self.traitCollection).cgColor
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }

    private func setupView() {
        self.layer.masksToBounds = false
        self.layer.cornerRadius = self.cornerRadius
        self.layer.shadowOpacity = self.shadowConfig.opacity

        super.addSubview(self.effectView)
        NSLayoutConstraint.activate([
            self.effectView.topAnchor.constraint(equalTo: self.topAnchor),
            self.effectView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.effectView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.effectView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        self.effectView.layer.cornerRadius = self.cornerRadius
        self.applyShadowStyle(for: self.traitCollection.userInterfaceStyle)

        // iOS 17+ 注册 trait 变更，避免使用已废弃的 traitCollectionDidChange
        if #available(iOS 17.0, *) {
            self.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (view: Self, _) in
                self?.applyAnimatedShadowStyle(for: view.traitCollection.userInterfaceStyle)
            }
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.cornerRadius).cgPath
    }

    public func configure(
        cornerRadius: CGFloat = 16.0,
        blurStyle: UIBlurEffect.Style = .systemUltraThinMaterial,
        borderWidth: CGFloat = 0.0,
        borderColor: UIColor? = nil,
        shadowConfig: ShadowConfiguration = .default
    ) {
        self.cornerRadius = cornerRadius
        self.blurStyle = blurStyle
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.shadowConfig = shadowConfig
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            self.applyAnimatedShadowStyle(for: self.traitCollection.userInterfaceStyle)
        }
    }

    private func applyAnimatedShadowStyle(for style: UIUserInterfaceStyle) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.25)
        self.applyShadowStyle(for: style)
        CATransaction.commit()
    }

    private func applyShadowStyle(for style: UIUserInterfaceStyle) {
        let isDark = style == .dark
        self.layer.shadowColor = (isDark ? self.shadowConfig.colorDark : self.shadowConfig.colorLight).cgColor
        self.layer.shadowRadius = isDark ? self.shadowConfig.radiusDark : self.shadowConfig.radiusLight
        self.layer.shadowOffset = isDark ? self.shadowConfig.offsetDark : self.shadowConfig.offsetLight
        self.layer.shadowOpacity = self.shadowConfig.opacity
        if let borderColor = self.borderColor {
            self.effectView.layer.borderColor = borderColor.resolvedColor(with: self.traitCollection).cgColor
        }
    }
}
