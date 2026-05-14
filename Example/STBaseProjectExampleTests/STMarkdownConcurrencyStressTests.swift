import XCTest
@testable import STBaseProject

/// 对照对比文档 P1：在 ``parseLock`` 存在的前提下，多队列并发调用 ``STMarkdownPipeline/process`` 应可完成且无崩溃。
final class STMarkdownConcurrencyStressTests: XCTestCase {

    func testConcurrentPipelineProcessCompletes() {
        let pipeline = STMarkdownPipeline(configuration: STMarkdownPipelineConfiguration(enableInputSanitizer: false))
        let md = """
        # Title

        Body with [^fn].

        [^fn]: Definition line.
        """
        let group = DispatchGroup()
        let queueCount = 12
        let iterationsPerQueue = 40
        for _ in 0..<queueCount {
            DispatchQueue.global().async(group: group) {
                for _ in 0..<iterationsPerQueue {
                    let result = pipeline.process(md)
                    XCTAssertFalse(result.renderDocument.blocks.isEmpty)
                }
            }
        }
        let wait = group.wait(timeout: .now() + 60)
        XCTAssertEqual(wait, .success)
    }
}
