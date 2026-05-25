//
//  STHudViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2022/8/4.
//

import UIKit
import STBaseProject

class STHudViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    @MainActor deinit {
        STLog("STNextViewController dealloc")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "HUD 测试"
        self.setupScrollView()
        self.setupButtons()
    }

    private func setupScrollView() {
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.scrollView)
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            self.scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        self.stackView.axis = .vertical
        self.stackView.spacing = 12
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.addSubview(self.stackView)
        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 20),
            self.stackView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 20),
            self.stackView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor, constant: -20),
            self.stackView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor, constant: -20),
            self.stackView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor, constant: -40)
        ])

        self.applyLiquidGlassScrollLayout(self.scrollView)
    }

    private func setupButtons() {
        self.addSectionLabel("自动隐藏")
        self.addButton("st_showSuccess", action: #selector(testSuccess))
        self.addButton("st_showSuccess（带详细文本）", action: #selector(testSuccessWithDetail))
        self.addButton("st_showError", action: #selector(testError))
        self.addButton("st_showError（带详细文本）", action: #selector(testErrorWithDetail))
        self.addButton("st_showWarning", action: #selector(testWarning))
        self.addButton("st_showInfo", action: #selector(testInfo))
        self.addButton("st_showToast（纯文本）", action: #selector(testToast))

        self.addSectionLabel("加载中（需手动关闭）")
        self.addButton("st_showLoading（全局 window）", action: #selector(testLoadingGlobal))
        self.addButton("st_showLoading（局部视图）", action: #selector(testLoadingLocal))

        self.addSectionLabel("关闭")
        self.addButton("st_dismiss", action: #selector(testDismiss))

        self.addSectionLabel("自定义配置")
        self.addButton("st_showHUD(with: config)", action: #selector(testCustomConfig))

        self.addSectionLabel("图标位置")
        self.addButton("iconPosition: .left（无 detail）", action: #selector(testIconLeft))
        self.addButton("iconPosition: .left（有 detail）", action: #selector(testIconLeftWithDetail))
        self.addButton("iconPosition: .right（无 detail）", action: #selector(testIconRight))
        self.addButton("iconPosition: .right（有 detail）", action: #selector(testIconRightWithDetail))
        self.addButton("设置全局 defaultIconPosition = .left", action: #selector(testSetGlobalIconPosition))
        self.addButton("恢复全局 defaultIconPosition = .top", action: #selector(testResetGlobalIconPosition))

        self.addSectionLabel("自定义主题（STHUDTheme）")
        self.addButton("浅色主题（白底黑字）", action: #selector(testThemeLight))
        self.addButton("品牌色主题（自定义背景+图标色）", action: #selector(testThemeBrand))
        self.addButton("大图标 + 大字体", action: #selector(testThemeLargeIcon))
        self.addButton("无阴影 + 小圆角", action: #selector(testThemeNoShadow))
        self.addButton("设置全局主题", action: #selector(testApplyGlobalTheme))
        self.addButton("恢复默认全局主题", action: #selector(testResetGlobalTheme))
    }

    private func addSectionLabel(_ title: String) {
        if !self.stackView.arrangedSubviews.isEmpty {
            let spacer = UIView()
            spacer.heightAnchor.constraint(equalToConstant: 8).isActive = true
            self.stackView.addArrangedSubview(spacer)
        }
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        self.stackView.addArrangedSubview(label)
    }

    private func addButton(_ title: String, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        self.stackView.addArrangedSubview(button)
    }

    // MARK: - 自动隐藏
    @objc private func testSuccess() {
        self.view.st_showSuccess("操作成功") {
            self.testToast()
        }
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
        self.view.st_showText("这是纯文本 Toast，无图标")
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

    // MARK: - 图标位置
    @objc private func testIconLeft() {
        self.view.st_showSuccess("操作成功", iconPosition: .left)
    }

    @objc private func testIconLeftWithDetail() {
        self.view.st_showError("加载失败", detailText: "请检查网络连接后重试", iconPosition: .left)
    }

    @objc private func testIconRight() {
        self.view.st_showWarning("操作有风险", iconPosition: .right)
    }

    @objc private func testIconRightWithDetail() {
        self.view.st_showInfo("这是提示", detailText: "图标显示在右侧，icon 垂直居中", iconPosition: .right)
    }

    /// 全局设置后，st_showSuccess 等便捷方法无需再传 iconPosition
    @objc private func testSetGlobalIconPosition() {
        STHUD.sharedHUD.defaultIconPosition = .left
        self.view.st_showSuccess("全局图标位置已设为 left", detailText: "后续便捷方法默认左侧图标")
    }

    @objc private func testResetGlobalIconPosition() {
        STHUD.sharedHUD.defaultIconPosition = .top
        self.view.st_showSuccess("已恢复默认图标位置（top）")
    }

    // MARK: - 自定义主题
    /// 浅色主题：白底黑字，较大圆角
    @objc private func testThemeLight() {
        let theme = STHUDTheme(
            backgroundColor: UIColor.white.withAlphaComponent(0.95),
            textColor: .black,
            detailTextColor: .darkGray,
            successColor: .systemGreen,
            cornerRadius: 14,
            shadow: .enabled
        )
        let config = STHUDConfig(type: .success, title: "操作成功", detailText: "浅色主题效果", autoHide: true, theme: theme)
        self.view.st_showHUD(with: config)
    }

    /// 品牌色主题：自定义背景色与图标颜色
    @objc private func testThemeBrand() {
        let brandPurple = UIColor(red: 0.42, green: 0.22, blue: 0.80, alpha: 1)
        let theme = STHUDTheme(
            backgroundColor: brandPurple,
            textColor: .white,
            detailTextColor: UIColor.white.withAlphaComponent(0.7),
            successColor: .white,
            cornerRadius: 16,
            shadow: .enabled
        )
        let config = STHUDConfig(type: .success, title: "支付成功", detailText: "品牌色主题", autoHide: true, theme: theme)
        self.view.st_showHUD(with: config)
    }

    /// 大图标 + 大字体
    @objc private func testThemeLargeIcon() {
        let theme = STHUDTheme(
            iconSize: CGSize(width: 48, height: 48),
            labelFont: UIFont.systemFont(ofSize: 20, weight: .bold),
            detailLabelFont: UIFont.systemFont(ofSize: 15, weight: .regular)
        )
        let config = STHUDConfig(type: .warning, title: "注意", detailText: "大图标 + 大字体主题", autoHide: true, theme: theme)
        self.view.st_showHUD(with: config)
    }

    /// 无阴影 + 小圆角
    @objc private func testThemeNoShadow() {
        let theme = STHUDTheme(
            cornerRadius: 4,
            shadow: .disabled
        )
        let config = STHUDConfig(type: .info, title: "无阴影", detailText: "小圆角，无阴影效果", autoHide: true, theme: theme)
        self.view.st_showHUD(with: config)
    }

    /// 设置全局主题（后续所有 st_showXxx 便捷方法都生效）
    @objc private func testApplyGlobalTheme() {
        let theme = STHUDTheme(
            backgroundColor: UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 0.95),
            textColor: .white,
            detailTextColor: UIColor.white.withAlphaComponent(0.6),
            successColor: .systemYellow,
            errorColor: .systemPink,
            warningColor: .systemOrange,
            infoColor: .systemTeal,
            cornerRadius: 12
        )
        STHUD.sharedHUD.applyTheme(theme)
        self.view.st_showSuccess("全局主题已设置", detailText: "后续 HUD 均使用此主题")
    }

    /// 恢复默认全局主题
    @objc private func testResetGlobalTheme() {
        STHUD.sharedHUD.applyTheme(STHUDTheme())
        self.view.st_showInfo("已恢复默认主题")
    }
}
