//
//  STMarkdownASTAndRenderASTExhaustiveTests.swift
//  STBaseProjectExampleTests
//
//  穷举覆盖 STMarkdownAST.swift / STMarkdownRenderAST.swift 中的公开类型：
//  各 enum case、struct 初始化与计算属性、Hashable / Sendable 可赋值性。
//

import XCTest
import STBaseProject

/// 编译期校验：传入参数必须满足 `Sendable`，否则编译失败。
/// 运行期不做任何断言——`as any Sendable` 后判 `nil` 永远非空，无法验证一致性，
/// `Sendable` 由编译器静态保证。本 helper 仅靠「调用即通过编译」表达契约。
@inline(__always)
private func st_requireSendable<T: Sendable>(_: T) {}

// MARK: - 穷举分支标签（编译器可校验 switch 穷尽性）

private enum InlineCaseTag: String, CaseIterable {
    case text
    case inlineMath
    case emphasis
    case strong
    case code
    case link
    case image
    case softBreak
    case strikethrough
}

private func st_tag(forInline node: STMarkdownInlineNode) -> InlineCaseTag {
    switch node {
    case .text: return .text
    case .inlineMath: return .inlineMath
    case .emphasis: return .emphasis
    case .strong: return .strong
    case .code: return .code
    case .link: return .link
    case .image: return .image
    case .softBreak: return .softBreak
    case .strikethrough: return .strikethrough
    }
}

private enum BlockCaseTag: String, CaseIterable {
    case paragraph
    case heading
    case quote
    case list
    case codeBlock
    case table
    case mathBlock
    case image
    case thematicBreak
}

private func st_tag(forBlock node: STMarkdownBlockNode) -> BlockCaseTag {
    switch node {
    case .paragraph: return .paragraph
    case .heading: return .heading
    case .quote: return .quote
    case .list: return .list
    case .codeBlock: return .codeBlock
    case .table: return .table
    case .mathBlock: return .mathBlock
    case .image: return .image
    case .thematicBreak: return .thematicBreak
    }
}

private enum RenderBlockCaseTag: String, CaseIterable {
    case paragraph
    case heading
    case quote
    case list
    case codeBlock
    case table
    case mathBlock
    case image
    case thematicBreak
}

private func st_tag(forRenderBlock node: STMarkdownRenderBlock) -> RenderBlockCaseTag {
    switch node {
    case .paragraph: return .paragraph
    case .heading: return .heading
    case .quote: return .quote
    case .list: return .list
    case .codeBlock: return .codeBlock
    case .table: return .table
    case .mathBlock: return .mathBlock
    case .image: return .image
    case .thematicBreak: return .thematicBreak
    }
}

// MARK: - Tests

final class STMarkdownASTAndRenderASTExhaustiveTests: XCTestCase {

    // MARK: STMarkdownInlineNode

    func testInlineNodeExhaustiveCasesProduceDistinctTags() {
        let samples: [STMarkdownInlineNode] = [
            .text("a"),
            .inlineMath("x", isDisplayMode: false),
            .inlineMath("y", isDisplayMode: true),
            .emphasis([.text("e")]),
            .strong([.text("s")]),
            .code("c"),
            .link(destination: "https://u", children: [.text("t")]),
            .image(source: "https://i", alt: "alt", title: "ti"),
            .image(source: "https://i2", alt: "a2", title: nil),
            .softBreak,
            .strikethrough([.text("d")]),
        ]
        let tags = samples.map { st_tag(forInline: $0) }
        XCTAssertEqual(Set(tags), Set(InlineCaseTag.allCases))
    }

    func testInlineNodeHashableEqualityAndSendable() {
        let a: STMarkdownInlineNode = .text("z")
        let b: STMarkdownInlineNode = .text("z")
        let c: STMarkdownInlineNode = .text("w")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)

        let nested: STMarkdownInlineNode = .strong([.emphasis([.link(destination: "d", children: [.code("x")])])])
        st_requireSendable(nested)
    }

    // MARK: STMarkdownCheckbox / STMarkdownListKind / STMarkdownColumnAlignment

    func testCheckboxExhaustiveCases() {
        let cases: [STMarkdownCheckbox] = [.checked, .unchecked]
        XCTAssertEqual(Set(cases), Set([STMarkdownCheckbox.checked, .unchecked]))
        st_requireSendable(STMarkdownCheckbox.checked)
    }

    func testListKindExhaustiveCases() {
        let kinds: [STMarkdownListKind] = [.ordered(startIndex: 1), .ordered(startIndex: 7), .unordered]
        XCTAssertTrue(kinds.contains(.unordered))
        XCTAssertTrue(kinds.contains { if case .ordered(let n) = $0 { return n == 7 }; return false })
        st_requireSendable(STMarkdownListKind.unordered)
    }

    func testColumnAlignmentExhaustiveCases() {
        let all: [STMarkdownColumnAlignment] = [.left, .center, .right]
        XCTAssertEqual(Set(all), [.left, .center, .right])
    }

    // MARK: STMarkdownListItemNode

    func testListItemNodeInitializersAndEquality() {
        let a = STMarkdownListItemNode(blocks: [.paragraph([.text("p")])])
        let b = STMarkdownListItemNode(blocks: [.paragraph([.text("p")])], checkbox: nil)
        let c = STMarkdownListItemNode(blocks: [.paragraph([.text("p")])], checkbox: .checked)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    // MARK: STMarkdownTableModel

    func testTableModelTwoInitializersAndColumnAlignments() {
        let cell: [STMarkdownInlineNode] = [.text("c")]
        let row: [[STMarkdownInlineNode]] = [cell]
        let t0 = STMarkdownTableModel(header: [cell], rows: [row])
        XCTAssertTrue(t0.columnAlignments.isEmpty, "双参数 init 应默认空对齐")

        let t1 = STMarkdownTableModel(
            header: nil,
            rows: [row],
            columnAlignments: [.left, .center, .right]
        )
        XCTAssertEqual(t1.columnAlignments, [.left, .center, .right])

        XCTAssertNotEqual(t0, t1)
    }

    /// 不带 alignments 的双参数 init 与带空 alignments 数组的三参数 init 应得到相等模型。
    /// 钉住「默认值漂移」类回归——若实现把双参数 init 默认值改成非空数组，本用例会红字提示。
    func testTableModelDefaultAlignmentsEquivalentToExplicitEmptyAlignments() {
        let cell: [STMarkdownInlineNode] = [.text("c")]
        let row: [[STMarkdownInlineNode]] = [cell]
        let implicit = STMarkdownTableModel(header: [cell], rows: [row])
        let explicit = STMarkdownTableModel(header: [cell], rows: [row], columnAlignments: [])
        XCTAssertEqual(implicit, explicit, "双参数 init 与显式空 alignments 三参数 init 应等价")
    }

    // MARK: STMarkdownBlockNode

    func testBlockNodeExhaustiveCasesProduceDistinctTags() {
        let table = STMarkdownTableModel(header: nil, rows: [[ [.text("a")] ]])
        let samples: [STMarkdownBlockNode] = [
            .paragraph([.text("p")]),
            .heading(level: 3, content: [.text("h")]),
            .quote([.paragraph([.text("q")])]),
            .list(kind: .unordered, items: [STMarkdownListItemNode(blocks: [.paragraph([.text("i")])])]),
            .codeBlock(language: "swift", code: "let x = 0"),
            .codeBlock(language: nil, code: "plain"),
            .table(table),
            .mathBlock("E=mc^2"),
            .image(url: "https://u", altText: "al", title: "t"),
            .image(url: "https://u2", altText: "a2", title: nil),
            .thematicBreak,
        ]
        let tags = samples.map { st_tag(forBlock: $0) }
        XCTAssertEqual(Set(tags), Set(BlockCaseTag.allCases))
    }

    func testBlockNodeHashableNestedStructure() {
        let inner = STMarkdownBlockNode.paragraph([.strong([.text("x")])])
        let doc = STMarkdownDocument(blocks: [.quote([inner, .thematicBreak])])
        let copy = STMarkdownDocument(blocks: [.quote([inner, .thematicBreak])])
        XCTAssertEqual(doc, copy)
    }

    // MARK: STMarkdownDocument

    func testDocumentInitializerAndSendable() {
        let d = STMarkdownDocument(blocks: [.paragraph([])])
        st_requireSendable(d)
        XCTAssertEqual(d.blocks.count, 1)
        if case .paragraph(let inlines)? = d.blocks.first {
            XCTAssertTrue(inlines.isEmpty)
        } else {
            XCTFail("期望单一段落块")
        }
    }

    // MARK: STMarkdownRenderDocument

    func testRenderDocumentInitializerAndEquality() {
        let r = STMarkdownRenderDocument(blocks: [.thematicBreak])
        let same = STMarkdownRenderDocument(blocks: [.thematicBreak])
        XCTAssertEqual(r, same)
        st_requireSendable(r)
    }

    // MARK: STMarkdownRenderBlock

    func testRenderBlockExhaustiveCasesProduceDistinctTags() {
        let table = STMarkdownTableModel(header: [[.text("H")]], rows: [[ [.text("c")] ]])
        let samples: [STMarkdownRenderBlock] = [
            .paragraph([.text("p")]),
            .heading(level: 2, anchorId: "h", content: [.text("h")]),
            .quote([.paragraph([.text("q")])]),
            .list([
                STMarkdownRenderListItem(
                    blocks: [.paragraph([.text("li")])],
                    ordered: false,
                    level: 0,
                    orderedIndex: nil
                ),
            ]),
            .codeBlock(language: "js", code: "1"),
            .codeBlock(language: nil, code: "2"),
            .table(table),
            .mathBlock("a+b"),
            .image(url: "https://img", altText: "x", title: "y"),
            .image(url: "https://img2", altText: "x2", title: nil),
            .thematicBreak,
        ]
        let tags = samples.map { st_tag(forRenderBlock: $0) }
        XCTAssertEqual(Set(tags), Set(RenderBlockCaseTag.allCases))
    }

    // MARK: STMarkdownRenderListItem

    func testRenderListItemDirectInitializerPreservesFields() {
        let item = STMarkdownRenderListItem(
            blocks: [.paragraph([.text("a")]), .codeBlock(language: nil, code: "b")],
            ordered: true,
            level: 2,
            orderedIndex: 9,
            checkbox: .unchecked
        )
        XCTAssertEqual(item.blocks.count, 2)
        XCTAssertTrue(item.ordered)
        XCTAssertEqual(item.level, 2)
        XCTAssertEqual(item.orderedIndex, 9)
        XCTAssertEqual(item.checkbox, .unchecked)
        XCTAssertEqual(item.content, [.text("a")])
        XCTAssertEqual(item.childBlocks.count, 1)
        if case .codeBlock(_, let code)? = item.childBlocks.first {
            XCTAssertEqual(code, "b")
        } else {
            XCTFail("childBlocks 首项应为 codeBlock")
        }
    }

    func testRenderListItemContentInitializerBuildsParagraphPrefix() {
        let item = STMarkdownRenderListItem(
            content: [.text("lead")],
            ordered: false,
            level: 1,
            orderedIndex: nil,
            childBlocks: [.quote([.paragraph([.text("nested")])])],
            checkbox: .checked
        )
        XCTAssertEqual(item.content, [.text("lead")])
        XCTAssertEqual(item.childBlocks.count, 1)
        XCTAssertEqual(item.checkbox, .checked)
        if case .quote(let inner)? = item.childBlocks.first {
            XCTAssertFalse(inner.isEmpty)
        } else {
            XCTFail("期望 childBlocks 首块为 quote")
        }
    }

    func testRenderListItemContentInitializerEmptyContentOnlyAppendsChildBlocks() {
        // content 为空时不会前置合成 paragraph；若 childBlocks 首块非 paragraph，
        // 则 `content` 为空且 `childBlocks` 与 `blocks` 一致。
        let item = STMarkdownRenderListItem(
            content: [],
            ordered: false,
            level: 0,
            orderedIndex: nil,
            childBlocks: [.codeBlock(language: "swift", code: "only-code")],
            checkbox: nil
        )
        XCTAssertEqual(item.blocks, [.codeBlock(language: "swift", code: "only-code")])
        XCTAssertEqual(item.blocks.count, 1)
        XCTAssertTrue(item.content.isEmpty)
        XCTAssertEqual(item.childBlocks, item.blocks)
    }

    /// 空 content 不插入额外段；若 childBlocks 仍以 paragraph 开头，则按 API 契约
    /// `content` 取该段 inlines，`childBlocks` 为剩余块（此处为空）。
    func testRenderListItemContentInitializerEmptyContentWithParagraphFirstChildExposesChildInContent() {
        let item = STMarkdownRenderListItem(
            content: [],
            ordered: false,
            level: 0,
            orderedIndex: nil,
            childBlocks: [.paragraph([.text("only-child")])],
            checkbox: nil
        )
        XCTAssertEqual(item.blocks.count, 1)
        XCTAssertEqual(item.content, [.text("only-child")])
        XCTAssertTrue(item.childBlocks.isEmpty)
    }

    func testRenderListItemNonParagraphFirstContentAndChildBlocksContract() {
        let item = STMarkdownRenderListItem(
            blocks: [.codeBlock(language: "swift", code: "x")],
            ordered: false,
            level: 0,
            orderedIndex: nil
        )
        XCTAssertTrue(item.content.isEmpty)
        XCTAssertEqual(item.childBlocks, item.blocks)
    }

    func testRenderListItemHashable() {
        let a = STMarkdownRenderListItem(blocks: [.paragraph([.text("z")])], ordered: false, level: 0, orderedIndex: nil)
        let b = STMarkdownRenderListItem(blocks: [.paragraph([.text("z")])], ordered: false, level: 0, orderedIndex: nil)
        XCTAssertEqual(a, b)
    }
}
