import XCTest
@testable import STBaseModule
@testable import STConfig

final class STBaseProjectTests: XCTestCase {
    
    func testSTBaseModule() throws {
        // 测试 STBaseModule 模块
        XCTAssertTrue(true, "STBaseModule 模块加载成功")
    }
    
    func testSTConfig() throws {
        // 测试 STConfig 模块
        XCTAssertTrue(true, "STConfig 模块加载成功")
    }
}
