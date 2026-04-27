//
//  STLogViewController.swift
//  STBaseProject_Example
//
//  Created by 寒江孤影 on 2022/8/4.
//  Copyright © 2022 STBaseProject. All rights reserved.
//

import UIKit
import STBaseProject

final class STLogViewController: STBaseViewController {

    private var timer: Timer?
    private let logView = STLogView()
    private let logGenerator = STDemoLogGenerator()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.setupNavBar()
        self.setupLogView()
        self.seedInitialLogs()
        self.startAutoLogging()
        self.logNetworkSample()
    }

    private func setupNavBar() {
        self.st_showNavBtnType(type: .showLeftBtn)
        self.leftBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        let randomBtn = self.makeNavButton(title: "随机日志", action: #selector(addRandomLog))
        let burstBtn = self.makeNavButton(title: "批量注入", action: #selector(addBurstLogs))
        let stack = UIStackView(arrangedSubviews: [burstBtn, randomBtn])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        self.navigationBarItemsView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: self.navigationBarItemsView.centerYAnchor),
            stack.trailingAnchor.constraint(equalTo: self.navigationBarItemsView.trailingAnchor, constant: -12)
        ])
    }

    private func setupLogView() {
        self.logView.translatesAutoresizingMaskIntoConstraints = false
        self.logView.mDelegate = self
        self.view.addSubview(self.logView)
        NSLayoutConstraint.activate([
            self.logView.topAnchor.constraint(equalTo: self.contentTopAnchor),
            self.logView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.logView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.logView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func seedInitialLogs() {
        STLogLevel.allCases.forEach { level in
            let message = "示例 \(level.rawValue) 级别日志，用于展示过滤效果。"
            STPersistentLog(message, level: level, metadata: ["seed": "true"], file: "STLogDemoViewController.swift", function: "viewDidLoad", line: 52
            )
        }
    }

    @objc private func addRandomLog() {
        self.logGenerator.randomLog()
    }

    @objc private func addBurstLogs() {
        (0..<10).forEach { _ in
            self.logGenerator.randomLog()
        }
    }

    private func makeNavButton(title: String, action: Selector) -> UIButton {
        let button = STIconBtn(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.iconContentInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        button.layer.cornerRadius = 14
        button.layer.masksToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        button.setTitleColor(.systemBlue, for: .normal)
        button.backgroundColor = .secondarySystemBackground
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.addTarget(self, action: action, for: .touchUpInside)
        let heightConstraint = button.heightAnchor.constraint(equalToConstant: 28)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        return button
    }

    private func startAutoLogging() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
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
            STPersistentLog("网络请求返回：\n\(jsonString)", level: .info)
        }
    }

    deinit {
        self.timer?.invalidate()
    }
}

// MARK: - STLogViewDelegate
extension STLogViewController: STLogViewDelegate {
    func logViewBackBtnClick() {
        self.onLeftBtnTap()
    }

    func logViewDidFilterLogs(with results: [STLogEntry]) {
    
    }
}

// MARK: - Demo Log Generator
private struct STDemoLogGenerator {
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
        STPersistentLog(message, level: level)
        return message
    }
}
