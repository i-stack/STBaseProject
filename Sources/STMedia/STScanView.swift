//
//  STScanView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit

public struct STScanViewConfiguration {
    public var scanAreaMargin: CGFloat = 60.0
    public var scanLineHeight: CGFloat = 5.0
    public var maskAlpha: CGFloat = 0.6
    public var borderColor: UIColor = .white
    public var cornerColor: UIColor = UIColor(red: 0.110, green: 0.659, blue: 0.894, alpha: 1.0)
    public var cornerSize: CGSize = CGSize(width: 15.0, height: 15.0)
    public var cornerLineWidth: CGFloat = 4.0
    public var tipText: String = "将二维码放入框内,即可自动扫描"
    public var tipTextColor: UIColor = .white
    public var tipTextFont: UIFont = UIFont.systemFont(ofSize: 13)
    public var animationDuration: TimeInterval = 1.5
    public var animationInterval: TimeInterval = 0.3
    public var automaticSafeAreaAdaptation: Bool = true

    public init() {}
}

public enum STScanViewTheme {
    case light
    case dark
    case custom(STScanViewConfiguration)

    fileprivate var configuration: STScanViewConfiguration {
        switch self {
        case .light:
            var config = STScanViewConfiguration()
            config.maskAlpha = 0.4
            config.borderColor = .black
            config.tipTextColor = .black
            return config
        case .dark:
            return STScanViewConfiguration()
        case .custom(let config):
            return config
        }
    }
}

public class STScanView: UIView {

    // MARK: - Public Properties

    public var scanType: STScanType = .qrCode {
        didSet { updateScanType() }
    }

    public var theme: STScanViewTheme = .dark {
        didSet {
            configuration = theme.configuration
            setNeedsDisplay()
        }
    }

    public var configuration: STScanViewConfiguration = STScanViewConfiguration() {
        didSet { updateConfiguration() }
    }

    public var isAnimating: Bool {
        return !isAnimationStopped && scanType != .barCode
    }

    // MARK: - Private Properties

    private var isAnimationStopped: Bool = false
    private var heightScale: CGFloat = 1.0
    private var tipLabel: UILabel?
    private var scanLineView: UIImageView?

    private lazy var scanLineImage: UIImage = {
        let size = CGSize(width: 1, height: self.configuration.scanLineHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [UIColor.clear.cgColor,
                          self.configuration.cornerColor.cgColor,
                          UIColor.clear.cgColor] as CFArray
            let locations: [CGFloat] = [0, 0.5, 1]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: locations
            ) else { return }
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: 0, y: size.height),
                options: []
            )
        }
    }()

    // MARK: - Lifecycle

    deinit {
        stopAnimation()
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateScanLineFrame()
        updateTipLabelFrame()
    }

    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        if self.configuration.automaticSafeAreaAdaptation {
            setNeedsDisplay()
            setNeedsLayout()
        }
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear
        isAnimationStopped = false
        setupScanLine()
        setupTipLabel()
        setupAccessibility()
    }

    private func setupScanLine() {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        view.alpha = 0
        addSubview(view)
        self.scanLineView = view
    }

    private func setupTipLabel() {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.layer.zPosition = 1
        addSubview(label)
        bringSubviewToFront(label)
        self.tipLabel = label
        updateTipLabelAppearance()
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .staticText
        accessibilityLabel = "扫码区域"
        accessibilityHint = self.configuration.tipText
    }

    // MARK: - Public Methods

    public func st_configScanType(scanType: STScanType) {
        self.scanType = scanType
    }

    public func st_startAnimating() {
        startAnimation()
    }

    public func st_stopAnimating() {
        stopAnimation()
    }

    // MARK: - Private Methods

    private func updateScanType() {
        switch self.scanType {
        case .barCode:
            heightScale = 3.0
            stopAnimation()
        case .qrCode, .all:
            heightScale = 1.0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.startAnimation()
            }
        }
        setNeedsDisplay()
        setNeedsLayout()
    }

    private func updateConfiguration() {
        updateTipLabelAppearance()
        updateScanLineImage()
        setNeedsDisplay()
        setupAccessibility()
    }

    private func updateTipLabelAppearance() {
        self.tipLabel?.text = self.configuration.tipText
        self.tipLabel?.textColor = self.configuration.tipTextColor
        self.tipLabel?.font = self.configuration.tipTextFont
    }

    private func updateScanLineImage() {
        self.scanLineView?.image = self.scanLineImage
    }

    private func updateScanLineFrame() {
        guard let scanLineView = self.scanLineView else { return }
        let scanRect = calculateScanAreaRect()
        let scanSize = calculateScanAreaSize()
        scanLineView.frame = CGRect(
            x: scanRect.minX + 2,
            y: scanRect.minY + 2,
            width: scanSize.width - 4,
            height: self.configuration.scanLineHeight
        )
    }

    private func updateTipLabelFrame() {
        guard let tipLabel = self.tipLabel else { return }
        let scanRect = calculateScanAreaRect()
        tipLabel.frame = CGRect(
            x: 0,
            y: scanRect.maxY + 15,
            width: bounds.width,
            height: 50
        )
    }

    private func startAnimation() {
        guard self.scanType != .barCode && !isAnimationStopped else { return }
        stopAnimation()
        isAnimationStopped = false
        guard let scanLineView = self.scanLineView else { return }
        let scanRect = calculateScanAreaRect()
        let startY = scanRect.minY + 2
        let endY = scanRect.maxY - self.configuration.scanLineHeight - 2
        var frame = scanLineView.frame
        frame.origin.y = startY
        scanLineView.frame = frame
        scanLineView.alpha = 1.0
        UIView.animate(
            withDuration: self.configuration.animationDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                var newFrame = scanLineView.frame
                newFrame.origin.y = endY
                scanLineView.frame = newFrame
            }
        ) { [weak self] _ in
            guard let self, !self.isAnimationStopped else { return }
            UIView.animate(withDuration: 0.2, animations: {
                scanLineView.alpha = 0
            }) { _ in
                guard !self.isAnimationStopped else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.configuration.animationInterval) {
                    self.startAnimation()
                }
            }
        }
    }

    private func stopAnimation() {
        isAnimationStopped = true
        self.scanLineView?.layer.removeAllAnimations()
        self.scanLineView?.alpha = 0
    }

    // MARK: - Drawing

    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawScanRect()
    }

    private func drawScanRect() {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let scanRect = calculateScanAreaRect()
        drawMask(context: context, scanRect: scanRect)
        drawBorder(context: context, scanRect: scanRect)
        drawCorners(context: context, scanRect: scanRect)
    }

    private func calculateScanAreaSize() -> CGSize {
        let margin = getEffectiveMargin()
        let width = bounds.width - margin * 2
        return CGSize(width: width, height: width / heightScale)
    }

    private func calculateScanAreaRect() -> CGRect {
        let margin = getEffectiveMargin()
        let scanSize = calculateScanAreaSize()
        let x = margin
        var y = bounds.height / 2.0 - scanSize.height / 2.0
        if self.configuration.automaticSafeAreaAdaptation {
            let safeAreaInsets = self.safeAreaInsets
            let availableHeight = bounds.height - safeAreaInsets.top - safeAreaInsets.bottom
            y = safeAreaInsets.top + (availableHeight - scanSize.height) / 2.0
        }
        return CGRect(x: x, y: y, width: scanSize.width, height: scanSize.height)
    }

    private func getEffectiveMargin() -> CGFloat {
        var margin = self.configuration.scanAreaMargin / heightScale
        if self.configuration.automaticSafeAreaAdaptation {
            let safeAreaInsets = self.safeAreaInsets
            margin = max(margin, safeAreaInsets.left + 20, safeAreaInsets.right + 20)
        }
        return margin
    }

    private func drawMask(context: CGContext, scanRect: CGRect) {
        context.setFillColor(red: 0, green: 0, blue: 0, alpha: self.configuration.maskAlpha)
        context.fill(CGRect(x: 0, y: 0, width: bounds.width, height: scanRect.minY))
        context.fill(CGRect(x: 0, y: scanRect.minY, width: scanRect.minX, height: scanRect.height))
        context.fill(CGRect(x: scanRect.maxX, y: scanRect.minY, width: scanRect.minX, height: scanRect.height))
        context.fill(CGRect(x: 0, y: scanRect.maxY, width: bounds.width, height: bounds.height - scanRect.maxY))
    }

    private func drawBorder(context: CGContext, scanRect: CGRect) {
        context.setStrokeColor(self.configuration.borderColor.cgColor)
        context.setLineWidth(1.0)
        context.addRect(scanRect)
        context.strokePath()
    }

    private func drawCorners(context: CGContext, scanRect: CGRect) {
        context.setStrokeColor(self.configuration.cornerColor.cgColor)
        context.setLineWidth(self.configuration.cornerLineWidth)
        let cornerSize = self.configuration.cornerSize
        let lineWidth = self.configuration.cornerLineWidth
        let offset = lineWidth / 3.0
        let points: [(CGPoint, [(CGFloat, CGFloat)])] = [
            (CGPoint(x: scanRect.minX - offset, y: scanRect.minY - offset),
             [(0, -lineWidth/2), (cornerSize.width, 0), (0, cornerSize.height)]),
            (CGPoint(x: scanRect.maxX + offset, y: scanRect.minY - offset),
             [(0, -lineWidth/2), (-cornerSize.width, 0), (0, cornerSize.height)]),
            (CGPoint(x: scanRect.minX - offset, y: scanRect.maxY + offset),
             [(0, lineWidth/2), (cornerSize.width, 0), (0, -cornerSize.height)]),
            (CGPoint(x: scanRect.maxX + offset, y: scanRect.maxY + offset),
             [(0, lineWidth/2), (-cornerSize.width, 0), (0, -cornerSize.height)])
        ]
        for (startPoint, offsets) in points {
            context.move(to: CGPoint(x: startPoint.x + offsets[0].0, y: startPoint.y + offsets[0].1))
            context.addLine(to: CGPoint(x: startPoint.x + offsets[1].0, y: startPoint.y + offsets[1].1))
            context.move(to: startPoint)
            context.addLine(to: CGPoint(x: startPoint.x + offsets[2].0, y: startPoint.y + offsets[2].1))
        }
        context.strokePath()
    }
}

// MARK: - Convenience Initializers
extension STScanView {

    public convenience init(frame: CGRect, theme: STScanViewTheme) {
        self.init(frame: frame)
        self.theme = theme
    }

    public convenience init(frame: CGRect, configuration: STScanViewConfiguration) {
        self.init(frame: frame)
        self.configuration = configuration
    }
}

// MARK: - Additional Public APIs
extension STScanView {

    public func updateTipText(_ text: String) {
        self.configuration.tipText = text
        self.tipLabel?.text = text
        setupAccessibility()
    }

    public func setSafeAreaAdaptation(enabled: Bool) {
        self.configuration.automaticSafeAreaAdaptation = enabled
        setNeedsDisplay()
        setNeedsLayout()
    }

    public func getScanAreaRect() -> CGRect {
        return calculateScanAreaRect()
    }

    public func resetToDefault() {
        self.configuration = STScanViewConfiguration()
        self.theme = .dark
        self.scanType = .qrCode
    }
}
