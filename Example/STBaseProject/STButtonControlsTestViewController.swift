//
//  STButtonControlsTestViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2026/4/27.
//

import UIKit
import STBaseProject

final class STButtonControlsTestViewController: STBaseViewController {
    
    private let stackView = UIStackView()
    private let verificationButton = STVerificationCodeBtn(type: .custom)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "按钮子类测试"
        self.st_showNavBtnType(type: .showLeftBtn)
        self.leftBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        self.view.backgroundColor = .systemGroupedBackground
        self.setupStackView()
        self.setupSamples()
    }
    
    private func setupStackView() {
        self.stackView.axis = .vertical
        self.stackView.spacing = 16
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.stackView)
        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: STDeviceAdapter.navigationBarHeight + 24),
            self.stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            self.stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupSamples() {
        self.stackView.addArrangedSubview(self.makeIconButton(position: .left, title: "STIconBtn 左图右文"))
        self.stackView.addArrangedSubview(self.makeIconButton(position: .right, title: "STIconBtn 右图左文"))
        self.stackView.addArrangedSubview(self.makeIconButton(position: .top, title: "STIconBtn 上图下文"))
        self.setupVerificationButton()
        self.stackView.addArrangedSubview(self.verificationButton)
    }
    
    private func makeIconButton(position: STIconPosition, title: String) -> STIconBtn {
        let button = STIconBtn(type: .custom)
        button.setTitle(title, for: .normal)
        button.setImage(UIImage(systemName: "sparkles"), for: .normal)
        button.tintColor = .systemBlue
        button.setTitleColor(.label, for: .normal)
        button.cornerRadius = 18
        button.st_setLiquidGlassBackground()
        button.configure().iconPosition(position).spacing(10).contentInsets(UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)).done()
        button.heightAnchor.constraint(equalToConstant: position == .top ? 88 : 56).isActive = true
        return button
    }
    
    private func setupVerificationButton() {
        self.verificationButton.setTitle("发送验证码", for: .normal)
        self.verificationButton.setTitleColor(.white, for: .normal)
        self.verificationButton.setTitleColor(.secondaryLabel, for: .disabled)
        self.verificationButton.titleSuffix = "s 后重试"
        self.verificationButton.timerInterval = 10
        self.verificationButton.cornerRadius = 18
        self.verificationButton.st_setGradientBackground(colors: [.systemBlue, .systemCyan])
        self.verificationButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        self.verificationButton.addTarget(self, action: #selector(startVerificationCountdown), for: .touchUpInside)
    }
    
    @objc private func startVerificationCountdown() {
        self.verificationButton.beginTimer()
    }
}
