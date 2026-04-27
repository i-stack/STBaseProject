//
//  STHUD.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2017/10/14.
//

import UIKit
import Foundation
import CoreGraphics

public protocol STProgressHUDDelegate: AnyObject {
    func hudWasHidden(_ hud: STProgressHUD)
}

extension STProgressHUDDelegate {
    func hudWasHidden(_ hud: STProgressHUD) {}
}

public class STProgressHUD: UIView {

    public enum HudMode {
        case indeterminate, determinate, determinateHorizontalBar, annularDeterminate, customView, text
    }

    public enum HudAnimation {
        case fade, zoom, zoomOut, zoomIn
    }

    public static let maxOffset: CGFloat = 1_000_000.0

    public var progress: Float = 0.0 {
        didSet {
            guard oldValue != self.progress else { return }
            (self.indicator as? STProgressView)?.progress = self.progress
        }
    }

    public var progressObject: Progress? {
        didSet {
            guard oldValue !== self.progressObject else { return }
            self.setProgressDisplayLinkEnabled(true)
        }
    }

    public var customView: UIView? {
        didSet {
            guard oldValue != self.customView, self.mode == .customView else { return }
            self.updateIndicators()
        }
    }

    public var mode: HudMode = .indeterminate {
        didSet {
            guard self.mode != oldValue else { return }
            self.updateIndicators()
        }
    }

    public var contentColor = UIColor(white: 0, alpha: 0.7) {
        didSet {
            guard oldValue != self.contentColor else { return }
            self.updateViews(forColor: self.contentColor)
        }
    }

    public var animationType: HudAnimation = .fade
    public var offset: CGPoint = .zero
    public var margin: CGFloat = 20.0
    public var minSize: CGSize = .zero
    public var isSquare = false
    public var isDefaultMotionEffectsEnabled = true
    public var minShowTime: TimeInterval = 0.0
    public var graceTime: TimeInterval = 0.0
    public var removeFromSuperViewOnHide: Bool = false
    public var completionBlock: (() -> Void)?
    public weak var delegate: STProgressHUDDelegate?

    public private(set) lazy var backgroundView: STProgressHUDBackgroundView = {
        let view = STProgressHUDBackgroundView(frame: self.bounds)
        view.style = .solidColor
        view.backgroundColor = .clear
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.alpha = 0
        return view
    }()

    public private(set) lazy var bezelView: STProgressHUDBackgroundView = {
        let view = STProgressHUDBackgroundView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.alpha = 0
        return view
    }()

    public private(set) lazy var label: UILabel = {
        let lbl = UILabel()
        lbl.adjustsFontSizeToFitWidth = false
        lbl.textAlignment = .center
        lbl.textColor = self.contentColor
        lbl.font = UIFont.st_boldSystemFont(ofSize: self.defaultLabelFontSize)
        lbl.isOpaque = false
        lbl.backgroundColor = .clear
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.setContentCompressionResistancePriority(.init(rawValue: 998), for: .horizontal)
        lbl.setContentCompressionResistancePriority(.init(rawValue: 998), for: .vertical)
        return lbl
    }()

    public private(set) lazy var detailsLabel: UILabel = {
        let lbl = UILabel()
        lbl.adjustsFontSizeToFitWidth = false
        lbl.textAlignment = .center
        lbl.textColor = self.contentColor
        lbl.font = UIFont.st_boldSystemFont(ofSize: self.defaultDetailsLabelFontSize)
        lbl.isOpaque = false
        lbl.backgroundColor = .clear
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.setContentCompressionResistancePriority(.init(rawValue: 998), for: .horizontal)
        lbl.setContentCompressionResistancePriority(.init(rawValue: 998), for: .vertical)
        return lbl
    }()

    public private(set) lazy var button: UIButton = {
        let btn = STProgressHUDRoundedButton()
        btn.titleLabel?.textAlignment = .center
        btn.titleLabel?.font = UIFont.st_boldSystemFont(ofSize: self.defaultDetailsLabelFontSize)
        btn.setTitleColor(self.contentColor, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setContentCompressionResistancePriority(.init(rawValue: 998), for: .horizontal)
        btn.setContentCompressionResistancePriority(.init(rawValue: 998), for: .vertical)
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    convenience init(withView view: UIView) {
        self.init(frame: view.bounds)
    }

    deinit {
        self.unregisterFromNotifications()
    }

    @discardableResult
    public class func show(addedToView view: UIView, animated: Bool) -> STProgressHUD {
        let hud = STProgressHUD(withView: view)
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: animated)
        return hud
    }

    @discardableResult
    public class func hide(addedToView view: UIView, animated: Bool) -> Bool {
        guard let hud = hudForView(view) else { return false }
        hud.removeFromSuperViewOnHide = true
        hud.hide(animated: animated)
        return true
    }

    public class func hudForView(_ view: UIView) -> STProgressHUD? {
        return view.subviews.reversed().first { $0 is STProgressHUD } as? STProgressHUD
    }

    public func show(animated: Bool) {
        assert(Thread.isMainThread, "STProgressHUD needs to be accessed on the main thread.")
        self.minShowTimer?.invalidate()
        self.isUseAnimation = animated
        self.isFinished = false
        if self.graceTime > 0.0 {
            let timer = Timer(
                timeInterval: self.graceTime,
                target: self,
                selector: #selector(handleGraceTimer(_:)),
                userInfo: nil,
                repeats: false
            )
            RunLoop.current.add(timer, forMode: .common)
            self.graceTimer = timer
        } else {
            self.showUsingAnimation(animated)
        }
    }

    public func hide(animated: Bool) {
        assert(Thread.isMainThread, "STProgressHUD needs to be accessed on the main thread.")
        self.graceTimer?.invalidate()
        self.isUseAnimation = animated
        self.isFinished = true
        if self.minShowTime > 0.0, let showStarted = self.showStarted {
            let interval = Date().timeIntervalSince(showStarted)
            if interval < self.minShowTime {
                let timer = Timer(
                    timeInterval: self.minShowTime - interval,
                    target: self,
                    selector: #selector(handleMinShowTimer(_:)),
                    userInfo: nil,
                    repeats: false
                )
                RunLoop.current.add(timer, forMode: .common)
                self.minShowTimer = timer
                return
            }
        }
        self.hideUsingAnimation(self.isUseAnimation)
    }

    public func hide(animated: Bool, afterDelay delay: TimeInterval) {
        let timer = Timer(
            timeInterval: delay,
            target: self,
            selector: #selector(handleHideTimer(_:)),
            userInfo: animated,
            repeats: false
        )
        RunLoop.current.add(timer, forMode: .common)
        self.hideDelayTimer = timer
    }

    public override func updateConstraints() {
        let metrics: [String: Any] = ["margin": self.margin]
        var subviews: [UIView] = [self.topSpacer, self.label, self.detailsLabel, self.button, self.bottomSpacer]
        if let indicator = self.indicator {
            subviews.insert(indicator, at: 1)
        }

        self.removeConstraints(self.constraints)
        self.topSpacer.removeConstraints(self.topSpacer.constraints)
        self.bottomSpacer.removeConstraints(self.bottomSpacer.constraints)
        self.bezelView.removeConstraints(self.bezelConstraints)
        self.bezelConstraints = []

        var centeringConstraints: [NSLayoutConstraint] = [
            NSLayoutConstraint(item: self.bezelView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: self.offset.x),
            NSLayoutConstraint(item: self.bezelView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: self.offset.y)
        ]
        self.apply(priority: .init(rawValue: 998), toConstraints: centeringConstraints)
        self.addConstraints(centeringConstraints)

        var sideConstraints: [NSLayoutConstraint] = []
        sideConstraints += NSLayoutConstraint.constraints(withVisualFormat: "|-(>=margin)-[bezel]-(>=margin)-|", options: .alignAllTop, metrics: metrics, views: ["bezel": self.bezelView])
        sideConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=margin)-[bezel]-(>=margin)-|", options: .alignAllTop, metrics: metrics, views: ["bezel": self.bezelView])
        self.apply(priority: .init(rawValue: 999), toConstraints: sideConstraints)
        self.addConstraints(sideConstraints)

        if self.minSize != .zero {
            let miniSizeConstraints: [NSLayoutConstraint] = [
                NSLayoutConstraint(item: self.bezelView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.minSize.width),
                NSLayoutConstraint(item: self.bezelView, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.minSize.height)
            ]
            self.apply(priority: .init(rawValue: 997), toConstraints: miniSizeConstraints)
            self.bezelConstraints += miniSizeConstraints
        }

        if self.isSquare {
            let square = NSLayoutConstraint(item: self.bezelView, attribute: .height, relatedBy: .equal, toItem: self.bezelView, attribute: .width, multiplier: 1, constant: 0)
            square.priority = .init(rawValue: 997)
            self.bezelConstraints.append(square)
        }

        self.topSpacer.addConstraint(NSLayoutConstraint(item: self.topSpacer, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.margin))
        self.bottomSpacer.addConstraint(NSLayoutConstraint(item: self.bottomSpacer, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: self.margin))
        self.bezelConstraints.append(NSLayoutConstraint(item: self.topSpacer, attribute: .height, relatedBy: .equal, toItem: self.bottomSpacer, attribute: .height, multiplier: 1, constant: 0))

        self.paddingConstraints = []
        for (index, view) in subviews.enumerated() {
            self.bezelConstraints.append(NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: self.bezelView, attribute: .centerX, multiplier: 1, constant: 0))
            self.bezelConstraints += NSLayoutConstraint.constraints(withVisualFormat: "|-(>=margin)-[view]-(>=margin)-|", options: .alignAllTop, metrics: metrics, views: ["view": view])
            if index == 0 {
                self.bezelConstraints.append(NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self.bezelView, attribute: .top, multiplier: 1, constant: 0))
            } else if index == subviews.count - 1 {
                self.bezelConstraints.append(NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self.bezelView, attribute: .bottom, multiplier: 1, constant: 0))
            }
            if index > 0 {
                let padding = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: subviews[index - 1], attribute: .bottom, multiplier: 1, constant: 0)
                self.bezelConstraints.append(padding)
                self.paddingConstraints.append(padding)
            }
        }

        self.bezelView.addConstraints(self.bezelConstraints)
        self.updatePaddingConstraints()
        super.updateConstraints()
    }

    public override func layoutSubviews() {
        if !self.needsUpdateConstraints() {
            self.updatePaddingConstraints()
        }
        super.layoutSubviews()
    }

    private let defaultPadding: CGFloat = 4.0
    private let defaultLabelFontSize: CGFloat = 16.0
    private let defaultDetailsLabelFontSize: CGFloat = 12.0
    private var isUseAnimation: Bool = false
    private var isFinished: Bool = true
    private var showStarted: Date?
    private var indicator: UIView?
    private var paddingConstraints: [NSLayoutConstraint] = []
    private var bezelConstraints: [NSLayoutConstraint] = []
    private var graceTimer: Timer?
    private var minShowTimer: Timer?
    private var hideDelayTimer: Timer?
    private var progressObjectDisplayLink: CADisplayLink? {
        willSet {
            guard newValue !== self.progressObjectDisplayLink else { return }
            self.progressObjectDisplayLink?.invalidate()
        }
        didSet {
            guard oldValue !== self.progressObjectDisplayLink else { return }
            self.progressObjectDisplayLink?.add(to: .main, forMode: .default)
        }
    }

    private lazy var topSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private lazy var bottomSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
}

private extension STProgressHUD {

    func commonInit() {
        self.alpha = 0
        self.isOpaque = false
        self.backgroundColor = .clear
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.layer.allowsGroupOpacity = false
        self.setupViews()
        self.updateIndicators()
        self.registerForNotifications()
    }

    func setupViews() {
        self.addSubview(self.backgroundView)
        self.addSubview(self.bezelView)
        self.updateBezelMotionEffects()
        for view in [self.label, self.detailsLabel, self.button] as [UIView] {
            self.bezelView.addSubview(view)
        }
        self.bezelView.addSubview(self.topSpacer)
        self.bezelView.addSubview(self.bottomSpacer)
    }

    func showUsingAnimation(_ animated: Bool) {
        self.bezelView.layer.removeAllAnimations()
        self.backgroundView.layer.removeAllAnimations()
        self.hideDelayTimer?.invalidate()
        self.showStarted = Date()
        self.alpha = 1.0
        self.setProgressDisplayLinkEnabled(true)
        if animated {
            self.animateIn(true, withType: self.animationType, completion: nil)
        } else {
            self.bezelView.alpha = 1
            self.backgroundView.alpha = 1
        }
    }

    func hideUsingAnimation(_ animated: Bool) {
        if animated, self.showStarted != nil {
            self.showStarted = nil
            self.animateIn(false, withType: self.animationType) { [weak self] _ in
                self?.done()
            }
        } else {
            self.showStarted = nil
            self.bezelView.alpha = 0
            self.backgroundView.alpha = 0
            self.done()
        }
    }

    func animateIn(_ animatingIn: Bool, withType: HudAnimation, completion: ((Bool) -> Void)?) {
        var type = withType
        if type == .zoom {
            type = animatingIn ? .zoomIn : .zoomOut
        }
        let small = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let large = CGAffineTransform(scaleX: 1.5, y: 1.5)
        if animatingIn, self.bezelView.alpha == 0.0 {
            self.bezelView.transform = (type == .zoomIn) ? small : large
        }
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: .beginFromCurrentState,
            animations: {
                if animatingIn {
                    self.bezelView.transform = .identity
                } else if type == .zoomIn {
                    self.bezelView.transform = large
                } else if type == .zoomOut {
                    self.bezelView.transform = small
                }
                self.bezelView.alpha = animatingIn ? 1.0 : 0.0
                self.backgroundView.alpha = animatingIn ? 1.0 : 0.0
            },
            completion: completion
        )
    }

    func done() {
        self.hideDelayTimer?.invalidate()
        self.setProgressDisplayLinkEnabled(false)
        if self.isFinished {
            self.alpha = 0
            if self.removeFromSuperViewOnHide {
                self.removeFromSuperview()
            }
        }
        self.completionBlock?()
        self.delegate?.hudWasHidden(self)
    }

    func updateIndicators() {
        switch self.mode {
        case .indeterminate:
            guard !(self.indicator is UIActivityIndicatorView) else { break }
            self.indicator?.removeFromSuperview()
            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.startAnimating()
            self.indicator = activityIndicator
            self.bezelView.addSubview(activityIndicator)

        case .determinateHorizontalBar:
            self.indicator?.removeFromSuperview()
            let barView = STBarProgressView()
            self.indicator = barView
            self.bezelView.addSubview(barView)

        case .determinate:
            guard !(self.indicator is STRoundProgressView) else { break }
            self.indicator?.removeFromSuperview()
            let roundView = STRoundProgressView()
            self.indicator = roundView
            self.bezelView.addSubview(roundView)

        case .annularDeterminate:
            guard !(self.indicator is STAnnularProgressView) else { break }
            self.indicator?.removeFromSuperview()
            let annularView = STAnnularProgressView()
            self.indicator = annularView
            self.bezelView.addSubview(annularView)

        case .customView:
            guard let customView = self.customView, customView !== self.indicator else { break }
            self.indicator?.removeFromSuperview()
            self.indicator = customView
            self.bezelView.addSubview(customView)

        case .text:
            self.indicator?.removeFromSuperview()
            self.indicator = nil
        }

        self.indicator?.translatesAutoresizingMaskIntoConstraints = false
        (self.indicator as? STProgressView)?.progress = self.progress
        self.indicator?.setContentCompressionResistancePriority(.init(rawValue: 998), for: .horizontal)
        self.indicator?.setContentCompressionResistancePriority(.init(rawValue: 998), for: .vertical)
        self.updateViews(forColor: self.contentColor)
        self.setNeedsUpdateConstraints()
    }

    func updateViews(forColor color: UIColor) {
        self.label.textColor = color
        self.detailsLabel.textColor = color
        self.button.setTitleColor(color, for: .normal)
        if let activityIndicator = self.indicator as? UIActivityIndicatorView {
            activityIndicator.color = color
        } else if let barProgressView = self.indicator as? STBarProgressView {
            barProgressView.progressColor = color
            barProgressView.lineColor = color
        } else if let circleProgressView = self.indicator as? STCircleProgressView {
            circleProgressView.progressTintColor = color
            circleProgressView.backgroundTintColor = color.withAlphaComponent(0.1)
        }
    }

    func updateBezelMotionEffects() {
        if self.isDefaultMotionEffectsEnabled {
            let effectOffset: CGFloat = 10.0
            let effectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            effectX.maximumRelativeValue = effectOffset
            effectX.minimumRelativeValue = -effectOffset
            // Fix: effectY 应使用 tiltAlongVerticalAxis
            let effectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
            effectY.maximumRelativeValue = effectOffset
            effectY.minimumRelativeValue = -effectOffset
            let group = UIMotionEffectGroup()
            group.motionEffects = [effectX, effectY]
            self.bezelView.addMotionEffect(group)
        } else {
            self.bezelView.motionEffects.forEach { self.bezelView.removeMotionEffect($0) }
        }
    }

    func updatePaddingConstraints() {
        var hasVisibleAncestors = false
        for padding in self.paddingConstraints {
            guard let firstView = padding.firstItem as? UIView,
                  let secondView = padding.secondItem as? UIView else { continue }
            let firstVisible = !firstView.isHidden && firstView.intrinsicContentSize != .zero
            let secondVisible = !secondView.isHidden && secondView.intrinsicContentSize != .zero
            padding.constant = (firstVisible && (secondVisible || hasVisibleAncestors)) ? self.defaultPadding : 0
            hasVisibleAncestors = hasVisibleAncestors || secondVisible
        }
    }

    func apply(priority: UILayoutPriority, toConstraints constraints: [NSLayoutConstraint]) {
        constraints.forEach { $0.priority = priority }
    }

    func setProgressDisplayLinkEnabled(_ enabled: Bool) {
        if enabled, self.progressObject != nil {
            if self.progressObjectDisplayLink == nil {
                self.progressObjectDisplayLink = CADisplayLink(target: self, selector: #selector(updateProgressFromProgressObject))
            }
        } else {
            self.progressObjectDisplayLink = nil
        }
    }

    func registerForNotifications() {
        #if !os(tvOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(statusBarOrientationDidChange(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        #endif
    }

    func unregisterFromNotifications() {
        #if !os(tvOS)
        NotificationCenter.default.removeObserver(self)
        #endif
    }
}

private extension STProgressHUD {

    @objc func handleGraceTimer(_ timer: Timer) {
        guard !self.isFinished else { return }
        self.showUsingAnimation(self.isUseAnimation)
    }

    @objc func handleMinShowTimer(_ timer: Timer) {
        self.hideUsingAnimation(self.isUseAnimation)
    }

    @objc func handleHideTimer(_ timer: Timer) {
        guard let animated = timer.userInfo as? Bool else { return }
        self.hide(animated: animated)
    }

    @objc func updateProgressFromProgressObject() {
        guard let fractionCompleted = self.progressObject?.fractionCompleted else { return }
        self.progress = Float(fractionCompleted)
    }

    #if !os(tvOS)
    @objc func statusBarOrientationDidChange(_ notification: NSNotification) {
        guard self.superview != nil else { return }
        self.frame = self.superview?.bounds ?? self.frame
    }
    #endif
}

public class STProgressHUDBackgroundView: UIView {

    public enum BackgroundStyle {
        case solidColor, blur, liquidGlass
    }

    public var style: BackgroundStyle? {
        didSet { self.updateForBackgroundStyle() }
    }

    public var color: UIColor? {
        didSet {
            assert(self.color != nil, "The color should not be nil.")
            guard let color = self.color else { return }
            self.backgroundColor = color
        }
    }

    private var effectView: UIVisualEffectView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isOpaque = false
        self.style = .blur
        self.color = UIColor(white: 0.8, alpha: 0.6)
        self.clipsToBounds = true
        self.updateForBackgroundStyle()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isOpaque = false
        self.style = .blur
        self.color = UIColor(white: 0.8, alpha: 0.6)
        self.clipsToBounds = true
        self.updateForBackgroundStyle()
    }

    public override var intrinsicContentSize: CGSize { .zero }

    private func updateForBackgroundStyle() {
        if self.style == .liquidGlass {
            self.effectView?.removeFromSuperview()
            self.st_enableLiquidGlassBackground(
                tintColor: self.color ?? UIColor(white: 0.8, alpha: 0.35),
                highlightOpacity: 0.28,
                borderColor: UIColor.white.withAlphaComponent(0.32)
            )
            self.backgroundColor = .clear
            self.layer.allowsGroupOpacity = false
        } else if self.style == .blur {
            self.st_disableLiquidGlassBackground()
            self.effectView?.removeFromSuperview()
            let effect = UIBlurEffect(style: .light)
            let view = UIVisualEffectView(effect: effect)
            self.addSubview(view)
            view.frame = self.bounds
            view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            self.effectView = view
            self.backgroundColor = self.color
            self.layer.allowsGroupOpacity = false
        } else {
            self.st_disableLiquidGlassBackground()
            self.effectView?.removeFromSuperview()
            self.effectView = nil
            self.backgroundColor = self.color
            self.layer.allowsGroupOpacity = true
        }
    }
}

class STProgressHUDRoundedButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.borderWidth = 1.0
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.bounds.height / 2.0
    }

    override var intrinsicContentSize: CGSize {
        guard self.allControlEvents != UIControl.Event(rawValue: 0) else { return .zero }
        var size = super.intrinsicContentSize
        size.width += 20.0
        return size
    }

    override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)
        self.layer.borderColor = color?.cgColor
        let highlighted = self.isHighlighted
        self.isHighlighted = highlighted
    }

    override var isHighlighted: Bool {
        didSet {
            let baseColor = self.titleColor(for: .selected)
            self.backgroundColor = self.isHighlighted ? baseColor?.withAlphaComponent(0.1) : .clear
        }
    }
}
