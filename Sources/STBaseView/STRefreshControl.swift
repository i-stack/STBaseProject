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
    private var originalInsetTop: CGFloat = 0
    private var hasRecordedOriginalInset = false

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
        // originalInsetTop 延迟到首次 KVO 回调时捕获，避免 viewDidLoad 阶段 inset 尚未稳定
        self.frame = CGRect(x: 0, y: -self.height, width: scrollView.bounds.width, height: self.height)
        self.autoresizingMask = [.flexibleWidth]
        scrollView.addSubview(self)
        self.offsetToken = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
            self?.handleContentOffsetChange(sv)
        }
    }

    // MARK: End Refreshing
    public func endRefreshing() {
        guard self.state == .refreshing else { return }
        UIView.animate(withDuration: 0.3, animations: {
            var inset = self.attachedScrollView?.contentInset ?? .zero
            inset.top = self.originalInsetTop
            self.attachedScrollView?.contentInset = inset
        }, completion: { _ in
            self.state = .idle
        })
    }

    /// 程序化触发刷新（等效于用户下拉松手）。
    public func beginRefreshing() {
        guard self.state != .refreshing, let sv = self.attachedScrollView else { return }
        if !self.hasRecordedOriginalInset {
            self.originalInsetTop = sv.contentInset.top
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
        // 首次回调时捕获稳定的 originalInsetTop（此时布局已完成）
        if !self.hasRecordedOriginalInset {
            self.originalInsetTop = scrollView.contentInset.top
            self.hasRecordedOriginalInset = true
        }
        guard self.isEnabled, self.state != .refreshing else { return }
        // pullDistance > 0 表示正在下拉
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
            // 松手时如果已触发，则开始刷新
            if self.state == .triggered {
                self.beginRefreshing(scrollView: scrollView)
            } else if state == .pulling {
                self.state = .idle
            }
        }
    }

    private func beginRefreshing(scrollView: UIScrollView) {
        self.state = .refreshing
        UIView.animate(withDuration: 0.3) {
            var inset = scrollView.contentInset
            inset.top = self.originalInsetTop + self.height
            scrollView.contentInset = inset
            scrollView.setContentOffset(CGPoint(x: 0, y: -(self.originalInsetTop + self.height)), animated: false)
        }
        self.action?()
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
    private var originalInsetBottom: CGFloat = 0
    private var hasRecordedOriginalInset = false
    /// 是否启用上拉加载更多（默认 true）。
    public var isEnabled: Bool = true

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
        // originalInsetBottom 延迟到首次 KVO 回调时捕获
        let footerY = max(scrollView.contentSize.height, scrollView.bounds.height)
        frame = CGRect(x: 0, y: footerY, width: scrollView.bounds.width, height: height)
        autoresizingMask = [.flexibleWidth]
        scrollView.addSubview(self)
        self.offsetToken = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
            self?.handleContentOffsetChange(sv)
        }
        self.contentSizeToken = scrollView.observe(\.contentSize, options: [.new]) { [weak self] sv, _ in
            self?.repositionFooter(in: sv)
        }
    }

    // MARK: End Loading
    /// 结束加载状态。`hasMore = false` 时显示"无更多"状态并锁定。
    public func endLoading(hasMore: Bool) {
        if hasMore {
            self.state = .idle
        } else {
            self.state = .noMore
            // noMore 时保持 footer 可见
            if let sv = self.attachedScrollView {
                var inset = sv.contentInset
                inset.bottom = self.originalInsetBottom + height
                sv.contentInset = inset
            }
        }
    }

    /// 重置为初始 idle 状态（换页/重新加载时调用）
    public func resetToIdle() {
        self.state = .idle
        if let sv = self.attachedScrollView {
            var inset = sv.contentInset
            inset.bottom = self.originalInsetBottom
            sv.contentInset = inset
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
        if !self.hasRecordedOriginalInset {
            self.originalInsetBottom = scrollView.contentInset.bottom
            self.hasRecordedOriginalInset = true
        }
        guard self.state == .idle, self.isEnabled else { return }
        let contentH = scrollView.contentSize.height
        guard contentH > scrollView.bounds.height else { return }
        let bottomEdge = scrollView.contentOffset.y + scrollView.bounds.height
        let threshold: CGFloat = 20
        let triggerPoint = contentH + self.originalInsetBottom - threshold
        if bottomEdge >= triggerPoint {
            self.beginLoading(scrollView: scrollView)
        }
    }

    private func beginLoading(scrollView: UIScrollView) {
        self.state = .loading
        var inset = scrollView.contentInset
        inset.bottom = self.originalInsetBottom + self.height
        scrollView.contentInset = inset
        self.action?()
    }

    private func repositionFooter(in scrollView: UIScrollView) {
        let footerY = max(scrollView.contentSize.height, scrollView.bounds.height)
        frame = CGRect(x: frame.origin.x, y: footerY, width: frame.width, height: self.height)
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
