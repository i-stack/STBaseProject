//
//  STMarkdownPipeline.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public struct STMarkdownPipelineConfiguration: Sendable {
    public var enableInputSanitizer: Bool
    public var sanitizerRules: [any STMarkdownRule]
    public var debug: Bool
    public var semanticNormalizers: [any STMarkdownSemanticNormalizing]
    /// 解析前修正常见断裂表格（孤立 `|` 行、表内误插空行等），对 LLM 流式输出更友好。
    public var autoFixMalformedTables: Bool

    public init(
        enableInputSanitizer: Bool = true,
        sanitizerRules: [any STMarkdownRule] = STMarkdownInputSanitizer.defaultRules,
        debug: Bool = false,
        semanticNormalizers: [any STMarkdownSemanticNormalizing] = [],
        autoFixMalformedTables: Bool = true
    ) {
        self.enableInputSanitizer = enableInputSanitizer
        self.sanitizerRules = sanitizerRules
        self.debug = debug
        self.semanticNormalizers = semanticNormalizers
        self.autoFixMalformedTables = autoFixMalformedTables
    }
}

public struct STMarkdownPipelineResult: Sendable {
    public let rawMarkdown: String
    public let sanitizedMarkdown: String
    public let appliedRules: [String]
    public let sourceDocument: STMarkdownDocument
    public let normalizedDocument: STMarkdownDocument
    public let renderDocument: STMarkdownRenderDocument
    /// 从 ``renderDocument`` 抽取的目录（对齐对比文档 P1）；与富文本 ``NSAttributedString.Key.stMarkdownHeadingAnchor`` 一致。
    public let tableOfContents: [STMarkdownTOCItem]

    public init(
        rawMarkdown: String,
        sanitizedMarkdown: String,
        appliedRules: [String],
        sourceDocument: STMarkdownDocument,
        normalizedDocument: STMarkdownDocument,
        renderDocument: STMarkdownRenderDocument,
        tableOfContents: [STMarkdownTOCItem]
    ) {
        self.rawMarkdown = rawMarkdown
        self.sanitizedMarkdown = sanitizedMarkdown
        self.appliedRules = appliedRules
        self.sourceDocument = sourceDocument
        self.normalizedDocument = normalizedDocument
        self.renderDocument = renderDocument
        self.tableOfContents = tableOfContents
    }
}

/// 原始 Markdown 处理顺序：可选输入规整 →（可选）断裂表格预修复 → `swift-markdown` 解析
/// → 语义归一 → 渲染 AST；公式在 ``STMarkdownStructureParser`` 内先于解析做块级抽取。
public final class STMarkdownPipeline: Sendable {
    public let configuration: STMarkdownPipelineConfiguration
    public let parser: any STMarkdownStructureParsing
    public let semanticNormalizer: STMarkdownSemanticNormalizer
    public let renderAdapter: any STMarkdownRenderAdapting

    /// 预先构建的 sanitizer；当配置禁用时为 nil。
    /// 缓存实例可避免高频 `process(_:)` 调用的重复初始化开销。
    private let sanitizer: STMarkdownInputSanitizer?

    public init(
        configuration: STMarkdownPipelineConfiguration = STMarkdownPipelineConfiguration(),
        parser: any STMarkdownStructureParsing = STMarkdownStructureParser(),
        renderAdapter: any STMarkdownRenderAdapting = STMarkdownRenderAdapter()
    ) {
        self.configuration = configuration
        self.parser = parser
        self.semanticNormalizer = STMarkdownSemanticNormalizer(
            normalizers: configuration.semanticNormalizers
        )
        self.renderAdapter = renderAdapter
        self.sanitizer = configuration.enableInputSanitizer
            ? STMarkdownInputSanitizer(rules: configuration.sanitizerRules)
            : nil
    }

    public func process(_ rawMarkdown: String) -> STMarkdownPipelineResult {
        let sanitizationResult: STMarkdownSanitizationResult
        if let sanitizer = self.sanitizer {
            sanitizationResult = sanitizer.sanitize(rawMarkdown, debug: self.configuration.debug)
        } else {
            sanitizationResult = STMarkdownSanitizationResult(
                originalText: rawMarkdown,
                sanitizedText: rawMarkdown,
                appliedRules: []
            )
        }

        let parserInput = STMarkdownMalformedTableNormalizer.normalize(
            sanitizationResult.sanitizedText,
            enabled: self.configuration.autoFixMalformedTables
        )
        let sourceDocument = self.parser.parse(parserInput)
        let normalizedDocument = self.semanticNormalizer.normalize(sourceDocument)
        let renderDocument = self.renderAdapter.adapt(normalizedDocument)
        let tableOfContents = STMarkdownTOCExtraction.items(from: renderDocument)
        return STMarkdownPipelineResult(
            rawMarkdown: rawMarkdown,
            sanitizedMarkdown: sanitizationResult.sanitizedText,
            appliedRules: sanitizationResult.appliedRules,
            sourceDocument: sourceDocument,
            normalizedDocument: normalizedDocument,
            renderDocument: renderDocument,
            tableOfContents: tableOfContents
        )
    }
}
