//
//  STToolsManualTestViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2022/8/4.
//

import UIKit
import STBaseProject

final class STToolsManualTestViewController: BaseViewController {
    
    private var markdownTypewriterTimer: Timer?
    private var markdownTypewriterText: String = ""
    private var markdownTypewriterIndex: Int = 0
    private let markdownTypewriterInterval: TimeInterval = 0.02
    private let markdownTypewriterStep: Int = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "STTools 手动测试"
        self.buildUI()
        self.appendLine("进入页面后可逐项触发依赖系统能力的测试")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.stopMarkdownTypewriter()
    }

    private func buildUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(scrollView)

        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        scrollView.addSubview(stackView)

        let actions: [(String, Selector)] = [
            ("读取 DeviceInfo", #selector(self.readDeviceInfo)),
            ("读取 DeviceAdapter", #selector(self.readDeviceAdapter)),
            ("CrashDetector 标记/检查", #selector(self.testCrashDetector)),
            ("字体/颜色示例", #selector(self.testFontAndColor)),
            ("性能测量示例", #selector(self.testScrollPerfDiagnostics)),
            ("Markdown 资源逐字输出", #selector(self.showMarkdownResourcesVerbatim))
        ]

        for action in actions {
            let button = UIButton(type: .system)
            button.contentHorizontalAlignment = .left
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
            button.setTitle(action.0, for: .normal)
            button.addTarget(self, action: action.1, for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }

        stackView.addArrangedSubview(self.markdownStreamingView)
        stackView.addArrangedSubview(self.outputTextView)
        NSLayoutConstraint.activate([
            self.markdownStreamingView.heightAnchor.constraint(equalToConstant: 360),
            self.outputTextView.heightAnchor.constraint(equalToConstant: 260),
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

    private func appendLine(_ message: String) {
        let time = Date().formatted("HH:mm:ss")
        let line = "[\(time)] \(message)"
        let current = self.outputTextView.text ?? ""
        self.outputTextView.text = current.isEmpty ? line : current + "\n" + line
        STLog(message)
    }
    
    private lazy var outputTextView: UITextView = {
       let textView = UITextView()
       textView.translatesAutoresizingMaskIntoConstraints = false
       textView.isEditable = false
       textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
       textView.backgroundColor = UIColor.secondarySystemBackground
       textView.layer.cornerRadius = 8
       return textView
   }()
    
    private lazy var markdownStreamingView: STMarkdownStreamingTextView = {
        let view = STMarkdownStreamingTextView(
            style: .default,
            advancedRenderers: .empty,
            engine: STMarkdownEngine()
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.secondarySystemBackground
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.isTextSelectionEnabled = true
        view.tokenFadeDuration = 0.1
        view.animateAcrossNewlines = false
        return view
    }()
}

private extension STToolsManualTestViewController {

    @objc func readDeviceInfo() {
        let info = STDeviceInfo.appInfo
        self.appendLine("App: \(info.displayName) \(info.version)(\(info.buildVersion))")
        self.appendLine("System: \(STDeviceInfo.systemName) \(STDeviceInfo.systemVersion), model: \(STDeviceInfo.deviceModelName)")
        self.appendLine("Battery: \(STDeviceInfo.batteryInfo.percentage)%, charging=\(STDeviceInfo.isCharging)")
        self.appendLine("Storage used: \(STDeviceInfo.usedStorage), RAM used: \(STDeviceInfo.usedRAM)")
    }

    @objc func readDeviceAdapter() {
        self.appendLine("Screen: \(STDeviceAdapter.screenSize), scale: \(UIScreen.main.scale)")
        self.appendLine("NavBar: \(STDeviceAdapter.navigationBarHeight), TabBar: \(STDeviceAdapter.tabBarHeight)")
        self.appendLine("SafeInsets: \(STDeviceAdapter.safeAreaInsets), isNotch=\(STDeviceAdapter.isNotchScreen)")
    }

    @objc func testCrashDetector() {
        let detector = STCrashDetector.shared
        detector.markAppLaunch()
        detector.markAppBackgroundEntry()
        let detected = detector.detectCrash()
        self.appendLine("CrashDetector.detectCrash = \(detected), info = \(detector.crashInfo())")
        detector.markAppTermination()
        detector.clearCrashData()
    }

    @objc func testFontAndColor() {
        let font = UIFont.st_systemFont(ofSize: 14, weight: .medium)
        let color = UIColor.color(hex: "#FF8800CC")
        let components = color.cgColor.components ?? []
        self.appendLine("Font: \(font.fontName) \(font.pointSize)")
        self.appendLine("Color components: \(components)")
    }

    @objc func testScrollPerfDiagnostics() {
        let value = STScrollPerfDiagnostics.measure(name: "ManualCalc") { () -> Int in
            (0..<200_000).reduce(0, +)
        }
        self.appendLine("STScrollPerfDiagnostics measure result = \(value)")
    }

    @objc func showMarkdownResourcesVerbatim() {
        self.stopMarkdownTypewriter()
        let resourceNames = ["data1", "data2", "data3"]
        var sections: [String] = []

        for name in resourceNames {
            guard let path = Bundle.main.path(forResource: name, ofType: "txt") else {
                self.appendLine("未找到资源文件：\(name).txt")
                continue
            }
            do {
                let content = try String(contentsOfFile: path, encoding: .utf8)
                sections.append("## \(name).txt\n\n\(content)")
            } catch {
                self.appendLine("读取 \(name).txt 失败：\(error.localizedDescription)")
            }
        }

        if sections.isEmpty == false {
            self.markdownTypewriterText = sections.joined(separator: "\n\n---\n\n")
            self.markdownTypewriterIndex = 0
            self.markdownStreamingView.reset()
            self.startMarkdownTypewriter()
            self.appendLine("已开始通过 STMarkdown 逐字渲染 3 份资源")
        }
    }
    
    private func startMarkdownTypewriter() {
        guard !self.markdownTypewriterText.isEmpty else { return }
        self.markdownTypewriterTimer = Timer.scheduledTimer(
            timeInterval: self.markdownTypewriterInterval,
            target: self,
            selector: #selector(self.handleMarkdownTypewriterTick),
            userInfo: nil,
            repeats: true
        )
        if let timer = self.markdownTypewriterTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopMarkdownTypewriter() {
        self.markdownTypewriterTimer?.invalidate()
        self.markdownTypewriterTimer = nil
    }
    
    @objc private func handleMarkdownTypewriterTick() {
        guard self.markdownTypewriterIndex < self.markdownTypewriterText.count else {
            self.stopMarkdownTypewriter()
            self.appendLine("逐字渲染完成")
            return
        }
        let nextIndex = min(self.markdownTypewriterIndex + self.markdownTypewriterStep, self.markdownTypewriterText.count)
        let end = self.markdownTypewriterText.index(self.markdownTypewriterText.startIndex, offsetBy: nextIndex)
        let current = String(self.markdownTypewriterText[..<end])
        self.markdownStreamingView.updateStreamingMarkdown(current)
        self.markdownTypewriterIndex = nextIndex
    }
}
