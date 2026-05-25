//
//  STMarkdownStreamingTestViewController.swift
//  STBaseProjectExample
//
//  Created by 寒江孤影 on 2026/5/11.
//

import UIKit
import STBaseProject

/// 从 Bundle 读取 `Resources/data1~3.txt`，通过 ``STMarkdownStreamingTextView`` 智能流式 API 逐字渲染。
final class STMarkdownStreamingTestViewController: BaseViewController {

    private enum StreamSpeed: CaseIterable {
        case slow
        case normal
        case fast

        var interval: TimeInterval {
            switch self {
            case .slow: return 0.04
            case .normal: return 0.02
            case .fast: return 0.008
            }
        }

        var step: Int {
            switch self {
            case .slow: return 1
            case .normal: return 2
            case .fast: return 4
            }
        }

        var title: String {
            switch self {
            case .slow: return "慢"
            case .normal: return "中"
            case .fast: return "快"
            }
        }
    }

    private static let fixtureNames = ["data1", "data2", "data3"]

    private var typewriterTimer: Timer?
    private var fullMarkdownText: String = ""
    private var currentIndex: Int = 0
    private var isPaused = false
    private var streamSpeed: StreamSpeed = .normal

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

    // MARK: - UI

    private func buildUI() {
        let controlStack = UIStackView(arrangedSubviews: [
            self.speedControl,
            self.pauseButton,
            self.reloadButton
        ])
        controlStack.translatesAutoresizingMaskIntoConstraints = false
        controlStack.axis = .horizontal
        controlStack.spacing = 8
        controlStack.distribution = .fillEqually

        self.view.addSubview(self.statusLabel)
        self.view.addSubview(self.progressView)
        self.view.addSubview(self.renderView)
        self.view.addSubview(controlStack)

        NSLayoutConstraint.activate([
            self.statusLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 8),
            self.statusLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            self.statusLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),

            self.progressView.topAnchor.constraint(equalTo: self.statusLabel.bottomAnchor, constant: 8),
            self.progressView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            self.progressView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),

            controlStack.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            controlStack.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
            controlStack.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            controlStack.heightAnchor.constraint(equalToConstant: 40),

            self.renderView.topAnchor.constraint(equalTo: self.progressView.bottomAnchor, constant: 12),
            self.renderView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            self.renderView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
            self.renderView.bottomAnchor.constraint(equalTo: controlStack.topAnchor, constant: -12)
        ])

        self.applyLiquidGlassScrollLayout(self.renderView.contentTextView)
    }

    // MARK: - Actions

    @objc private func speedChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        guard index >= 0, index < StreamSpeed.allCases.count else { return }
        self.streamSpeed = StreamSpeed.allCases[index]
        if self.typewriterTimer != nil {
            self.restartTimerIfNeeded()
        }
    }

    @objc private func pauseTapped() {
        self.isPaused.toggle()
        self.pauseButton.setTitle(self.isPaused ? "继续" : "暂停", for: .normal)
        self.updateStatusLabel()
    }

    @objc private func restartRenderTapped() {
        self.startRendering()
    }

    // MARK: - Streaming

    private func startRendering() {
        self.stopTypewriter()
        self.isPaused = false
        self.pauseButton.setTitle("暂停", for: .normal)
        self.currentIndex = 0

        self.fullMarkdownText = self.loadAllFixtures()
        self.renderView.reset()

        guard self.fullMarkdownText.isEmpty == false else {
            self.renderView.setMarkdown(
                "资源读取失败，请确认 `Resources/data1~3.txt` 已加入主工程 Bundle。",
                animated: false
            )
            self.progressView.progress = 0
            self.statusLabel.text = "加载失败"
            return
        }

        self.renderView.beginSmartMarkdownStreaming()
        self.updateStatusLabel()
        self.restartTimerIfNeeded()
    }

    private func restartTimerIfNeeded() {
        guard self.currentIndex < self.fullMarkdownText.count else { return }
        self.stopTypewriter()
        self.typewriterTimer = Timer.scheduledTimer(
            timeInterval: self.streamSpeed.interval,
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
        guard self.isPaused == false else { return }
        guard self.currentIndex < self.fullMarkdownText.count else {
            self.completeStreaming()
            return
        }

        let next = min(self.currentIndex + self.streamSpeed.step, self.fullMarkdownText.count)
        let start = self.fullMarkdownText.index(self.fullMarkdownText.startIndex, offsetBy: self.currentIndex)
        let end = self.fullMarkdownText.index(self.fullMarkdownText.startIndex, offsetBy: next)
        let chunk = String(self.fullMarkdownText[start..<end])
        self.renderView.appendSmartMarkdownStreamingChunk(chunk)
        self.currentIndex = next
        self.updateStatusLabel()
        self.scrollToBottomIfNeeded()
    }

    private func completeStreaming() {
        self.stopTypewriter()
        self.renderView.endSmartMarkdownStreaming(flushPending: true)
        self.renderView.finishStreaming()
        self.updateStatusLabel(finished: true)
    }

    private func updateStatusLabel(finished: Bool = false) {
        let total = self.fullMarkdownText.count
        if total == 0 {
            self.progressView.progress = 0
            self.statusLabel.text = "无内容"
            return
        }

        let progress = Float(self.currentIndex) / Float(total)
        self.progressView.progress = progress

        if finished {
            self.statusLabel.text = "渲染完成 · \(total) 字符 · \(Self.fixtureNames.count) 份资源"
            return
        }

        if self.isPaused {
            self.statusLabel.text = String(
                format: "已暂停 · %d / %d 字符 (%.0f%%)",
                self.currentIndex, total, progress * 100
            )
            return
        }

        self.statusLabel.text = String(
            format: "流式输出中 · %d / %d 字符 (%.0f%%)",
            self.currentIndex, total, progress * 100
        )
    }

    private func scrollToBottomIfNeeded() {
        let textView = self.renderView.contentTextView
        let bottom = textView.contentSize.height - textView.bounds.height + textView.contentInset.bottom
        guard bottom > 0 else { return }
        let targetY = max(-textView.contentInset.top, bottom)
        if abs(textView.contentOffset.y - targetY) > 4 {
            textView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
        }
    }

    // MARK: - Resources

    private func loadAllFixtures() -> String {
        let sections = Self.fixtureNames.compactMap { name -> String? in
            self.readFixture(named: name).map { "## \(name).txt\n\n\($0)" }
        }
        return sections.joined(separator: "\n\n---\n\n")
    }

    private func readFixture(named name: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "txt") else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Subviews

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.text = "准备加载…"
        return label
    }()

    private lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.progress = 0
        return view
    }()

    private lazy var renderView: STMarkdownStreamingTextView = {
        let view = STMarkdownStreamingTextView(
            style: .default,
            advancedRenderers: .empty,
            engine: STMarkdownEngine()
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.isTextSelectionEnabled = true
        view.tokenFadeDuration = 0.1
        view.animateAcrossNewlines = false
        return view
    }()

    private lazy var speedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: StreamSpeed.allCases.map(\.title))
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 1
        control.addTarget(self, action: #selector(self.speedChanged), for: .valueChanged)
        return control
    }()

    private lazy var pauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("暂停", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.addTarget(self, action: #selector(self.pauseTapped), for: .touchUpInside)
        return button
    }()

    private lazy var reloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("重新渲染", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.addTarget(self, action: #selector(self.restartRenderTapped), for: .touchUpInside)
        return button
    }()
}
