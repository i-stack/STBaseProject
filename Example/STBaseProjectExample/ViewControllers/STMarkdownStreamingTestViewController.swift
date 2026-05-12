//
//  STMarkdownStreamingTestViewController.swift
//  STBaseProjectExample
//
//  Created by Codex on 2026/5/11.
//

import UIKit
import STBaseProject

final class STMarkdownStreamingTestViewController: BaseViewController {

    private var typewriterTimer: Timer?
    private var fullMarkdownText: String = ""
    private var currentIndex: Int = 0

    private let typingInterval: TimeInterval = 0.02
    private let typingStep: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "Markdown 流式测试"
        self.buildUI()
        self.startRendering()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.stopTypewriter()
    }

    private func buildUI() {
        self.view.addSubview(self.renderView)
        self.view.addSubview(self.reloadButton)

        NSLayoutConstraint.activate([
            self.reloadButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            self.reloadButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
            self.reloadButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            self.reloadButton.heightAnchor.constraint(equalToConstant: 44),

            self.renderView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.renderView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            self.renderView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
            self.renderView.bottomAnchor.constraint(equalTo: self.reloadButton.topAnchor, constant: -12)
        ])

        self.applyLiquidGlassScrollLayout(self.renderView.contentTextView)
    }

    @objc private func restartRenderTapped() {
        self.startRendering()
    }

    private func startRendering() {
        self.stopTypewriter()
        self.fullMarkdownText = self.loadAllFixtures()
        self.currentIndex = 0
        self.renderView.reset()

        guard !self.fullMarkdownText.isEmpty else {
            self.renderView.setMarkdown("资源读取失败，请检查 data1~3.txt 是否已加入主工程 Bundle。", animated: false)
            return
        }

        self.typewriterTimer = Timer.scheduledTimer(
            timeInterval: self.typingInterval,
            target: self,
            selector: #selector(self.handleTypewriterTick),
            userInfo: nil,
            repeats: true
        )
        if let timer = self.typewriterTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func stopTypewriter() {
        self.typewriterTimer?.invalidate()
        self.typewriterTimer = nil
    }

    @objc private func handleTypewriterTick() {
        guard self.currentIndex < self.fullMarkdownText.count else {
            self.stopTypewriter()
            return
        }
        let next = min(self.currentIndex + self.typingStep, self.fullMarkdownText.count)
        let end = self.fullMarkdownText.index(self.fullMarkdownText.startIndex, offsetBy: next)
        let prefix = String(self.fullMarkdownText[..<end])
        self.renderView.updateStreamingMarkdown(prefix)
        self.currentIndex = next
    }

    private func loadAllFixtures() -> String {
        let names = ["data1", "data2", "data3"]
        let texts = names.compactMap { name in
            self.readFixture(named: name).map { "## \(name).txt\n\n\($0)" }
        }
        return texts.joined(separator: "\n\n---\n\n")
    }

    private func readFixture(named name: String) -> String? {
        guard let path = Bundle.main.path(forResource: name, ofType: "txt") else {
            return nil
        }
        return try? String(contentsOfFile: path, encoding: .utf8)
    }

    private lazy var renderView: STMarkdownStreamingTextView = {
        let view = STMarkdownStreamingTextView(style: .default, advancedRenderers: .empty, engine: STMarkdownEngine())
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.isTextSelectionEnabled = true
        view.tokenFadeDuration = 0.1
        view.animateAcrossNewlines = false
        return view
    }()

    private lazy var reloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("重新逐字渲染", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.addTarget(self, action: #selector(self.restartRenderTapped), for: .touchUpInside)
        return button
    }()
}
