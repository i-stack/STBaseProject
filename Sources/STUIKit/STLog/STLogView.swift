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
        self.backgroundColor = .systemGroupedBackground
        self.addSubview(self.tableView)
        self.addSubview(self.bottomToolbar)
        self.setupConstraints()
        self.tableView.register(STLogTableViewCell.self, forCellReuseIdentifier: "STLogTableViewCell")
    }

    private func setupConstraints() {
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.bottomToolbar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.bottomToolbar.topAnchor),

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
                    // 基于偏移的分页在实时追加后会产生边界重复，按 id 去重消除
                    let existingIds = Set(self.allLogEntries.map(\.id))
                    let deduplicated = entries.filter { !existingIds.contains($0.id) }
                    if requestState.isFiltering {
                        self.displayedLogEntries.append(contentsOf: deduplicated)
                    } else {
                        self.allLogEntries.append(contentsOf: deduplicated)
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
            // 幂等校验：分页 reset 可能已包含该记录，避免通知与磁盘读取重复
            guard !self.allLogEntries.contains(where: { $0.id == entry.id }) else { return }
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

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 130
        table.tableFooterView = UIView()
        table.separatorStyle = .none
        table.backgroundColor = .systemGroupedBackground
        return table
    }()

    private lazy var bottomToolbar: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separator)
        view.addSubview(self.bottomToolbarStackView)
        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: view.topAnchor),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            self.bottomToolbarStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            self.bottomToolbarStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            self.bottomToolbarStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            self.bottomToolbarStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])
        return view
    }()

    private lazy var bottomToolbarStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            self.makeToolbarButton(title: "返回", action: #selector(backBtnClick)),
            self.makeToolbarButton(title: "清除", action: #selector(cleanLogBtnClick)),
            self.makeToolbarButton(title: "导出文本", action: #selector(exportBtnClick)),
            self.makeToolbarButton(title: "导出文件", action: #selector(outputLogBtnClick))
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

// MARK: - STLogTableViewCell

private final class STLogTableViewCell: UITableViewCell {

    private let cardView = UIView()
    private let colorBarView = UIView()
    private let contentStack = UIStackView()
    private let headerRow = UIStackView()
    private let levelBadge = UILabel()
    private let timestampLabel = UILabel()
    private let sourceLabel = UILabel()
    private let locationLabel = UILabel()
    private let metadataLabel = UILabel()
    private let divider = UIView()
    private let messageLabel = UILabel()

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
        self.backgroundColor = .clear

        self.cardView.layer.cornerRadius = 10
        self.cardView.layer.masksToBounds = true
        self.cardView.backgroundColor = .secondarySystemBackground
        self.cardView.translatesAutoresizingMaskIntoConstraints = false

        self.colorBarView.translatesAutoresizingMaskIntoConstraints = false

        self.levelBadge.font = UIFont.boldSystemFont(ofSize: 11)
        self.levelBadge.textAlignment = .center
        self.levelBadge.layer.cornerRadius = 8
        self.levelBadge.clipsToBounds = true
        self.levelBadge.setContentHuggingPriority(.required, for: .horizontal)
        self.levelBadge.setContentCompressionResistancePriority(.required, for: .horizontal)

        self.timestampLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        self.timestampLabel.textColor = .secondaryLabel
        self.timestampLabel.textAlignment = .right

        self.headerRow.axis = .horizontal
        self.headerRow.spacing = 8
        self.headerRow.alignment = .center
        [self.levelBadge, self.timestampLabel].forEach(self.headerRow.addArrangedSubview)

        self.sourceLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        self.sourceLabel.textColor = .secondaryLabel

        self.locationLabel.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        self.locationLabel.textColor = .tertiaryLabel
        self.locationLabel.numberOfLines = 2

        self.metadataLabel.font = UIFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        self.metadataLabel.textColor = .secondaryLabel
        self.metadataLabel.numberOfLines = 0

        self.divider.backgroundColor = .separator

        self.messageLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        self.messageLabel.numberOfLines = 0
        self.messageLabel.textColor = .label

        self.contentStack.axis = .vertical
        self.contentStack.spacing = 4
        self.contentStack.translatesAutoresizingMaskIntoConstraints = false
        [self.headerRow, self.sourceLabel, self.locationLabel, self.metadataLabel, self.divider, self.messageLabel]
            .forEach(self.contentStack.addArrangedSubview)
        self.contentStack.setCustomSpacing(6, after: self.headerRow)
        self.contentStack.setCustomSpacing(2, after: self.sourceLabel)
        self.contentStack.setCustomSpacing(8, after: self.locationLabel)
        self.contentStack.setCustomSpacing(8, after: self.metadataLabel)
        self.contentStack.setCustomSpacing(8, after: self.divider)

        self.cardView.addSubview(self.colorBarView)
        self.cardView.addSubview(self.contentStack)
        self.contentView.addSubview(self.cardView)

        NSLayoutConstraint.activate([
            self.cardView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 5),
            self.cardView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 12),
            self.cardView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -12),
            self.cardView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -5),

            self.colorBarView.topAnchor.constraint(equalTo: self.cardView.topAnchor),
            self.colorBarView.leadingAnchor.constraint(equalTo: self.cardView.leadingAnchor),
            self.colorBarView.bottomAnchor.constraint(equalTo: self.cardView.bottomAnchor),
            self.colorBarView.widthAnchor.constraint(equalToConstant: 4),

            self.contentStack.topAnchor.constraint(equalTo: self.cardView.topAnchor, constant: 10),
            self.contentStack.leadingAnchor.constraint(equalTo: self.colorBarView.trailingAnchor, constant: 10),
            self.contentStack.trailingAnchor.constraint(equalTo: self.cardView.trailingAnchor, constant: -12),
            self.contentStack.bottomAnchor.constraint(equalTo: self.cardView.bottomAnchor, constant: -10),

            self.divider.heightAnchor.constraint(equalToConstant: 0.5),
            self.levelBadge.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(with entry: STLogEntry) {
        let levelColor = entry.level.color
        self.colorBarView.backgroundColor = levelColor

        self.levelBadge.text = "  \(entry.level.icon) \(entry.level.rawValue)  "
        self.levelBadge.backgroundColor = levelColor.withAlphaComponent(0.15)
        self.levelBadge.textColor = levelColor

        self.timestampLabel.text = entry.timestamp.formatted("yyyy-MM-dd HH:mm:ss.SSS")

        self.sourceLabel.text = "[\(entry.label)]  \(entry.thread)"

        self.locationLabel.text = "\(entry.file):\(entry.line)  ·  \(entry.function)"

        if entry.metadata.isEmpty {
            self.metadataLabel.isHidden = true
        } else {
            self.metadataLabel.isHidden = false
            self.metadataLabel.text = entry.metadata
                .sorted { $0.key < $1.key }
                .map { "[\($0.key): \($0.value)]" }
                .joined(separator: "  ")
        }

        self.messageLabel.text = entry.message
    }
}

// MARK: - Public API

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
        self.applyFilter()
    }

    public func st_setSearchText(_ text: String) {
        self.queryState.searchText = text
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
