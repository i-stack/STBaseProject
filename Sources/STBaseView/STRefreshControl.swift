//
//  STRefreshControl.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit

/// 下拉刷新内容配置
public enum STRefreshContent {
    /// 仅默认 spinner 动画
    case animation
    /// 箭头 + 文字（三状态文字）
    case text(pulling: String, releasing: String, refreshing: String)
    /// 自定义图片 + 文字（刷新时图片持续旋转）
    case imageAndText(image: UIImage, pulling: String, refreshing: String)
}

/// 上拉加载更多内容配置
public enum STLoadMoreContent {
    /// 仅默认 spinner 动画
    case animation
    /// 文字
    case text(loading: String, noMore: String)
    /// 自定义图片 + 文字（加载时图片持续旋转）
    case imageAndText(image: UIImage, loading: String, noMore: String)
}

// MARK: - STRefreshHeaderView
/// 下拉刷新 Header View（高度 60pt）
public final class STRefreshHeaderView: UIView {

    public let height: CGFloat = 60

    private enum State { case idle, pulling, triggered, refreshing }
    private var state: State = .idle { didSet { guard state != oldValue else { return }; applyState() } }
    private let content: STRefreshContent
    private var action: (() -> Void)?

    private weak var attachedScrollView: UIScrollView?
    private var offsetToken: NSKeyValueObservation?
    // adjustedContentInset.top（含 safeArea）作为基准，避免 safeArea 场景下 offset 计算偏差
    private var originalInsetTop: CGFloat = 0
    private var hasRecordedOriginalInset = false
    /// 防止 setEffectiveInsetTop 写入 contentInset 后回调 KVO 再次进入计算循环。
    private var isAdjustingInset = false

    /// 是否启用下拉刷新（默认 true）。设为 false 时忽略所有用户手势，但程序化触发仍有效。
    public var isEnabled: Bool = true

    public init(content: STRefreshContent = .animation) {
        self.content = content
        super.init(frame: .zero)
        self.setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    deinit { self.offsetToken?.invalidate() }

    // MARK: Attach
    /// 将 Header 附加到 scrollView 上，并设置刷新回调。
    /// 必须在 scrollView 已经完成布局（addSubview）后调用。
    public func attach(to scrollView: UIScrollView, action: @escaping () -> Void) {
        self.action = action
        self.attachedScrollView = scrollView
        self.frame = CGRect(x: 0, y: -self.height, width: scrollView.bounds.width, height: self.height)
        self.autoresizingMask = [.flexibleWidth]
        scrollView.addSubview(self)
        // attach 时立即记录基准 inset，避免在第一次 KVO 之前调用 endLoading/setEffectiveInsetTop 拿到 0
        self.originalInsetTop = scrollView.adjustedContentInset.top
        self.hasRecordedOriginalInset = true
        self.offsetToken = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
            self?.handleContentOffsetChange(sv)
        }
    }

    /// 由宿主（STBaseView）在 safeAreaInsetsDidChange 后调用，重新校准 originalInsetTop。
    public func safeAreaInsetsDidChangeFromHost() {
        guard let sv = self.attachedScrollView else { return }
        // 当前刷新中（已经把 +height 注入了 inset）则需要扣除 height 才是真实的"原始"基准
        self.originalInsetTop = sv.adjustedContentInset.top - self.injectedInsetTop
        self.hasRecordedOriginalInset = true
    }

    /// 当前 header 额外注入到 scrollView.contentInset.top 的增量（refreshing 时为 height，否则 0）。
    /// 宿主在 `safeAreaInsetsDidChange` 中合成基础 inset 时需要感知该增量以避免抹掉刷新占位。
    public var injectedInsetTop: CGFloat {
        return (self.state == .refreshing) ? self.height : 0
    }

    // MARK: Public API
    public func endRefreshing() {
        guard self.state == .refreshing else { return }
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let self = self, let sv = self.attachedScrollView else { return }
            self.setEffectiveInsetTop(self.originalInsetTop, on: sv)
            // resetInset 已在刷新期间持续收缩 inset；此处仅在用户仍处于顶部区域时对齐 offset
            if sv.contentOffset.y <= -self.originalInsetTop {
                sv.contentOffset = CGPoint(x: sv.contentOffset.x, y: -self.originalInsetTop)
            }
        }, completion: { [weak self] _ in
            self?.state = .idle
        })
    }

    /// 程序化触发刷新（等效于用户下拉松手）。
    public func beginRefreshing() {
        guard self.state != .refreshing, let sv = self.attachedScrollView else { return }
        if !self.hasRecordedOriginalInset {
            self.originalInsetTop = sv.adjustedContentInset.top
            self.hasRecordedOriginalInset = true
        }
        self.beginRefreshing(scrollView: sv)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let cx = bounds.midX
        let cy = bounds.midY
        switch self.content {
        case .animation:
            self.spinner.center = CGPoint(x: cx, y: cy)

        case .text:
            let arrowW: CGFloat = 20
            let labelW: CGFloat = min(bounds.width * 0.55, 180)
            let gap: CGFloat = 6
            let totalW = arrowW + gap + labelW
            let startX = cx - totalW / 2
            self.arrowImageView.frame = CGRect(x: startX, y: cy - arrowW / 2, width: arrowW, height: arrowW)
            self.textLabel.frame = CGRect(x: startX + arrowW + gap, y: cy - 11, width: labelW, height: 22)
            self.spinner.center = CGPoint(x: self.arrowImageView.center.x, y: self.arrowImageView.center.y)

        case .imageAndText:
            let imgW: CGFloat = 32
            let labelH: CGFloat = 18
            let gap: CGFloat = 5
            let totalH = imgW + gap + labelH
            self.customImageView.frame = CGRect(x: cx - imgW / 2, y: cy - totalH / 2, width: imgW, height: imgW)
            self.textLabel.frame = CGRect(x: 20, y: self.customImageView.frame.maxY + gap, width: bounds.width - 40, height: labelH)
            self.spinner.center = CGPoint(x: cx, y: cy)
        }
    }

    // MARK: - Private
    private func setupUI() {
        self.backgroundColor = .clear
        self.clipsToBounds = true
        self.addSubview(self.spinner)
        switch self.content {
        case .animation:
            break
        case .text(let pulling, _, _):
            let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            self.arrowImageView.image = UIImage(systemName: "arrow.down", withConfiguration: cfg)
            self.arrowImageView.tintColor = .secondaryLabel
            self.arrowImageView.contentMode = .scaleAspectFit
            self.addSubview(self.arrowImageView)
            self.textLabel.text = pulling
            self.addSubview(self.textLabel)
        case .imageAndText(let image, let pulling, _):
            self.customImageView.image = image
            self.customImageView.contentMode = .scaleAspectFit
            self.addSubview(self.customImageView)
            self.textLabel.text = pulling
            self.addSubview(textLabel)
        }
    }

    private func handleContentOffsetChange(_ scrollView: UIScrollView) {
        // 防止 setEffectiveInsetTop 写入 contentInset 触发的二次 KVO 进入计算循环
        guard !self.isAdjustingInset else { return }
        if !self.hasRecordedOriginalInset {
            // 使用 adjustedContentInset 捕获含 safeArea 的真实顶部基准
            self.originalInsetTop = scrollView.adjustedContentInset.top
            self.hasRecordedOriginalInset = true
        }
        // 刷新期间：持续用当前 offset 反算并同步 inset，保证 endRefreshing 时位置连续
        if self.state == .refreshing {
            self.resetInset(scrollView: scrollView)
            return
        }
        guard self.isEnabled else { return }
        let pullDistance = -(scrollView.contentOffset.y + self.originalInsetTop)
        if scrollView.isDragging {
            if pullDistance >= self.height {
                self.state = .triggered
            } else if pullDistance > 0 {
                self.state = .pulling
            } else {
                self.state = .idle
            }
        } else {
            if self.state == .triggered {
                self.beginRefreshing(scrollView: scrollView)
            } else if state == .pulling {
                self.state = .idle
            }
        }
    }

    private func beginRefreshing(scrollView: UIScrollView) {
        self.state = .refreshing
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            self.setEffectiveInsetTop(self.originalInsetTop + self.height, on: scrollView)
            scrollView.setContentOffset(CGPoint(x: 0, y: -(self.originalInsetTop + self.height)), animated: false)
        }
        self.action?()
    }

    // MARK: - inset helpers
    /// 刷新期间根据当前 offset 动态收缩 inset，用户滚离顶部时 header 随之隐藏，
    /// 使 endRefreshing 时无需强制修改 offset 也能平滑复原。
    private func resetInset(scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        // 将有效 insetTop 钳制在 [originalInsetTop, originalInsetTop + height]
        var insetT = max(-offsetY, self.originalInsetTop)
        insetT = min(insetT, self.originalInsetTop + self.height)
        guard abs(scrollView.adjustedContentInset.top - insetT) > 0.001 else { return }
        self.setEffectiveInsetTop(insetT, on: scrollView)
    }

    /// 将"有效顶部 inset（含 safeArea）"设为 value；写入 contentInset 时自动扣除 safeArea 贡献。
    private func setEffectiveInsetTop(_ value: CGFloat, on sv: UIScrollView) {
        self.isAdjustingInset = true
        defer { self.isAdjustingInset = false }
        let safeAreaDelta = sv.adjustedContentInset.top - sv.contentInset.top
        var inset = sv.contentInset
        inset.top = value - safeAreaDelta
        sv.contentInset = inset
    }

    private func applyState() {
        switch self.content {
        case .animation:
            self.applyAnimationMode()
        case .text(let pulling, let releasing, let refreshing):
            self.applyTextMode(pulling: pulling, releasing: releasing, refreshing: refreshing)
        case .imageAndText(_, let pulling, let refreshing):
            self.applyImageTextMode(pulling: pulling, refreshing: refreshing)
        }
    }

    private func applyAnimationMode() {
        switch state {
        case .idle:
            self.spinner.isHidden = false
            self.spinner.stopAnimating()
        case .pulling:
            self.spinner.stopAnimating()
            self.spinner.isHidden = false
        case .triggered:
            self.spinner.isHidden = false
        case .refreshing:
            self.spinner.isHidden = false
            self.spinner.startAnimating()
        }
    }

    private func applyTextMode(pulling: String, releasing: String, refreshing: String) {
        switch state {
        case .idle:
            self.spinner.stopAnimating()
            self.arrowImageView.isHidden = false
            UIView.animate(withDuration: 0.2) { self.arrowImageView.transform = .identity }
            self.textLabel.text = pulling
            self.textLabel.alpha = 0
        case .pulling:
            self.spinner.stopAnimating()
            self.arrowImageView.isHidden = false
            UIView.animate(withDuration: 0.15) {
                self.arrowImageView.transform = .identity
                self.textLabel.alpha = 1
            }
            self.textLabel.text = pulling
        case .triggered:
            self.spinner.stopAnimating()
            self.arrowImageView.isHidden = false
            UIView.animate(withDuration: 0.15) {
                self.arrowImageView.transform = CGAffineTransform(rotationAngle: .pi)
            }
            self.textLabel.text = releasing
        case .refreshing:
            self.arrowImageView.isHidden = true
            self.arrowImageView.transform = .identity
            self.spinner.startAnimating()
            self.textLabel.text = refreshing
            self.textLabel.alpha = 1
        }
    }

    private func applyImageTextMode(pulling: String, refreshing: String) {
        switch self.state {
        case .idle:
            self.customImageView.layer.removeAnimation(forKey: "st_rotation")
            self.customImageView.isHidden = false
            self.spinner.stopAnimating()
            UIView.animate(withDuration: 0.2) { self.customImageView.transform = .identity }
            self.textLabel.text = pulling
            self.textLabel.alpha = 0
        case .pulling:
            self.customImageView.layer.removeAnimation(forKey: "st_rotation")
            self.customImageView.isHidden = false
            self.spinner.stopAnimating()
            UIView.animate(withDuration: 0.15) {
                self.customImageView.transform = .identity
                self.textLabel.alpha = 1
            }
            self.textLabel.text = pulling
        case .triggered:
            self.customImageView.layer.removeAnimation(forKey: "st_rotation")
            self.customImageView.isHidden = false
            self.spinner.stopAnimating()
            UIView.animate(withDuration: 0.15) {
                self.customImageView.transform = CGAffineTransform(rotationAngle: .pi)
            }
            self.textLabel.text = pulling
        case .refreshing:
            self.customImageView.isHidden = false
            self.customImageView.transform = .identity
            self.startImageRotation()
            self.spinner.stopAnimating()
            self.textLabel.text = refreshing
            self.textLabel.alpha = 1
        }
    }

    private func startImageRotation() {
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.toValue = CGFloat.pi * 2
        anim.duration = 1.0
        anim.isCumulative = true
        anim.repeatCount = .infinity
        self.customImageView.layer.add(anim, forKey: "st_rotation")
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            self.customImageView.layer.removeAnimation(forKey: "st_rotation")
            self.offsetToken?.invalidate()
            self.offsetToken = nil
        }
    }

    private let spinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        return v
    }()

    private let arrowImageView = UIImageView()
    private let customImageView = UIImageView()

    private let textLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()
}

// MARK: - STLoadMoreFooterView
/// 上拉加载更多 Footer View（高度 44pt）
public final class STLoadMoreFooterView: UIView {

    public let height: CGFloat = 44
    private enum State { case idle, loading, noMore }
    private var state: State = .idle { didSet { guard state != oldValue else { return }; applyState() } }
    private let content: STLoadMoreContent
    private var action: (() -> Void)?
    private weak var attachedScrollView: UIScrollView?
    private var offsetToken: NSKeyValueObservation?
    private var contentSizeToken: NSKeyValueObservation?
    // adjustedContentInset.bottom（含 safeArea）作为基准
    private var originalInsetBottom: CGFloat = 0
    private var hasRecordedOriginalInset = false
    // beginLoading 时实际增加的 insetBottom 差值，结束时用于精确还原
    private var lastBottomDelta: CGFloat = 0
    /// 防止 setEffectiveInsetBottom 写入 contentInset 后 KVO 再次进入计算循环。
    private var isAdjustingInset = false
    /// 是否启用上拉加载更多（默认 true）。
    public var isEnabled: Bool = true
    /// 自动加载触发的距离阈值（contentSize.bottom 之上多少点开始触发，默认 20）。
    public var triggerThreshold: CGFloat = 20

    public init(content: STLoadMoreContent = .animation) {
        self.content = content
        super.init(frame: .zero)
        self.setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    deinit {
        self.offsetToken?.invalidate()
        self.contentSizeToken?.invalidate()
    }

    /// 将 Footer 附加到 scrollView 上，并设置加载回调。
    public func attach(to scrollView: UIScrollView, action: @escaping () -> Void) {
        self.action = action
        self.attachedScrollView = scrollView
        let footerY = max(scrollView.contentSize.height, scrollView.bounds.height)
        frame = CGRect(x: 0, y: footerY, width: scrollView.bounds.width, height: height)
        autoresizingMask = [.flexibleWidth]
        scrollView.addSubview(self)
        // attach 时立即记录基准，避免后续 endLoading 在第一次 KVO 之前调用拿到 0。
        self.originalInsetBottom = scrollView.adjustedContentInset.bottom
        self.hasRecordedOriginalInset = true
        self.offsetToken = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
            self?.handleContentOffsetChange(sv)
        }
        self.contentSizeToken = scrollView.observe(\.contentSize, options: [.new]) { [weak self] sv, _ in
            self?.repositionFooter(in: sv)
        }
    }

    /// 由宿主（STBaseView）在 safeAreaInsetsDidChange 后调用，重新校准 originalInsetBottom。
    public func safeAreaInsetsDidChangeFromHost() {
        guard let sv = self.attachedScrollView else { return }
        self.originalInsetBottom = sv.adjustedContentInset.bottom - self.injectedInsetBottom
        self.hasRecordedOriginalInset = true
    }

    /// 当前 footer 额外注入到 scrollView.contentInset.bottom 的增量
    /// （loading / noMore 为 height，idle 为 0）。宿主在 `safeAreaInsetsDidChange`
    /// 中合成基础 inset 时需要感知该增量以避免抹掉刷新占位。
    public var injectedInsetBottom: CGFloat {
        switch self.state {
        case .loading, .noMore: return self.height
        case .idle:             return 0
        }
    }

    // MARK: Public API
    /// 结束加载状态。`hasMore = false` 时显示"无更多"状态并锁定。
    public func endLoading(hasMore: Bool) {
        if hasMore {
            if let sv = self.attachedScrollView {
                self.setEffectiveInsetBottom(self.originalInsetBottom, on: sv)
            }
            self.state = .idle
        } else {
            self.state = .noMore
            if let sv = self.attachedScrollView {
                // noMore 时保持 footer 可见
                self.setEffectiveInsetBottom(self.originalInsetBottom + self.height, on: sv)
                // 同时确保 footer view 紧贴 contentSize 之后，让用户能看到 noMore 文案
                self.repositionFooter(in: sv)
            }
        }
    }

    /// 重置为初始 idle 状态（换页/重新加载时调用）
    public func resetToIdle() {
        self.state = .idle
        if let sv = self.attachedScrollView {
            self.setEffectiveInsetBottom(self.originalInsetBottom, on: sv)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let cx = bounds.midX
        let cy = bounds.midY
        switch self.content {
        case .animation:
            self.spinner.center = CGPoint(x: cx, y: cy)
        case .text:
            self.textLabel.frame = bounds
        case .imageAndText:
            let imgW: CGFloat = 24
            let labelW: CGFloat = min(bounds.width * 0.55, 180)
            let gap: CGFloat = 6
            let totalW = imgW + gap + labelW
            let startX = cx - totalW / 2
            self.customImageView.frame = CGRect(x: startX, y: cy - imgW / 2, width: imgW, height: imgW)
            self.textLabel.frame = CGRect(x: startX + imgW + gap, y: cy - 11, width: labelW, height: 22)
            self.spinner.center = CGPoint(x: self.customImageView.center.x, y: self.customImageView.center.y)
        }
    }

    // MARK: - Private
    private func setupUI() {
        self.backgroundColor = .clear
        self.clipsToBounds = true
        self.addSubview(self.spinner)
        switch self.content {
        case .animation:
            break
        case .text(let loading, _):
            self.textLabel.text = loading
            self.addSubview(self.textLabel)
        case .imageAndText(let image, let loading, _):
            self.customImageView.image = image
            self.customImageView.contentMode = .scaleAspectFit
            self.addSubview(self.customImageView)
            self.textLabel.text = loading
            self.addSubview(self.textLabel)
        }
    }

    private func handleContentOffsetChange(_ scrollView: UIScrollView) {
        // 防止 setEffectiveInsetBottom 写入 contentInset 触发的二次 KVO 进入计算循环
        guard !self.isAdjustingInset else { return }
        if !self.hasRecordedOriginalInset {
            self.originalInsetBottom = scrollView.adjustedContentInset.bottom
            self.hasRecordedOriginalInset = true
        }
        guard self.state == .idle, self.isEnabled else { return }
        let contentH = scrollView.contentSize.height
        guard contentH > scrollView.bounds.height else { return }
        // 仅在用户真实滚动时触发，避免初次 attach 或外部 setContentOffset 导致的"伪触发"
        guard scrollView.isDragging || scrollView.isDecelerating else { return }
        let bottomEdge = scrollView.contentOffset.y + scrollView.bounds.height
        let triggerPoint = contentH + self.originalInsetBottom - self.triggerThreshold
        if bottomEdge >= triggerPoint {
            self.beginLoading(scrollView: scrollView)
        }
    }

    private func beginLoading(scrollView: UIScrollView) {
        self.state = .loading
        let targetBottom = self.originalInsetBottom + self.height
        // 记录本次实际增加的差值（外部可能已修改过 inset），还原时只减去这段 delta
        self.lastBottomDelta = targetBottom - scrollView.adjustedContentInset.bottom
        self.setEffectiveInsetBottom(targetBottom, on: scrollView)
        self.action?()
    }

    private func repositionFooter(in scrollView: UIScrollView) {
        let footerY = max(scrollView.contentSize.height, scrollView.bounds.height)
        frame = CGRect(x: frame.origin.x, y: footerY, width: frame.width, height: self.height)
    }

    /// 将"有效底部 inset（含 safeArea）"设为 value；写入 contentInset 时自动扣除 safeArea 贡献。
    private func setEffectiveInsetBottom(_ value: CGFloat, on sv: UIScrollView) {
        self.isAdjustingInset = true
        defer { self.isAdjustingInset = false }
        let safeAreaDelta = sv.adjustedContentInset.bottom - sv.contentInset.bottom
        var inset = sv.contentInset
        inset.bottom = value - safeAreaDelta
        sv.contentInset = inset
    }

    private func applyState() {
        switch self.content {
        case .animation:
            self.applyAnimationMode()
        case .text(let loading, let noMore):
            self.applyTextMode(loading: loading, noMore: noMore)
        case .imageAndText(_, let loading, let noMore):
            self.applyImageTextMode(loading: loading, noMore: noMore)
        }
    }

    private func applyAnimationMode() {
        switch self.state {
        case .idle:
            self.spinner.stopAnimating()
        case .loading:
            self.spinner.startAnimating()
        case .noMore:
            self.spinner.stopAnimating()
        }
    }

    private func applyTextMode(loading: String, noMore: String) {
        switch self.state {
        case .idle:
            self.spinner.stopAnimating()
            self.textLabel.text = loading
        case .loading:
            self.spinner.startAnimating()
            self.textLabel.text = loading
        case .noMore:
            self.spinner.stopAnimating()
            self.textLabel.text = noMore
        }
    }

    private func applyImageTextMode(loading: String, noMore: String) {
        switch self.state {
        case .idle:
            self.customImageView.layer.removeAnimation(forKey: "st_rotation")
            self.spinner.stopAnimating()
            self.textLabel.text = loading
        case .loading:
            self.spinner.stopAnimating()
            self.startImageRotation()
            self.textLabel.text = loading
        case .noMore:
            self.customImageView.layer.removeAnimation(forKey: "st_rotation")
            self.spinner.stopAnimating()
            self.textLabel.text = noMore
        }
    }

    private func startImageRotation() {
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.toValue = CGFloat.pi * 2
        anim.duration = 1.0
        anim.isCumulative = true
        anim.repeatCount = .infinity
        self.customImageView.layer.add(anim, forKey: "st_rotation")
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            self.customImageView.layer.removeAnimation(forKey: "st_rotation")
            self.offsetToken?.invalidate()
            self.offsetToken = nil
            self.contentSizeToken?.invalidate()
            self.contentSizeToken = nil
        }
    }

    private let spinner: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .medium)
        v.hidesWhenStopped = true
        return v
    }()

    private let customImageView = UIImageView()

    private let textLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        return l
    }()
}
