//
//  STLogView.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//

import UIKit

// MARK: - 日志条目模型
public struct STLogEntry {
    public let id: String
    public let timestamp: Date
    public let level: STLogLevel
    public let file: String
    public let function: String
    public let line: Int
    public let message: String
    public let rawContent: String
    
    init(content: String) {
        self.id = UUID().uuidString
        self.rawContent = content
        
        // 解析日志内容
        let components = content
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if components.count >= 4 {
            let timestampString = components[0]
            self.timestamp = timestampString.st_toDate() ?? Date()
            self.file = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let functionLine = components[2]
            if functionLine.contains("funcName:") {
                self.function = functionLine.components(separatedBy: "funcName: ").last ?? ""
            } else {
                self.function = ""
            }
            let lineLine = components[3]
            if lineLine.contains("lineNum:") {
                let lineString = lineLine.components(separatedBy: "lineNum: (").last?.components(separatedBy: ")").first ?? "0"
                self.line = Int(lineString) ?? 0
            } else {
                self.line = 0
            }
            var levelFromContent: STLogLevel?
            var messageLineIndex = 4
            if components.count > messageLineIndex {
                let levelLine = components[messageLineIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                if levelLine.lowercased().hasPrefix("level:") {
                    let value = levelLine.components(separatedBy: "level:").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    levelFromContent = STLogLevel(rawValue: value.uppercased())
                    messageLineIndex += 1
                }
            }
            if components.count > messageLineIndex {
                var messageComponents = Array(components[messageLineIndex...])
                if !messageComponents.isEmpty {
                    let firstLine = messageComponents[0]
                    let cleanedFirstLine = firstLine.components(separatedBy: "message: ").last ?? firstLine
                    messageComponents[0] = cleanedFirstLine
                }
                self.message = STLogEntry.prettyMessage(from: messageComponents.joined(separator: "\n"))
            } else {
                self.message = ""
            }
            if let parsedLevel = levelFromContent {
                self.level = parsedLevel
            } else {
                self.level = STLogEntry.detectLogLevel(from: self.message)
            }
        } else {
            self.timestamp = Date()
            self.file = ""
            self.function = ""
            self.line = 0
            self.message = STLogEntry.prettyMessage(from: content)
            self.level = STLogEntry.detectLogLevel(from: self.message)
        }
    }
    
    private static func prettyMessage(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if let data = trimmed.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data, options: []),
           JSONSerialization.isValidJSONObject(object),
           let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
           let prettyString = String(data: prettyData, encoding: .utf8),
           content.count != prettyString.count {
            return prettyString
        }
        return trimmed
    }
    
    private static func detectLogLevel(from message: String) -> STLogLevel {
        let lowerMessage = message.lowercased()
        if lowerMessage.contains("fatal") || lowerMessage.contains("crash") {
            return .fatal
        } else if lowerMessage.contains("error") || lowerMessage.contains("exception") {
            return .error
        } else if lowerMessage.contains("warning") || lowerMessage.contains("warn") {
            return .warning
        } else if lowerMessage.contains("info") || lowerMessage.contains("information") {
            return .info
        } else {
            return .debug
        }
    }
}

// MARK: - 日志视图代理
public protocol STLogViewDelegate: NSObjectProtocol {
    func logViewBackBtnClick()
    func logViewShowDocumentInteractionController()
    func logViewDidFilterLogs(with results: [STLogEntry])
}

// MARK: - 日志视图
open class STLogView: UIView {

    private var outputPath: String = ""
    open weak var mDelegate: STLogViewDelegate?
    private var allLogEntries: [STLogEntry] = []
    private var filteredLogEntries: [STLogEntry] = []
    private var currentLogEntries: [STLogEntry] {
        return isFiltering ? filteredLogEntries : allLogEntries
    }
    
    private var isFiltering: Bool = false
    private var selectedLogLevels: Set<STLogLevel> = Set(STLogLevel.allCases)
    private var searchText: String = ""
    private var currentPage: Int = 0
    private let pageSize: Int = 100
        
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.configUI()
        self.outputPath = STLogManager.st_outputLogPath()
        self.setupNotifications()
        self.loadInitialLogs()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configUI()
        self.outputPath = STLogManager.st_outputLogPath()
        self.setupNotifications()
        self.loadInitialLogs()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true {
                self.applySystemAppearance()
            }
        } else {
            self.applySystemAppearance()
        }
    }
        
    private func configUI() {
        self.backgroundColor = .systemBackground
        self.addSubview(self.searchBar)
        self.addSubview(self.filterView)
        self.addSubview(self.tableView)
        self.addSubview(self.bottomToolbar)
        self.setupConstraints()
        self.applySystemAppearance()
        self.tableView.register(STLogTableViewCell.self, forCellReuseIdentifier: "STLogTableViewCell")
    }
    
    private func setupConstraints() {
        // 搜索栏约束
        self.addConstraints([
            NSLayoutConstraint(item: self.searchBar, attribute: .top, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.searchBar, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.searchBar, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.searchBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 44)
        ])
        
        // 过滤视图约束
        self.addConstraints([
            NSLayoutConstraint(item: self.filterView, attribute: .top, relatedBy: .equal, toItem: self.searchBar, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.filterView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.filterView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.filterView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)
        ])
        
        // 表格视图约束
        self.addConstraints([
            NSLayoutConstraint(item: self.tableView, attribute: .top, relatedBy: .equal, toItem: self.filterView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.tableView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.tableView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.tableView, attribute: .bottom, relatedBy: .equal, toItem: self.bottomToolbar, attribute: .top, multiplier: 1, constant: 0)
        ])
        
        // 底部工具栏约束
        self.addConstraints([
            NSLayoutConstraint(item: self.bottomToolbar, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.bottomToolbar, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.bottomToolbar, attribute: .bottom, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.bottomToolbar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 60)
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(beginQueryLogP(notification:)),
            name: NSNotification.Name(rawValue: STLogManager.st_notificationQueryLogName()),
            object: nil
        )
    }
    
    private func loadInitialLogs() {
        let userDefault = UserDefaults.standard
        if let originalContent = userDefault.object(forKey: self.outputPath) as? String {
            if originalContent.count > 0 {
                self.parseLogContent(originalContent)
            }
        }
    }
    
    private func applySystemAppearance() {
        self.backgroundColor = .systemBackground
        self.tintColor = .systemBlue
        self.searchBar.barTintColor = .systemBackground
        self.searchBar.tintColor = .systemBlue
        if #available(iOS 13.0, *) {
            self.searchBar.searchTextField.backgroundColor = .secondarySystemBackground
            self.searchBar.searchTextField.textColor = .label
        } else if let textField = self.searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor(white: 0.92, alpha: 1.0)
            textField.textColor = .darkText
        }
        self.filterView.backgroundColor = .systemBackground
        self.tableView.backgroundColor = .systemBackground
        self.tableView.separatorColor = .separator
        self.bottomToolbar.barTintColor = .systemBackground
        self.bottomToolbar.tintColor = .systemBlue
        self.bottomToolbar.backgroundColor = .systemBackground
    }
        
    @objc private func beginQueryLogP(notification: Notification) {
        if let content = notification.object as? String {
            self.addLogEntry(content: content)
        }
    }
    
    public func beginQueryLogP(content: String) {
        if content.count > 0 {
            self.addLogEntry(content: content)
        } else {
            self.loadAllLogs()
        }
    }
    
    private func addLogEntry(content: String) {
        let logEntry = STLogEntry(content: content)
        self.allLogEntries.append(logEntry)
        if self.isFiltering {
            self.performFilter()
        } else {
            self.reloadTableView()
        }
    }
    
    private func loadAllLogs() {
        let userDefault = UserDefaults.standard
        if let originalContent = userDefault.object(forKey: self.outputPath) as? String {
            if originalContent.count > 0 {
                self.parseLogContent(originalContent)
            }
        }
    }
    
    private func parseLogContent(_ content: String) {
        let logComponents = content.components(separatedBy: "\n\n")
        self.allLogEntries.removeAll()
        for component in logComponents {
            if component.trimmingCharacters(in: .whitespacesAndNewlines).count > 0 {
                let logEntry = STLogEntry(content: component)
                self.allLogEntries.append(logEntry)
            }
        }
        
        self.reloadTableView()
    }
    
    private func reloadTableView() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            if self.currentLogEntries.count > 0 {
                let indexPath = IndexPath(row: self.currentLogEntries.count - 1, section: 0)
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
        
    private func performFilter() {
        var filtered = self.allLogEntries
        
        // 按日志级别过滤
        if self.selectedLogLevels.count < STLogLevel.allCases.count {
            filtered = filtered.filter { self.selectedLogLevels.contains($0.level) }
        }
        
        // 按搜索文本过滤
        if !self.searchText.isEmpty {
            filtered = filtered.filter { logEntry in
                logEntry.message.lowercased().contains(self.searchText.lowercased()) ||
                logEntry.file.lowercased().contains(self.searchText.lowercased()) ||
                logEntry.function.lowercased().contains(self.searchText.lowercased())
            }
        }
        self.filteredLogEntries = filtered
        self.isFiltering = true
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.mDelegate?.logViewDidFilterLogs(with: filtered)
        }
    }
    
    private func clearFilter() {
        self.isFiltering = false
        self.filteredLogEntries.removeAll()
        self.searchText = ""
        self.selectedLogLevels = Set(STLogLevel.allCases)
        DispatchQueue.main.async {
            self.searchBar.text = ""
            self.updateFilterButtons()
            self.tableView.reloadData()
            self.mDelegate?.logViewDidFilterLogs(with: self.allLogEntries)
        }
    }
        
    @objc private func backBtnClick() {
        self.mDelegate?.logViewBackBtnClick()
    }
    
    @objc private func cleanLogBtnClick() {
        let alert = UIAlertController(title: "清除日志", message: "确定要清除所有日志吗？此操作不可撤销。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { _ in
            self.clearAllLogs()
        })
        if let topViewController = self.getTopViewController() {
            topViewController.present(alert, animated: true)
        }
    }
    
    @objc private func outputLogBtnClick() {
        self.exportLogFile()
    }
    
    @objc private func filterBtnClick() {
        self.showFilterOptions()
    }
    
    @objc private func exportBtnClick() {
        self.exportLogs()
    }
        
    private func clearAllLogs() {
        self.allLogEntries.removeAll()
        self.filteredLogEntries.removeAll()
        self.clearFilter()
        let userDefault = UserDefaults.standard
        userDefault.removeObject(forKey: self.outputPath)
        userDefault.synchronize()
        STFileManager.st_removeItem(atPath: self.outputPath)
    }
    
    private func showFilterOptions() {
        let alert = UIAlertController(title: "过滤选项", message: "选择要显示的日志级别", preferredStyle: .actionSheet)
        for level in STLogLevel.allCases {
            let isSelected = selectedLogLevels.contains(level)
            let action = UIAlertAction(title: "\(level.icon) \(level.rawValue)", style: .default) { _ in
                if isSelected {
                    self.selectedLogLevels.remove(level)
                } else {
                    self.selectedLogLevels.insert(level)
                }
                self.updateFilterButtons()
                self.performFilter()
            }
            action.setValue(isSelected, forKey: "checked")
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "全选", style: .default) { _ in
            self.selectedLogLevels = Set(STLogLevel.allCases)
            self.updateFilterButtons()
            self.performFilter()
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let topViewController = self.getTopViewController() {
            topViewController.present(alert, animated: true)
        }
    }
    
    private func exportLogs() {
        let logsToExport = currentLogEntries
        let logText = logsToExport.map { $0.rawContent }.joined(separator: "\n\n")
        let activityViewController = UIActivityViewController(activityItems: [logText], applicationActivities: nil)
        if let topViewController = self.getTopViewController() {
            topViewController.present(activityViewController, animated: true)
        }
    }

    private func exportLogFile() {
        let filePath = STLogManager.st_outputLogPath()
        let userDefault = UserDefaults.standard
        guard let originalContent = userDefault.object(forKey: filePath) as? String,
              originalContent.isEmpty == false else {
            self.presentAlert(title: "暂无日志", message: "当前没有可导出的日志内容。")
            return
        }
        STLogView.st_logWriteToFile()
        guard FileManager.default.fileExists(atPath: filePath) else {
            self.presentAlert(title: "导出失败", message: "未找到日志文件。")
            return
        }
        let fileURL = URL(fileURLWithPath: filePath)
        let activityController = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activityController.completionWithItemsHandler = { [weak self] _, _, _, _ in
            guard let strongSelf = self else { return }
            strongSelf.mDelegate?.logViewShowDocumentInteractionController()
        }
        if let topVC = self.getTopViewController() {
            if let popover = activityController.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 1, height: 1)
            }
            topVC.present(activityController, animated: true)
        } else {
            self.presentAlert(title: "导出失败", message: "无法找到可展示分享界面的视图控制器。")
        }
    }
    
    private func updateFilterButtons() {
        for (index, level) in STLogLevel.allCases.enumerated() {
            guard index < self.filterButtons.count else { continue }
            let button = self.filterButtons[index]
            let isSelected = self.selectedLogLevels.contains(level)
            button.isSelected = isSelected
            self.applyStyle(to: button, level: level, selected: isSelected)
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        var topController = UIApplication.shared.windows.first?.rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        return topController
    }

    private func presentAlert(title: String, message: String) {
        guard let topVC = self.getTopViewController() else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        topVC.present(alert, animated: true)
    }
        
    // MARK: - UI 组件
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "搜索日志..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    private lazy var filterView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        self.filterScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.filterScrollView.showsHorizontalScrollIndicator = false
        self.filterScrollView.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        view.addSubview(self.filterScrollView)
        self.filterScrollView.addSubview(self.filterStackView)
        NSLayoutConstraint.activate([
            self.filterScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.filterScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.filterScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            self.filterScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            self.filterStackView.leadingAnchor.constraint(equalTo: self.filterScrollView.contentLayoutGuide.leadingAnchor),
            self.filterStackView.trailingAnchor.constraint(equalTo: self.filterScrollView.contentLayoutGuide.trailingAnchor),
            self.filterStackView.topAnchor.constraint(equalTo: self.filterScrollView.contentLayoutGuide.topAnchor, constant: 8),
            self.filterStackView.bottomAnchor.constraint(equalTo: self.filterScrollView.contentLayoutGuide.bottomAnchor, constant: -8),
            self.filterStackView.heightAnchor.constraint(equalTo: self.filterScrollView.frameLayoutGuide.heightAnchor, constant: -16)
        ])
        return view
    }()

    private lazy var filterScrollView: UIScrollView = UIScrollView()

    private lazy var filterStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        STLogLevel.allCases.enumerated().forEach { index, level in
            let button = self.makeFilterButton(for: level, index: index)
            stack.addArrangedSubview(button)
            self.filterButtons.append(button)
        }
        return stack
    }()
    
    private var filterButtons: [UIButton] = []

    private func makeFilterButton(for level: STLogLevel, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.tag = index
        button.addTarget(self, action: #selector(filterLevelButtonTapped(_:)), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.layer.cornerRadius = 0
        button.layer.masksToBounds = false
        button.isSelected = true
        self.applyStyle(to: button, level: level, selected: true)
        return button
    }

    private func applyStyle(to button: UIButton, level: STLogLevel, selected: Bool) {
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.tinted()
            config.title = "\(level.icon) \(level.rawValue)"
            config.imagePadding = 4
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 14)
            let foregroundColor: UIColor = selected ? .white : level.color
            let backgroundColor = selected ? level.color : level.color.withAlphaComponent(0.12)
            let titleText = "\(level.icon) \(level.rawValue)"
            let attributedTitle = AttributedString(titleText, attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 13, weight: selected ? .semibold : .medium),
                .foregroundColor: foregroundColor
            ]))
            config.attributedTitle = attributedTitle
            config.baseForegroundColor = foregroundColor
            config.baseBackgroundColor = backgroundColor
            config.background.strokeColor = selected ? level.color : level.color.withAlphaComponent(0.2)
            config.background.strokeWidth = selected ? 0 : 1
            button.configuration = config
        } else {
            button.setTitle("\(level.icon) \(level.rawValue)", for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
            button.layer.cornerRadius = 16
            button.layer.borderWidth = selected ? 0 : 1
            button.layer.borderColor = level.color.withAlphaComponent(0.4).cgColor
            button.backgroundColor = selected ? level.color : level.color.withAlphaComponent(0.1)
            button.setTitleColor(selected ? .white : level.color, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: selected ? .semibold : .regular)
        }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var bottomToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        let backItem = UIBarButtonItem(title: "返回", style: .plain, target: self, action: #selector(backBtnClick))
        let cleanItem = UIBarButtonItem(title: "清除", style: .plain, target: self, action: #selector(cleanLogBtnClick))
        let filterItem = UIBarButtonItem(title: "过滤", style: .plain, target: self, action: #selector(filterBtnClick))
        let exportItem = UIBarButtonItem(title: "导出", style: .plain, target: self, action: #selector(exportBtnClick))
        let outputItem = UIBarButtonItem(title: "输出", style: .plain, target: self, action: #selector(outputLogBtnClick))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [backItem, flexibleSpace, cleanItem, flexibleSpace, filterItem, flexibleSpace, exportItem, flexibleSpace, outputItem]
        return toolbar
    }()
    
    @objc private func filterLevelButtonTapped(_ sender: UIButton) {
        let level = STLogLevel.allCases[sender.tag]
        if self.selectedLogLevels.contains(level) {
            self.selectedLogLevels.remove(level)
        } else {
            self.selectedLogLevels.insert(level)
        }
        self.updateFilterButtons()
        self.performFilter()
    }
}

// MARK: - TableView 代理方法
extension STLogView: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentLogEntries.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "STLogTableViewCell", for: indexPath) as! STLogTableViewCell
        let logEntry = self.currentLogEntries[indexPath.row]
        cell.configure(with: logEntry)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - 搜索栏代理方法
extension STLogView: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        self.performFilter()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        self.clearFilter()
    }
}

// MARK: - 自定义日志 Cell
private class STLogTableViewCell: UITableViewCell {
    
    private let levelLabel = UILabel()
    private let timestampLabel = UILabel()
    private let fileLabel = UILabel()
    private let messageLabel = UILabel()
    private let stackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupUI()
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        // 配置标签
        self.levelLabel.font = UIFont.boldSystemFont(ofSize: 12)
        self.levelLabel.textAlignment = .center
        self.levelLabel.layer.cornerRadius = 8
        self.levelLabel.clipsToBounds = true
        
        self.timestampLabel.font = UIFont.systemFont(ofSize: 10)
        self.timestampLabel.textColor = .secondaryLabel
        
        self.fileLabel.font = UIFont.systemFont(ofSize: 11)
        self.fileLabel.textColor = .secondaryLabel
        
        self.messageLabel.font = UIFont.systemFont(ofSize: 13)
        self.messageLabel.numberOfLines = 0
        
        // 配置堆栈视图
        self.stackView.axis = .vertical
        self.stackView.spacing = 4
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.addArrangedSubview(self.levelLabel)
        self.stackView.addArrangedSubview(self.timestampLabel)
        self.stackView.addArrangedSubview(self.fileLabel)
        self.stackView.addArrangedSubview(self.messageLabel)
        self.contentView.addSubview(self.stackView)
        
        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            self.stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            self.stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            self.stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            self.levelLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with logEntry: STLogEntry) {
        self.levelLabel.text = "\(logEntry.level.icon) \(logEntry.level.rawValue)"
        self.levelLabel.backgroundColor = logEntry.level.color.withAlphaComponent(0.2)
        self.levelLabel.textColor = logEntry.level.color
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        self.timestampLabel.text = formatter.string(from: logEntry.timestamp)
        
        self.fileLabel.text = "\(logEntry.file):\(logEntry.line) - \(logEntry.function)"
        self.messageLabel.text = logEntry.message
        
        self.backgroundColor = .secondarySystemBackground
        self.levelLabel.backgroundColor = logEntry.level.color.withAlphaComponent(0.2)
        self.timestampLabel.textColor = .secondaryLabel
        self.fileLabel.textColor = .secondaryLabel
        self.messageLabel.textColor = .label
    }
}

// MARK: - 公共方法
extension STLogView {
    
    /// 获取日志输出路径
    public class func st_outputLogPath() -> String {
        return STLogManager.st_outputLogPath()
    }
    
    /// 将日志写入文件
    public class func st_logWriteToFile() {
        let userDefault = UserDefaults.standard
        let path = STLogManager.st_outputLogPath()
        if let originalContent = userDefault.object(forKey: path) as? String {
            STFileManager.st_writeToFile(content: originalContent, filePath: path)
        }
    }

    /// 获取日志查询通知名称
    public class func st_notificationQueryLogName() -> String {
        return STLogManager.st_notificationQueryLogName()
    }
    
    /// 获取当前日志数量
    public func st_getLogCount() -> Int {
        return self.currentLogEntries.count
    }
    
    /// 获取过滤后的日志数量
    public func st_getFilteredLogCount() -> Int {
        return self.filteredLogEntries.count
    }
    
    /// 获取所有日志数量
    public func st_getAllLogCount() -> Int {
        return self.allLogEntries.count
    }
    
    /// 清空所有日志
    public func st_clearAllLogs() {
        self.clearAllLogs()
    }
    
    /// 导出当前显示的日志
    public func st_exportCurrentLogs() {
        self.exportLogs()
    }
    
    /// 设置日志级别过滤
    public func st_setLogLevelFilter(_ levels: Set<STLogLevel>) {
        self.selectedLogLevels = levels
        self.updateFilterButtons()
        self.performFilter()
    }
    
    /// 设置搜索文本
    public func st_setSearchText(_ text: String) {
        self.searchText = text
        self.searchBar.text = text
        self.performFilter()
    }
    
    /// 获取当前过滤状态
    public func st_isFiltering() -> Bool {
        return self.isFiltering
    }
    
    /// 获取当前选中的日志级别
    public func st_getSelectedLogLevels() -> Set<STLogLevel> {
        return self.selectedLogLevels
    }
    
    /// 获取当前搜索文本
    public func st_getSearchText() -> String {
        return self.searchText
    }
}
