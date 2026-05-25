//
//  STBtnTestViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2026/4/27.
//

import UIKit
import STBaseProject

final class STBtnTestViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let verificationButton = STVerificationCodeBtn(type: .custom)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "STBtn 测试"
        self.setupScrollView()
        self.setupButtons()
    }

    private func setupScrollView() {
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.scrollView)
        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

        self.stackView.axis = .vertical
        self.stackView.spacing = 14
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.addSubview(self.stackView)
        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: 20),
            self.stackView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 20),
            self.stackView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor, constant: -20),
            self.stackView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor, constant: -24),
            self.stackView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor, constant: -40)
        ])

        self.applyLiquidGlassScrollLayout(self.scrollView)
    }

    private func setupButtons() {
        self.addSectionLabel("基础样式")
        self.stackView.addArrangedSubview(self.makeNormalButton())
        self.stackView.addArrangedSubview(self.makeRoundedButton())
        self.stackView.addArrangedSubview(self.makeDisabledButton())

        self.addSectionLabel("内容边距")
        self.stackView.addArrangedSubview(self.makeLeftPaddingButton())
        self.stackView.addArrangedSubview(self.makeRightPaddingButton())

        self.addSectionLabel("背景样式")
        self.stackView.addArrangedSubview(self.makeGradientButton())
        self.stackView.addArrangedSubview(self.makeLiquidGlassButton())

        self.addSectionLabel("阴影与圆角")
        self.stackView.addArrangedSubview(self.makeShadowButton())

        self.addSectionLabel("交互反馈 · 点击变色")
        self.stackView.addArrangedSubview(self.makeHighlightColorButton())
        self.stackView.addArrangedSubview(self.makeHighlightColorRoundedButton())

        self.addSectionLabel("STIconBtn · 图文位置")
        self.stackView.addArrangedSubview(self.makeFilledIconButton(position: .left, title: "STIconBtn 左图右文"))
        self.stackView.addArrangedSubview(self.makeFilledIconButton(position: .right, title: "STIconBtn 右图左文"))
        self.stackView.addArrangedSubview(self.makeFilledIconButton(position: .top, title: "STIconBtn 上图下文"))

        self.addSectionLabel("STIconBtn · 自适应宽度")
        self.stackView.addArrangedSubview(self.makeAdaptiveIconButtonsRow())

        self.addSectionLabel("STIconBtn · 选中态切换")
        self.stackView.addArrangedSubview(self.makeSelectableIconButtonsRow())

        self.addSectionLabel("STVerificationCodeBtn · 倒计时")
        self.setupVerificationButton()
        self.stackView.addArrangedSubview(self.verificationButton)
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

    // MARK: - 基础样式
    private func makeNormalButton() -> STBtn {
        let button = self.makeBaseButton(title: "普通 STBtn")
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        return button
    }

    private func makeRoundedButton() -> STBtn {
        let button = self.makeBaseButton(title: "圆角 + 边框")
        button.backgroundColor = .secondarySystemGroupedBackground
        button.setTitleColor(.label, for: .normal)
        button.st_roundedButton(cornerRadius: 14, borderWidth: 1, borderColor: .systemBlue)
        return button
    }

    private func makeDisabledButton() -> STBtn {
        let button = self.makeBaseButton(title: "禁用态 STBtn")
        button.backgroundColor = .systemGray5
        button.setTitleColor(.secondaryLabel, for: .disabled)
        button.isEnabled = false
        return button
    }

    // MARK: - 内容边距
    private func makeLeftPaddingButton() -> STBtn {
        let button = self.makeBaseButton(title: "左对齐 + 左侧 24pt 边距")
        button.backgroundColor = .systemIndigo.withAlphaComponent(0.14)
        button.setTitleColor(.systemIndigo, for: .normal)
        button.contentHorizontalAlignment = .left
        button.configuration?.contentInsets.leading += 24
        return button
    }

    private func makeRightPaddingButton() -> STBtn {
        let button = self.makeBaseButton(title: "右对齐 + 右侧 24pt 边距")
        button.backgroundColor = .systemTeal.withAlphaComponent(0.14)
        button.setTitleColor(.systemTeal, for: .normal)
        button.contentHorizontalAlignment = .right
        button.configuration?.contentInsets.trailing += 24
        return button
    }

    // MARK: - 背景样式
    private func makeGradientButton() -> STBtn {
        let button = self.makeBaseButton(title: "渐变背景")
        button.cornerRadius = 16
        button.clipsContentToBounds = true
        button.setTitleColor(.white, for: .normal)
        button.st_setGradientBackground(
            colors: [.systemPurple, .systemPink, .systemOrange],
            startPoint: CGPoint(x: 0, y: 0.5),
            endPoint: CGPoint(x: 1, y: 0.5)
        )
        return button
    }

    private func makeLiquidGlassButton() -> STBtn {
        let button = self.makeBaseButton(title: "Liquid Glass 背景")
        button.cornerRadius = 18
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        button.st_setLiquidGlassBackground(
            tintColor: UIColor.white.withAlphaComponent(0.2),
            highlightOpacity: 0.5,
            borderColor: UIColor.white.withAlphaComponent(0.55)
        )
        button.st_setShadow(
            color: UIColor.black.withAlphaComponent(0.18),
            offset: CGSize(width: 0, height: 8),
            radius: 18,
            opacity: 1
        )
        return button
    }

    // MARK: - 阴影
    private func makeShadowButton() -> STBtn {
        let button = self.makeBaseButton(title: "阴影 + 圆角不裁剪")
        button.cornerRadius = 16
        button.backgroundColor = .secondarySystemGroupedBackground
        button.setTitleColor(.label, for: .normal)
        button.st_setShadow(
            color: UIColor.black.withAlphaComponent(0.16),
            offset: CGSize(width: 0, height: 6),
            radius: 14,
            opacity: 1
        )
        return button
    }

    private func makeBaseButton(title: String) -> STBtn {
        let button = STBtn(type: .custom)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return button
    }

    // MARK: - 交互反馈：点击后背景颜色变化
    /// 直接通过 `st_setBackgroundColor(_:for:)` 按状态声明颜色，
    /// `STBtn` 会在 `refineButtonConfiguration` 里自动按当前 `button.state` 命中对应颜色。
    /// 不需要子类化、不需要自定义 `configurationUpdateHandler`。
    private func makeHighlightColorButton() -> STBtn {
        let button = self.makeBaseButton(title: "按下查看背景色变化")
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white, for: .highlighted)
        button.st_setBackgroundColor(.systemBlue, for: .normal)
        button.st_setBackgroundColor(.systemIndigo, for: .highlighted)
        button.st_setBackgroundColor(.systemGray3, for: .disabled)
        button.addTarget(self, action: #selector(self.onHighlightButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    private func makeHighlightColorRoundedButton() -> STBtn {
        let button = self.makeBaseButton(title: "按下变色 + 圆角 + 阴影")
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.white, for: .highlighted)
        button.st_setBackgroundColor(.systemGreen, for: .normal)
        button.st_setBackgroundColor(.systemTeal, for: .highlighted)
        button.st_roundedButton(cornerRadius: 14)
        button.st_setShadow(
            color: UIColor.black.withAlphaComponent(0.18),
            offset: CGSize(width: 0, height: 4),
            radius: 10,
            opacity: 1
        )
        button.addTarget(self, action: #selector(self.onHighlightButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func onHighlightButtonTapped(_ sender: UIButton) {
        sender.isEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            sender.isEnabled = true
        }
    }

    // MARK: - STIconBtn 图文位置（LiquidGlass 背景）
    private func makeFilledIconButton(position: STIconPosition, title: String) -> STIconBtn {
        let button = STIconBtn(type: .custom)
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: "sparkles"), for: .normal)
        button.tintColor = .systemBlue
        button.setTitleColor(.label, for: .normal)
        button.cornerRadius = 18
        button.st_setLiquidGlassBackground()
        button.configure()
            .iconPosition(position)
            .spacing(10)
            .contentInsets(UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16))
            .done()
        button.heightAnchor.constraint(equalToConstant: position == .top ? 88 : 56).isActive = true
        return button
    }

    // MARK: - STIconBtn 自适应宽度
    /// 借助 `UIStackView(alignment = .leading)` 让每个 `STIconBtn` 以自身 intrinsicContentSize
    /// （`UIButton.Configuration` 原生依据 `contentInsets + imagePlacement + imagePadding` 计算）
    /// 横向收缩到贴合内容，不同文案长度下宽度自动伸缩。
    private func makeAdaptiveIconButtonsRow() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .leading
        container.spacing = 10

        container.addArrangedSubview(self.makeAdaptiveIconButton(
            title: "收藏",
            systemIconName: "star.fill",
            iconPosition: .left,
            tint: .systemOrange
        ))
        container.addArrangedSubview(self.makeAdaptiveIconButton(
            title: "下一步",
            systemIconName: "arrow.right.circle.fill",
            iconPosition: .right,
            tint: .systemBlue
        ))
        container.addArrangedSubview(self.makeAdaptiveIconButton(
            title: "按下可变色 · 含较长文本的自适应测试",
            systemIconName: "hand.tap.fill",
            iconPosition: .left,
            tint: .systemPurple
        ))
        container.addArrangedSubview(self.makeAdaptiveIconButton(
            title: "上传",
            systemIconName: "icloud.and.arrow.up.fill",
            iconPosition: .top,
            tint: .systemTeal
        ))
        return container
    }

    private func makeAdaptiveIconButton(
        title: String,
        systemIconName: String,
        iconPosition: STIconPosition,
        tint: UIColor
    ) -> STIconBtn {
        let button = STIconBtn(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        if let icon = UIImage(systemName: systemIconName)?.withRenderingMode(.alwaysTemplate) {
            button.setImage(icon, for: .normal)
            button.tintColor = .white
        }
        button.backgroundColor = tint
        button.configure()
            .iconPosition(iconPosition)
            .spacing(8)
            .contentInsets(UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14))
            .done()
        button.st_roundedButton(cornerRadius: 10)
        return button
    }

    // MARK: - STIconBtn 选中态切换
    /// 验证「点击切换 isSelected，图标 + 标题同步切换，宽度随文本自适应伸缩」。
    /// `UIButton.Configuration` 会在 `isSelected` 变化时自动经由 `configurationUpdateHandler`
    /// 读取对应 state 的 title/image，无需手动同步。
    private func makeSelectableIconButtonsRow() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.alignment = .leading
        container.spacing = 10

        container.addArrangedSubview(self.makeThinkingToggleButton())
        container.addArrangedSubview(self.makeFavoriteToggleButton())
        container.addArrangedSubview(self.makeCheckableToggleButton())
        return container
    }

    /// 「思考 / 思考中」 —— 点击切换，文字变长时按钮宽度随之扩展。
    private func makeThinkingToggleButton() -> STIconBtn {
        let button = STIconBtn(type: .custom)
        button.setTitle("思考", for: .normal)
        button.setTitle("思考中…", for: .selected)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setTitleColor(.systemGreen, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setImage(self.symbolImage("brain.head.profile", tint: .secondaryLabel), for: .normal)
        button.setImage(self.symbolImage("brain.head.profile.fill", tint: .systemGreen), for: .selected)
        button.configure()
            .iconPosition(.left)
            .spacing(4)
            .contentInsets(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
            .done()
        button.backgroundColor = .secondarySystemBackground
        button.st_roundedButton(cornerRadius: 8)
        button.addTarget(self, action: #selector(self.onToggleButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    /// 收藏开关 —— 图标 + 文案 + 颜色全部按 state 切换。
    private func makeFavoriteToggleButton() -> STIconBtn {
        let button = STIconBtn(type: .custom)
        button.setTitle("收藏", for: .normal)
        button.setTitle("已收藏", for: .selected)
        button.setTitleColor(.label, for: .normal)
        button.setTitleColor(.systemOrange, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setImage(self.symbolImage("star", tint: .label), for: .normal)
        button.setImage(self.symbolImage("star.fill", tint: .systemOrange), for: .selected)
        button.configure()
            .iconPosition(.left)
            .spacing(6)
            .contentInsets(UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14))
            .done()
        button.backgroundColor = .secondarySystemBackground
        button.st_roundedButton(cornerRadius: 8, borderWidth: 1, borderColor: .separator)
        button.addTarget(self, action: #selector(self.onToggleButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    /// 勾选开关 —— 右侧图标 + 等长文字，验证 `.right` 位置下 selected 图标替换。
    private func makeCheckableToggleButton() -> STIconBtn {
        let button = STIconBtn(type: .custom)
        button.setTitle("同意用户协议", for: .normal)
        button.setTitle("同意用户协议", for: .selected)
        button.setTitleColor(.secondaryLabel, for: .normal)
        button.setTitleColor(.systemBlue, for: .selected)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.setImage(self.symbolImage("circle", tint: .tertiaryLabel), for: .normal)
        button.setImage(self.symbolImage("checkmark.circle.fill", tint: .systemBlue), for: .selected)
        button.configure()
            .iconPosition(.right)
            .spacing(6)
            .contentInsets(UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
            .done()
        button.addTarget(self, action: #selector(self.onToggleButtonTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func onToggleButtonTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
    }

    private func symbolImage(_ name: String, tint: UIColor) -> UIImage? {
        return UIImage(systemName: name)?.withTintColor(tint, renderingMode: .alwaysOriginal)
    }

    // MARK: - STVerificationCodeBtn
    private func setupVerificationButton() {
        self.verificationButton.setTitle("发送验证码", for: .normal)
        self.verificationButton.setTitleColor(.white, for: .normal)
        self.verificationButton.setTitleColor(.secondaryLabel, for: .disabled)
        self.verificationButton.titleSuffix = "s 后重试"
        self.verificationButton.timerInterval = 10
        self.verificationButton.cornerRadius = 18
        self.verificationButton.st_setGradientBackground(colors: [.systemBlue, .systemCyan])
        self.verificationButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        self.verificationButton.addTarget(self, action: #selector(self.startVerificationCountdown), for: .touchUpInside)
    }

    @objc private func startVerificationCountdown() {
        self.verificationButton.beginTimer()
    }
}
