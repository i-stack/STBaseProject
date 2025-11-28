//
//  STLogDemoViewController.swift
//  STBaseProject_Example
//
//  Created to showcase STLogView capabilities within the Example app.
//

import UIKit
import STBaseProject

/// 通过注入模拟日志，演示 STLogView 的过滤、搜索与主题切换等能力
final class STLogDemoViewController: UIViewController {

    private let baseTitle = "STLogView Demo"

    private let logView = STLogView()
    private let logGenerator = STDemoLogGenerator()
    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = baseTitle
        view.backgroundColor = .systemBackground

        setupLogView()
        configureNavigationItems()
        seedInitialLogs()
        startAutoLogging()
        logNetworkSample()
    }

    private func setupLogView() {
        logView.translatesAutoresizingMaskIntoConstraints = false
        logView.mDelegate = self
        view.addSubview(logView)

        NSLayoutConstraint.activate([
            logView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            logView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            logView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            logView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureNavigationItems() {
        let randomItem = makeNavButton(title: "随机日志", action: #selector(addRandomLog))
        let burstItem = makeNavButton(title: "批量注入", action: #selector(addBurstLogs))
        navigationItem.rightBarButtonItems = [randomItem, burstItem]
    }

    private func seedInitialLogs() {
        STLogLevel.allCases.forEach { level in
            let message = "示例 \(level.rawValue) 级别日志，用于展示过滤效果。"
            let content = logGenerator.makeLog(level: level, message: message, function: "viewDidLoad", line: 52)
            logView.beginQueryLogP(content: content)
        }
    }

    @objc private func addRandomLog() {
        logGenerator.randomLog()
    }

    @objc private func addBurstLogs() {
        (0..<10).forEach { _ in
            logGenerator.randomLog()
        }
    }

    private func makeNavButton(title: String, action: Selector) -> UIBarButtonItem {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 68).isActive = true
        
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        return UIBarButtonItem(customView: container)
    }

    private func startAutoLogging() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.logGenerator.randomLog()
        }
    }

    private func logNetworkSample() {
        let sampleResponse: [String: Any] = [
            "code": 0,
            "message": "success",
            "data": [
                "user": [
                    "id": 123456789,
                    "name": "StackOverflow",
                    "roles": ["admin", "editor", "auditor"],
                    "meta": [
                        "lastLogin": "2024-11-28T08:12:45Z",
                        "preferences": [
                            "theme": "dark",
                            "timezone": "Asia/Shanghai",
                            "featureFlags": [
                                "newDashboard": true,
                                "betaNetwork": false,
                                "logStreaming": true
                            ]
                        ]
                    ]
                ],
                "items": (0..<5).map { index -> [String: Any] in
                    return [
                        "index": index,
                        "title": "示例请求条目 \(index)",
                        "values": (0..<10).map {
                            [
                                "value": Int.random(in: 1000...9999),
                                "timestamp": "2024-11-28T08:\(String(format: "%02d", $0)):00Z"
                            ]
                        }
                    ]
                }
            ]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: sampleResponse, options: [.prettyPrinted]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            STLogP("网络请求返回：\n\(jsonString)", level: .info)
        }
    }

    deinit {
        timer?.invalidate()
    }
}

// MARK: - STLogViewDelegate
extension STLogDemoViewController: STLogViewDelegate {
    func logViewBackBtnClick() {
        navigationController?.popViewController(animated: true)
    }

    func logViewShowDocumentInteractionController() {
        presentAlert(title: "导出日志", message: "示例环境仅展示导出入口，未真正写入文件。")
    }

    func logViewDidFilterLogs(with results: [STLogEntry]) {
        if !logView.st_isFiltering() || results.count == logView.st_getAllLogCount() {
            title = baseTitle
            return
        }
        
        if results.isEmpty {
            title = "\(baseTitle) · 无结果"
        } else {
            title = "\(baseTitle) · \(results.count) 条"
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Demo Log Generator
private struct STDemoLogGenerator {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        return formatter
    }()

    private let sampleMessages: [STLogLevel: [String]] = [
        .debug: ["缓存命中，返回内存数据", "启动性能统计完成", "收到调试命令，准备执行"],
        .info: ["用户完成登录流程", "配置加载成功", "同步完成，共 42 条记录"],
        .warning: ["磁盘空间不足 10%", "网络波动重试中", "检测到可能的循环引用"],
        .error: ["接口返回 500 错误", "数据库写入失败", "JSON 解析失败，字段缺失"],
        .fatal: ["应用即将崩溃，触发 CrashGuard", "严重数据错乱，终止流程", "安全策略失效，阻断操作"]
    ]

    @discardableResult
    func randomLog() -> String {
        guard let level = STLogLevel.allCases.randomElement() else { return "" }
        let message = sampleMessages[level]?.randomElement() ?? "未知日志"
        STLogP(message, level: level)
        return makeLog(level: level, message: message)
    }

    func makeLog(level: STLogLevel, message: String, function: String = #function, line: Int = #line) -> String {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "STLogDemoViewController.swift"
        let formattedMessage = "\(level.rawValue): \(message)"

        return """
        \(timestamp)
        \(fileName)
        funcName: \(function)
        lineNum: (\(line))
        level: \(level.rawValue)
        message: \(formattedMessage)
        """
    }
}

