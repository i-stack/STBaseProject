//
//  BaseViewController.swift
//  STBaseProjectExample
//
//  Created by 寒江孤影 on 2026/4/27.
//

import UIKit
import STBaseProject

class BaseViewController: STBaseViewController, UIGestureRecognizerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemGroupedBackground
        self.st_setNavigationBarColor(.systemBackground)
        self.configureDefaultBackButtonIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateInteractivePopGestureState()
    }

    @objc override func onLeftBtnTap() {
        if let navigationController = self.navigationController,
           navigationController.viewControllers.first !== self {
            navigationController.popViewController(animated: true)
            return
        }

        if self.presentingViewController != nil {
            self.dismiss(animated: true)
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.shouldEnableInteractivePopGesture
    }

    private func configureDefaultBackButtonIfNeeded() {
        guard self.shouldShowDefaultBackButton else { return }
        self.st_showNavBtnType(type: .showLeftBtn)
        self.leftBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
    }

    private func updateInteractivePopGestureState() {
        guard let interactivePopGestureRecognizer = self.navigationController?.interactivePopGestureRecognizer else {
            return
        }

        interactivePopGestureRecognizer.isEnabled = self.shouldEnableInteractivePopGesture
        interactivePopGestureRecognizer.delegate = self.shouldEnableInteractivePopGesture ? self : nil
    }

    private var shouldShowDefaultBackButton: Bool {
        if let navigationController = self.navigationController {
            return navigationController.viewControllers.first !== self
        }

        return self.presentingViewController != nil
    }

    private var shouldEnableInteractivePopGesture: Bool {
        guard let navigationController = self.navigationController else {
            return false
        }

        return navigationController.viewControllers.count > 1
    }

    /// 让滚动视图从导航栏下方穿过，并启用 Liquid Glass 玻璃导航栏。
    /// 调用方需保证 scrollView 顶部钉在 view.topAnchor，而不是 contentTopAnchor。
    func applyLiquidGlassScrollLayout(_ scrollView: UIScrollView) {
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset.top = self.navBarHeight
        scrollView.verticalScrollIndicatorInsets.top = self.navBarHeight
        self.view.bringSubviewToFront(self.navigationBarView)
        if #available(iOS 26.0, *) {
            self.st_enableLiquidGlass()
            self.navBarBackgroundColor = .clear
            self.st_linkLiquidGlassVisibility(scrollView)
        }
    }
}
