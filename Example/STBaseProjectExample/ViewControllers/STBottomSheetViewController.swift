//
//  STBottomSheetViewController.swift
//  STBaseProjectExample
//
//  Created by 寒江孤影 on 2026/6/16.
//

import UIKit

class STBottomSheetViewController: BaseViewController {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private let data: [String] = (1...50).map {
        "这是第 \($0) 行内容，可以上下滑动测试"
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // 1. 设置自定义呈现样式
        modalPresentationStyle = .custom
        // 2. 绑定转场代理
        transitioningDelegate = BottomSheetTransitionManager.shared
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        setupHeader()
        setupTableView()
        
        view.backgroundColor = .white
                // 设置顶部圆角
                view.layer.cornerRadius = 16
                view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    private func setupHeader() {
        let titleLabel = UILabel()
        titleLabel.text = "半屏弹窗 Demo"
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 56
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension STBottomSheetViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.selectionStyle = .none
        return cell
    }
}

import UIKit

class BottomSheetPresentationController: UIPresentationController {
    
    private var dimmingView: UIView!
    private let sheetHeight: CGFloat = 400 // 弹窗高度
    
    // 1. 定义弹窗在容器中的最终 Frame
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let container = containerView else { return .zero }
        return CGRect(
            x: 0,
            y: container.bounds.height - sheetHeight,
            width: container.bounds.width,
            height: sheetHeight
        )
    }
    
    // 2. Present 动画即将开始：添加遮罩并执行渐显动画
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView = containerView else { return }
        
        dimmingView = UIView(frame: containerView.bounds)
        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimmingView.alpha = 0.0
        containerView.insertSubview(dimmingView, at: 0)
        
        // 使用 transitionCoordinator 同步执行遮罩动画
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1.0
        })
    }
    
    // 3. Dismiss 动画即将开始：执行遮罩渐隐动画
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        })
    }
    
    // 4. Dismiss 动画结束：清理遮罩视图
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            dimmingView?.removeFromSuperview()
            dimmingView = nil
        }
    }
}

import UIKit

class BottomSheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let isPresenting: Bool
    
    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }
    
    // 动画时长
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.35
    }
    
    // 核心动画逻辑
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        if isPresenting {
            guard let toView = transitionContext.view(forKey: .to) else { return }
            containerView.addSubview(toView)
            
            // 设置初始状态（隐藏在屏幕底部）
            let finalFrame = transitionContext.finalFrame(for: transitionContext.viewController(forKey: .to)!)
            toView.frame = finalFrame.offsetBy(dx: 0, dy: finalFrame.height)
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseOut, animations: {
                toView.frame = finalFrame
            }, completion: { finished in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        } else {
            guard let fromView = transitionContext.view(forKey: .from) else { return }
            
            // 设置最终状态（滑出屏幕底部）
            var finalFrame = fromView.frame
            finalFrame.origin.y += finalFrame.height
            
            UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseIn, animations: {
                fromView.frame = finalFrame
            }, completion: { finished in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
    }
}

import UIKit

class BottomSheetTransitionManager: NSObject, UIViewControllerTransitioningDelegate {
    
    // 单例，方便全局调用
    static let shared = BottomSheetTransitionManager()
    private override init() { super.init() }
    
    // 交互式过渡控制器
    private var interactiveDismissal: UIPercentDrivenInteractiveTransition?
    
    // 1. 返回自定义的 PresentationController
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return BottomSheetPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    // 2. Present 动画
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetAnimator(isPresenting: true)
    }
    
    // 3. Dismiss 动画
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BottomSheetAnimator(isPresenting: false)
    }
    
    // 4. 返回交互式过渡控制器
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveDismissal
    }
    
    // 5. 绑定下拉手势到目标控制器
    func bindDismissGesture(to viewController: UIViewController) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        viewController.view.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let translation = gesture.translation(in: view)
        let progress = translation.y / view.bounds.height
        
        switch gesture.state {
        case .began:
            interactiveDismissal = UIPercentDrivenInteractiveTransition()
            view.window?.rootViewController?.dismiss(animated: true)
        case .changed:
            interactiveDismissal?.update(progress)
        case .cancelled:
            interactiveDismissal?.cancel()
            interactiveDismissal = nil
        case .ended:
            // 下拉超过 30% 或 速度足够快时关闭
            if progress > 0.3 || gesture.velocity(in: view).y > 500 {
                interactiveDismissal?.finish()
            } else {
                interactiveDismissal?.cancel()
            }
            interactiveDismissal = nil
        default:
            break
        }
    }
}
