//
//  STApplePurchaseTestViewController.swift
//  STBaseProjectExample
//
//  Created by 寒江孤影 on 2026/11/3.
//

import UIKit
import STBaseProject
import STApplePurchase

/// 演示 STApplePurchase 的核心用法：加载商品、购买消耗型商品、恢复购买、查询订阅状态。
///
/// 本地跑通需要在 Scheme 的 Run > Options > StoreKit Configuration 里
/// 选中 `STBaseProjectExample.storekit`，否则商品加载会失败（找不到商品）。
class STApplePurchaseTestViewController: BaseViewController {

    private let manager = STApplePurchaseManager()
    private var loadedProducts: [STApplePurchaseProduct] = []
    private var logLines: [String] = []

    private static let consumableProductID = "com.stapplepurchase.example.coins_small"
    private static let subscriptionProductID = "com.stapplepurchase.example.pro_monthly"
    private static let subscriptionGroupID = "B2000000-0000-0000-0000-000000000003"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "内购功能测试"
        self.manager.logger = self
        self.manager.startListeningForTransactionUpdates()
        self.buildUI()
    }

    private func buildUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scrollView)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 12
        scrollView.addSubview(stackView)

        self.addSection(title: "商品与购买", actions: [
            ("加载商品列表", #selector(self.loadProducts)),
            ("购买消耗型商品", #selector(self.purchaseConsumable)),
            ("购买订阅商品", #selector(self.purchaseSubscription)),
            ("恢复购买", #selector(self.restorePurchases))
        ], to: stackView)

        self.addSection(title: "订阅状态", actions: [
            ("查询订阅状态", #selector(self.inspectSubscriptionStatus))
        ], to: stackView)

        stackView.addArrangedSubview(self.logTextView)
        NSLayoutConstraint.activate([
            self.logTextView.heightAnchor.constraint(equalToConstant: 240)
        ])

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        self.applyLiquidGlassScrollLayout(scrollView)
    }

    private func addSection(title: String, actions: [(String, Selector)], to parent: UIStackView) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = STTypography.headline.font(compatibleWith: titleLabel.traitCollection)
        titleLabel.adjustsFontForContentSizeCategory = true
        parent.addArrangedSubview(titleLabel)

        for action in actions {
            let button = UIButton(type: .system)
            button.contentHorizontalAlignment = .left
            button.titleLabel?.font = UIFont.st_preferredFont(ofSize: 15, forTextStyle: .body, weight: .medium)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.setTitle(action.0, for: .normal)
            button.addTarget(self, action: action.1, for: .touchUpInside)
            parent.addArrangedSubview(button)
        }
    }

    private func appendLog(_ message: String) {
        let line = "[\(Self.timeString())] \(message)"
        self.logLines.append(line)
        if self.logLines.count > 120 {
            self.logLines.removeFirst(self.logLines.count - 120)
        }
        self.logTextView.text = self.logLines.joined(separator: "\n")
        let range = NSRange(location: max(self.logTextView.text.count - 1, 0), length: 1)
        self.logTextView.scrollRangeToVisible(range)
    }

    private static func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    private lazy var logTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFontMetrics(forTextStyle: .caption1).scaledFont(
            for: .monospacedSystemFont(ofSize: 12, weight: .regular)
        )
        textView.adjustsFontForContentSizeCategory = true
        textView.backgroundColor = UIColor.secondarySystemBackground
        textView.layer.cornerRadius = 8
        return textView
    }()

    private func product(withID id: String) -> STApplePurchaseProduct? {
        self.loadedProducts.first { $0.id == id }
    }
}

extension STApplePurchaseTestViewController: STApplePurchaseLogging {
    func log(_ message: String) {
        self.appendLog("[internal] \(message)")
    }
}

private extension STApplePurchaseTestViewController {
    @objc func loadProducts() {
        Task {
            do {
                let products = try await self.manager.loadProducts(productIDs: [
                    Self.consumableProductID,
                    Self.subscriptionProductID
                ])
                self.loadedProducts = products
                self.appendLog("加载商品成功，共 \(products.count) 个：\(products.map { "\($0.id)(\($0.displayPrice))" }.joined(separator: ", "))")
            } catch {
                self.appendLog("加载商品失败: \(error.localizedDescription)（请检查 Scheme 是否已配置 StoreKit Configuration 为 STBaseProjectExample.storekit）")
            }
        }
    }

    @objc func purchaseConsumable() {
        self.purchase(productID: Self.consumableProductID)
    }

    @objc func purchaseSubscription() {
        self.purchase(productID: Self.subscriptionProductID)
    }

    func purchase(productID: String) {
        Task {
            do {
                let product = try await self.resolveProduct(productID: productID)
                let result = try await self.manager.purchase(product)
                switch result {
                case .success(let transaction):
                    self.appendLog("购买成功: productID=\(transaction.productID), transactionID=\(transaction.id)")
                case .userCancelled:
                    self.appendLog("用户取消了购买")
                case .pending:
                    self.appendLog("购买正在等待处理（如 Ask to Buy）")
                }
            } catch {
                self.appendLog("购买失败: \(error.localizedDescription)")
            }
        }
    }

    /// 避免购买流程依赖"必须先点加载"这个隐性前提。
    func resolveProduct(productID: String) async throws -> STApplePurchaseProduct {
        if let cached = self.product(withID: productID) {
            return cached
        }
        let products = try await self.manager.loadProducts(productIDs: [productID])
        for product in products where self.product(withID: product.id) == nil {
            self.loadedProducts.append(product)
        }
        guard let product = products.first else {
            throw STApplePurchaseError.productNotFound
        }
        return product
    }

    @objc func restorePurchases() {
        Task {
            do {
                let transactions = try await self.manager.restorePurchases()
                self.appendLog("恢复购买完成，当前拥有 \(transactions.count) 笔有效交易：\(transactions.map { $0.productID }.joined(separator: ", "))")
            } catch {
                self.appendLog("恢复购买失败: \(error.localizedDescription)")
            }
        }
    }

    @objc func inspectSubscriptionStatus() {
        Task {
            do {
                let statuses = try await self.manager.subscriptionStatus(for: Self.subscriptionGroupID)
                if statuses.isEmpty {
                    self.appendLog("当前订阅组没有任何状态记录（可能尚未购买过该订阅）")
                    return
                }
                for status in statuses {
                    self.appendLog("订阅状态: state=\(status.state), willAutoRenew=\(status.willAutoRenew), renewalDate=\(status.renewalDate?.description ?? "nil")")
                }
            } catch {
                self.appendLog("查询订阅状态失败: \(error.localizedDescription)")
            }
        }
    }
}
