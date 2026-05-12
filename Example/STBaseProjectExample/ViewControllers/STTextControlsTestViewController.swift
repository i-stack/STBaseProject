//
//  STTextControlsTestViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2026/4/27.
//

import UIKit
import STBaseProject

final class STTextControlsTestViewController: BaseViewController {
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "文本控件测试"
        self.setupScrollView()
        self.setupSamples()
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
        self.stackView.spacing = 16
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
    
    private func setupSamples() {
        self.stackView.addArrangedSubview(self.makeLabel())
        self.stackView.addArrangedSubview(self.makeTextField())
        self.stackView.addArrangedSubview(self.makePlaceholderTextView())
        self.stackView.addArrangedSubview(self.makeTextView())
    }
    
    private func makeLabel() -> STLabel {
        let label = STLabel()
        label.text = "STLabel：内容边距 + Liquid Glass"
        label.numberOfLines = 0
        label.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        label.cornerRadius = 16
        label.isLiquidGlassEnabled = true
        return label
    }
    
    private func makeTextField() -> STTextField {
        let textField = STTextField()
        textField.placeholder = "STTextField：请输入内容"
        textField.textInsetLeft = 16
        textField.textInsetRight = 16
        textField.cornerRadius = 16
        textField.borderWidth = 1
        textField.borderColor = UIColor.white.withAlphaComponent(0.5)
        textField.isLiquidGlassEnabled = true
        textField.heightAnchor.constraint(equalToConstant: 52).isActive = true
        textField.st_enablePasswordToggle()
        return textField
    }
    
    private func makePlaceholderTextView() -> STPlaceholderTextView {
        let textView = STPlaceholderTextView()
        textView.placeholder = "STPlaceholderTextView：placeholder 与 glass 背景"
        textView.font = .systemFont(ofSize: 16)
        textView.contentInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.layer.cornerRadius = 16
        textView.isLiquidGlassEnabled = true
        textView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        return textView
    }
    
    private func makeTextView() -> STTextView {
        let textView = STTextView()
        textView.placeholder = "STTextView：自适应高度、字数限制"
        textView.font = .systemFont(ofSize: 16)
        textView.cornerRadius = 16
        textView.borderWidth = 1
        textView.borderColor = UIColor.white.withAlphaComponent(0.5)
        textView.isLiquidGlassEnabled = true
        textView.maxTextCount = 80
        textView.minimumNumberOfLines = 3
        textView.maximumNumberOfLines = 5
        return textView
    }
}
