//
//  STRefreshBehavior.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit

final class STRefreshBehavior {

    private var header: STRefreshHeaderView?
    private var footer: STLoadMoreFooterView?

    func addPullToRefresh(to scrollView: UIScrollView, content: STRefreshContent, action: @escaping () -> Void) {
        self.removePullToRefresh()
        let header = STRefreshHeaderView(content: content)
        header.attach(to: scrollView, action: action)
        self.header = header
    }

    func removePullToRefresh() {
        self.header?.removeFromSuperview()
        self.header = nil
    }

    func beginRefreshing() {
        self.header?.beginRefreshing()
    }

    func endRefreshing() {
        self.header?.endRefreshing()
    }

    func addLoadMore(to scrollView: UIScrollView, content: STLoadMoreContent, action: @escaping () -> Void) {
        self.removeLoadMore()
        let footer = STLoadMoreFooterView(content: content)
        footer.attach(to: scrollView, action: action)
        self.footer = footer
    }

    func removeLoadMore() {
        self.footer?.removeFromSuperview()
        self.footer = nil
    }

    func endLoadMore(paging: STPagingState) {
        self.footer?.endLoading(paging: paging)
    }

    func resetLoadMore() {
        self.footer?.resetToIdle()
    }

    var footerInjectedInsetBottom: CGFloat {
        return self.footer?.injectedInsetBottom ?? 0
    }

    func notifySafeAreaChanged() {
        self.header?.safeAreaInsetsDidChangeFromHost()
        self.footer?.safeAreaInsetsDidChangeFromHost()
    }
}