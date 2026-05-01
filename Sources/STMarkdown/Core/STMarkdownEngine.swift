//
//  STMarkdownEngine.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

/// 抽象的 Markdown 处理入口，便于单测/桩替换。
public protocol STMarkdownProcessing {
    /// 将原始 Markdown 文本经过 sanitize → parse → normalize → adapt 流水线后返回结果。
    func process(_ rawMarkdown: String) -> STMarkdownPipelineResult
}

/// 默认的 Markdown 处理引擎。
///
/// 线程安全：仅当传入的 `parser`、`renderAdapter` 与 `configuration` 中的所有
/// rules / normalizers 都满足 `Sendable` 时，本类型才可在多线程并发调用。
/// 框架内置的实现均已满足该约束。
public final class STMarkdownEngine: STMarkdownProcessing, Sendable {
    public let pipeline: STMarkdownPipeline

    public init(
        configuration: STMarkdownPipelineConfiguration = STMarkdownPipelineConfiguration(),
        parser: any STMarkdownStructureParsing = STMarkdownStructureParser(),
        renderAdapter: any STMarkdownRenderAdapting = STMarkdownRenderAdapter()
    ) {
        self.pipeline = STMarkdownPipeline(
            configuration: configuration,
            parser: parser,
            renderAdapter: renderAdapter
        )
    }

    public func process(_ rawMarkdown: String) -> STMarkdownPipelineResult {
        self.pipeline.process(rawMarkdown)
    }
}
