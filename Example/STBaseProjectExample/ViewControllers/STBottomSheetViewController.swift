//
//  STBottomSheetViewController.swift
//  STBaseProjectExample
//
//  Created by 寒江孤影 on 2026/6/16.
//

import UIKit

import UIKit

import UIKit

class STBottomSheetViewController: UIViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let data: [String] = (1...50).map { "这是第 \($0) 行内容，可以上下滑动测试" }
    
    // 💡 定义两个档位的高度（使用 UIScreen 避免 viewDidLoad 拿到 0 导致计算错误）
    private var partialHeight: CGFloat { return UIScreen.main.bounds.height * 0.5 } // 半屏
    private var fullHeight: CGFloat { return UIScreen.main.bounds.height - 100 }    // 全屏（自定义距离顶部 100）
    
    // 记录当前的 Top 约束值
    private var containerTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 💡 必须是全透明，才能漏出底层的黑色半透明背景
        view.backgroundColor = .clear
        
        setupContentView()
        setupHeader()
        setupTableView()
        setupPanGesture()
        
        // 💡 刚加载时，让卡片完全藏在屏幕底部外面（由展现动画将其推上来）
        containerTopConstraint.constant = UIScreen.main.bounds.height
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 💡 在即将显示时，用动画平滑地推到“半屏”位置，这能完美配合 PresentationController 的黑色背景淡入
        view.layoutIfNeeded()
        containerTopConstraint.constant = UIScreen.main.bounds.height - partialHeight
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    // 实际承载内容的白色卡片
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground // 💡 白色底，确保盖住下面的内容
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()
    
    private func setupContentView() {
        view.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        containerTopConstraint = contentView.topAnchor.constraint(equalTo: view.topAnchor, constant: UIScreen.main.bounds.height)
        
        NSLayoutConstraint.activate([
            containerTopConstraint,
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // 💡 解决方案：把底部约束的优先级降低到 999。
            // 这样在刚弹出、高度被迫为 0 的一瞬间，系统允许破坏这个底部约束，而不会打印大段警告。
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor).withPriority(.defaultHigh)
        ])
    }
    
    private func setupHeader() {
        let titleLabel = UILabel()
        titleLabel.text = "半屏/全屏自适应弹窗"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 56
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        contentView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    // MARK: - 手势与联动核心逻辑
    private func setupPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }


    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        let screenHeight = UIScreen.main.bounds.height
        
        let partialOffset = screenHeight - partialHeight
        let fullOffset = screenHeight - fullHeight
        
        switch gesture.state {
        case .began:
            break
            
        case .changed:
            // 💡 优化 1 & 2：全屏且列表没到顶时，只有“往下划”才允许卡片跟随手动。往上划继续滚列表
            let isFullScreen = abs(containerTopConstraint.constant - fullOffset) < 5
            if isFullScreen && tableView.contentOffset.y > 0 && translation.y < 0 {
                gesture.setTranslation(.zero, in: view)
                return
            }
            
            // 💡 窗口实时跟随手指移动
            let newConstant = containerTopConstraint.constant + translation.y
            let minConstant = screenHeight - fullHeight // 限制不能冲出设定的最高点
            if newConstant >= minConstant {
                containerTopConstraint.constant = newConstant
                gesture.setTranslation(.zero, in: view)
            }
            
        case .ended, .cancelled:
            let currentOffset = containerTopConstraint.constant
            
            // 💡 优化 3：大速度（甩动手势）的高级物理判定
            // 只要用户是“往下猛甩”（速度 > 600）
            if velocity.y > 600 {
                // 如果松手位置还在半屏以上（说明刚开始甩），让他退到半屏，防止误触直接消失
                if currentOffset < partialOffset - 50 {
                    animateToOffset(partialOffset)
                } else {
                    // 如果松手位置已经接近或超过半屏，顺从用户的动量，直接滑出界面消失！
                    animateToDismiss()
                }
                return
            }
            // 如果是“往上猛甩”（速度 < -600）
            else if velocity.y < -600 {
                animateToOffset(fullOffset) // 直接冲到全屏
                return
            }
            
            // 💡 优化 2：慢速滑动或手动停止滑动时，纯根据松手时的当前【绝对位置】来判定该去哪
            let totalTransitionDistance = partialOffset - fullOffset
            let currentProgress = (currentOffset - fullOffset) / totalTransitionDistance // 0(全屏) -> 1(半屏)
            
            if currentOffset <= partialOffset {
                // 在【全屏】和【半屏】之间松手
                // 如果拉过了这段距离的 40%，就去半屏，否则弹回全屏
                if currentProgress > 0.40 {
                    animateToOffset(partialOffset)
                } else {
                    animateToOffset(fullOffset)
                }
            } else {
                // 在【半屏】和【屏幕底部】之间松手
                let dismissProgress = (currentOffset - partialOffset) / (screenHeight - partialOffset)
                // 如果继续下拉超过了半屏到终点距离的 35%，则直接消失，否则弹回半屏
                if dismissProgress > 0.35 {
                    animateToDismiss()
                } else {
                    animateToOffset(partialOffset)
                }
            }
            
        default:
            break
        }
    }
    
    private func animateToOffset(_ offset: CGFloat) {
        containerTopConstraint.constant = offset
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    // 💡 自定义退出动画，让卡片丝滑地滑出屏幕后再执行系统 dismiss
    func animateToDismiss() {
        containerTopConstraint.constant = UIScreen.main.bounds.height
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
        }) { _ in
            self.dismiss(animated: false, completion: nil)
        }
    }
}

// MARK: - UITableView 滚动联动处理

extension STBottomSheetViewController: UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 只有当我们添加的 UIPanGestureRecognizer 准备启动时才处理
        if gestureRecognizer is UIPanGestureRecognizer {
            let screenHeight = UIScreen.main.bounds.height
            let isFullScreen = abs(containerTopConstraint.constant - (screenHeight - fullHeight)) < 5
            
            // 💡 核心逻辑：如果当前已经是全屏状态，且 TableView 已经被卷上去超过 0 了
            if isFullScreen && tableView.contentOffset.y > 0 {
                // 如果用户此时手指是往下滑（想让列表回滚），外层手势不能启动，必须让列表自己滚回来
                let velocity = (gestureRecognizer as! UIPanGestureRecognizer).velocity(in: view)
                if velocity.y > 0 {
                    return false // 禁用外层手势，把控制权百分百给 TableView
                }
            }
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = containerTopConstraint.constant
        let fullOffset = UIScreen.main.bounds.height - fullHeight
        
        // 💡 当卡片还没有完全到达全屏时（比如在半屏或者正在往上拖）
        if currentOffset > fullOffset + 1 {
            // 强行把内容锁死在顶部，这样你的手指无论在 TableView 的什么地方划，都会百分之百触发外层的卡片位移动画
            scrollView.contentOffset = .zero
            scrollView.showsVerticalScrollIndicator = false
        } else {
            // 只有到了全屏，才允许 TableView 内部正常滚动
            scrollView.showsVerticalScrollIndicator = true
            
            // 当在全屏向下拉到顶时，交还手势给外层卡片
            if scrollView.contentOffset.y < 0 {
                containerTopConstraint.constant -= scrollView.contentOffset.y
                scrollView.contentOffset = .zero
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        return cell
    }
}

class CustomPresentationController: UIPresentationController {
    
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5) // 💡 黑色 0.5 透明度
        view.alpha = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDimmingViewTap))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    override var frameOfPresentedViewInContainerView: CGRect {
        return containerView?.bounds ?? .zero
    }
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }
        dimmingView.frame = containerView.bounds
        containerView.insertSubview(dimmingView, at: 0)
        
        // 随转场完美淡入
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1
        })
    }
    
    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        }, completion: { _ in
            self.dimmingView.removeFromSuperview()
        })
    }
    
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        dimmingView.frame = containerView?.bounds ?? .zero
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    @objc private func handleDimmingViewTap() {
        // 如果你的弹窗实现了自定义的退出动画，可以调用它的自定义退出方法
        if let bottomSheetVC = presentedViewController as? STBottomSheetViewController {
            bottomSheetVC.animateToDismiss()
        } else {
            // 兜底：如果没有自定义退出动画，则直接执行系统的 dismiss
            presentedViewController.dismiss(animated: true, completion: nil)
        }
    }
}

// 💡 简化转场动画器，只负责把 VC 塞进容器，位移交由 VC 自身的 viewWillAppear 驱动
class CustomTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool
    init(isPresenting: Bool) { self.isPresenting = isPresenting }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        if isPresenting {
            guard let toView = transitionContext.view(forKey: .to) else { return }
            containerView.addSubview(toView)
            toView.frame = containerView.bounds
            transitionContext.completeTransition(true)
        } else {
            guard let fromView = transitionContext.view(forKey: .from) else { return }
            fromView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }
}

class CustomTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    // 谁来管理布局和黑色背景？
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CustomPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    // 谁来提供弹出动画？
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CustomTransitionAnimator(isPresenting: true)
    }
    
    // 谁来提供消失动画？
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CustomTransitionAnimator(isPresenting: false)
    }
}

extension NSLayoutConstraint {
    func withPriority(_ priority: UILayoutPriority) -> NSLayoutConstraint {
        self.priority = priority
        return self
    }
}
