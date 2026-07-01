//
//  STShimmerTextViewTestViewController.swift
//  STBaseProjectExample
//
//  Created by Cursor on 2026/6/6.
//

import UIKit
import STBaseProject

/// 逐字流式输出 ``STShimmerTextView`` 的字符渐显与行级扫入动画。
final class STShimmerTextViewTestViewController: BaseViewController {

    private enum AnimationMode: Int, CaseIterable {
        case characterFade
        case lineFade

        var title: String {
            switch self {
            case .characterFade: return "字符渐显"
            case .lineFade: return "行级扫入"
            }
        }
    }

    private enum StreamSpeed: Int, CaseIterable {
        case slow
        case normal
        case fast

        var interval: TimeInterval {
            switch self {
            case .slow: return 0.05
            case .normal: return 0.025
            case .fast: return 0.01
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

    private static let sampleText: String = """
    STShimmerTextView 动画效果测试

    第一段：字符级 foregroundColor 淡入。每个新增 token 从透明过渡到目标色，配合 characterStaggerInterval 可呈现逐字出现的打字机观感。该模式适合纯文本流式输出，开销较低，且与 Markdown 渲染管线中的 replaceTrailingAttributedText 增量更新兼容。

    第二段：换行与跨行行为。当 animateAcrossNewlines 为 false 时，每次 append 之前会把「最后一个换行符之前」尚未完成的 fade 立即置为全不透明，仅保留当前行尾部的动画。这样可以避免多行内容同时处于半透明中间态，视觉上更接近「上一行已稳定、当前行正在输出」的聊天体验。

    第三段：行级扫入（lineFadeMode）。启用后 appendAttributedText 会使用 CAGradientLayer 遮罩做水平扫入，风格对齐 FluidMarkdown。行尾保留柔和渐隐宽度 lineFadeTrailingWidth，适合大段 Markdown 或富文本连续追加的场景。与字符渐显互斥，由本页顶部的模式切换控制。

    第四段：较长正文用于观察滚动与性能。Swift 与 UIKit 在流式 UI 中常需要 CADisplayLink 驱动逐帧更新 attributed string 的 foregroundColor，或在 TextKit 2 布局完成后对最末行安装 mask 动画。请在真机与模拟器上分别体验不同速度档位，并尝试暂停、继续与重新渲染，确认动画状态回调 onAnimationStateChange 与 finishAnimations 行为是否符合预期。

    第五段：混合中英文与标点。Hello STShimmerTextView! 2026 年的 iOS 开发 increasingly relies on incremental layout: sizeThatFits、contentOffset 保护与 allowsNonContiguousLayout = false 共同减少流式输出时的跳动。若你在集成自定义 TextView，建议像本组件一样维护 _baseAttributedText 作为「目标态」快照，供前缀比较与外部 diff 使用，避免动画过渡期 alpha 干扰逻辑判断。

    第六段：收尾。以上静态文本约两千字，足够观察多段落、多换行下的两种动画模式。点击「重新渲染」可清空并重播；切换「跨行动画」或模式后也会自动从头开始。祝测试顺利。
    """

    private var typewriterTimer: Timer?
    private var currentIndex: Int = 0
    private var isPaused = false
    private var streamSpeed: StreamSpeed = .normal
    private var animationMode: AnimationMode = .characterFade

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "Shimmer 动画测试"
        self.buildUI()
        self.startRendering()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.stopTypewriter()
    }

    // MARK: - UI

    private func buildUI() {
        let modeRow = UIStackView(arrangedSubviews: [self.modeControl])
        modeRow.axis = .vertical
        modeRow.spacing = 6

        let newlineRow = UIStackView(arrangedSubviews: [self.newlineLabel, self.newlineSwitch])
        newlineRow.axis = .horizontal
        newlineRow.spacing = 8
        newlineRow.alignment = .center

        let controlStack = UIStackView(arrangedSubviews: [
            modeRow,
            newlineRow,
            self.speedControl,
            self.actionStack
        ])
        controlStack.translatesAutoresizingMaskIntoConstraints = false
        controlStack.axis = .vertical
        controlStack.spacing = 10

        self.view.addSubview(self.statusLabel)
        self.view.addSubview(self.progressView)
        self.view.addSubview(self.shimmerContainer)
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

            self.shimmerContainer.topAnchor.constraint(equalTo: self.progressView.bottomAnchor, constant: 12),
            self.shimmerContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            self.shimmerContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
            self.shimmerContainer.bottomAnchor.constraint(equalTo: controlStack.topAnchor, constant: -12)
        ])

        self.applyLiquidGlassScrollLayout(self.shimmerTextView)
        self.applyAnimationModeSettings()
    }

    // MARK: - Actions

    @objc private func modeChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        guard index >= 0, index < AnimationMode.allCases.count else { return }
        self.animationMode = AnimationMode.allCases[index]
        self.applyAnimationModeSettings()
        self.startRendering()
    }

    @objc private func newlineSwitchChanged(_ sender: UISwitch) {
        self.shimmerTextView.animateAcrossNewlines = sender.isOn
        self.startRendering()
    }

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

    @objc private func restartTapped() {
        self.startRendering()
    }

    @objc private func finishTapped() {
        self.completeStreaming(skipFinishAnimations: false)
    }

    // MARK: - Streaming

    private func applyAnimationModeSettings() {
        switch self.animationMode {
        case .characterFade:
            self.shimmerTextView.lineFadeMode = false
            self.shimmerTextView.tokenFadeDuration = 0.28
            self.shimmerTextView.characterStaggerInterval = 0.016
        case .lineFade:
            self.shimmerTextView.lineFadeMode = true
            self.shimmerTextView.lineFadeDuration = 0.15
            self.shimmerTextView.lineFadeTrailingWidth = 18
            self.shimmerTextView.tokenFadeDuration = 0
        }
    }

    private func startRendering() {
        self.stopTypewriter()
        self.isPaused = false
        self.pauseButton.setTitle("暂停", for: .normal)
        self.currentIndex = 0
        self.shimmerTextView.reset()
        self.applyAnimationModeSettings()
        self.updateStatusLabel()
        self.restartTimerIfNeeded()
    }

    private func restartTimerIfNeeded() {
        guard self.currentIndex < Self.sampleText.count else { return }
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
        guard self.currentIndex < Self.sampleText.count else {
            self.completeStreaming(skipFinishAnimations: true)
            return
        }

        let next = min(self.currentIndex + self.streamSpeed.step, Self.sampleText.count)
        let start = Self.sampleText.index(Self.sampleText.startIndex, offsetBy: self.currentIndex)
        let end = Self.sampleText.index(Self.sampleText.startIndex, offsetBy: next)
        let chunk = String(Self.sampleText[start..<end])
        self.appendChunk(chunk)
        self.currentIndex = next
        self.updateStatusLabel()
        self.scrollToBottomIfNeeded()
    }

    private func appendChunk(_ chunk: String) {
        switch self.animationMode {
        case .characterFade:
            self.shimmerTextView.append(chunk)
        case .lineFade:
            let attrs: [NSAttributedString.Key: Any] = [
                .font: self.shimmerTextView.font ?? UIFont.st_systemFont(ofSize: 16),
                .foregroundColor: self.shimmerTextView.textColor ?? UIColor.label
            ]
            self.shimmerTextView.appendAttributedText(NSAttributedString(string: chunk, attributes: attrs), animated: true)
        }
    }

    private func completeStreaming(skipFinishAnimations: Bool) {
        self.stopTypewriter()
        if skipFinishAnimations == false {
            self.shimmerTextView.finishAnimations()
        }
        self.updateStatusLabel(finished: true)
    }

    private func updateStatusLabel(finished: Bool = false) {
        let total = Self.sampleText.count
        let progress = total > 0 ? Float(self.currentIndex) / Float(total) : 0
        self.progressView.progress = progress

        let animating = self.shimmerTextView.isAnimatingTextReveal ? "动画中" : "静止"
        let modeTitle = self.animationMode.title

        if finished {
            self.statusLabel.text = "输出完成 · \(total) 字符 · \(modeTitle) · \(animating)"
            return
        }

        if self.isPaused {
            self.statusLabel.text = String(
                format: "已暂停 · %d / %d · %@ · %@",
                self.currentIndex, total, modeTitle, animating
            )
            return
        }

        self.statusLabel.text = String(
            format: "流式输出 · %d / %d (%.0f%%) · %@ · %@",
            self.currentIndex, total, progress * 100, modeTitle, animating
        )
    }

    private func scrollToBottomIfNeeded() {
        let bottom = self.shimmerTextView.contentSize.height
            - self.shimmerTextView.bounds.height
            + self.shimmerTextView.contentInset.bottom
        guard bottom > 0 else { return }
        let targetY = max(-self.shimmerTextView.contentInset.top, bottom)
        if abs(self.shimmerTextView.contentOffset.y - targetY) > 4 {
            self.shimmerTextView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
        }
    }

    // MARK: - Subviews

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 3
        label.text = "准备输出…"
        return label
    }()

    private lazy var progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.progress = 0
        return view
    }()

    private lazy var shimmerContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 8
        container.clipsToBounds = true
        container.addSubview(self.shimmerTextView)
        NSLayoutConstraint.activate([
            self.shimmerTextView.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            self.shimmerTextView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            self.shimmerTextView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            self.shimmerTextView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
        return container
    }()

    private lazy var shimmerTextView: STShimmerTextView = {
        let view = STShimmerTextView(usingTextLayoutManager: true)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isScrollEnabled = true
        view.font = .st_systemFont(ofSize: 16)
        view.textColor = .label
        view.animateAcrossNewlines = false
        view.onAnimationStateChange = { [weak self] _ in
            self?.updateStatusLabel(finished: self?.typewriterTimer == nil && (self?.currentIndex ?? 0) >= Self.sampleText.count)
        }
        return view
    }()

    private lazy var modeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: AnimationMode.allCases.map(\.title))
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(self.modeChanged), for: .valueChanged)
        return control
    }()

    private lazy var newlineLabel: UILabel = {
        let label = UILabel()
        label.text = "跨行动画 animateAcrossNewlines"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()

    private lazy var newlineSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.isOn = false
        toggle.addTarget(self, action: #selector(self.newlineSwitchChanged), for: .valueChanged)
        return toggle
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
        button.setTitle("暂停", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.addTarget(self, action: #selector(self.pauseTapped), for: .touchUpInside)
        return button
    }()

    private lazy var restartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("重新渲染", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.addTarget(self, action: #selector(self.restartTapped), for: .touchUpInside)
        return button
    }()

    private lazy var finishButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("立即完成动画", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.addTarget(self, action: #selector(self.finishTapped), for: .touchUpInside)
        return button
    }()

    private lazy var actionStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            self.pauseButton,
            self.restartButton,
            self.finishButton
        ])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return stack
    }()
}
