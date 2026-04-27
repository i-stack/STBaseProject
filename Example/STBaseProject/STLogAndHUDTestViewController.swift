//
//  STLogAndHUDTestViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2026/4/27.
//

import UIKit
import STBaseProject

final class STLogAndHUDTestViewController: STBaseViewController {
    
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "Log/HUD 背景测试"
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
        let logView = STLogView()
        logView.layer.cornerRadius = 20
        logView.clipsToBounds = true
        logView.st_setLiquidGlassBackground()
        logView.heightAnchor.constraint(equalToConstant: 320).isActive = true
        self.stackView.addArrangedSubview(logView)
        
        let hudBackground = STProgressHUDBackgroundView()
        hudBackground.style = .liquidGlass
        hudBackground.layer.cornerRadius = 18
        hudBackground.heightAnchor.constraint(equalToConstant: 96).isActive = true
        self.stackView.addArrangedSubview(hudBackground)
        
        let label = UILabel()
        label.text = "STProgressHUDBackgroundView(.liquidGlass)"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        hudBackground.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: hudBackground.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: hudBackground.centerYAnchor)
        ])
    }
}
