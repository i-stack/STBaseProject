//
//  STRefreshControl.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit

// MARK: - Configuration Enums

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

    // UI elements
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

    // MARK: Init

    public init(content: STRefreshContent = .animation) {
        self.content = content
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    deinit { offsetToken?.invalidate() }

    // MARK: Attach

    /// 将 Header 附加到 scrollView 上，并设置刷新回调。
    /// 必须在 scrollView 已经完成布局（addSubview）后调用。
    public func attach(to scrollView: UIScrollView, action: @escaping () -> Void) {
        self.action = action
        self.attachedScrollView = scrollView
        self.originalInsetTop = scrollView.contentInset.top

        frame = CGRect(x: 0, y: -height, width: scrollView.bounds.width, height: height)
        autoresizingMask = [.flexibleWidth]
        scrollView.addSubview(self)

        offsetToken = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
            self?.handleContentOffsetChange(sv)
        }
    }

    // MARK: End Refreshing

    public func endRefreshing() {
        guard state == .refreshing else { return }
        UIView.animate(withDuration: 0.3, animations: {
            var inset = self.attachedScrollView?.contentInset ?? .zero
            inset.top = self.originalInsetTop
            self.attachedScrollView?.contentInset = inset
        }, completion: { _ in
            self.state = .idle
        })
    }

    // MARK: Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        let cx = bounds.midX
        let cy = bounds.midY

        switch content {
        case .animation:
            spinner.center = CGPoint(x: cx, y: cy)

        case .text:
            let arrowW: CGFloat = 20
            let labelW: CGFloat = min(bounds.width * 0.55, 180)
            let gap: CGFloat = 6
            let totalW = arrowW + gap + labelW
            let startX = cx - totalW / 2
            arrowImageView.frame = CGRect(x: startX, y: cy - arrowW / 2, width: arrowW, height: arrowW)
            textLabel.frame = CGRect(x: startX + arrowW + gap, y: cy - 11, width: labelW, height: 22)
            spinner.center = CGPoint(x: arrowImageView.center.x, y: arrowImageView.center.y)

        case .imageAndText:
            let imgW: CGFloat = 32
            let labelH: CGFloat = 18
            let gap: CGFloat = 5
            let totalH = imgW + gap + labelH
            customImageView.frame = CGRect(x: cx - imgW / 2, y: cy - totalH / 2, width: imgW, height: imgW)
            textLabel.frame = CGRect(x: 20, y: customImageView.frame.maxY + gap, width: bounds.width - 40, height: labelH)
            spinner.center = CGPoint(x: cx, y: cy)
        }
    }

    // MARK: Private

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = true

        addSubview(spinner)

        switch content {
        case .animation:
            break

        case .text(let pulling, _, _):
            let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
            arrowImageView.image = UIImage(systemName: "arrow.down", withConfiguration: cfg)
            arrowImageView.tintColor = .secondaryLabel
            arrowImageView.contentMode = .scaleAspectFit
            addSubview(arrowImageView)
            textLabel.text = pulling
            addSubview(textLabel)

        case .imageAndText(let image, let pulling, _):
            customImageView.image = image
            customImageView.contentMode = .scaleAspectFit
            addSubview(customImageView)
            textLabel.text = pulling
            addSubview(textLabel)
        }
    }

    private func handleContentOffsetChange(_ scrollView: UIScrollView) {
        guard state != .refreshing else { return }

        // pullDistance > 0 表示正在下拉
        let pullDistance = -(scrollView.contentOffset.y + originalInsetTop)

        if scrollView.isDragging {
            if pullDistance >= height {
                state = .triggered
            } else if pullDistance > 0 {
                state = .pulling
            } else {
                state = .idle
            }
        } else {
            // 松手时如果已触发，则开始刷新
            if state == .triggered {
                beginRefreshing(scrollView: scrollView)
            } else if state == .pulling {
                state = .idle
            }
        }
    }

    private func beginRefreshing(scrollView: UIScrollView) {
        state = .refreshing
        UIView.animate(withDuration: 0.3) {
            var inset = scrollView.contentInset
            inset.top = self.originalInsetTop + self.height
            scrollView.contentInset = inset
            scrollView.setContentOffset(CGPoint(x: 0, y: -(self.originalInsetTop + self.height)), animated: false)
        }
        action?()
    }

    private func applyState() {
        switch content {
        case .animation:
            applyAnimationMode()
        case .text(let pulling, let releasing, let refreshing):
            applyTextMode(pulling: pulling, releasing: releasing, refreshing: refreshing)
        case .imageAndText(_, let pulling, let refreshing):
            applyImageTextMode(pulling: pulling, refreshing: refreshing)
        }
    }

    private func applyAnimationMode() {
        switch state {
        case .idle:
            spinner.stopAnimating()
        case .pulling:
            spinner.stopAnimating()
            spinner.isHidden = false  // 显示静态轮廓，给用户视觉反馈
        case .triggered:
            spinner.isHidden = false
        case .refreshing:
            spinner.isHidden = false
            spinner.startAnimating()
        }
    }

    private func applyTextMode(pulling: String, releasing: String, refreshing: String) {
        switch state {
        case .idle:
            spinner.stopAnimating()
            arrowImageView.isHidden = false
            UIView.animate(withDuration: 0.2) { self.arrowImageView.transform = .identity }
            textLabel.text = pulling
            textLabel.alpha = 0
        case .pulling:
            spinner.stopAnimating()
            arrowImageView.isHidden = false
            UIView.animate(withDuration: 0.15) {
                self.arrowImageView.transform = .identity
                self.textLabel.alpha = 1
            }
            textLabel.text = pulling
        case .triggered:
            spinner.stopAnimating()
            arrowImageView.isHidden = false
            UIView.animate(withDuration: 0.15) {
                self.arrowImageView.transform = CGAffineTransform(rotationAngle: .pi)
            }
            textLabel.text = releasing
        case .refreshing:
            arrowImageView.isHidden = true
            arrowImageView.transform = .identity
            spinner.startAnimating()
            textLabel.text = refreshing
            textLabel.alpha = 1
        }
    }

    private func applyImageTextMode(pulling: String, refreshing: String) {
        switch state {
        case .idle:
            customImageView.layer.removeAnimation(forKey: "st_rotation")
            customImageView.isHidden = false
            spinner.stopAnimating()
            UIView.animate(withDuration: 0.2) { self.customImageView.transform = .identity }
            textLabel.text = pulling
            textLabel.alpha = 0
        case .pulling:
            customImageView.layer.removeAnimation(forKey: "st_rotation")
            customImageView.isHidden = false
            spinner.stopAnimating()
            UIView.animate(withDuration: 0.15) {
                self.customImageView.transform = .identity
                self.textLabel.alpha = 1
            }
            textLabel.text = pulling
        case .triggered:
            customImageView.layer.removeAnimation(forKey: "st_rotation")
            customImageView.isHidden = false
            spinner.stopAnimating()
            UIView.animate(withDuration: 0.15) {
                self.customImageView.transform = CGAffineTransform(rotationAngle: .pi)
            }
            textLabel.text = pulling
        case .refreshing:
            customImageView.isHidden = false
            customImageView.transform = .identity
            startImageRotation()
            spinner.stopAnimating()
            textLabel.text = refreshing
            textLabel.alpha = 1
        }
    }

    private func startImageRotation() {
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.toValue = CGFloat.pi * 2
        anim.duration = 1.0
        anim.isCumulative = true
        anim.repeatCount = .infinity
        customImageView.layer.add(anim, forKey: "st_rotation")
    }
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

    // UI elements
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

    // MARK: Init

    public init(content: STLoadMoreContent = .animation) {
        self.content = content
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    deinit {
        offsetToken?.invalidate()
        contentSizeToken?.invalidate()
    }

    // MARK: Attach

    /// 将 Footer 附加到 scrollView 上，并设置加载回调。
    public func attach(to scrollView: UIScrollView, action: @escaping () -> Void) {
        self.action = action
        self.attachedScrollView = scrollView
        self.originalInsetBottom = scrollView.contentInset.bottom

        let footerY = max(scrollView.contentSize.height, scrollView.bounds.height)
        frame = CGRect(x: 0, y: footerY, width: scrollView.bounds.width, height: height)
        autoresizingMask = [.flexibleWidth]
        scrollView.addSubview(self)

        offsetToken = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
            self?.handleContentOffsetChange(sv)
        }
        contentSizeToken = scrollView.observe(\.contentSize, options: [.new]) { [weak self] sv, _ in
            self?.repositionFooter(in: sv)
        }
    }

    // MARK: End Loading

    /// 结束加载状态。`hasMore = false` 时显示"无更多"状态并锁定。
    public func endLoading(hasMore: Bool) {
        if hasMore {
            state = .idle
        } else {
            state = .noMore
            // noMore 时保持 footer 可见
            if let sv = attachedScrollView {
                var inset = sv.contentInset
                inset.bottom = originalInsetBottom + height
                sv.contentInset = inset
            }
        }
    }

    /// 重置为初始 idle 状态（换页/重新加载时调用）
    public func resetToIdle() {
        state = .idle
        if let sv = attachedScrollView {
            var inset = sv.contentInset
            inset.bottom = originalInsetBottom
            sv.contentInset = inset
        }
    }

    // MARK: Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        let cx = bounds.midX
        let cy = bounds.midY

        switch content {
        case .animation:
            spinner.center = CGPoint(x: cx, y: cy)

        case .text:
            textLabel.frame = bounds

        case .imageAndText:
            let imgW: CGFloat = 24
            let labelW: CGFloat = min(bounds.width * 0.55, 180)
            let gap: CGFloat = 6
            let totalW = imgW + gap + labelW
            let startX = cx - totalW / 2
            customImageView.frame = CGRect(x: startX, y: cy - imgW / 2, width: imgW, height: imgW)
            textLabel.frame = CGRect(x: startX + imgW + gap, y: cy - 11, width: labelW, height: 22)
            spinner.center = CGPoint(x: customImageView.center.x, y: customImageView.center.y)
        }
    }

    // MARK: Private

    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = true

        addSubview(spinner)

        switch content {
        case .animation:
            break

        case .text(let loading, _):
            textLabel.text = loading
            addSubview(textLabel)

        case .imageAndText(let image, let loading, _):
            customImageView.image = image
            customImageView.contentMode = .scaleAspectFit
            addSubview(customImageView)
            textLabel.text = loading
            addSubview(textLabel)
        }
    }

    private func handleContentOffsetChange(_ scrollView: UIScrollView) {
        guard state == .idle else { return }
        let contentH = scrollView.contentSize.height
        guard contentH > scrollView.bounds.height else { return } // 内容不足一屏不触发

        let bottomEdge = scrollView.contentOffset.y + scrollView.bounds.height
        let threshold: CGFloat = 20
        let triggerPoint = contentH + originalInsetBottom - threshold

        if bottomEdge >= triggerPoint {
            beginLoading(scrollView: scrollView)
        }
    }

    private func beginLoading(scrollView: UIScrollView) {
        state = .loading
        var inset = scrollView.contentInset
        inset.bottom = originalInsetBottom + height
        scrollView.contentInset = inset
        action?()
    }

    private func repositionFooter(in scrollView: UIScrollView) {
        let footerY = max(scrollView.contentSize.height, scrollView.bounds.height)
        frame = CGRect(x: frame.origin.x, y: footerY, width: frame.width, height: height)
    }

    private func applyState() {
        switch content {
        case .animation:
            applyAnimationMode()
        case .text(let loading, let noMore):
            applyTextMode(loading: loading, noMore: noMore)
        case .imageAndText(_, let loading, let noMore):
            applyImageTextMode(loading: loading, noMore: noMore)
        }
    }

    private func applyAnimationMode() {
        switch state {
        case .idle:
            spinner.stopAnimating()
        case .loading:
            spinner.startAnimating()
        case .noMore:
            spinner.stopAnimating()
        }
    }

    private func applyTextMode(loading: String, noMore: String) {
        switch state {
        case .idle:
            spinner.stopAnimating()
            textLabel.text = loading
        case .loading:
            spinner.startAnimating()
            textLabel.text = loading
        case .noMore:
            spinner.stopAnimating()
            textLabel.text = noMore
        }
    }

    private func applyImageTextMode(loading: String, noMore: String) {
        switch state {
        case .idle:
            customImageView.layer.removeAnimation(forKey: "st_rotation")
            spinner.stopAnimating()
            textLabel.text = loading
        case .loading:
            spinner.stopAnimating()
            startImageRotation()
            textLabel.text = loading
        case .noMore:
            customImageView.layer.removeAnimation(forKey: "st_rotation")
            spinner.stopAnimating()
            textLabel.text = noMore
        }
    }

    private func startImageRotation() {
        let anim = CABasicAnimation(keyPath: "transform.rotation.z")
        anim.toValue = CGFloat.pi * 2
        anim.duration = 1.0
        anim.isCumulative = true
        anim.repeatCount = .infinity
        customImageView.layer.add(anim, forKey: "st_rotation")
    }
}
