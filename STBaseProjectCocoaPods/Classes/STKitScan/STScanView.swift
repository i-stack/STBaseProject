//
//  STScanView.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//  Copyright © 2018 ST. All rights reserved.
//

import UIKit

/// 扫码视图配置
public struct STScanViewConfiguration {
    /// 扫码区域边距
    public var scanAreaMargin: CGFloat = 60.0
    /// 扫码线高度
    public var scanLineHeight: CGFloat = 5.0
    /// 遮罩透明度
    public var maskAlpha: CGFloat = 0.6
    /// 扫码框边框颜色
    public var borderColor: UIColor = .white
    /// 扫码框角标颜色
    public var cornerColor: UIColor = UIColor(red: 0.110, green: 0.659, blue: 0.894, alpha: 1.0)
    /// 角标尺寸
    public var cornerSize: CGSize = CGSize(width: 15.0, height: 15.0)
    /// 角标线宽
    public var cornerLineWidth: CGFloat = 4.0
    /// 提示文字
    public var tipText: String = "将二维码放入框内,即可自动扫描"
    /// 提示文字颜色
    public var tipTextColor: UIColor = .white
    /// 提示文字字体
    public var tipTextFont: UIFont = UIFont.systemFont(ofSize: 13)
    /// 动画持续时间
    public var animationDuration: TimeInterval = 1.5
    /// 动画间隔
    public var animationInterval: TimeInterval = 0.3
    /// 是否自动适配安全区域
    public var automaticSafeAreaAdaptation: Bool = true
    
    public init() {}
}

/// 扫码视图主题
public enum STScanViewTheme {
    case light
    case dark
    case custom(STScanViewConfiguration)
    
    var configuration: STScanViewConfiguration {
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

open class STScanView: UIView {

    // MARK: - Public Properties
    
    /// 扫码类型
    open var scanType: STScanType = .STScanTypeQrCode {
        didSet {
            updateScanType()
        }
    }
    
    /// 主题配置
    open var theme: STScanViewTheme = .dark {
        didSet {
            configuration = theme.configuration
            setNeedsDisplay()
        }
    }
    
    /// 配置
    open var configuration: STScanViewConfiguration = STScanViewConfiguration() {
        didSet {
            updateConfiguration()
        }
    }
    
    /// 是否显示扫码线动画
    open var isAnimating: Bool {
        return !isAnimationStopped && scanType != .STScanTypeBarCode
    }
    
    // MARK: - Private Properties
    
    private var isAnimationStopped: Bool = false
    private var heightScale: CGFloat = 1.0
    private var tipLabel: UILabel?
    private var scanLineView: UIImageView?
    private var animationTimer: Timer?
    
    private lazy var scanLineImage: UIImage = {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: configuration.scanLineHeight))
        return renderer.image { context in
            let gradient = CAGradientLayer()
            gradient.colors = [
                UIColor.clear.cgColor,
                configuration.cornerColor.cgColor,
                UIColor.clear.cgColor
            ]
            gradient.locations = [0, 0.5, 1]
            gradient.frame = CGRect(x: 0, y: 0, width: 1, height: configuration.scanLineHeight)
            gradient.render(in: context.cgContext)
        }
    }()
    
    // MARK: - Lifecycle
    
    deinit {
        stopAnimation()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        updateScanLineFrame()
        updateTipLabelFrame()
    }
    
    @available(iOS 11.0, *)
    override open func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        if configuration.automaticSafeAreaAdaptation {
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
        scanLineView = UIImageView()
        scanLineView?.contentMode = .scaleToFill
        scanLineView?.alpha = 0
        if let scanLineView = scanLineView {
            addSubview(scanLineView)
        }
    }
    
    private func setupTipLabel() {
        tipLabel = UILabel()
        tipLabel?.numberOfLines = 0
        tipLabel?.textAlignment = .center
        tipLabel?.layer.zPosition = 1
        if let tipLabel = tipLabel {
            addSubview(tipLabel)
            bringSubviewToFront(tipLabel)
        }
        updateTipLabelAppearance()
    }
    
    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .staticText
        accessibilityLabel = "扫码区域"
        accessibilityHint = configuration.tipText
    }
    
    // MARK: - Public Methods
    
    /// 配置扫码类型
    open func st_configScanType(scanType: STScanType) {
        self.scanType = scanType
    }
    
    /// 开始扫码线动画
    open func st_startAnimating() {
        startAnimation()
    }
    
    /// 停止扫码线动画
    open func st_stopAnimating() {
        stopAnimation()
    }
    
    // MARK: - Private Methods
    
    private func updateScanType() {
        switch scanType {
        case .STScanTypeBarCode:
            heightScale = 3.0
            stopAnimation()
        case .STScanTypeQrCode, .STScanTypeAll:
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
        tipLabel?.text = configuration.tipText
        tipLabel?.textColor = configuration.tipTextColor
        tipLabel?.font = configuration.tipTextFont
    }
    
    private func updateScanLineImage() {
        scanLineView?.image = scanLineImage
    }
    
    private func updateScanLineFrame() {
        guard let scanLineView = scanLineView else { return }
        
        let margin = configuration.scanAreaMargin / heightScale
        let scanSize = calculateScanAreaSize()
        let scanRect = calculateScanAreaRect()
        
        scanLineView.frame = CGRect(
            x: scanRect.minX + 2,
            y: scanRect.minY + 2,
            width: scanSize.width - 4,
            height: configuration.scanLineHeight
        )
    }
    
    private func updateTipLabelFrame() {
        guard let tipLabel = tipLabel else { return }
        
        let scanRect = calculateScanAreaRect()
        let tipY = scanRect.maxY + 15
        
        tipLabel.frame = CGRect(
            x: 0,
            y: tipY,
            width: bounds.width,
            height: 50
        )
    }
    
    private func startAnimation() {
        guard scanType != .STScanTypeBarCode && !isAnimationStopped else { return }
        
        stopAnimation() // 确保之前的动画已停止
        isAnimationStopped = false
        
        guard let scanLineView = scanLineView else { return }
        
        let scanRect = calculateScanAreaRect()
        let startY = scanRect.minY + 2
        let endY = scanRect.maxY - configuration.scanLineHeight - 2
        
        // 设置初始位置
        var frame = scanLineView.frame
        frame.origin.y = startY
        scanLineView.frame = frame
        scanLineView.alpha = 1.0
        
        // 开始动画
        UIView.animate(
            withDuration: configuration.animationDuration,
            delay: 0,
            options: [.curveEaseInOut],
            animations: {
                var newFrame = scanLineView.frame
                newFrame.origin.y = endY
                scanLineView.frame = newFrame
            }
        ) { [weak self] _ in
            guard let self = self, !self.isAnimationStopped else { return }
            
            // 淡出效果
            UIView.animate(
                withDuration: 0.2,
                animations: {
                    scanLineView.alpha = 0
                }
            ) { _ in
                guard !self.isAnimationStopped else { return }
                
                // 延迟后重新开始动画
                DispatchQueue.main.asyncAfter(deadline: .now() + self.configuration.animationInterval) {
                    self.startAnimation()
                }
            }
        }
    }
    
    private func stopAnimation() {
        isAnimationStopped = true
        animationTimer?.invalidate()
        animationTimer = nil
        scanLineView?.layer.removeAllAnimations()
        scanLineView?.alpha = 0
    }
    
    // MARK: - Drawing
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        drawScanRect()
    }
    
    private func drawScanRect() {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let scanRect = calculateScanAreaRect()
        
        // 绘制遮罩
        drawMask(context: context, scanRect: scanRect)
        
        // 绘制扫码框边框
        drawBorder(context: context, scanRect: scanRect)
        
        // 绘制扫码框角标
        drawCorners(context: context, scanRect: scanRect)
    }
    
    private func calculateScanAreaSize() -> CGSize {
        let effectiveMargin = getEffectiveMargin()
        let width = bounds.width - effectiveMargin * 2
        let height = width / heightScale
        return CGSize(width: width, height: height)
    }
    
    private func calculateScanAreaRect() -> CGRect {
        let effectiveMargin = getEffectiveMargin()
        let scanSize = calculateScanAreaSize()
        let x = effectiveMargin
        
        // 计算 Y 坐标时考虑安全区域
        var y = bounds.height / 2.0 - scanSize.height / 2.0
        
        if configuration.automaticSafeAreaAdaptation {
            if #available(iOS 11.0, *) {
                let safeAreaInsets = self.safeAreaInsets
                let availableHeight = bounds.height - safeAreaInsets.top - safeAreaInsets.bottom
                y = safeAreaInsets.top + (availableHeight - scanSize.height) / 2.0
            }
        }
        
        return CGRect(x: x, y: y, width: scanSize.width, height: scanSize.height)
    }
    
    private func getEffectiveMargin() -> CGFloat {
        var margin = configuration.scanAreaMargin / heightScale
        
        if configuration.automaticSafeAreaAdaptation {
            if #available(iOS 11.0, *) {
                let safeAreaInsets = self.safeAreaInsets
                // 确保扫码区域不会被安全区域遮挡
                margin = max(margin, safeAreaInsets.left + 20, safeAreaInsets.right + 20)
            }
        }
        
        return margin
    }
    
    private func drawMask(context: CGContext, scanRect: CGRect) {
        context.setFillColor(red: 0, green: 0, blue: 0, alpha: configuration.maskAlpha)
        
        // 上方遮罩
        let topRect = CGRect(x: 0, y: 0, width: bounds.width, height: scanRect.minY)
        context.fill(topRect)
        
        // 左侧遮罩
        let leftRect = CGRect(x: 0, y: scanRect.minY, width: scanRect.minX, height: scanRect.height)
        context.fill(leftRect)
        
        // 右侧遮罩
        let rightRect = CGRect(x: scanRect.maxX, y: scanRect.minY, width: scanRect.minX, height: scanRect.height)
        context.fill(rightRect)
        
        // 下方遮罩
        let bottomRect = CGRect(x: 0, y: scanRect.maxY, width: bounds.width, height: bounds.height - scanRect.maxY)
        context.fill(bottomRect)
    }
    
    private func drawBorder(context: CGContext, scanRect: CGRect) {
        context.setStrokeColor(configuration.borderColor.cgColor)
        context.setLineWidth(1.0)
        context.addRect(scanRect)
        context.strokePath()
    }
    
    private func drawCorners(context: CGContext, scanRect: CGRect) {
        context.setStrokeColor(configuration.cornerColor.cgColor)
        context.setLineWidth(configuration.cornerLineWidth)
        
        let cornerSize = configuration.cornerSize
        let lineWidth = configuration.cornerLineWidth
        let offset = lineWidth / 3.0
        
        let points = [
            // 左上角
            (CGPoint(x: scanRect.minX - offset, y: scanRect.minY - offset),
             [(0, -lineWidth/2), (cornerSize.width, 0), (0, cornerSize.height)]),
            
            // 右上角  
            (CGPoint(x: scanRect.maxX + offset, y: scanRect.minY - offset),
             [(0, -lineWidth/2), (-cornerSize.width, 0), (0, cornerSize.height)]),
            
            // 左下角
            (CGPoint(x: scanRect.minX - offset, y: scanRect.maxY + offset),
             [(0, lineWidth/2), (cornerSize.width, 0), (0, -cornerSize.height)]),
            
            // 右下角
            (CGPoint(x: scanRect.maxX + offset, y: scanRect.maxY + offset),
             [(0, lineWidth/2), (-cornerSize.width, 0), (0, -cornerSize.height)])
        ]
        
        for (startPoint, offsets) in points {
            // 水平线
            context.move(to: CGPoint(x: startPoint.x + CGFloat(offsets[0].0), y: startPoint.y + CGFloat(offsets[0].1)))
            context.addLine(to: CGPoint(x: startPoint.x + CGFloat(offsets[1].0), y: startPoint.y + CGFloat(offsets[1].1)))
            
            // 垂直线
            context.move(to: startPoint)
            context.addLine(to: CGPoint(x: startPoint.x + CGFloat(offsets[2].0), y: startPoint.y + CGFloat(offsets[2].1)))
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
    
    /// 更新提示文字
    public func updateTipText(_ text: String) {
        configuration.tipText = text
        tipLabel?.text = text
        setupAccessibility()
    }
    
    /// 设置扫码区域安全区域适配
    public func setSafeAreaAdaptation(enabled: Bool) {
        configuration.automaticSafeAreaAdaptation = enabled
        setNeedsDisplay()
        setNeedsLayout()
    }
    
    /// 获取当前扫码区域的矩形
    public func getScanAreaRect() -> CGRect {
        return calculateScanAreaRect()
    }
    
    /// 重置为默认配置
    public func resetToDefault() {
        configuration = STScanViewConfiguration()
        theme = .dark
        scanType = .STScanTypeQrCode
    }
}