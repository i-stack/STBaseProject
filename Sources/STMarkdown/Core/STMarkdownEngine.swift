//
//  STMarkdownEngine.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/03/16.
//

import Foundation

public protocol STMarkdownProcessing {
    func process(_ rawMarkdown: String) -> STMarkdownPipelineResult
}

public final class STMarkdownEngine: STMarkdownProcessing, @unchecked Sendable {
    public let pipeline: STMarkdownPipeline

    public init(configuration: STMarkdownPipelineConfiguration = STMarkdownPipelineConfiguration(), parser: any STMarkdownStructureParsing = STMarkdownStructureParser(), renderAdapter: any STMarkdownRenderAdapting = STMarkdownRenderAdapter()) {
        self.pipeline = STMarkdownPipeline(configuration: configuration, parser: parser, renderAdapter: renderAdapter)
    }

    public func process(_ rawMarkdown: String) -> STMarkdownPipelineResult {
        self.pipeline.process(rawMarkdown)
    }
}
