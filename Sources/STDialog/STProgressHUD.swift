import UIKit
import Foundation
import CoreGraphics

public protocol STProgressHUDDelegate {
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
    
    public static let maxOffset: CGFloat = 1000000.0
    let defaultPadding: CGFloat = 4.0
    let defaultLabelFontSize: CGFloat = 16.0
    let defaultDetailsLabelFontSize: CGFloat = 12.0
    public var progress: Float = 0.0 {
        didSet {
            if(oldValue != progress) {
                if let progressView = indicator as? STProgressView {
                    progressView.progress = progress
                }
            }
        }
    }
    public var progressObject: Progress? {
        didSet {
            if(oldValue !== progressObject) {
                setProgressDisplayLinkEnabled(true)
            }
        }
    }
    public var bezelView: STProgressHUDBackgroundView?
    public var backgroundView: STProgressHUDBackgroundView?
    public var customView: UIView? {
        didSet {
            if(oldValue != customView && mode == .customView) {
                updateIndicators()
            }
        }
    }
    public var label: UILabel?
    public var detailsLabel: UILabel?
    public var button: UIButton?
    public var removeFromSuperViewOnHide: Bool = false
    public var mode: HudMode = .indeterminate {
        didSet {
            if(mode != oldValue) {
                updateIndicators()
            }
        }
    }
    public var contentColor = UIColor(white: 0, alpha: 0.7) {
        didSet {
            if (oldValue != contentColor) {
                updateViews(forColor: contentColor)
            }
        }
    }
    public var animationType: HudAnimation = .fade
    public var offset: CGPoint = CGPoint(x: 0, y: 0)
    public var margin: CGFloat = 20.0
    public var minSize:CGSize = CGSize.zero
    public var isSquare = false
    public var isDefaultMotionEffectsEnabled = true
    public var minShowTime: TimeInterval = 0.0
    public var completionBlock: (() -> Void)?
    public var delegate: STProgressHUDDelegate?
    public var graceTime: TimeInterval = 0.0
    var activityIndicatorColor: UIColor?
    var isUseAnimation: Bool?
    var isFinished: Bool = true
    var indicator: UIView?
    var showStarted: Date?
    var paddingConstraints: [NSLayoutConstraint]?
    var bezelConstraints: [NSLayoutConstraint]?
    var topSpacer: UIView?
    var bottomSpacer: UIView?
    var graceTimer: Timer?
    var minShowTimer: Timer?
    var hideDelayTimer: Timer?
    var progressObjectDisplayLink: CADisplayLink? {
        willSet {
            if newValue !== progressObjectDisplayLink {
                progressObjectDisplayLink?.invalidate()
            }
        }
        didSet {
            if oldValue !== progressObjectDisplayLink {
                progressObjectDisplayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
            }
        }
    }
    
    public class func show(addedToView view: UIView, animated: Bool) -> STProgressHUD {
        let hud = STProgressHUD(withView: view)
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: animated)
        return hud;
    }
    
    public class func hide(addedToView view: UIView, animated: Bool) -> Bool {
        let hud = hudForView(view)
        if (hud != nil) {
            hud?.removeFromSuperViewOnHide = true
            hud?.hide(animated: animated)
            return true
        }
        return false
    }
    
    public class func hudForView(_ view: UIView) -> STProgressHUD? {
        let subviews = view.subviews.reversed()
        for subview in subviews {
            if (subview is STProgressHUD) {
                return subview as? STProgressHUD
            }
        }
        
        return nil
    }
    
    func commonInit() {
        self.alpha = 0
        self.isOpaque = false
        self.backgroundColor = UIColor.clear
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.layer.allowsGroupOpacity = false
        setupViews()
        updateIndicators()
        registerForNotifications()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    convenience init(withView view: UIView) {
        self.init(frame: view.bounds)
    }
    
    func show(animated: Bool) {
        assert(Thread.isMainThread, "Progresshud needs to be accessed on the main thread.")
        minShowTimer?.invalidate()
        isUseAnimation = animated
        isFinished = false
        if ( graceTime > 0.0) {
            let timer = Timer(timeInterval: graceTime, target: self, selector: #selector(handleGraceTimer(_:)), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
            graceTimer = timer
        } else {
            showUsingAnimation(animated)
        }
    }
    
    func hide(animated: Bool) {
        assert(Thread.isMainThread, "Progresshud needs to be accessed on the main thread.")
        graceTimer?.invalidate()
        isUseAnimation = animated
        isFinished = true
        if (minShowTime > 0.0 && showStarted != nil) {
            let interval = Date().timeIntervalSince(showStarted!)
            if(interval < minShowTime) {
                let timer = Timer(timeInterval: (minShowTime - interval), target: self, selector: #selector(handleMinShowTimer(_:)), userInfo: nil, repeats: false)
                RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
                minShowTimer = timer
            }
        } else {
            hideUsingAnimation(isUseAnimation!)
        }
    }
    
    func hide(animated: Bool, afterDelay delay: TimeInterval) {
        let timer = Timer(timeInterval: delay, target: self, selector: #selector(handleHideTimer(_:)), userInfo: animated, repeats: false)
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
        hideDelayTimer = timer
    }
    
    @objc func handleGraceTimer(_ timer: Timer) {
        if(!isFinished) {
            showUsingAnimation(isUseAnimation!)
        }
    }
    
    @objc func handleMinShowTimer(_ timer: Timer) {
        hideUsingAnimation(isUseAnimation!)
    }
    
    @objc func handleHideTimer(_ timer: Timer) {
        hide(animated: timer.userInfo as! Bool)
    }
    
    func showUsingAnimation(_ animation: Bool) {
        bezelView?.layer.removeAllAnimations()
        backgroundView?.layer.removeAllAnimations()
        hideDelayTimer?.invalidate()
        showStarted = Date()
        alpha = 1.0
        setProgressDisplayLinkEnabled(true)
        if(animation) {
            animateIn(true, withType: animationType, completion: nil)
        } else {
            self.bezelView?.alpha = 1
            self.backgroundView?.alpha = 1
        }
    }
    
    func hideUsingAnimation(_ animated: Bool) {
        if (animated && showStarted != nil) {
            self.showStarted = nil
            animateIn(false, withType: animationType, completion: { finished in
                self.done()
            })
        } else {
            showStarted = nil
            bezelView?.alpha = 0
            backgroundView?.alpha = 1
            done()
        }
    }
    
    func animateIn(_ animatingIn: Bool, withType: HudAnimation, completion: ((Bool) -> Void)?) {
        var type = withType
        if (type == .zoom) {
            type = animatingIn ? .zoomIn : .zoomOut
        }
        let small = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let large = CGAffineTransform(scaleX: 1.5, y: 1.5)
        if (animatingIn && bezelView?.alpha == 0.0 && type == .zoomIn) {
            bezelView?.transform = small
        } else if (animatingIn && bezelView?.alpha == 0.0 && type == .zoomOut) {
            bezelView?.transform = large
        }
        let animations = { () -> Void in
            if (animatingIn) {
                self.bezelView?.transform = .identity
            } else if(!animatingIn && type == .zoomIn) {
                self.bezelView?.transform = large
            } else if(!animatingIn && type == .zoomOut) {
                self.bezelView?.transform = small
            }
            self.bezelView?.alpha = animatingIn ? 1.0 : 0.0
            self.backgroundView?.alpha = animatingIn ? 1.0: 0.0
        }
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .beginFromCurrentState, animations: animations, completion: completion)
    }
    
    func done() {
        hideDelayTimer?.invalidate()
        setProgressDisplayLinkEnabled(false)
        if (isFinished) {
            alpha = 0
            if (removeFromSuperViewOnHide) {
                removeFromSuperview()
            }
        }
        if let completed = completionBlock {
            completed()
        }
        if delegate != nil {
            delegate?.hudWasHidden(self)
        }
    }
    
    func setupViews() {
        let defaultColor = contentColor
        backgroundView = STProgressHUDBackgroundView(frame: self.bounds)
        backgroundView?.style = .solidColor
        backgroundView?.backgroundColor = UIColor.clear
        backgroundView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView?.alpha = 0
        addSubview(backgroundView!)
        
        bezelView = STProgressHUDBackgroundView()
        bezelView?.translatesAutoresizingMaskIntoConstraints = false
        bezelView?.layer.cornerRadius = 5
        bezelView?.alpha = 0
        addSubview(bezelView!)
        updateBezelMotionEffects()
        
        label = UILabel()
        label?.adjustsFontSizeToFitWidth = false
        label?.textAlignment = .center
        label?.textColor = defaultColor
        label?.font = UIFont.boldSystemFont(ofSize: defaultLabelFontSize)
        label?.isOpaque = false
        label?.backgroundColor = UIColor.clear
        
        detailsLabel = UILabel()
        detailsLabel?.adjustsFontSizeToFitWidth = false
        detailsLabel?.textAlignment = .center
        detailsLabel?.textColor = defaultColor
        detailsLabel?.font = UIFont.boldSystemFont(ofSize: defaultDetailsLabelFontSize)
        detailsLabel?.isOpaque = false
        detailsLabel?.backgroundColor = UIColor.clear
        
        button = STProgressHUDRoundedButton()
        button?.titleLabel?.textAlignment = .center
        button?.titleLabel?.font = UIFont.boldSystemFont(ofSize: defaultDetailsLabelFontSize)
        button?.setTitleColor(defaultColor, for: .normal)
        
        for view: UIView in [label!, detailsLabel!, button!] {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998.0), for: .horizontal)
            view.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998.0), for: .vertical)
            bezelView?.addSubview(view)
        }
        
        topSpacer = UIView()
        topSpacer?.translatesAutoresizingMaskIntoConstraints = false
        topSpacer?.isHidden = true
        bezelView?.addSubview(topSpacer!)
        
        bottomSpacer = UIView()
        bottomSpacer?.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer?.isHidden = true
        bezelView?.addSubview(bottomSpacer!)
    }
    
    func updateIndicators() {
        switch mode {
        case .indeterminate:
            if indicator as? UIActivityIndicatorView == nil {
                indicator?.removeFromSuperview()
                let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
                activityIndicator.startAnimating()
                indicator = activityIndicator
                bezelView?.addSubview(activityIndicator)
            }
        case .determinateHorizontalBar:
            indicator?.removeFromSuperview()
            indicator = STBarProgressView()
            bezelView?.addSubview(indicator!)
        case .determinate:
            if !(indicator is STRoundProgressView) {
                indicator?.removeFromSuperview()
                indicator = STRoundProgressView()
                bezelView?.addSubview(indicator!)
            }
        case .annularDeterminate:
            if !(indicator is STAnnularProgressView) {
                indicator?.removeFromSuperview()
                indicator = STAnnularProgressView()
                bezelView?.addSubview(indicator!)
            }
        case .customView:
            if customView != nil && customView !== indicator {
                indicator?.removeFromSuperview()
                indicator = customView
                bezelView?.addSubview(customView!)
            }
        case .text:
            indicator?.removeFromSuperview()
            indicator = nil
        }
        
        indicator?.translatesAutoresizingMaskIntoConstraints = false
        if let progressView = indicator as? STProgressView {
            progressView.progress = progress
        }
        
        indicator?.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998), for: .horizontal)
        indicator?.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 998), for: .vertical)
        
        updateViews(forColor: contentColor)
        setNeedsUpdateConstraints()
    }
    
    func updateViews(forColor color: UIColor) {
        label?.textColor = color
        detailsLabel?.textColor = color
        button?.setTitleColor(color, for: .normal)
        if let activityIndicator = indicator as? UIActivityIndicatorView {
            activityIndicator.color = color
        } else if let barProgressView = indicator as? STBarProgressView {
            barProgressView.progressColor = color
            barProgressView.lineColor = color
        } else if let circleProgressView = indicator as? STCircleProcessView {
            circleProgressView.progressTintColor = color
            circleProgressView.backgroundTintColor = color.withAlphaComponent(0.1)
        }
    }
    
    func updateBezelMotionEffects() {
        if (isDefaultMotionEffectsEnabled) {
            let effectOffset: CGFloat = 10.0
            let effectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            effectX.maximumRelativeValue = effectOffset
            effectX.minimumRelativeValue = -effectOffset
            
            let effectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongHorizontalAxis)
            effectY.maximumRelativeValue = effectOffset
            effectY.minimumRelativeValue = -effectOffset
            
            let group = UIMotionEffectGroup()
            group.motionEffects = [effectX, effectY]
            bezelView?.addMotionEffect(group)
        } else {
            if let effects = bezelView?.motionEffects {
                for effect in effects {
                    bezelView?.removeMotionEffect(effect)
                }
            }
        }
    }
    
    public override func updateConstraints() {
        let metrics = ["margin": margin]
        
        var subviews: [UIView] = [topSpacer!, label!, detailsLabel!, button!, bottomSpacer!]
        if (indicator != nil) {
            subviews.insert(indicator!, at: 1)
        }
        
        removeConstraints(constraints)
        topSpacer?.removeConstraints(topSpacer!.constraints)
        bottomSpacer?.removeConstraints(bottomSpacer!.constraints)
        if (bezelConstraints != nil) {
            bezelView?.removeConstraints(bezelConstraints!)
            bezelConstraints = [NSLayoutConstraint]()
        } else {
            bezelConstraints = [NSLayoutConstraint]()
        }
        
        var centeringConstraints = [NSLayoutConstraint]()
        centeringConstraints.append(NSLayoutConstraint(item: bezelView!, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: offset.x))
        centeringConstraints.append(NSLayoutConstraint(item: bezelView!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: offset.y))
        apply(priority: UILayoutPriority(rawValue: 998), toConstraints: centeringConstraints)
        addConstraints(centeringConstraints)
        
        var sideConstraints = [NSLayoutConstraint]()
        sideConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-(>=margin)-[bezel]-(>=margin)-|", options: .alignAllTop, metrics: metrics, views: ["bezel": bezelView!]))
        sideConstraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=margin)-[bezel]-(>=margin)-|", options: .alignAllTop, metrics: metrics, views: ["bezel": bezelView!]))
        self.apply(priority: UILayoutPriority(rawValue: 999), toConstraints: sideConstraints)
        self.addConstraints(sideConstraints)
        
        let minimumSize = minSize
        if (minimumSize != CGSize.zero) {
            var miniSizeConstraints = [NSLayoutConstraint]()
            miniSizeConstraints.append(NSLayoutConstraint(item: bezelView!, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: minimumSize.width))
            miniSizeConstraints.append(NSLayoutConstraint(item: bezelView!, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: minimumSize.height))
            self.apply(priority: UILayoutPriority(rawValue: 997), toConstraints: miniSizeConstraints)
            bezelConstraints?.append(contentsOf: miniSizeConstraints)
        }
        
        if(isSquare) {
            let square = NSLayoutConstraint(item: bezelView!, attribute: .height, relatedBy: .equal, toItem: bezelView!, attribute: .width, multiplier: 1, constant: 0)
            square.priority = UILayoutPriority(rawValue: 997)
            bezelConstraints?.append(square)
        }
        
        topSpacer?.addConstraint(NSLayoutConstraint(item: topSpacer!, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: margin))
        bottomSpacer?.addConstraint(NSLayoutConstraint(item: bottomSpacer!, attribute: .height, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: margin))
        bezelConstraints?.append(NSLayoutConstraint(item: topSpacer!, attribute: .height, relatedBy: .equal, toItem: bottomSpacer!, attribute: .height, multiplier: 1, constant: 0))
        
        paddingConstraints = [NSLayoutConstraint]()
        for (index, view) in subviews.enumerated() {
            bezelConstraints?.append(NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: bezelView!, attribute: .centerX, multiplier: 1, constant: 0))
            bezelConstraints?.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "|-(>=margin)-[view]-(>=margin)-|", options: .alignAllTop, metrics: metrics, views: ["view": view]))
            if (index == 0) {
                bezelConstraints?.append(NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: bezelView!, attribute: .top, multiplier: 1, constant: 0))
            } else if (index == subviews.count - 1) {
                bezelConstraints?.append(NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: bezelView!, attribute: .bottom, multiplier: 1, constant: 0))
            }
            
            if (index > 0) {
                let padding = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: subviews[index - 1], attribute: .bottom, multiplier: 1, constant: 0)
                bezelConstraints?.append(padding)
                paddingConstraints?.append(padding)
            }
        }
        
        bezelView?.addConstraints(bezelConstraints!)
        updatePaddingConstraints()
        
        super.updateConstraints()
    }
    
    public override func layoutSubviews() {
        if (!needsUpdateConstraints()) {
            updatePaddingConstraints()
        }
        super.layoutSubviews()
    }
    
    func updatePaddingConstraints() {
        var hasVisibleAncestors = false
        for (_, padding) in paddingConstraints!.enumerated() {
            let firstView = padding.firstItem as! UIView
            let secondView = padding.secondItem as! UIView
            let firstVisible = !firstView.isHidden && firstView.intrinsicContentSize != CGSize.zero
            let secondVisible = !secondView.isHidden && secondView.intrinsicContentSize != CGSize.zero
            padding.constant = (firstVisible && (secondVisible || hasVisibleAncestors)) ? defaultPadding : 0
            hasVisibleAncestors = hasVisibleAncestors || secondVisible
        }
    }
    
    func apply(priority: UILayoutPriority, toConstraints constraints: [NSLayoutConstraint]) {
        for constraint in constraints {
            constraint.priority = priority
        }
    }
    
    func setProgressDisplayLinkEnabled(_ enabled: Bool) {
        if(enabled && (progressObject != nil)) {
            if(progressObjectDisplayLink == nil) {
                self.progressObjectDisplayLink = CADisplayLink(target: self, selector: #selector(updateProgressFromProgressObject))
            }
        } else {
            progressObjectDisplayLink = nil
        }
    }
    
    @objc func updateProgressFromProgressObject() {
        progress = Float((progressObject?.fractionCompleted)!)
    }
    
    func registerForNotifications() {
        #if !os(tvOS)
        let nc = NotificationCenter.default
        if #available(iOS 13.0, *) {
            nc.addObserver(self, selector: #selector(statusBarOrientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        } else {
            nc.addObserver(self, selector: #selector(statusBarOrientationDidChange(_:)), name: UIApplication.didChangeStatusBarFrameNotification, object: nil)
        }
        #endif
    }
    
    func unregisterFormNotifications() {
        #if !os(tvOS)
        let nc = NotificationCenter.default
        if #available(iOS 13.0, *) {
            nc.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        } else {
            nc.removeObserver(self, name: UIApplication.didChangeStatusBarFrameNotification, object: nil)
        }
        #endif
    }
    
#if !os(tvOS)
    @objc func statusBarOrientationDidChange(_ notification: NSNotification) {
        if (superview != nil) {
            updateForCurrentOrientation(animated: true)
        }
    }
#endif
    func updateForCurrentOrientation(animated: Bool) {
        if let superView = self.superview {
            frame = superView.bounds
        }
    }
}

public class STProgressHUDBackgroundView: UIView {
    public enum BackgroundStyle {
        case solidColor, blur
    }
    
    public var style: BackgroundStyle? {
        didSet {
            updateForBackgroundStyle()
        }
    }
    public var color: UIColor? {
        didSet {
            assert(color != nil, "The color should not be nil.")
            updateViews(forColor: color!)
        }
    }
    
    var effectView: UIVisualEffectView?
    #if !os(tvOS)
    var toolbar: UIToolbar?
    #endif
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        style = .blur
        color = UIColor(white: 0.8, alpha: 0.6)
        self.clipsToBounds = true
        updateForBackgroundStyle()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override var intrinsicContentSize: CGSize {
        return CGSize.zero
    }
    
    func updateForBackgroundStyle() {
        if (style == .blur) {
            let effect = UIBlurEffect(style: .light)
            effectView = UIVisualEffectView(effect: effect)
            self.addSubview(effectView!)
            effectView?.frame = self.bounds
            effectView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            backgroundColor = color
            layer.allowsGroupOpacity = false
        } else {
            effectView?.removeFromSuperview()
            effectView = nil
            backgroundColor = color
        }
    }
    
    func updateViews(forColor color: UIColor) {
        backgroundColor = color
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
        let height = self.bounds.height
        self.layer.cornerRadius = height / 2.0
    }
    
    override var intrinsicContentSize: CGSize {
        if(self.allControlEvents == UIControl.Event(rawValue: 0)) {
            return CGSize.zero
        }
        var size = super.intrinsicContentSize
        size.width += 20.0
        return size
    }
    
    override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)
        let highlighted = isHighlighted
        isHighlighted = highlighted
        self.layer.borderColor = color?.cgColor
    }
    
    override var isHighlighted: Bool {
        didSet {
            let baseColor = self.titleColor(for: .selected)
            backgroundColor = isHighlighted ? baseColor?.withAlphaComponent(0.1) : UIColor.clear
        }
    }
}
