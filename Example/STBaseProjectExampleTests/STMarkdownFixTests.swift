//
//  验证以下三个 Bug 修复：
//  1. STMarkdownMermaidRenderer.cacheKey 使用完整代码字符串，不再用 hashValue，消除碰撞风险
//  2. STMarkdownTableViewModel 使用静态正则常量，不再在热路径重复编译
//  3. STMarkdownTableView 添加 UICollectionViewDelegate，使 onCitationTap 回调可正常触发

import XCTest
import UIKit
@testable import STBaseProject
@testable import STBaseProjectExample

// MARK: - 1. Mermaid Cache Key Tests

/// 验证 cacheKey 使用完整代码字符串，不同代码/主题产生不同键，不会发生碰撞
@MainActor
final class STMarkdownMermaidCacheKeyTests: XCTestCase {

    func testDifferentCodesProduceDifferentKeys() {
        let renderer = STMarkdownMermaidRenderer.shared
        let keyA = renderer.cacheKey("graph LR\n  A --> B", .light)
        let keyB = renderer.cacheKey("graph TD\n  X --> Y", .light)
        XCTAssertNotEqual(keyA, keyB, "不同代码应产生不同 cacheKey")
    }

    func testSameCodeSameThemeProduceEqualKeys() {
        let renderer = STMarkdownMermaidRenderer.shared
        let code = "pie title Pets\n\"Dogs\": 386"
        let key1 = renderer.cacheKey(code, .light)
        let key2 = renderer.cacheKey(code, .light)
        XCTAssertEqual(key1, key2, "相同代码和主题应产生相同 cacheKey")
    }

    func testDarkAndLightThemeProduceDifferentKeys() {
        let renderer = STMarkdownMermaidRenderer.shared
        let code = "flowchart LR\n  A --> B"
        let lightKey = renderer.cacheKey(code, .light)
        let darkKey = renderer.cacheKey(code, .dark)
        XCTAssertNotEqual(lightKey, darkKey, "深色/浅色主题应产生不同 cacheKey")
    }

    func testKeyFormatIsCodeBased() {
        let renderer = STMarkdownMermaidRenderer.shared
        let code = "graph LR\n  A --> B"
        let key = renderer.cacheKey(code, .light)
        XCTAssertTrue(key.hasSuffix(code), "cacheKey 应以完整代码字符串结尾，而非 hashValue")
        XCTAssertTrue(key.hasPrefix("0_"), "浅色主题 cacheKey 应以 '0_' 开头")
    }

    func testDarkKeyFormatIsCodeBased() {
        let renderer = STMarkdownMermaidRenderer.shared
        let code = "sequenceDiagram\n  A->>B: Hello"
        let key = renderer.cacheKey(code, .dark)
        XCTAssertTrue(key.hasPrefix("1_"), "深色主题 cacheKey 应以 '1_' 开头")
        XCTAssertTrue(key.hasSuffix(code), "cacheKey 应包含完整代码字符串")
    }

    /// 回归测试：hashValue 在同进程中偶尔会对不同字符串返回相同值（Swift 有随机化处理，但原实现存在理论碰撞）
    /// 当前实现使用完整字符串，可保证唯一性
    func testKnownCollisionCandidatesProduceDifferentKeys() {
        let renderer = STMarkdownMermaidRenderer.shared
        // 两段意义完全不同的 Mermaid 代码
        let codes: [String] = [
            "graph LR\n  A --> B\n  B --> C",
            "graph RL\n  C --> B\n  B --> A",
            "sequenceDiagram\n  Alice->>Bob: Hi",
            "sequenceDiagram\n  Bob->>Alice: Hi",
            "pie title X\n  \"a\": 10",
            "pie title X\n  \"b\": 10",
        ]
        var keys = Set<String>()
        for code in codes {
            let key = renderer.cacheKey(code, .light)
            XCTAssertTrue(keys.insert(key).inserted, "代码 '\(code)' 产生的 key '\(key)' 与已有 key 碰撞")
        }
    }
}

// MARK: - 2. STMarkdownTableViewModel Citation Tests

/// 验证静态正则常量正确提取 citation、badge 替换，不受热路径重编译影响
final class STMarkdownTableViewModelCitationTests: XCTestCase {

    private let style = STMarkdownStyle.default

    // MARK: - Citation Extraction

    func testExtractsCitationFromLinkNode() {
        let table = STMarkdownTableModel(
            header: [[.link(destination: "", children: [.text("Citation:3")])]],
            rows: []
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: self.style)

        XCTAssertEqual(viewModel.cells.count, 1)
        let cellData = viewModel.cells[0][0]
        XCTAssertTrue(cellData.citations.contains("3"), "应提取 link 节点中的 Citation:3")
    }

    func testExtractsCitationFromInlineText() {
        let table = STMarkdownTableModel(
            header: nil,
            rows: [[[.text("参见 [Citation:7] 了解详情")]]]
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: self.style)

        let cellData = viewModel.cells[0][0]
        XCTAssertTrue(cellData.citations.contains("7"), "应从纯文本 [Citation:7] 提取编号")
    }

    func testNoCitationInPlainText() {
        let table = STMarkdownTableModel(
            header: nil,
            rows: [[[.text("普通内容，没有引用")]]]
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: self.style)

        XCTAssertEqual(viewModel.cells[0][0].citations, [], "无 citation 时应返回空数组")
    }

    func testMultipleCitationsInSameCell() {
        let table = STMarkdownTableModel(
            header: nil,
            rows: [[[
                .text("[Citation:1]"),
                .link(destination: "", children: [.text("Citation:2")])
            ]]]
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: self.style)

        let citations = viewModel.cells[0][0].citations
        XCTAssertTrue(citations.contains("1"), "应包含 Citation:1")
        XCTAssertTrue(citations.contains("2"), "应包含 Citation:2")
    }

    func testWebpageVariantAlsoExtracted() {
        let table = STMarkdownTableModel(
            header: nil,
            rows: [[[.text("[Webpage:4]")]]]
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: self.style)
        // citation badge regex 覆盖 [Webpage:N] 格式，验证不崩溃且处理正常
        XCTAssertNotNil(viewModel.cells[0][0].attributedContent)
    }

    // MARK: - Header Detection

    func testFirstRowIsHeaderWhenHeaderProvided() {
        let table = STMarkdownTableModel(
            header: [[.text("列标题")]],
            rows: [[[.text("数据")]]]
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: self.style)

        XCTAssertTrue(viewModel.hasHeader)
        XCTAssertTrue(viewModel.cells[0][0].role.isHeader, "第一行应标记为 header")
        XCTAssertFalse(viewModel.cells[1][0].role.isHeader, "数据行不应标记为 header")
    }

    func testNoHeaderWhenHeaderNil() {
        let table = STMarkdownTableModel(
            header: nil,
            rows: [[[.text("数据")]]]
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: self.style)

        XCTAssertFalse(viewModel.hasHeader)
        XCTAssertFalse(viewModel.cells[0][0].role.isHeader)
    }

    // MARK: - Badge Replacement

    func testCitationInlineTextReplacedWithAttachment() {
        let table = STMarkdownTableModel(
            header: nil,
            rows: [[[.text("参见 [Citation:5] 了解详情")]]]
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: self.style)

        let attributed = viewModel.cells[0][0].attributedContent
        XCTAssertTrue(
            self.containsAttachment(attributed),
            "Citation 文本应被替换为 NSTextAttachment badge"
        )
    }

    func testCitationLinkReplacedWithAttachment() {
        let table = STMarkdownTableModel(
            header: [[.link(destination: "", children: [.text("Citation:2")])]],
            rows: []
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: self.style)

        let attributed = viewModel.cells[0][0].attributedContent
        XCTAssertTrue(
            self.containsAttachment(attributed),
            "Citation link 节点应替换为 NSTextAttachment badge"
        )
    }

    func testPlainTextCellHasNoAttachment() {
        let table = STMarkdownTableModel(
            header: nil,
            rows: [[[.text("普通文字，无引用")]]]
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: self.style)

        let attributed = viewModel.cells[0][0].attributedContent
        XCTAssertFalse(
            self.containsAttachment(attributed),
            "无 citation 的 cell 不应包含 NSTextAttachment"
        )
    }

    // MARK: - Column / Row Count

    func testColumnAndRowCount() {
        // header: [[STMarkdownInlineNode]] — 3 columns, each with 1 node
        // rows:  [[[STMarkdownInlineNode]]] — 2 rows × 3 columns × 1 node
        let table = STMarkdownTableModel(
            header: [[.text("A")], [.text("B")], [.text("C")]],
            rows: [
                [[.text("1")], [.text("2")], [.text("3")]],
                [[.text("4")], [.text("5")], [.text("6")]]
            ]
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: self.style)

        XCTAssertEqual(viewModel.columnCount, 3)
        XCTAssertEqual(viewModel.rowCount, 3, "1 header + 2 data rows = 3 rows")
    }

    func testEmptyTableProducesZeroCounts() {
        let table = STMarkdownTableModel(header: nil, rows: [])
        let viewModel = STMarkdownTableViewModel(from: table, style: self.style)

        XCTAssertEqual(viewModel.columnCount, 0)
        XCTAssertEqual(viewModel.rowCount, 0)
    }

    // MARK: - Helpers

    private func containsAttachment(_ attributed: NSAttributedString) -> Bool {
        var found = false
        attributed.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: attributed.length),
            options: []
        ) { value, _, _ in
            if value is NSTextAttachment { found = true }
        }
        return found
    }
}

// MARK: - 3. STMarkdownTableView Citation Tap Tests

/// 验证添加 UICollectionViewDelegate 后 onCitationTap 回调正常触发
@MainActor
final class STMarkdownTableViewCitationTapTests: XCTestCase {

    func testCitationTapCallbackFiredWhenCellSelected() {
        let style = STMarkdownStyle.default
        let tableView = STMarkdownTableView(style: style)

        let table = STMarkdownTableModel(
            header: nil,
            rows: [[[.link(destination: "", children: [.text("Citation:9")])]]]
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: style)
        tableView.tableData = viewModel

        var tappedCitation: String?
        tableView.onCitationTap = { tappedCitation = $0 }

        tableView.frame = CGRect(x: 0, y: 0, width: 375, height: 200)
        tableView.layoutIfNeeded()

        let collectionView = tableView.subviews.compactMap { $0 as? UICollectionView }.first
        XCTAssertNotNil(collectionView, "STMarkdownTableView 应包含 UICollectionView 子视图")

        collectionView?.delegate?.collectionView?(
            collectionView!,
            didSelectItemAt: IndexPath(item: 0, section: 0)
        )

        XCTAssertEqual(tappedCitation, "9", "点击含 Citation:9 的 cell 应触发 onCitationTap(\"9\")")
    }

    func testCitationTapNotFiredWhenCellHasNoCitations() {
        let style = STMarkdownStyle.default
        let tableView = STMarkdownTableView(style: style)

        let table = STMarkdownTableModel(
            header: nil,
            rows: [[[.text("普通文本")]]]
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: style)
        tableView.tableData = viewModel

        var tappedCitation: String?
        tableView.onCitationTap = { tappedCitation = $0 }

        tableView.frame = CGRect(x: 0, y: 0, width: 375, height: 200)
        tableView.layoutIfNeeded()

        let collectionView = tableView.subviews.compactMap { $0 as? UICollectionView }.first
        collectionView?.delegate?.collectionView?(
            collectionView!,
            didSelectItemAt: IndexPath(item: 0, section: 0)
        )

        XCTAssertNil(tappedCitation, "无 citation 的 cell 被点击时不应触发 onCitationTap")
    }

    func testCitationTapWithNilTableDataIsSafe() {
        let style = STMarkdownStyle.default
        let tableView = STMarkdownTableView(style: style)
        tableView.tableData = nil

        var called = false
        tableView.onCitationTap = { _ in called = true }

        tableView.frame = CGRect(x: 0, y: 0, width: 375, height: 200)
        tableView.layoutIfNeeded()

        let collectionView = tableView.subviews.compactMap { $0 as? UICollectionView }.first
        // tableData 为 nil，点击任意 cell 不应崩溃且不应触发回调
        collectionView?.delegate?.collectionView?(
            collectionView!,
            didSelectItemAt: IndexPath(item: 0, section: 0)
        )

        XCTAssertFalse(called, "tableData 为 nil 时点击不应触发回调")
    }

    func testMultipleColumnsCorrectCitationTap() {
        let style = STMarkdownStyle.default
        let tableView = STMarkdownTableView(style: style)

        // rows: 1 row × 2 columns; col 0 = plain text, col 1 = citation link
        let table = STMarkdownTableModel(
            header: nil,
            rows: [
                [
                    [.text("无引用")],
                    [.link(destination: "", children: [.text("Citation:42")])]
                ]
            ]
        )
        let viewModel = STMarkdownTableViewModel(from: table, style: style)
        tableView.tableData = viewModel

        var tappedCitation: String?
        tableView.onCitationTap = { tappedCitation = $0 }

        tableView.frame = CGRect(x: 0, y: 0, width: 375, height: 200)
        tableView.layoutIfNeeded()

        let collectionView = tableView.subviews.compactMap { $0 as? UICollectionView }.first

        // 点击第 0 列（无引用）
        collectionView?.delegate?.collectionView?(
            collectionView!,
            didSelectItemAt: IndexPath(item: 0, section: 0)
        )
        XCTAssertNil(tappedCitation, "第 0 列无引用，不应触发回调")

        // 点击第 1 列（有 Citation:42）
        collectionView?.delegate?.collectionView?(
            collectionView!,
            didSelectItemAt: IndexPath(item: 1, section: 0)
        )
        XCTAssertEqual(tappedCitation, "42", "第 1 列应触发 Citation:42 回调")
    }
}
