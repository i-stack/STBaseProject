//
//  STTimerTestViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2022/8/4.
//

import UIKit
import STBaseProject

class STTimerTestViewController: BaseViewController {

    private var timer: STTimer?
    private var logLines: [String] = []
    private var countdownTimer: STCountdownTimer?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "STTimer 功能测试"
        self.buildUI()
    }

    private func buildUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scrollView)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 12
        scrollView.addSubview(stackView)

        self.addSection(title: "STTimer", actions: [
            ("创建 1s 定时器", #selector(self.createTimer)),
            ("start(firstFire: .immediate)", #selector(self.startTimer)),
            ("pause()", #selector(self.pauseTimer)),
            ("resume()", #selector(self.resumeTimer)),
            ("stop()", #selector(self.stopTimer)),
            ("读取状态", #selector(self.inspectTimerState))
        ], to: stackView)

        self.addSection(title: "STCountdownTimer", actions: [
            ("创建 10s 倒计时", #selector(self.createCountdown)),
            ("start()", #selector(self.startCountdown)),
            ("pause()", #selector(self.pauseCountdown)),
            ("resume()", #selector(self.resumeCountdown)),
            ("stop()", #selector(self.stopCountdown)),
            ("reset()", #selector(self.resetCountdown)),
            ("读取剩余/进度", #selector(self.inspectCountdownState))
        ], to: stackView)

        self.addSection(title: "STTimeProfiler", actions: [
            ("st_start + st_logElapsed", #selector(self.profileStartAndLog)),
            ("st_end", #selector(self.profileEnd)),
            ("st_measure (同步)", #selector(self.profileSyncMeasure)),
            ("st_measureAsync (异步)", #selector(self.profileAsyncMeasure)),
            ("st_clear(tag:)", #selector(self.profileClearTag)),
            ("st_clearAll()", #selector(self.profileClearAll))
        ], to: stackView)

        stackView.addArrangedSubview(self.logTextView)
        NSLayoutConstraint.activate([
            self.logTextView.heightAnchor.constraint(equalToConstant: 240)
        ])

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        self.applyLiquidGlassScrollLayout(scrollView)
    }

    private func addSection(title: String, actions: [(String, Selector)], to parent: UIStackView) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .boldSystemFont(ofSize: 17)
        parent.addArrangedSubview(titleLabel)

        for action in actions {
            let button = UIButton(type: .system)
            button.contentHorizontalAlignment = .left
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            button.setTitle(action.0, for: .normal)
            button.addTarget(self, action: action.1, for: .touchUpInside)
            parent.addArrangedSubview(button)
        }
    }

    private func appendLog(_ message: String) {
        let line = "[\(Self.timeString())] \(message)"
        self.logLines.append(line)
        if self.logLines.count > 120 {
            self.logLines.removeFirst(self.logLines.count - 120)
        }
        self.logTextView.text = self.logLines.joined(separator: "\n")
        let range = NSRange(location: max(self.logTextView.text.count - 1, 0), length: 1)
        self.logTextView.scrollRangeToVisible(range)
        STLog(message)
    }

    private static func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    private lazy var logTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = UIColor.secondarySystemBackground
        textView.layer.cornerRadius = 8
        return textView
    }()
}

private extension STTimerTestViewController {

    @objc func createTimer() {
        self.timer?.stop()
        self.timer = STTimer(interval: 1.0)
        self.appendLog("STTimer 已创建，间隔 1 秒")
    }

    @objc func startTimer() {
        guard let timer = self.timer else {
            self.appendLog("请先创建 STTimer")
            return
        }
        timer.start(firstFire: .immediate) { [weak self] timer in
            self?.appendLog("STTimer 触发: fireCount=\(timer.fireCount), isRunning=\(timer.isRunning), isPaused=\(timer.isPaused)")
        }
        self.appendLog("调用 STTimer.start(firstFire: .immediate)")
    }

    @objc func pauseTimer() {
        self.timer?.pause()
        self.appendLog("调用 STTimer.pause()")
    }

    @objc func resumeTimer() {
        self.timer?.resume()
        self.appendLog("调用 STTimer.resume()")
    }

    @objc func stopTimer() {
        self.timer?.stop()
        self.appendLog("调用 STTimer.stop()")
    }

    @objc func inspectTimerState() {
        guard let timer = self.timer else {
            self.appendLog("STTimer 不存在")
            return
        }
        self.appendLog("STTimer 状态: isRunning=\(timer.isRunning), isPaused=\(timer.isPaused), fireCount=\(timer.fireCount)")
    }

    @objc func createCountdown() {
        self.countdownTimer?.stop()
        do {
            self.countdownTimer = try STCountdownTimer(duration: 10)
            self.appendLog("STCountdownTimer 已创建，时长 10 秒")
        } catch {
            self.appendLog("创建 STCountdownTimer 失败: \(error.localizedDescription)")
        }
    }

    @objc func startCountdown() {
        guard let timer = self.countdownTimer else {
            self.appendLog("请先创建 STCountdownTimer")
            return
        }
        timer.start(progress: { [weak self] remaining in
            self?.appendLog("倒计时 progress: remaining=\(String(format: "%.2f", remaining))s")
        }, completion: { [weak self] in
            self?.appendLog("倒计时 completion 回调")
        }, error: { [weak self] error in
            self?.appendLog("倒计时 error: \(error.localizedDescription)")
        })
        self.appendLog("调用 STCountdownTimer.start()")
    }

    @objc func pauseCountdown() {
        self.countdownTimer?.pause()
        self.appendLog("调用 STCountdownTimer.pause()")
    }

    @objc func resumeCountdown() {
        self.countdownTimer?.resume()
        self.appendLog("调用 STCountdownTimer.resume()")
    }

    @objc func stopCountdown() {
        self.countdownTimer?.stop()
        self.appendLog("调用 STCountdownTimer.stop()")
    }

    @objc func resetCountdown() {
        self.countdownTimer?.reset()
        self.appendLog("调用 STCountdownTimer.reset()")
    }

    @objc func inspectCountdownState() {
        guard let timer = self.countdownTimer else {
            self.appendLog("STCountdownTimer 不存在")
            return
        }
        let remaining = timer.getRemainingTime()
        let progress = timer.getProgress()
        self.appendLog("Countdown 状态: isRunning=\(timer.isRunning), isPaused=\(timer.isPaused), remaining=\(String(format: "%.2f", remaining))s, progress=\(String(format: "%.2f", progress))")
    }

    @objc func profileStartAndLog() {
        STTimeProfiler.st_start(tag: "manual")
        self.appendLog("调用 STTimeProfiler.st_start(tag: manual)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            STTimeProfiler.st_logElapsed(tag: "manual", message: "手动检查耗时")
            if let elapsed = STTimeProfiler.st_elapsedTime(tag: "manual") {
                self?.appendLog("st_elapsedTime(manual)=\(String(format: "%.4f", elapsed))s")
            }
        }
    }

    @objc func profileEnd() {
        STTimeProfiler.st_end(tag: "manual", message: "手动结束")
        self.appendLog("调用 STTimeProfiler.st_end(tag: manual)")
    }

    @objc func profileSyncMeasure() {
        let result = STTimeProfiler.st_measure(tag: "syncMeasure", message: "同步计算") { () -> Int in
            (0..<100_000).reduce(0, +)
        }
        self.appendLog("st_measure 同步完成，结果=\(result)")
    }

    @objc func profileAsyncMeasure() {
        STTimeProfiler.st_measureAsync(tag: "asyncMeasure", message: "异步等待 300ms") { [weak self] in
            try await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run {
                self?.appendLog("st_measureAsync block 执行完成")
            }
        }
        self.appendLog("调用 STTimeProfiler.st_measureAsync(tag: asyncMeasure)")
    }

    @objc func profileClearTag() {
        STTimeProfiler.st_clear(tag: "manual")
        self.appendLog("调用 STTimeProfiler.st_clear(tag: manual)")
    }

    @objc func profileClearAll() {
        STTimeProfiler.st_clearAll()
        self.appendLog("调用 STTimeProfiler.st_clearAll()")
    }
}
