//
//  STLogView.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2018/3/14.
//

import UIKit

public struct STLogEntry {
    public let id: String
    public let timestamp: Date
    public let level: STLogLevel
    public let file: String
    public let function: String
    public let line: Int
    public let message: String
    public let rawContent: String
    public let label: String
    public let metadata: [String: String]
    public let thread: String

    init(
        id: String,
        timestamp: Date,
        level: STLogLevel,
        file: String,
        function: String,
        line: Int,
        message: String,
        rawContent: String,
        label: String,
        metadata: [String: String],
        thread: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.file = file
        self.function = function
        self.line = line
        self.message = message
        self.rawContent = rawContent
        self.label = label
        self.metadata = metadata
        self.thread = thread
    }

    init(record: STLogRecord) {
        self.init(
            id: record.id,
            timestamp: record.timestamp,
            level: record.level,
            file: record.fileName,
            function: record.function,
            line: record.line,
            message: STLogEntry.prettyMessage(from: record.message),
            rawContent: record.formatted(multiline: true),
            label: record.label,
            metadata: record.metadata,
            thread: record.thread
        )
    }

    static func prettyMessage(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if let data = trimmed.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data, options: []),
           JSONSerialization.isValidJSONObject(object),
           let prettyData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }
        return trimmed
    }
}

public protocol STLogViewDelegate: NSObjectProtocol {
    func logViewBackBtnClick()
    func logViewDidFilterLogs(with results: [STLogEntry])
}

open class STLogView: UIView {

    private struct QueryState: Equatable {
        var searchText: String = ""
        var selectedLogLevels: Set<STLogLevel> = Set(STLogLevel.allCases)

        var normalizedSearchText: String {
            self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var isFiltering: Bool {
            !self.normalizedSearchText.isEmpty || self.selectedLogLevels.count < STLogLevel.allCases.count
        }
    }

    open weak var mDelegate: STLogViewDelegate?

    private let pageSize = 100
    private var currentPage = 0
    private var hasMorePages = true
    private var isLoadingPage = false
    private var allLogEntries: [STLogEntry] = []
    private var displayedLogEntries: [STLogEntry] = []
    private var queryState = QueryState()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.configUI()
        self.setupNotifications()
        self.loadInitialLogs()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.configUI()
        self.setupNotifications()
        self.loadInitialLogs()
    }

    private func configUI() {
        self.backgroundColor = .systemBackground
        self.addSubview(self.searchBar)
        self.addSubview(self.filterView)
        self.addSubview(self.tableView)
        self.addSubview(self.bottomToolbar)
        self.setupConstraints()
        self.setupKeyboardDismissInteraction()
        self.tableView.register(STLogTableViewCell.self, forCellReuseIdentifier: "STLogTableViewCell")
    }

    private func setupKeyboardDismissInteraction() {
        self.tableView.keyboardDismissMode = .onDrag
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(endEditingFromTap))
        tapGesture.cancelsTouchesInView = false
        self.addGestureRecognizer(tapGesture)
    }

    @objc private func endEditingFromTap() {
        self.endEditing(true)
    }

    private func setupConstraints() {
        self.searchBar.translatesAutoresizingMaskIntoConstraints = false
        self.filterView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.bottomToolbar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.searchBar.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            self.searchBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.searchBar.trailingAnchor.constraint(equalTo: trailingAnchor),

            self.filterView.topAnchor.constraint(equalTo: self.searchBar.bottomAnchor, constant: 8),
            self.filterView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.filterView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.filterView.heightAnchor.constraint(equalToConstant: 50),

            self.tableView.topAnchor.constraint(equalTo: self.filterView.bottomAnchor, constant: 8),
            self.tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.bottomToolbar.topAnchor, constant: -8),

            self.bottomToolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.bottomToolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.bottomToolbar.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            self.bottomToolbar.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(beginQueryLogP(notification:)),
            name: NSNotification.Name(rawValue: STLogManager.didAppendRecordNotification),
            object: nil
        )
    }

    private func loadInitialLogs() {
        self.currentPage = 0
        self.allLogEntries.removeAll()
        self.displayedLogEntries.removeAll()
        self.loadPage(reset: true)
    }

    private func loadPage(reset: Bool) {
        guard !self.isLoadingPage else { return }
        self.isLoadingPage = true
        let requestPage = reset ? 0 : self.currentPage
        let requestState = self.queryState
        let requestLevels = requestState.isFiltering ? requestState.selectedLogLevels : nil
        let requestSearch = requestState.isFiltering ? requestState.normalizedSearchText : nil

        DispatchQueue.global(qos: .utility).async {
            let records = STLogManager.records(page: requestPage, pageSize: self.pageSize, levels: requestLevels, searchText: requestSearch)
            let entries = records.map(STLogEntry.init(record:))
            let hasMore = STLogManager.hasMoreRecords(page: requestPage, pageSize: self.pageSize, levels: requestLevels, searchText: requestSearch)

            DispatchQueue.main.async {
                guard self.queryState == requestState else {
                    self.isLoadingPage = false
                    return
                }

                if reset {
                    if requestState.isFiltering {
                        self.displayedLogEntries = entries
                    } else {
                        self.allLogEntries = entries
                        self.displayedLogEntries = self.allLogEntries
                    }
                } else {
                    if requestState.isFiltering {
                        self.displayedLogEntries.append(contentsOf: entries)
                    } else {
                        self.allLogEntries.append(contentsOf: entries)
                        self.displayedLogEntries = self.allLogEntries
                    }
                }
                self.currentPage = requestPage + 1
                self.hasMorePages = hasMore
                self.isLoadingPage = false
                self.tableView.reloadData()
                self.mDelegate?.logViewDidFilterLogs(with: self.displayedLogEntries)
            }
        }
    }

    private func applyFilter(reset: Bool = true) {
        if self.queryState.isFiltering {
            if reset {
                self.currentPage = 0
                self.displayedLogEntries = []
                self.tableView.reloadData()
            }
            self.loadPage(reset: reset)
        } else if reset {
            self.displayedLogEntries = self.allLogEntries
            self.tableView.reloadData()
            self.loadInitialLogs()
        }
    }

    @objc private func beginQueryLogP(notification: Notification) {
        guard !self.queryState.isFiltering, let record = notification.object as? STLogRecord else { return }
        let applyUpdate = {
            let entry = STLogEntry(record: record)
            self.allLogEntries.insert(entry, at: 0)
            if self.allLogEntries.count > STLogManager.configuration.retainedLogCountForDisplay {
                self.allLogEntries.removeLast(self.allLogEntries.count - STLogManager.configuration.retainedLogCountForDisplay)
            }
            self.displayedLogEntries = self.allLogEntries
            self.tableView.reloadData()
        }
        if Thread.isMainThread {
            applyUpdate()
        } else {
            DispatchQueue.main.async(execute: applyUpdate)
        }
    }

    @objc private func backBtnClick() {
        self.mDelegate?.logViewBackBtnClick()
    }

    @objc private func cleanLogBtnClick() {
        let alert = UIAlertController(title: "清除日志", message: "确定要清除所有日志吗？此操作不可撤销。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { _ in
            STLogManager.clearAllLogs()
            self.allLogEntries.removeAll()
            self.displayedLogEntries.removeAll()
            self.loadInitialLogs()
        })
        self.getTopViewController()?.present(alert, animated: true)
    }

    @objc private func exportBtnClick() {
        let text = self.displayedLogEntries.map(\.rawContent).joined(separator: "\n\n")
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        self.getTopViewController()?.present(activity, animated: true)
    }

    @objc private func outputLogBtnClick() {
        let paths = STLogManager.allLogFilePaths().map { URL(fileURLWithPath: $0) }
        guard !paths.isEmpty else {
            self.presentAlert(title: "暂无日志", message: "当前没有可导出的日志内容。")
            return
        }
        let activity = UIActivityViewController(activityItems: paths, applicationActivities: nil)
        self.getTopViewController()?.present(activity, animated: true)
    }

    @objc private func filterLevelButtonTapped(_ sender: UIButton) {
        let level = STLogLevel.allCases[sender.tag]
        if self.queryState.selectedLogLevels.contains(level) {
            self.queryState.selectedLogLevels.remove(level)
        } else {
            self.queryState.selectedLogLevels.insert(level)
        }
        self.updateFilterButtons()
        self.applyFilter()
    }

    private func updateFilterButtons() {
        for (index, button) in self.filterButtons.enumerated() {
            guard index < STLogLevel.allCases.count else { continue }
            let level = STLogLevel.allCases[index]
            let selected = self.queryState.selectedLogLevels.contains(level)
            self.applyFilterButtonStyle(button, level: level, selected: selected)
        }
    }

    private func makeFilterButton(level: STLogLevel, index: Int) -> STIconButton {
        let button = STIconButton(type: .system)
        button.tag = index
        button.layer.cornerRadius = 16
        button.layer.borderWidth = 1
        button.layer.masksToBounds = true
        button.contentHorizontalAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        button.titleLabel?.lineBreakMode = .byTruncatingTail
        button.titleLabel?.numberOfLines = 1
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        let heightConstraint = button.heightAnchor.constraint(equalToConstant: 32)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        button.addTarget(self, action: #selector(filterLevelButtonTapped(_:)), for: .touchUpInside)
        button.configure()
            .iconPosition(.left)
            .spacing(6)
            .contentInsets(UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14))
            .done()
        self.applyFilterButtonStyle(button, level: level, selected: true)
        return button
    }

    private func applyFilterButtonStyle(_ button: UIButton, level: STLogLevel, selected: Bool) {
        let foregroundColor = selected ? UIColor.white : level.color
        let backgroundColor = selected ? level.color : level.color.withAlphaComponent(0.12)
        let borderColor = selected ? level.color : level.color.withAlphaComponent(0.35)
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let image = UIImage(systemName: level.systemImageName, withConfiguration: symbolConfig)
        button.setTitle(level.rawValue, for: .normal)
        button.setTitleColor(foregroundColor, for: .normal)
        button.setImage(image, for: .normal)
        button.tintColor = foregroundColor
        button.backgroundColor = backgroundColor
        button.imageView?.contentMode = .scaleAspectFit
        button.layer.borderColor = borderColor.cgColor
    }

    private func getTopViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .default))
        self.getTopViewController()?.present(alert, animated: true)
    }

    private lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "搜索日志 / metadata / label"
        bar.searchBarStyle = .minimal
        bar.delegate = self
        return bar
    }()

    private lazy var filterView: UIView = {
        let view = UIView()
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsHorizontalScrollIndicator = false
        view.addSubview(scroll)
        scroll.addSubview(self.filterStackView)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.filterStackView.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 12),
            self.filterStackView.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -12),
            self.filterStackView.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 8),
            self.filterStackView.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -8),
            self.filterStackView.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor, constant: -16)
        ])
        return view
    }()

    private lazy var filterStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        STLogLevel.allCases.enumerated().forEach { index, level in
            let button = self.makeFilterButton(level: level, index: index)
            self.filterButtons.append(button)
            stack.addArrangedSubview(button)
        }
        self.updateFilterButtons()
        return stack
    }()

    private var filterButtons: [UIButton] = []

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 96
        table.tableFooterView = UIView()
        return table
    }()

    private lazy var bottomToolbar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.addSubview(bottomToolbarStackView)
        NSLayoutConstraint.activate([
            bottomToolbarStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            bottomToolbarStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            bottomToolbarStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            bottomToolbarStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        return view
    }()

    private lazy var bottomToolbarStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            makeToolbarButton(title: "返回", action: #selector(backBtnClick)),
            makeToolbarButton(title: "清除", action: #selector(cleanLogBtnClick)),
            makeToolbarButton(title: "导出文本", action: #selector(exportBtnClick)),
            makeToolbarButton(title: "导出文件", action: #selector(outputLogBtnClick))
        ])
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private func makeToolbarButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.backgroundColor = .secondarySystemBackground
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.separator.cgColor
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
}

extension STLogView: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.displayedLogEntries.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "STLogTableViewCell", for: indexPath) as! STLogTableViewCell
        guard indexPath.row < self.displayedLogEntries.count else { return cell }
        cell.configure(with: self.displayedLogEntries[indexPath.row])
        return cell
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row >= self.displayedLogEntries.count - 10, hasMorePages else { return }
        self.loadPage(reset: false)
    }
}

extension STLogView: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.queryState.searchText = searchText
        self.applyFilter()
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

private final class STLogTableViewCell: UITableViewCell {
    private let levelLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
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
        self.selectionStyle = .none
        self.levelLabel.font = UIFont.boldSystemFont(ofSize: 12)
        self.levelLabel.textAlignment = .center
        self.levelLabel.layer.cornerRadius = 8
        self.levelLabel.clipsToBounds = true
        self.titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        self.titleLabel.textColor = .secondaryLabel
        self.subtitleLabel.font = UIFont.systemFont(ofSize: 11)
        self.subtitleLabel.textColor = .tertiaryLabel
        self.messageLabel.font = UIFont.systemFont(ofSize: 13)
        self.messageLabel.numberOfLines = 0

        self.stackView.axis = .vertical
        self.stackView.spacing = 6
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        [self.levelLabel, self.titleLabel, self.subtitleLabel, self.messageLabel].forEach(self.stackView.addArrangedSubview)
        self.contentView.addSubview(self.stackView)

        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            self.stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            self.stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            self.stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            self.levelLabel.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    func configure(with logEntry: STLogEntry) {
        self.levelLabel.text = "\(logEntry.level.icon) \(logEntry.level.rawValue)"
        self.levelLabel.backgroundColor = logEntry.level.color.withAlphaComponent(0.14)
        self.levelLabel.textColor = logEntry.level.color
        self.titleLabel.text = "\(logEntry.timestamp.formatted("HH:mm:ss.SSS")) · \(logEntry.label) · \(logEntry.thread)"
        self.subtitleLabel.text = "\(logEntry.file):\(logEntry.line) · \(logEntry.function)"
        if logEntry.metadata.isEmpty {
            self.messageLabel.text = logEntry.message
        } else {
            let metadata = logEntry.metadata.sorted { $0.key < $1.key }.map { "[\($0.key): \($0.value)]" }.joined(separator: " ")
            self.messageLabel.text = "\(metadata)\n\(logEntry.message)"
        }
        self.backgroundColor = .secondarySystemBackground
    }
}

extension STLogView {
    public class func logFilePath() -> String {
        STLogManager.logFilePath()
    }

    public class func flushPersistentLogs() {
        STLogManager.flush()
    }

    public func logCount() -> Int {
        self.displayedLogEntries.count
    }

    public func filteredLogCount() -> Int {
        self.queryState.isFiltering ? self.displayedLogEntries.count : 0
    }

    public func allLogCount() -> Int {
        self.allLogEntries.count
    }

    public func clearLogs() {
        STLogManager.clearAllLogs()
        self.loadInitialLogs()
    }

    public func st_exportCurrentLogs() {
        self.exportBtnClick()
    }

    public func st_setLogLevelFilter(_ levels: Set<STLogLevel>) {
        self.queryState.selectedLogLevels = levels
        self.updateFilterButtons()
        self.applyFilter()
    }

    public func st_setSearchText(_ text: String) {
        self.queryState.searchText = text
        self.searchBar.text = text
        self.applyFilter()
    }

    public func st_isFiltering() -> Bool {
        self.queryState.isFiltering
    }

    public func st_getSelectedLogLevels() -> Set<STLogLevel> {
        self.queryState.selectedLogLevels
    }

    public func st_getSearchText() -> String {
        self.queryState.searchText
    }
}
