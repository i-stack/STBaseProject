//
//  STSSEViewController.swift
//  STBaseProjectExample
//
//  Created by 寒江孤影 on 2026/5/22.
//

import UIKit
import STBaseProject

/// 模拟 SSE 三路消息：本地 Bundle 读 data1~3 → Timer 切块 → ``STMarkdownStreamingTextView`` 逐字渲染。
///
/// 使用 ``UITableView`` 做 Cell 复用，避免聊天列表变长后 ``UIScrollView`` 堆叠全部 ``STMarkdownStreamingTextView`` 导致卡顿。
class STSSEViewController: STBaseViewController {

    private struct StreamFixture {
        let name: String
        let content: String
        let blockCount: Int
        let tableOfContentsCount: Int
        var streamedMarkdown: String = ""
        var isCompleted: Bool = false
    }

    private enum ParseValidationError: LocalizedError {
        case emptySourceBlocks(String)
        case emptyRenderBlocks(String)

        var errorDescription: String? {
            switch self {
            case .emptySourceBlocks(let name):
                return "\(name).txt：source AST 为空"
            case .emptyRenderBlocks(let name):
                return "\(name).txt：render AST 为空"
            }
        }
    }

    private static let fixtureNames = ["data1", "data2", "data3"]
    private static let markdownEngine = STMarkdownEngine()

    private let statusLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var fixtures: [StreamFixture] = []
    private var streamingTimer: Timer?
    private var currentFixtureIndex: Int = 0
    private var currentCharacterIndex: Int = 0
    private var isStreaming = false
    private var layoutFlushWorkItem: DispatchWorkItem?
    /// 精确行高缓存；不依赖 `estimatedHeightForRowAt`，由 `heightForRowAt` 唯一决定行高。
    private var rowHeights: [Int: CGFloat] = [:]
    private var lastStatusUpdateUptime: TimeInterval = 0
    private var lastLayoutFlushUptime: TimeInterval = 0
    private var pinsStreamToBottom = true

    /// 逐字输出；TableView 仅用 `rowHeights` + `heightForRowAt` 精确行高（`estimatedRowHeight = 0`）。
    private let streamInterval: TimeInterval = 0.025
    private let streamStep = 1
    private let layoutFlushMinInterval: TimeInterval = 0.5
    private let layoutHeightDeltaThreshold: CGFloat = 36
    private let statusUpdateMinInterval: TimeInterval = 0.3
    private static let placeholderRowHeight: CGFloat = 96

    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = "SSE 流式测试"
        self.view.backgroundColor = .systemBackground

        self.setupStatusLabel()
        self.setupTableView()
        self.addStartButton()
        self.updateStatusLabel(idle: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.stopStreaming()
    }

    // MARK: - UI

    private func setupStatusLabel() {
        self.statusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.statusLabel.font = .systemFont(ofSize: 13, weight: .medium)
        self.statusLabel.textColor = .secondaryLabel
        self.statusLabel.numberOfLines = 2
        self.statusLabel.textAlignment = .center
        self.statusLabel.lineBreakMode = .byTruncatingTail

        self.view.addSubview(self.statusLabel)
        NSLayoutConstraint.activate([
            self.statusLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 8),
            self.statusLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 16),
            self.statusLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -16),
            self.statusLabel.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupTableView() {
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.register(SSEMarkdownCell.self, forCellReuseIdentifier: SSEMarkdownCell.reuseIdentifier)
        self.tableView.rowHeight = UITableView.automaticDimension
        // 关闭 estimated 行高，避免与真实高度不一致时系统校正 contentOffset 造成抖动。
        self.tableView.estimatedRowHeight = 0
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = .systemBackground
        self.tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 100, right: 0)
        self.tableView.contentInsetAdjustmentBehavior = .never

        self.view.addSubview(self.tableView)
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.statusLabel.bottomAnchor, constant: 8),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }

    private func addStartButton() {
        let button = UIButton(type: .system)
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.filled()
            configuration.title = "▶️ 校验并流式展示 3 份资源"
            configuration.baseBackgroundColor = .systemBlue
            configuration.baseForegroundColor = .white
            configuration.cornerStyle = .large
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
            button.configuration = configuration
        } else {
            button.setTitle("▶️ 校验并流式展示 3 份资源", for: .normal)
            button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 12
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        }
        button.addTarget(self, action: #selector(self.startStreaming), for: .touchUpInside)

        self.view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func startStreaming() {
        self.stopStreaming()

        let loadResult = self.loadFixtures()
        guard loadResult.failedNames.isEmpty else {
            self.fixtures = []
            self.tableView.reloadData()
            self.updateStatusLabel(
                message: "资源读取失败：\(loadResult.failedNames.joined(separator: ", "))。请确认文件已加入主工程 Bundle。"
            )
            return
        }

        let validation = Self.validateParse(fixtures: loadResult.fixtures)
        guard validation.errors.isEmpty else {
            self.fixtures = []
            self.tableView.reloadData()
            self.updateStatusLabel(message: "解析校验失败\n" + validation.errors.joined(separator: "\n"))
            return
        }

        self.fixtures = validation.fixtures
        self.currentFixtureIndex = 0
        self.currentCharacterIndex = 0
        self.isStreaming = true
        self.pinsStreamToBottom = true
        self.lastStatusUpdateUptime = 0
        self.lastLayoutFlushUptime = 0
        self.rowHeights.removeAll()

        // 须在 isStreaming = true 之后 reload，否则 visibleRowCount 会先返回 3 再变 1，与后续 beginUpdates 冲突崩溃。
        self.tableView.reloadData()
        self.tableView.layoutIfNeeded()
        self.updateStatusLabel(
            message: "解析校验通过 · \(self.fixtures.count) 份资源 · 共 \(validation.totalRenderBlocks) 个 render block"
        )
        self.beginStreamingFixture(at: 0)
        self.scheduleStreamingTimer()
    }

    private func scheduleStreamingTimer() {
        self.streamingTimer?.invalidate()
        let timer = Timer.scheduledTimer(
            timeInterval: self.streamInterval,
            target: self,
            selector: #selector(self.handleStreamingTick),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        self.streamingTimer = timer
    }

    @objc private func handleStreamingTick() {
        guard self.isStreaming, self.currentFixtureIndex < self.fixtures.count else {
            self.completeAllStreaming()
            return
        }

        let fixture = self.fixtures[self.currentFixtureIndex]
        let characters = Array(fixture.content)
        guard self.currentCharacterIndex < characters.count else {
            self.flushTableLayoutIfNeeded(force: true)

            let finishedRow = self.currentFixtureIndex
            self.finishStreamingFixture(at: finishedRow)
            self.currentFixtureIndex += 1
            self.currentCharacterIndex = 0

            if self.currentFixtureIndex < self.fixtures.count {
                let nextRow = self.currentFixtureIndex
                UIView.performWithoutAnimation {
                    self.tableView.insertRows(at: [IndexPath(row: nextRow, section: 0)], with: .none)
                }
                self.rowHeights[nextRow] = Self.placeholderRowHeight
                self.beginStreamingFixture(at: nextRow)
                if self.pinsStreamToBottom {
                    self.pinTableToBottom(animated: false)
                }
            } else {
                self.completeAllStreaming()
            }
            return
        }

        let end = min(self.currentCharacterIndex + self.streamStep, characters.count)
        let chunk = String(characters[self.currentCharacterIndex..<end])
        self.currentCharacterIndex = end
        self.fixtures[self.currentFixtureIndex].streamedMarkdown += chunk

        if let cell = self.tableView.cellForRow(at: IndexPath(row: self.currentFixtureIndex, section: 0)) as? SSEMarkdownCell {
            cell.appendStreamingChunk(chunk)
        }
        self.scheduleDeferredLayoutFlush()

        let totalChars = characters.count
        self.updateStreamingStatusIfNeeded(
            fixtureName: fixture.name,
            progress: Float(self.currentCharacterIndex) / Float(max(totalChars, 1)),
            fixtureIndex: self.currentFixtureIndex + 1,
            fixtureCount: self.fixtures.count
        )
    }

    private func beginStreamingFixture(at index: Int) {
        guard index < self.fixtures.count else { return }
        let fixture = self.fixtures[index]
        if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SSEMarkdownCell {
            cell.bindFixture(
                name: fixture.name,
                blockCount: fixture.blockCount,
                tableOfContentsCount: fixture.tableOfContentsCount
            )
            cell.startStreaming()
            let tableWidth = self.tableView.bounds.width
            if tableWidth > 0 {
                self.rowHeights[index] = max(
                    self.rowHeights[index] ?? Self.placeholderRowHeight,
                    cell.measuredRowHeight(tableWidth: tableWidth)
                )
            }
        }
    }

    private func finishStreamingFixture(at index: Int) {
        guard index < self.fixtures.count else { return }
        self.fixtures[index].isCompleted = true
        let indexPath = IndexPath(row: index, section: 0)
        if let cell = self.tableView.cellForRow(at: indexPath) as? SSEMarkdownCell {
            cell.finishStreaming(finalMarkdown: self.fixtures[index].content)
            let tableWidth = self.tableView.bounds.width
            if tableWidth > 0 {
                self.rowHeights[index] = cell.measuredRowHeight(tableWidth: tableWidth)
            }
        }
    }

    private func completeAllStreaming() {
        self.isStreaming = false
        self.tableView.reloadData()
        self.tableView.layoutIfNeeded()
        self.stopStreaming(resetFixtures: false)
        self.updateStatusLabel(
            message: "流式展示完成 · \(Self.fixtureNames.count) 份资源已通过 STMarkdown 解析并渲染"
        )
    }

    private func stopStreaming(resetFixtures: Bool = true) {
        self.layoutFlushWorkItem?.cancel()
        self.layoutFlushWorkItem = nil
        self.streamingTimer?.invalidate()
        self.streamingTimer = nil
        self.isStreaming = false
        self.currentFixtureIndex = 0
        self.currentCharacterIndex = 0
        if resetFixtures {
            self.fixtures.removeAll()
            self.tableView.reloadData()
            self.updateStatusLabel(idle: true)
        }
    }

    // MARK: - Resources & Parse

    private func loadFixtures() -> (fixtures: [(name: String, content: String)], failedNames: [String]) {
        var fixtures: [(name: String, content: String)] = []
        var failedNames: [String] = []

        for name in Self.fixtureNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "txt"),
                  let content = try? String(contentsOf: url, encoding: .utf8) else {
                failedNames.append("\(name).txt")
                continue
            }
            fixtures.append((name: name, content: content))
        }

        return (fixtures, failedNames)
    }

    private static func validateParse(
        fixtures: [(name: String, content: String)]
    ) -> (fixtures: [StreamFixture], errors: [String], totalRenderBlocks: Int) {
        var validated: [StreamFixture] = []
        var errors: [String] = []
        var totalBlocks = 0

        for item in fixtures {
            do {
                let fixture = try self.makeValidatedFixture(name: item.name, content: item.content)
                validated.append(fixture)
                totalBlocks += fixture.blockCount
            } catch {
                errors.append(error.localizedDescription)
            }
        }

        return (validated, errors, totalBlocks)
    }

    private static func makeValidatedFixture(name: String, content: String) throws -> StreamFixture {
        let result = self.markdownEngine.process(content)

        guard result.sourceDocument.blocks.isEmpty == false else {
            throw ParseValidationError.emptySourceBlocks(name)
        }
        guard result.renderDocument.blocks.isEmpty == false else {
            throw ParseValidationError.emptyRenderBlocks(name)
        }

        switch name {
        case "data1":
            try self.assertData1Contracts(result: result, name: name)
        case "data2":
            try self.assertData2Contracts(result: result, name: name)
        case "data3":
            try self.assertData3Contracts(result: result, name: name)
        default:
            break
        }

        return StreamFixture(
            name: name,
            content: content,
            blockCount: result.renderDocument.blocks.count,
            tableOfContentsCount: result.tableOfContents.count
        )
    }

    private static func assertData1Contracts(result: STMarkdownPipelineResult, name: String) throws {
        let headings = result.sourceDocument.blocks.compactMap { block -> String? in
            if case .heading(level: _, let content) = block {
                return Self.joinInlineText(content)
            }
            return nil
        }
        guard headings.contains(where: { $0.contains("第一步") }) else {
            throw NSError(domain: "STSSEParse", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(name).txt：缺少「第一步」标题"])
        }
        guard headings.contains(where: { $0.contains("第三步") }) else {
            throw NSError(domain: "STSSEParse", code: 2, userInfo: [NSLocalizedDescriptionKey: "\(name).txt：缺少「第三步」标题"])
        }
    }

    private static func assertData2Contracts(result: STMarkdownPipelineResult, name: String) throws {
        let tables = result.sourceDocument.blocks.compactMap { block -> STMarkdownTableModel? in
            if case .table(let model) = block { return model }
            return nil
        }
        guard tables.count == 1 else {
            throw NSError(domain: "STSSEParse", code: 3, userInfo: [NSLocalizedDescriptionKey: "\(name).txt：应包含 1 个表格，实际 \(tables.count) 个"])
        }
        let headerText = Self.joinInlineText((tables[0].header ?? []).flatMap { $0 })
        guard headerText.contains("类别"), headerText.contains("具体建议") else {
            throw NSError(domain: "STSSEParse", code: 4, userInfo: [NSLocalizedDescriptionKey: "\(name).txt：表格表头字段不完整"])
        }
    }

    private static func assertData3Contracts(result: STMarkdownPipelineResult, name: String) throws {
        let codeBlocks = result.sourceDocument.blocks.compactMap { block -> String? in
            if case .codeBlock(language: _, let code) = block { return code }
            return nil
        }
        guard codeBlocks.count >= 2 else {
            throw NSError(domain: "STSSEParse", code: 5, userInfo: [NSLocalizedDescriptionKey: "\(name).txt：应至少包含 2 个代码块"])
        }
        let rendered = STMarkdownAttributedStringRenderer(style: .default, advancedRenderers: .empty)
            .render(document: result.renderDocument)
            .string
        guard rendered.contains("```") == false else {
            throw NSError(domain: "STSSEParse", code: 6, userInfo: [NSLocalizedDescriptionKey: "\(name).txt：代码围栏定界符泄漏到可见文本"])
        }
    }

    private static func joinInlineText(_ nodes: [STMarkdownInlineNode]) -> String {
        nodes.map { Self.inlinePlainText($0) }.joined()
    }

    private static func inlinePlainText(_ node: STMarkdownInlineNode) -> String {
        switch node {
        case .text(let value):
            return value
        case .softBreak:
            return "\n"
        case .inlineMath(let formula, _):
            return formula
        case .code(let value):
            return value
        case .emphasis(let inner), .strong(let inner), .strikethrough(let inner):
            return self.joinInlineText(inner)
        case .link(_, let inner):
            return self.joinInlineText(inner)
        case .image(_, let alt, _):
            return alt
        case .footnoteReference(let label):
            return "[^\(label)]"
        case .inlineRawHTML(let raw):
            return raw
        }
    }

    // MARK: - Status & Scroll

    private func updateStatusLabel(idle: Bool) {
        if idle {
            self.statusLabel.text = "点击开始：先用 STMarkdownEngine 校验 data1~3，再逐路 SSE 流式渲染"
        }
    }

    private func updateStatusLabel(message: String) {
        self.statusLabel.text = message
    }

    private func updateStreamingStatusIfNeeded(
        fixtureName name: String,
        progress: Float,
        fixtureIndex: Int,
        fixtureCount: Int
    ) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - self.lastStatusUpdateUptime >= self.statusUpdateMinInterval else { return }
        self.lastStatusUpdateUptime = now
        self.statusLabel.text = String(
            format: "流式输出 %@ · 第 %d/%d 路 · %.0f%%",
            name,
            fixtureIndex,
            fixtureCount,
            progress * 100
        )
    }

    private func visibleRowCount() -> Int {
        guard self.isStreaming, self.fixtures.isEmpty == false else {
            return self.fixtures.count
        }
        return min(self.fixtures.count, self.currentFixtureIndex + 1)
    }

    private func flushTableLayoutIfNeeded(force: Bool) {
        guard self.isStreaming else { return }

        let now = ProcessInfo.processInfo.systemUptime
        if force == false, now - self.lastLayoutFlushUptime < self.layoutFlushMinInterval {
            self.scheduleDeferredLayoutFlush()
            return
        }

        self.layoutFlushWorkItem?.cancel()
        self.layoutFlushWorkItem = nil
        self.lastLayoutFlushUptime = now

        let row = self.currentFixtureIndex
        let indexPath = IndexPath(row: row, section: 0)
        guard let cell = self.tableView.cellForRow(at: indexPath) as? SSEMarkdownCell else { return }

        let tableWidth = self.tableView.bounds.width
        guard tableWidth > 0 else { return }

        let measured = cell.measuredRowHeight(tableWidth: tableWidth)
        let previous = self.rowHeights[row] ?? Self.placeholderRowHeight
        let delta = measured - previous

        guard force || abs(delta) >= self.layoutHeightDeltaThreshold else { return }

        let expectedRows = self.visibleRowCount()
        let actualRows = self.tableView.numberOfRows(inSection: 0)
        guard actualRows == expectedRows else {
            self.tableView.reloadData()
            return
        }

        self.rowHeights[row] = measured

        let tableView = self.tableView
        let shouldPin = self.pinsStreamToBottom && self.isViewportNearStreamBottom()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        if shouldPin, delta > 0.5 {
            let insetBottom = tableView.adjustedContentInset.bottom
            let maxOffsetY = max(
                -tableView.adjustedContentInset.top,
                tableView.contentSize.height - tableView.bounds.height + insetBottom
            )
            tableView.contentOffset.y = min(tableView.contentOffset.y + delta, maxOffsetY)
        }
        CATransaction.commit()
    }

    private func isViewportNearStreamBottom(threshold: CGFloat = 120) -> Bool {
        let tableView = self.tableView
        let viewportBottom = tableView.contentOffset.y + tableView.bounds.height - tableView.adjustedContentInset.bottom
        return tableView.contentSize.height - viewportBottom < threshold
    }

    private func pinTableToBottom(animated: Bool) {
        let tableView = self.tableView
        tableView.layoutIfNeeded()
        let insetBottom = tableView.adjustedContentInset.bottom
        let maxOffsetY = max(
            -tableView.adjustedContentInset.top,
            tableView.contentSize.height - tableView.bounds.height + insetBottom
        )
        tableView.setContentOffset(CGPoint(x: 0, y: maxOffsetY), animated: animated)
    }

    private func scheduleDeferredLayoutFlush() {
        guard self.layoutFlushWorkItem == nil else { return }
        let work = DispatchWorkItem { [weak self] in
            self?.flushTableLayoutIfNeeded(force: true)
        }
        self.layoutFlushWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + self.layoutFlushMinInterval, execute: work)
    }
}

// MARK: - UITableView

extension STSSEViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.visibleRowCount()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        self.rowHeights[indexPath.row] ?? Self.placeholderRowHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: SSEMarkdownCell.reuseIdentifier,
            for: indexPath
        ) as! SSEMarkdownCell
        let row = indexPath.row
        let fixture = self.fixtures[row]

        cell.bindFixture(
            name: fixture.name,
            blockCount: fixture.blockCount,
            tableOfContentsCount: fixture.tableOfContentsCount
        )

        if fixture.isCompleted {
            cell.showFinal(markdown: fixture.content)
        } else if row < self.currentFixtureIndex {
            cell.showFinal(markdown: fixture.content)
        } else if row == self.currentFixtureIndex, self.isStreaming {
            if cell.accumulatedMarkdown.isEmpty, fixture.streamedMarkdown.isEmpty == false {
                cell.syncStreamingProgress(fixture.streamedMarkdown)
            }
        } else {
            cell.showPlaceholder()
        }

        return cell
    }
}

// MARK: - UIScrollViewDelegate

extension STSSEViewController: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.pinsStreamToBottom = false
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            self.syncPinsStreamToBottomFromScrollOffset()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.syncPinsStreamToBottomFromScrollOffset()
    }

    private func syncPinsStreamToBottomFromScrollOffset() {
        self.pinsStreamToBottom = self.isViewportNearStreamBottom()
    }
}

// MARK: - SSEMarkdownCell

/// 单路消息 Cell：流式阶段只用 ``appendMarkdownFragment`` 逐字追加，不用智能流式增量合并（避免标题重复）。
private final class SSEMarkdownCell: UITableViewCell {

    static let reuseIdentifier = "SSEMarkdownCell"

    private var boundFixtureName: String?
    private(set) var accumulatedMarkdown: String = ""

    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private var markdownHeightConstraint: NSLayoutConstraint?

    private let markdownView: STMarkdownStreamingTextView = {
        let view = STMarkdownStreamingTextView(
            style: .default,
            advancedRenderers: .empty,
            engine: STMarkdownEngine()
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.isTextSelectionEnabled = true
        view.tokenFadeDuration = 0.06
        view.animateAcrossNewlines = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.selectionStyle = .none

        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        self.titleLabel.textColor = .label

        self.metaLabel.translatesAutoresizingMaskIntoConstraints = false
        self.metaLabel.font = .systemFont(ofSize: 12)
        self.metaLabel.textColor = .secondaryLabel

        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.metaLabel)
        self.contentView.addSubview(self.markdownView)

        NSLayoutConstraint.activate([
            self.titleLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8),
            self.titleLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16),
            self.titleLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16),

            self.metaLabel.topAnchor.constraint(equalTo: self.titleLabel.bottomAnchor, constant: 2),
            self.metaLabel.leadingAnchor.constraint(equalTo: self.titleLabel.leadingAnchor),
            self.metaLabel.trailingAnchor.constraint(equalTo: self.titleLabel.trailingAnchor),

            self.markdownView.topAnchor.constraint(equalTo: self.metaLabel.bottomAnchor, constant: 8),
            self.markdownView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 12),
            self.markdownView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -12)
        ])

        let heightConstraint = self.markdownView.heightAnchor.constraint(equalToConstant: 1)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        self.markdownHeightConstraint = heightConstraint

        self.markdownView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -8).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.boundFixtureName = nil
        self.accumulatedMarkdown = ""
        self.markdownView.reset()
    }

    func bindFixture(name: String, blockCount: Int, tableOfContentsCount: Int) {
        self.titleLabel.text = "\(name).txt"
        self.metaLabel.text = "STMarkdown render blocks: \(blockCount) · TOC: \(tableOfContentsCount)"
        if self.boundFixtureName != name {
            self.boundFixtureName = name
            self.accumulatedMarkdown = ""
            self.markdownView.reset()
        }
    }

    func showPlaceholder() {
        guard self.accumulatedMarkdown.isEmpty == false else { return }
        self.accumulatedMarkdown = ""
        self.markdownView.reset()
    }

    func startStreaming() {
        self.accumulatedMarkdown = ""
        self.markdownView.reset()
        if let shimmer = self.markdownView.contentTextView as? STShimmerTextView {
            shimmer.characterStaggerInterval = 0.002
        }
    }

    /// Cell 滚出屏幕后回屏：仅当与 Model 不一致时恢复，避免打断正在 tick 的 Cell。
    func syncStreamingProgress(_ markdown: String) {
        guard self.accumulatedMarkdown != markdown else { return }
        if markdown.isEmpty {
            self.startStreaming()
            return
        }
        self.accumulatedMarkdown = markdown
        self.markdownView.setMarkdown(markdown, animated: false)
    }

    func appendStreamingChunk(_ chunk: String) {
        guard chunk.isEmpty == false else { return }
        self.accumulatedMarkdown += chunk
        self.markdownView.appendMarkdownFragment(chunk, animated: true)
        self.updateMarkdownHeightConstraintIfNeeded()
    }

    func measuredRowHeight(tableWidth: CGFloat) -> CGFloat {
        let horizontalInset: CGFloat = 12 + 16
        let contentWidth = max(0, tableWidth - horizontalInset * 2)
        self.markdownView.preferredContentWidth = contentWidth
        self.updateMarkdownHeightConstraintIfNeeded()
        self.setNeedsLayout()
        self.layoutIfNeeded()
        let target = CGSize(width: tableWidth, height: UIView.layoutFittingCompressedSize.height)
        return ceil(self.contentView.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height)
    }

    private func updateMarkdownHeightConstraintIfNeeded() {
        let width = self.markdownView.preferredContentWidth > 0
            ? self.markdownView.preferredContentWidth
            : self.markdownView.bounds.width
        guard width > 0 else { return }
        let contentHeight = self.markdownView.sizeThatFitsMarkdown(width: width).height
        guard contentHeight > 0 else { return }
        self.markdownHeightConstraint?.constant = ceil(contentHeight)
    }

    func showFinal(markdown: String) {
        guard self.accumulatedMarkdown != markdown else {
            self.markdownView.finishStreaming()
            return
        }
        self.accumulatedMarkdown = markdown
        self.markdownView.setMarkdown(markdown, animated: false)
        self.markdownView.finishStreaming()
    }

    func finishStreaming(finalMarkdown: String) {
        self.showFinal(markdown: finalMarkdown)
    }
}
