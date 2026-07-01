//
//  STMarkdownViewHeightCoordinator.swift
//  STMarkdown
//
//  高度测量协调器：缓存、测量、通知分发，从 NativeMarkdownView 中解耦出纯测量逻辑。
//  使用 protocol 而非直接引用视图类型，使此组件可在任意 UIView 宿主中复用。
//

import UIKit
import STBaseProject

/// 宿主视图需遵循此协议，供高度协调器回调。
public protocol STMarkdownHeightCoordinatorOwner: AnyObject {
    var renderMode: STMarkdownRenderMode { get }
    var stStaticRenderView: UITextView { get }
    var streamingRenderView: STMarkdownStreamingRenderInfo { get }
    var streamingTableHost: STStreamingTableHostMeasurable { get }
    var streamingCommittedMarkdown: String { get }
    var streamingPresentationSnapshot: String { get }
    var activeStreamingTableBlockMarkdown: String { get }
    var onHeightChanged: (() -> Void)? { get }
    var postResetHeightHoldUntil: CFTimeInterval { get }
    var measureWidthInset: CGFloat { get }
    var heightCoordinator: STMarkdownViewHeightCoordinator { get }
    var isRenderingInProgress: Bool { get }
    var currentMarkdown: String { get }
    func invalidateIntrinsicContentSize()
}

public extension STMarkdownHeightCoordinatorOwner {
    var isRenderingInProgress: Bool { false }
    var currentMarkdown: String { "" }
}

/// 流式渲染信息协议 — 持有一个 contentTextView 供测量
public protocol STMarkdownStreamingRenderInfo {
    var isHidden: Bool { get }
    var contentTextView: UITextView { get }
    var measurementContainerView: UIView? { get }
}

public extension STMarkdownStreamingRenderInfo {
    var measurementContainerView: UIView? { nil }
}

/// 流式表格宿主可测量协议
public protocol STStreamingTableHostMeasurable {
    var isHidden: Bool { get }
    var hasContent: Bool { get }
    func measuredHeight(forWidth width: CGFloat) -> CGFloat
}

public enum STMarkdownRenderMode {
    case ast
    case streaming
}

/// 高度测量协调器 — 纯测量逻辑，从 NativeMarkdownViewHeightCoordinator 通用化。
public final class STMarkdownViewHeightCoordinator {

    public weak var owner: STMarkdownHeightCoordinatorOwner?

    // MARK: - Cache

    public var cachedContentHeight: CGFloat?
    public var cachedContentWidth: CGFloat?
    public var hasCachedHeight: Bool { cachedContentHeight != nil }

    public var lastNotifiedWidth: CGFloat = -1
    public var lastNotifiedHeight: CGFloat = -1

    public var isComputingContentHeight = false

    // MARK: - Streaming Measurement Cache

    public var lastStreamingMeasuredHeight: CGFloat = 0
    public var lastStreamingMeasuredWidth: CGFloat = 0
    public var lastMeasuredStreamingTextLength = 0
    public var lastMeasuredStreamingResultForWidth: CGFloat = 0
    public var lastMeasuredStreamingResultHeight: CGFloat = 0

    // MARK: - Cell Content View Cache

    public weak var cachedCellContentView: UIView?
    public var cachedCellContentViewResolved = false

    // MARK: - Streaming Width Lock

    public var lockedStreamingMeasureWidth: CGFloat = 0

    // MARK: - Height Check Throttle

    public var lastStreamingHeightCheckTime: CFTimeInterval = 0
    public let minStreamingHeightCheckInterval: CFTimeInterval = 1.0 / 30.0

    public init() {}

    // MARK: - Cache Reset

    public func resetCellContentViewCache() {
        cachedCellContentView = nil
        cachedCellContentViewResolved = false
    }

    public func resetStreamingMeasureCache() {
        lastStreamingMeasuredWidth = 0
        lastStreamingMeasuredHeight = 0
        lastStreamingHeightCheckTime = 0
        lastMeasuredStreamingTextLength = 0
        lastMeasuredStreamingResultForWidth = 0
        lastMeasuredStreamingResultHeight = 0
    }

    public func invalidateContentSizing() {
        cachedContentHeight = nil
        cachedContentWidth = nil
        owner?.invalidateIntrinsicContentSize()
        (owner as? UIView)?.setNeedsLayout()
    }

    // MARK: - Width Resolution

    public func resolvedMeasureWidth() -> CGFloat {
        guard let owner else { return UIScreen.main.bounds.width }
        if (owner.renderMode == .streaming || owner.streamingTableHost.hasContent),
           lockedStreamingMeasureWidth > 0 {
            return lockedStreamingMeasureWidth
        }
        let width: CGFloat
        if let ownerView = owner as? UIView {
            if ownerView.bounds.width > 0 {
                width = ownerView.bounds.width
            } else if let superviewWidth = ownerView.superview?.bounds.width, superviewWidth > 0 {
                width = superviewWidth
            } else if owner.measureWidthInset > 0, let cellWidth = cellContentViewWidth(from: ownerView), cellWidth > 0 {
                width = max(cellWidth - owner.measureWidthInset, 1)
            } else {
                width = UIScreen.main.bounds.width
            }
        } else {
            width = UIScreen.main.bounds.width
        }
        if (owner.renderMode == .streaming || owner.streamingTableHost.hasContent),
           width > 0,
           lockedStreamingMeasureWidth == 0 {
            lockedStreamingMeasureWidth = width
        }
        return width
    }

    private func cellContentViewWidth(from view: UIView) -> CGFloat? {
        if cachedCellContentViewResolved {
            return (cachedCellContentView?.bounds.width ?? 0) > 0 ? cachedCellContentView?.bounds.width : nil
        }
        var v: UIView? = view
        while let cur = v {
            if let cell = cur.superview as? UICollectionViewCell, cell.contentView == cur {
                cachedCellContentView = cur
                cachedCellContentViewResolved = true
                return cur.bounds.width > 0 ? cur.bounds.width : nil
            }
            v = cur.superview
        }
        return nil
    }

    // MARK: - Streaming Height Notification

    public func notifyStreamingHeightIfNeeded(force: Bool = false) {
        guard let owner, owner.renderMode == .streaming else { return }
        let now = CACurrentMediaTime()
        if !force, (now - lastStreamingHeightCheckTime) < minStreamingHeightCheckInterval { return }
        lastStreamingHeightCheckTime = now
        let width = resolvedMeasureWidth()
        guard width > 0 else { return }
        let streamingHeight = measuredStreamingHeight(for: width)
        let widthChanged = abs(width - lastStreamingMeasuredWidth) > 0.5
        let heightChanged = abs(streamingHeight - lastStreamingMeasuredHeight) > 0.5
        guard force || widthChanged || heightChanged else { return }

        if !force,
           streamingHeight < lastStreamingMeasuredHeight {
            cachedContentWidth = width
            cachedContentHeight = max(lastStreamingMeasuredHeight, lastNotifiedHeight)
            return
        }

        lastStreamingMeasuredWidth = width
        lastStreamingMeasuredHeight = streamingHeight

        let isInPostResetHold =
            CACurrentMediaTime() < owner.postResetHeightHoldUntil
            && streamingHeight > lastNotifiedHeight
        let effectiveHeight: CGFloat
        if isInPostResetHold {
            effectiveHeight = lastNotifiedHeight
        } else if streamingHeight >= lastNotifiedHeight {
            effectiveHeight = streamingHeight
        } else {
            effectiveHeight = lastNotifiedHeight
        }
        cachedContentWidth = width
        cachedContentHeight = effectiveHeight

        let heightNotifyThreshold: CGFloat = 3.0
        let shouldNotify =
            abs(effectiveHeight - lastNotifiedHeight) > heightNotifyThreshold
            || abs(width - lastNotifiedWidth) > 0.5
        guard shouldNotify else { return }
        lastNotifiedWidth = width
        lastNotifiedHeight = effectiveHeight
        owner.invalidateIntrinsicContentSize()
        owner.onHeightChanged?()
    }

    // MARK: - Streaming Height Measurement

    public func measuredStreamingHeight(for width: CGFloat) -> CGFloat {
        guard let owner else { return 1 }
        let targetWidth = max(width, 1)
        let textLen = owner.streamingCommittedMarkdown.count
            + owner.streamingPresentationSnapshot.count
            + owner.activeStreamingTableBlockMarkdown.count

        if textLen > 0,
           textLen == lastMeasuredStreamingTextLength,
           abs(targetWidth - lastMeasuredStreamingResultForWidth) < 0.5,
           lastMeasuredStreamingResultHeight > 0 {
            return lastMeasuredStreamingResultHeight
        }

        let staticHeight = owner.stStaticRenderView.isHidden
            ? 0
            : STMarkdownTextViewMeasure.measure(owner.stStaticRenderView, width: targetWidth, gridSize: 2.0)
        let streamingHeight = owner.streamingRenderView.isHidden
            ? 0
            : STMarkdownTextViewMeasure.measure(
                owner.streamingRenderView.contentTextView,
                width: targetWidth,
                gridSize: 2.0,
                containerView: owner.streamingRenderView.measurementContainerView
            )
        let tableHeight = owner.streamingTableHost.isHidden
            ? 0
            : owner.streamingTableHost.measuredHeight(forWidth: targetWidth)
        let result = max(staticHeight + tableHeight + streamingHeight, 1)

        lastMeasuredStreamingTextLength = textLen
        lastMeasuredStreamingResultForWidth = targetWidth
        lastMeasuredStreamingResultHeight = result
        return result
    }

    // MARK: - Total Content Height

    public func totalContentHeight(for width: CGFloat) -> CGFloat {
        guard let owner else { return 1 }
        if width < 2 {
            return lastNotifiedHeight > 0 ? lastNotifiedHeight : (cachedContentHeight ?? 1)
        }
        if let cached = cachedContentHeight, cachedContentWidth == width {
            return cached
        }
        if owner.renderMode == .streaming,
           let cached = cachedContentHeight,
           let cachedWidth = cachedContentWidth,
           abs(cachedWidth - width) < 1.0 {
            return cached
        }
        if isComputingContentHeight {
            return cachedContentHeight ?? 1
        }
        if owner.isRenderingInProgress, lastNotifiedHeight > 0 {
            let height = lastNotifiedHeight
            if abs(lastNotifiedWidth - width) < 1 {
                cachedContentWidth = width
                cachedContentHeight = height
            }
            return height
        }
        isComputingContentHeight = true
        defer { isComputingContentHeight = false }
        let height: CGFloat
        switch owner.renderMode {
        case .streaming:
            let measured = measuredStreamingHeight(for: width)
            let floor = max(cachedContentHeight ?? 0, lastNotifiedHeight)
            if measured < floor, (floor - measured) < 40.0 {
                height = floor
            } else {
                height = measured
            }
        case .ast:
            let textView = owner.stStaticRenderView
            let layoutManager = textView.layoutManager
            let textContainer = textView.textContainer
            let inset = textView.textContainerInset
            textContainer.size = CGSize(width: width - inset.left - inset.right, height: .greatestFiniteMagnitude)
            layoutManager.ensureLayout(for: textContainer)
            let usedRect = layoutManager.usedRect(for: textContainer)
            let measured = ceil(usedRect.height + inset.top + inset.bottom)
            if measured < 1 {
                if !owner.currentMarkdown.isEmpty {
                    return lastNotifiedHeight > 0 ? lastNotifiedHeight : 1
                }
                return 0
            }
            let tableHeight = owner.streamingTableHost.isHidden
                ? 0
                : owner.streamingTableHost.measuredHeight(forWidth: width)
            let afterTableHeight: CGFloat
            if !owner.streamingRenderView.isHidden,
               let afterText = owner.streamingRenderView.contentTextView.attributedText,
               afterText.length > 0 {
                afterTableHeight = STMarkdownTextViewMeasure.measure(
                    owner.streamingRenderView.contentTextView,
                    width: width,
                    gridSize: 2.0,
                    containerView: owner.streamingRenderView.measurementContainerView
                )
            } else {
                afterTableHeight = 0
            }
            height = measured + tableHeight + afterTableHeight
        }
        cachedContentWidth = width
        cachedContentHeight = height
        return height
    }
}
