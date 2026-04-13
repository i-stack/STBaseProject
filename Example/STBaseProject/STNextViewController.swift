//
//  STNextViewController.swift
//  STBaseProject_Example
//
//  Created by qcraft on 2022/8/4.
//  Copyright © 2022 STBaseProject. All rights reserved.
//

import UIKit
import STBaseProject

class STNextViewController: STBaseViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()

    deinit {
        STLog("STNextViewController dealloc")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "HUD 测试"
        setupScrollView()
        setupButtons()
    }

    // MARK: - 布局

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    private func setupButtons() {
        addSectionLabel("自动隐藏")
        addButton("st_showSuccess", action: #selector(testSuccess))
        addButton("st_showSuccess（带详细文本）", action: #selector(testSuccessWithDetail))
        addButton("st_showError", action: #selector(testError))
        addButton("st_showError（带详细文本）", action: #selector(testErrorWithDetail))
        addButton("st_showWarning", action: #selector(testWarning))
        addButton("st_showInfo", action: #selector(testInfo))
        addButton("st_showToast（纯文本）", action: #selector(testToast))

        addSectionLabel("加载中（需手动关闭）")
        addButton("st_showLoading（全局 window）", action: #selector(testLoadingGlobal))
        addButton("st_showLoading（局部视图）", action: #selector(testLoadingLocal))

        addSectionLabel("关闭")
        addButton("st_dismiss", action: #selector(testDismiss))

        addSectionLabel("自定义配置")
        addButton("st_showHUD(with: config)", action: #selector(testCustomConfig))
    }

    private func addSectionLabel(_ title: String) {
        if !stackView.arrangedSubviews.isEmpty {
            let spacer = UIView()
            spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
            stackView.addArrangedSubview(spacer)
        }
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        stackView.addArrangedSubview(label)
    }

    private func addButton(_ title: String, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        stackView.addArrangedSubview(button)
    }

    // MARK: - 自动隐藏

    @objc private func testSuccess() {
        self.view.st_showSuccess("操作成功")
    }

    @objc private func testSuccessWithDetail() {
        self.view.st_showSuccess("操作成功", detailText: "数据已保存到云端")
    }

    @objc private func testError() {
        self.view.st_showError("加载失败")
    }

    @objc private func testErrorWithDetail() {
        self.view.st_showError("加载失败", detailText: "请检查网络连接后重试")
    }

    @objc private func testWarning() {
        self.view.st_showWarning("操作有风险，请谨慎")
    }

    @objc private func testInfo() {
        self.view.st_showInfo("这是一条提示信息")
    }

    @objc private func testToast() {
        self.view.st_showToast("这是纯文本 Toast，无图标")
    }

    // MARK: - 加载中

    @objc private func testLoadingGlobal() {
        self.view.st_showLoading("正在加载...")
    }

    @objc private func testLoadingLocal() {
        self.view.st_showLoading("正在加载...", in: self.view)
    }

    // MARK: - 关闭

    @objc private func testDismiss() {
        self.view.st_dismiss()
    }

    // MARK: - 自定义配置

    @objc private func testCustomConfig() {
        let config = STHUDConfig(
            type: .success,
            title: "自定义配置",
            detailText: "通过 STHUDConfig 传入",
            location: .bottom,
            autoHide: true,
            hideDelay: 3.0
        )
        self.view.st_showHUD(with: config)
    }
}
