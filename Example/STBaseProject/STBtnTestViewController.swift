//
//  STBtnTestViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2026/4/27.
//  Copyright © 2026 STBaseProject. All rights reserved.
//

import UIKit
import STBaseProject

final class STBtnTestViewController: STBaseViewController {
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "STBtn 测试"
        self.st_showNavBtnType(type: .showLeftBtn)
        self.leftBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        self.view.backgroundColor = .systemGroupedBackground
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
            self.stackView.topAnchor.constraint(equalTo: self.scrollView.topAnchor, constant: STDeviceAdapter.navigationBarHeight + 20),
            self.stackView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 20),
            self.stackView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor, constant: -20),
            self.stackView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor, constant: -24),
            self.stackView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor, constant: -40)
        ])
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
    
    private func makeLeftPaddingButton() -> STBtn {
        let button = self.makeBaseButton(title: "左对齐 + contentHorizontalPadding = 24")
        button.backgroundColor = .systemIndigo.withAlphaComponent(0.14)
        button.setTitleColor(.systemIndigo, for: .normal)
        button.contentHorizontalAlignment = .left
        button.contentHorizontalPadding = 24
        return button
    }
    
    private func makeRightPaddingButton() -> STBtn {
        let button = self.makeBaseButton(title: "右对齐 + contentHorizontalPadding = 24")
        button.backgroundColor = .systemTeal.withAlphaComponent(0.14)
        button.setTitleColor(.systemTeal, for: .normal)
        button.contentHorizontalAlignment = .right
        button.contentHorizontalPadding = 24
        return button
    }
    
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
}
