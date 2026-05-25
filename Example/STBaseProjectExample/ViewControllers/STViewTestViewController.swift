//
//  STViewTestViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2026/4/27.
//

import UIKit
import STBaseProject

final class STViewTestViewController: BaseViewController {
    
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "STView 测试"
        self.setupStackView()
        self.setupSamples()
    }
    
    private func setupStackView() {
        self.stackView.axis = .vertical
        self.stackView.spacing = 18
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.stackView)
        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: STDeviceAdapter.navigationBarHeight + 24),
            self.stackView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            self.stackView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupSamples() {
        self.stackView.addArrangedSubview(self.makeCard(title: "STView 圆角 + 边框", glass: false))
        self.stackView.addArrangedSubview(self.makeCard(title: "STView Liquid Glass", glass: true))
        let gradientView = self.makeCard(title: "UIView 渐变扩展", glass: false)
        gradientView.st_setGradientBackground(colors: [.systemBlue, .systemPurple])
        self.stackView.addArrangedSubview(gradientView)
    }
    
    private func makeCard(title: String, glass: Bool) -> STView {
        let card = STView()
        card.heightAnchor.constraint(equalToConstant: 96).isActive = true
        card.cornerRadius = 18
        card.borderWidth = 1
        card.borderColor = UIColor.white.withAlphaComponent(0.5)
        card.backgroundColor = glass ? .clear : .secondarySystemGroupedBackground
        if glass {
            card.st_enableLiquidGlassBackground()
            card.st_setShadow(color: UIColor.black.withAlphaComponent(0.12), offset: CGSize(width: 0, height: 8), radius: 18, opacity: 1)
        }
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        return card
    }
}
