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

    public init(
        enableInputSanitizer: Bool = true,
        sanitizerRules: [any STMarkdownRule] = STMarkdownInputSanitizer.defaultRules,
        debug: Bool = false,
        semanticNormalizers: [any STMarkdownSemanticNormalizing] = []
    ) {
        self.enableInputSanitizer = enableInputSanitizer
        self.sanitizerRules = sanitizerRules
        self.debug = debug
        self.semanticNormalizers = semanticNormalizers
    }
}

public struct STMarkdownPipelineResult: Sendable {
    public let rawMarkdown: String
    public let sanitizedMarkdown: String
    public let appliedRules: [String]
    public let sourceDocument: STMarkdownDocument
    public let normalizedDocument: STMarkdownDocument
    public let renderDocument: STMarkdownRenderDocument

    public init(
        rawMarkdown: String,
        sanitizedMarkdown: String,
        appliedRules: [String],
        sourceDocument: STMarkdownDocument,
        normalizedDocument: STMarkdownDocument,
        renderDocument: STMarkdownRenderDocument
    ) {
        self.rawMarkdown = rawMarkdown
        self.sanitizedMarkdown = sanitizedMarkdown
        self.appliedRules = appliedRules
        self.sourceDocument = sourceDocument
        self.normalizedDocument = normalizedDocument
        self.renderDocument = renderDocument
    }
}

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

        let sourceDocument = self.parser.parse(sanitizationResult.sanitizedText)
        let normalizedDocument = self.semanticNormalizer.normalize(sourceDocument)
        let renderDocument = self.renderAdapter.adapt(normalizedDocument)
        return STMarkdownPipelineResult(
            rawMarkdown: rawMarkdown,
            sanitizedMarkdown: sanitizationResult.sanitizedText,
            appliedRules: sanitizationResult.appliedRules,
            sourceDocument: sourceDocument,
            normalizedDocument: normalizedDocument,
            renderDocument: renderDocument
        )
    }
}
