//
//  STBottomSheetViewController.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/6/16.
//

import os
import UIKit

private final class STBottomSheetRootView: UIView {
    
    weak var interactiveContentView: UIView?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else {
            return nil
        }
        guard let interactiveContentView else {
            return hitView
        }

        let contentPoint = interactiveContentView.convert(point, from: self)
        return interactiveContentView.bounds.contains(contentPoint) ? hitView : nil
    }
}

open class STBottomSheetViewController: UIViewController {

    open weak var contentScrollView: UIScrollView?

    #if DEBUG
    private static let diagnosticsLog = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "app",
        category: "STBottomSheet"
    )

    private var lastScrollDiagnosticsTime: CFTimeInterval = 0
    #endif

    open var topInset: CGFloat {
        return 106
    }

    open var partialHeightRatio: CGFloat {
        return 0.5
    }

    private var containerTopConstraint: NSLayoutConstraint!

    private var containerHeight: CGFloat {
        let height = self.view.bounds.height
        return height > 0 ? height : UIScreen.main.bounds.height
    }

    private var partialHeight: CGFloat {
        return self.containerHeight * self.partialHeightRatio
    }

    private var fullHeight: CGFloat {
        return max(self.containerHeight - self.topInset, 0)
    }

    private var hiddenOffset: CGFloat {
        return self.containerHeight
    }

    private var partialOffset: CGFloat {
        return self.containerHeight - self.partialHeight
    }

    private var fullOffset: CGFloat {
        return self.containerHeight - self.fullHeight
    }

    private let fullOffsetTolerance: CGFloat = 24

    private var isFullScreen: Bool {
        return abs(self.containerTopConstraint.constant - self.fullOffset) < self.fullOffsetTolerance
    }

    open override func loadView() {
        let rootView = STBottomSheetRootView()
        rootView.backgroundColor = .clear
        rootView.interactiveContentView = self.contentView
        self.view = rootView
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.setupContentView()
        self.setupPanGesture()
        self.setupContent()
        self.containerTopConstraint.constant = self.hiddenOffset
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.containerTopConstraint.constant > self.hiddenOffset {
            self.containerTopConstraint.constant = self.hiddenOffset
        }
    }

    open func setupContent() {}

    public func animateToDismiss() {
        self.dismiss(animated: true, completion: nil)
    }

    public func bottomSheetScrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = self.containerTopConstraint.constant
        if currentOffset > self.fullOffset + self.fullOffsetTolerance {
            self.logScrollDiagnostics(
                event: "lockScrollBeforeFull",
                scrollView: scrollView,
                sheetOffset: currentOffset,
                force: true
            )
            scrollView.contentOffset = .zero
            scrollView.showsVerticalScrollIndicator = false
        } else {
            scrollView.showsVerticalScrollIndicator = true

            if scrollView.contentOffset.y < 0 {
                self.logScrollDiagnostics(
                    event: "pullDownFromTop",
                    scrollView: scrollView,
                    sheetOffset: currentOffset,
                    force: true
                )
                self.containerTopConstraint.constant -= scrollView.contentOffset.y
                scrollView.contentOffset = .zero
            } else {
                if currentOffset > self.fullOffset {
                    self.containerTopConstraint.constant = self.fullOffset
                }
                self.logScrollDiagnostics(
                    event: "scroll",
                    scrollView: scrollView,
                    sheetOffset: currentOffset,
                    force: false
                )
            }
        }
    }

    func prepareForPresentationTransition() {
        self.view.layoutIfNeeded()
        self.containerTopConstraint.constant = self.hiddenOffset
        self.view.layoutIfNeeded()
    }

    func finishPresentationWithoutAnimation() {
        self.view.layoutIfNeeded()
        self.containerTopConstraint.constant = self.partialOffset
        self.view.layoutIfNeeded()
    }

    func animatePresentationTransition(duration: TimeInterval, completion: @escaping () -> Void) {
        self.containerTopConstraint.constant = self.partialOffset
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            completion()
        })
    }

    func animateDismissalTransition(duration: TimeInterval, completion: @escaping () -> Void) {
        self.containerTopConstraint.constant = self.hiddenOffset
        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            completion()
        })
    }

    private func setupContentView() {
        self.view.addSubview(self.contentView)
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.containerTopConstraint = self.contentView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: self.hiddenOffset)
        let bottomConstraint = self.contentView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        bottomConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            self.containerTopConstraint,
            self.contentView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            bottomConstraint
        ])
    }

    private func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(_:)))
        panGesture.delegate = self
        self.view.addGestureRecognizer(panGesture)
        self.logDiagnostics("setupPanGesture")
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        let velocity = gesture.velocity(in: self.view)
        switch gesture.state {
        case .began:
            self.logPanDiagnostics(event: "began", gesture: gesture)

        case .changed:
            self.logPanDiagnostics(event: "changed", gesture: gesture)
            if self.isFullScreen, let contentScrollView = self.contentScrollView, contentScrollView.contentOffset.y > 0, translation.y < 0 {
                self.logPanDiagnostics(event: "ignoreUpwardWhenScrollHasOffset", gesture: gesture)
                gesture.setTranslation(.zero, in: self.view)
                return
            }
            let newConstant = self.containerTopConstraint.constant + translation.y
            if newConstant >= self.fullOffset {
                self.containerTopConstraint.constant = newConstant
                self.logDiagnostics(
                    "sheetOffsetChanged translationY=\(self.diagnosticValue(translation.y)) velocityY=\(self.diagnosticValue(velocity.y)) newOffset=\(self.diagnosticValue(newConstant)) fullOffset=\(self.diagnosticValue(self.fullOffset))"
                )
                gesture.setTranslation(.zero, in: self.view)
            }

        case .ended, .cancelled:
            self.logPanDiagnostics(event: "endedOrCancelled", gesture: gesture)
            self.finishPanGesture(velocity: velocity)

        default:
            break
        }
    }

    private func finishPanGesture(velocity: CGPoint) {
        let currentOffset = self.containerTopConstraint.constant
        self.logDiagnostics(
            "finishPan velocityY=\(self.diagnosticValue(velocity.y)) currentOffset=\(self.diagnosticValue(currentOffset)) fullOffset=\(self.diagnosticValue(self.fullOffset)) partialOffset=\(self.diagnosticValue(self.partialOffset)) hiddenOffset=\(self.diagnosticValue(self.hiddenOffset))"
        )
        if velocity.y > 600 {
            if currentOffset < self.partialOffset - 50 {
                self.animateToOffset(self.partialOffset)
            } else {
                self.animateToDismiss()
            }
            return
        }
        
        if velocity.y < -600 {
            self.animateToOffset(self.fullOffset)
            return
        }

        let totalTransitionDistance = self.partialOffset - self.fullOffset
        let currentProgress = (currentOffset - self.fullOffset) / totalTransitionDistance
        if currentOffset <= self.partialOffset {
            if currentProgress > 0.40 {
                self.animateToOffset(self.partialOffset)
            } else {
                self.animateToOffset(self.fullOffset)
            }
        } else {
            let dismissProgress = (currentOffset - self.partialOffset) / (self.hiddenOffset - self.partialOffset)
            if dismissProgress > 0.35 {
                self.animateToDismiss()
            } else {
                self.animateToOffset(self.partialOffset)
            }
        }
    }

    private func animateToOffset(_ offset: CGFloat) {
        self.containerTopConstraint.constant = offset
        self.logDiagnostics(
            "animateToOffset target=\(self.diagnosticValue(offset)) fullOffset=\(self.diagnosticValue(self.fullOffset)) partialOffset=\(self.diagnosticValue(self.partialOffset)) hiddenOffset=\(self.diagnosticValue(self.hiddenOffset))"
        )
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    private func shouldBeginSheetPan(_ panGesture: UIPanGestureRecognizer) -> Bool {
        guard self.isFullScreen, let contentScrollView = self.contentScrollView else {
            return true
        }

        let location = panGesture.location(in: contentScrollView)
        let shouldBegin = !contentScrollView.bounds.contains(location)
        self.logPanDiagnostics(
            event: "shouldBegin=\(shouldBegin)",
            gesture: panGesture,
            contentScrollView: contentScrollView,
            location: location
        )
        return shouldBegin
    }

    private func diagnosticValue(_ value: CGFloat) -> String {
        return String(format: "%.2f", Double(value))
    }

    private func diagnosticValue(_ value: Double) -> String {
        return String(format: "%.2f", value)
    }

    private func logDiagnostics(_ message: String) {
        #if DEBUG
        os_log(.default, log: Self.diagnosticsLog, "[STBottomSheet] %{public}@", message)
        #endif
    }

    private func logScrollDiagnostics(event: String, scrollView: UIScrollView, sheetOffset: CGFloat, force: Bool) {
        #if DEBUG
        if !force {
            let now = CFAbsoluteTimeGetCurrent()
            guard now - self.lastScrollDiagnosticsTime > 0.20 else {
                return
            }
            self.lastScrollDiagnosticsTime = now
        }

        os_log(
            .default,
            log: Self.diagnosticsLog,
            "[STBottomSheet][Scroll] %{public}@ isFull=%{public}@ sheetOffset=%{public}@ fullOffset=%{public}@ delta=%{public}@ contentOffsetY=%{public}@ adjustedTop=%{public}@ contentSizeH=%{public}@ boundsH=%{public}@ scroll=%{public}@",
            event,
            "\(self.isFullScreen)",
            self.diagnosticValue(sheetOffset),
            self.diagnosticValue(self.fullOffset),
            self.diagnosticValue(sheetOffset - self.fullOffset),
            self.diagnosticValue(scrollView.contentOffset.y),
            self.diagnosticValue(scrollView.adjustedContentInset.top),
            self.diagnosticValue(scrollView.contentSize.height),
            self.diagnosticValue(scrollView.bounds.height),
            String(describing: type(of: scrollView))
        )
        #endif
    }

    private func logPanDiagnostics(event: String, gesture: UIPanGestureRecognizer) {
        #if DEBUG
        self.logPanDiagnostics(
            event: event,
            gesture: gesture,
            contentScrollView: self.contentScrollView,
            location: self.contentScrollView.map { gesture.location(in: $0) }
        )
        #endif
    }

    private func logPanDiagnostics(event: String, gesture: UIPanGestureRecognizer, contentScrollView: UIScrollView?, location: CGPoint?) {
        #if DEBUG
        let translation = gesture.translation(in: self.view)
        let velocity = gesture.velocity(in: self.view)
        let contentOffsetY = contentScrollView?.contentOffset.y ?? .nan
        let adjustedTop = contentScrollView?.adjustedContentInset.top ?? .nan
        let locationX = location?.x ?? .nan
        let locationY = location?.y ?? .nan
        let inScroll = location.map { contentScrollView?.bounds.contains($0) ?? false } ?? false

        os_log(
            .default,
            log: Self.diagnosticsLog,
            "[STBottomSheet][Pan] %{public}@ state=%{public}ld isFull=%{public}@ sheetOffset=%{public}@ fullOffset=%{public}@ translationY=%{public}@ velocityY=%{public}@ inScroll=%{public}@ location=(%{public}@,%{public}@) contentOffsetY=%{public}@ adjustedTop=%{public}@ scroll=%{public}@",
            event,
            gesture.state.rawValue,
            "\(self.isFullScreen)",
            self.diagnosticValue(self.containerTopConstraint.constant),
            self.diagnosticValue(self.fullOffset),
            self.diagnosticValue(translation.y),
            self.diagnosticValue(velocity.y),
            "\(inScroll)",
            self.diagnosticValue(locationX),
            self.diagnosticValue(locationY),
            self.diagnosticValue(contentOffsetY),
            self.diagnosticValue(adjustedTop),
            contentScrollView.map { String(describing: type(of: $0)) } ?? "nil"
        )
        #endif
    }
    
    public let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()
}

extension STBottomSheetViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }

        return self.shouldBeginSheetPan(panGesture)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

public class STBottomSheetPresentationController: UIPresentationController {
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleDimmingViewTap))
        view.addGestureRecognizer(tapGesture)
        return view
    }()

    public override var frameOfPresentedViewInContainerView: CGRect {
        return self.containerView?.bounds ?? .zero
    }

    public override func presentationTransitionWillBegin() {
        guard let containerView = self.containerView else { return }
        self.dimmingView.frame = containerView.bounds
        containerView.insertSubview(self.dimmingView, at: 0)
        guard let transitionCoordinator = self.presentedViewController.transitionCoordinator else {
            self.dimmingView.alpha = 1
            return
        }
        transitionCoordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        })
    }

    public override func dismissalTransitionWillBegin() {
        guard let transitionCoordinator = self.presentedViewController.transitionCoordinator else {
            self.dimmingView.alpha = 0
            self.dimmingView.removeFromSuperview()
            return
        }
        transitionCoordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        }, completion: { _ in
            self.dimmingView.removeFromSuperview()
        })
    }

    public override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        if completed {
            (self.presentedViewController as? STBottomSheetViewController)?.finishPresentationWithoutAnimation()
        } else {
            self.dimmingView.removeFromSuperview()
        }
    }

    public override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        self.dimmingView.frame = self.containerView?.bounds ?? .zero
        self.presentedView?.frame = self.frameOfPresentedViewInContainerView
    }

    @objc private func handleDimmingViewTap() {
        if let bottomSheetViewController = self.presentedViewController as? STBottomSheetViewController {
            bottomSheetViewController.animateToDismiss()
        } else {
            self.presentedViewController.dismiss(animated: true, completion: nil)
        }
    }
}

public class STBottomSheetTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let isPresenting: Bool

    public init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView

        if self.isPresenting {
            self.animatePresentation(in: containerView, transitionContext: transitionContext)
        } else {
            self.animateDismissal(transitionContext: transitionContext)
        }
    }

    private func animatePresentation(in containerView: UIView, transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toView = transitionContext.view(forKey: .to),
            let toViewController = transitionContext.viewController(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        containerView.addSubview(toView)
        toView.frame = containerView.bounds
        toViewController.view.layoutIfNeeded()

        guard let bottomSheetViewController = toViewController as? STBottomSheetViewController else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }

        bottomSheetViewController.prepareForPresentationTransition()
        bottomSheetViewController.animatePresentationTransition(duration: self.transitionDuration(using: transitionContext)) {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

    private func animateDismissal(transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromView = transitionContext.view(forKey: .from),
            let fromViewController = transitionContext.viewController(forKey: .from)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let finishTransition = {
            fromView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        guard let bottomSheetViewController = fromViewController as? STBottomSheetViewController else {
            finishTransition()
            return
        }

        bottomSheetViewController.animateDismissalTransition(duration: self.transitionDuration(using: transitionContext), completion: finishTransition)
    }
}

public class STBottomSheetTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {

    public override init() {
        super.init()
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return STBottomSheetPresentationController(presentedViewController: presented, presenting: presenting)
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return STBottomSheetTransitionAnimator(isPresenting: true)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return STBottomSheetTransitionAnimator(isPresenting: false)
    }
}
