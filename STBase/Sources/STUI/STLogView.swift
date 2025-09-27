//
//  STLogView.swift
//  STBaseProject
//
//  Created by stack on 2018/3/14.
//

import UIKit

// MARK: - 日志级别
public enum STLogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case fatal = "FATAL"
    
    var color: UIColor {
        switch self {
        case .debug: return .systemBlue
        case .info: return .systemGreen
        case .warning: return .systemOrange
        case .error: return .systemRed
        case .fatal: return .systemPurple
        }
    }
    
    var icon: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .fatal: return "💀"
        }
    }
}

// MARK: - 日志条目模型
public struct STLogEntry {
    let id: String
    let timestamp: Date
    let level: STLogLevel
    let file: String
    let function: String
    let line: Int
    let message: String
    let rawContent: String
    
    init(content: String) {
        self.id = UUID().uuidString
        self.rawContent = content
        
        // 解析日志内容
        let components = content.components(separatedBy: "\n")
        if components.count >= 4 {
            // 解析时间戳
            let timestampString = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            self.timestamp = Date() // 简化处理，实际应该解析时间戳
            
            // 解析文件名
            self.file = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 解析函数名
            let functionLine = components[2]
            if functionLine.contains("funcName:") {
                self.function = functionLine.components(separatedBy: "funcName: ").last ?? ""
            } else {
                self.function = ""
            }
            
            // 解析行号
            let lineLine = components[3]
            if lineLine.contains("lineNum:") {
                let lineString = lineLine.components(separatedBy: "lineNum: (").last?.components(separatedBy: ")").first ?? "0"
                self.line = Int(lineString) ?? 0
            } else {
                self.line = 0
            }
            
            // 解析消息
            if components.count > 4 {
                self.message = components[4].components(separatedBy: "message: ").last ?? ""
            } else {
                self.message = ""
            }
        } else {
            self.timestamp = Date()
            self.file = ""
            self.function = ""
            self.line = 0
            self.message = content
        }
        
        // 根据消息内容判断日志级别
        self.level = STLogEntry.detectLogLevel(from: self.message)
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
    func logViewDidSelectLog(_ logEntry: STLogEntry)
    func logViewDidFilterLogs(with results: [STLogEntry])
}

// MARK: - 日志视图主题
public struct STLogViewTheme {
    public var backgroundColor: UIColor = .systemBackground
    public var textColor: UIColor = .label
    public var secondaryTextColor: UIColor = .secondaryLabel
    public var separatorColor: UIColor = .separator
    public var buttonTintColor: UIColor = .systemBlue
    public var searchBarTintColor: UIColor = .systemBlue
    public var cellBackgroundColor: UIColor = .secondarySystemBackground
    public var selectedCellBackgroundColor: UIColor = .systemBlue.withAlphaComponent(0.1)
    
    public static let dark = STLogViewTheme(
        backgroundColor: .black,
        textColor: .white,
        secondaryTextColor: .lightGray,
        separatorColor: .darkGray,
        buttonTintColor: .systemOrange,
        searchBarTintColor: .systemOrange,
        cellBackgroundColor: .darkGray,
        selectedCellBackgroundColor: .systemOrange.withAlphaComponent(0.2)
    )
    
    public static let light = STLogViewTheme(
        backgroundColor: .white,
        textColor: .black,
        secondaryTextColor: .darkGray,
        separatorColor: .lightGray,
        buttonTintColor: .systemBlue,
        searchBarTintColor: .systemBlue,
        cellBackgroundColor: .systemGray6,
        selectedCellBackgroundColor: .systemBlue.withAlphaComponent(0.1)
    )
}

// MARK: - 日志视图
open class STLogView: UIView {
    
    // MARK: - 属性
    
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
    
    private var theme: STLogViewTheme = .light {
        didSet {
            applyTheme()
        }
    }
    
    // MARK: - 初始化
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.configUI()
        self.outputPath = STLogView.st_outputLogPath()
        self.setupNotifications()
        self.loadInitialLogs()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configUI()
        self.outputPath = STLogView.st_outputLogPath()
        self.setupNotifications()
        self.loadInitialLogs()
    }
    
    // MARK: - 配置方法
    
    private func configUI() {
        self.backgroundColor = theme.backgroundColor
        
        // 添加子视图
        self.addSubview(self.searchBar)
        self.addSubview(self.filterView)
        self.addSubview(self.tableView)
        self.addSubview(self.bottomToolbar)
        
        // 设置约束
        self.setupConstraints()
        
        // 应用主题
        self.applyTheme()
        
        // 注册自定义 cell
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
            name: NSNotification.Name(rawValue: STLogView.st_notificationQueryLogName()),
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
    
    private func applyTheme() {
        self.backgroundColor = theme.backgroundColor
        self.searchBar.backgroundColor = theme.backgroundColor
        self.searchBar.tintColor = theme.searchBarTintColor
        self.filterView.backgroundColor = theme.backgroundColor
        self.tableView.backgroundColor = theme.backgroundColor
        self.tableView.separatorColor = theme.separatorColor
        self.bottomToolbar.backgroundColor = theme.backgroundColor
    }
    
    // MARK: - 日志处理方法
    
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
        
        // 如果当前在过滤状态，需要重新过滤
        if isFiltering {
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
    
    // MARK: - 过滤和搜索方法
    
    private func performFilter() {
        var filtered = allLogEntries
        
        // 按日志级别过滤
        if selectedLogLevels.count < STLogLevel.allCases.count {
            filtered = filtered.filter { selectedLogLevels.contains($0.level) }
        }
        
        // 按搜索文本过滤
        if !searchText.isEmpty {
            filtered = filtered.filter { logEntry in
                logEntry.message.lowercased().contains(searchText.lowercased()) ||
                logEntry.file.lowercased().contains(searchText.lowercased()) ||
                logEntry.function.lowercased().contains(searchText.lowercased())
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
        }
    }
    
    // MARK: - 按钮点击事件
    
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
        STLogView.st_logWriteToFile()
        self.mDelegate?.logViewShowDocumentInteractionController()
    }
    
    @objc private func filterBtnClick() {
        self.showFilterOptions()
    }
    
    @objc private func themeBtnClick() {
        self.toggleTheme()
    }
    
    @objc private func exportBtnClick() {
        self.exportLogs()
    }
    
    // MARK: - 辅助方法
    
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
    
    private func toggleTheme() {
        self.theme = (self.theme.backgroundColor == STLogViewTheme.dark.backgroundColor) ? .light : .dark
    }
    
    private func exportLogs() {
        let logsToExport = currentLogEntries
        let logText = logsToExport.map { $0.rawContent }.joined(separator: "\n\n")
        
        let activityViewController = UIActivityViewController(activityItems: [logText], applicationActivities: nil)
        
        if let topViewController = self.getTopViewController() {
            topViewController.present(activityViewController, animated: true)
        }
    }
    
    private func updateFilterButtons() {
        // 更新过滤按钮状态
        for (index, level) in STLogLevel.allCases.enumerated() {
            if index < filterButtons.count {
                let button = filterButtons[index]
                button.isSelected = selectedLogLevels.contains(level)
                button.backgroundColor = button.isSelected ? level.color.withAlphaComponent(0.3) : .clear
            }
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        var topController = UIApplication.shared.windows.first?.rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        return topController
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
        
        // 添加过滤按钮
        for (index, level) in STLogLevel.allCases.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle("\(level.icon) \(level.rawValue)", for: .normal)
            button.setTitleColor(level.color, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            button.layer.cornerRadius = 15
            button.layer.borderWidth = 1
            button.layer.borderColor = level.color.cgColor
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(filterLevelButtonTapped(_:)), for: .touchUpInside)
            button.tag = index
            
            view.addSubview(button)
            filterButtons.append(button)
        }
        
        return view
    }()
    
    private var filterButtons: [UIButton] = []
    
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
        let themeItem = UIBarButtonItem(title: "主题", style: .plain, target: self, action: #selector(themeBtnClick))
        let exportItem = UIBarButtonItem(title: "导出", style: .plain, target: self, action: #selector(exportBtnClick))
        let outputItem = UIBarButtonItem(title: "输出", style: .plain, target: self, action: #selector(outputLogBtnClick))
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbar.items = [backItem, flexibleSpace, cleanItem, flexibleSpace, filterItem, flexibleSpace, themeItem, flexibleSpace, exportItem, flexibleSpace, outputItem]
        
        return toolbar
    }()
    
    @objc private func filterLevelButtonTapped(_ sender: UIButton) {
        let level = STLogLevel.allCases[sender.tag]
        
        if selectedLogLevels.contains(level) {
            selectedLogLevels.remove(level)
        } else {
            selectedLogLevels.insert(level)
        }
        
        updateFilterButtons()
        performFilter()
    }
}

// MARK: - TableView 代理方法
extension STLogView: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentLogEntries.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "STLogTableViewCell", for: indexPath) as! STLogTableViewCell
        let logEntry = currentLogEntries[indexPath.row]
        cell.configure(with: logEntry, theme: theme)
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let logEntry = currentLogEntries[indexPath.row]
        mDelegate?.logViewDidSelectLog(logEntry)
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
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        // 配置标签
        levelLabel.font = UIFont.boldSystemFont(ofSize: 12)
        levelLabel.textAlignment = .center
        levelLabel.layer.cornerRadius = 8
        levelLabel.clipsToBounds = true
        
        timestampLabel.font = UIFont.systemFont(ofSize: 10)
        timestampLabel.textColor = .secondaryLabel
        
        fileLabel.font = UIFont.systemFont(ofSize: 11)
        fileLabel.textColor = .secondaryLabel
        
        messageLabel.font = UIFont.systemFont(ofSize: 13)
        messageLabel.numberOfLines = 0
        
        // 配置堆栈视图
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(levelLabel)
        stackView.addArrangedSubview(timestampLabel)
        stackView.addArrangedSubview(fileLabel)
        stackView.addArrangedSubview(messageLabel)
        
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            levelLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func configure(with logEntry: STLogEntry, theme: STLogViewTheme) {
        levelLabel.text = "\(logEntry.level.icon) \(logEntry.level.rawValue)"
        levelLabel.backgroundColor = logEntry.level.color.withAlphaComponent(0.2)
        levelLabel.textColor = logEntry.level.color
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        timestampLabel.text = formatter.string(from: logEntry.timestamp)
        
        fileLabel.text = "\(logEntry.file):\(logEntry.line) - \(logEntry.function)"
        messageLabel.text = logEntry.message
        
        // 应用主题
        backgroundColor = theme.cellBackgroundColor
        levelLabel.backgroundColor = logEntry.level.color.withAlphaComponent(0.2)
        timestampLabel.textColor = theme.secondaryTextColor
        fileLabel.textColor = theme.secondaryTextColor
        messageLabel.textColor = theme.textColor
    }
}

// MARK: - 公共方法
extension STLogView {
    
    /// 获取日志输出路径
    public class func st_outputLogPath() -> String {
        let outputPath = "\(STFileManager.st_getLibraryCachePath())/outputLog"
        let pathIsExist = STFileManager.st_fileExistAt(path: outputPath)
        if !pathIsExist.0 {
            let _ = STFileManager.st_create(filePath: outputPath, fileName: "log.txt")
        }
        return "\(outputPath)/log.txt"
    }
    
    /// 将日志写入文件
    public class func st_logWriteToFile() {
        let userDefault = UserDefaults.standard
        if let originalContent = userDefault.object(forKey: STLogView.st_outputLogPath()) as? String {
            let path = STFileManager.st_create(filePath: "\(STFileManager.st_getLibraryCachePath())/outputLog", fileName: "log.txt")
            STFileManager.st_writeToFile(content: originalContent, filePath: path)
        }
    }

    /// 获取日志查询通知名称
    public class func st_notificationQueryLogName() -> String {
        return "com.notification.queryLog"
    }
    
    /// 设置主题
    public func st_setTheme(_ theme: STLogViewTheme) {
        self.theme = theme
    }
    
    /// 获取当前日志数量
    public func st_getLogCount() -> Int {
        return currentLogEntries.count
    }
    
    /// 获取过滤后的日志数量
    public func st_getFilteredLogCount() -> Int {
        return filteredLogEntries.count
    }
    
    /// 获取所有日志数量
    public func st_getAllLogCount() -> Int {
        return allLogEntries.count
    }
    
    /// 清空所有日志
    public func st_clearAllLogs() {
        clearAllLogs()
    }
    
    /// 导出当前显示的日志
    public func st_exportCurrentLogs() {
        exportLogs()
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
        return isFiltering
    }
    
    /// 获取当前选中的日志级别
    public func st_getSelectedLogLevels() -> Set<STLogLevel> {
        return selectedLogLevels
    }
    
    /// 获取当前搜索文本
    public func st_getSearchText() -> String {
        return searchText
    }
}
