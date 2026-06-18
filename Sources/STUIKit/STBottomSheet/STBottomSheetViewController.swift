//
//  STBottomSheetViewController.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2026/6/16.
//

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

    open var topInset: CGFloat {
        return 100
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
        if currentOffset > self.fullOffset + 1 {
            scrollView.contentOffset = .zero
            scrollView.showsVerticalScrollIndicator = false
        } else {
            scrollView.showsVerticalScrollIndicator = true

            if scrollView.contentOffset.y < 0 {
                self.containerTopConstraint.constant -= scrollView.contentOffset.y
                scrollView.contentOffset = .zero
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
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        let velocity = gesture.velocity(in: self.view)
        switch gesture.state {
        case .began:
            break

        case .changed:
            let isFullScreen = abs(self.containerTopConstraint.constant - self.fullOffset) < 5
            if isFullScreen, let contentScrollView = self.contentScrollView, contentScrollView.contentOffset.y > 0, translation.y < 0 {
                gesture.setTranslation(.zero, in: self.view)
                return
            }
            let newConstant = self.containerTopConstraint.constant + translation.y
            if newConstant >= self.fullOffset {
                self.containerTopConstraint.constant = newConstant
                gesture.setTranslation(.zero, in: self.view)
            }

        case .ended, .cancelled:
            self.finishPanGesture(velocity: velocity)

        default:
            break
        }
    }

    private func finishPanGesture(velocity: CGPoint) {
        let currentOffset = self.containerTopConstraint.constant
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
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
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

        let isFullScreen = abs(self.containerTopConstraint.constant - self.fullOffset) < 5
        guard isFullScreen, let contentScrollView = self.contentScrollView, contentScrollView.contentOffset.y > 0 else {
            return true
        }

        return panGesture.velocity(in: self.view).y <= 0
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
