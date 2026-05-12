import XCTest
import Contacts
import STContacts

// MARK: - STContactPermissionStatus 映射测试

final class STContactPermissionStatusTests: XCTestCase {

    func testMappingNotDetermined() {
        XCTAssertEqual(STContactPermissionStatus(.notDetermined), .notDetermined)
    }

    func testMappingRestricted() {
        XCTAssertEqual(STContactPermissionStatus(.restricted), .restricted)
    }

    func testMappingDenied() {
        XCTAssertEqual(STContactPermissionStatus(.denied), .denied)
    }

    func testMappingLimited() {
        if #available(iOS 18.0, *) {
            XCTAssertEqual(STContactPermissionStatus(.limited), .limited)
        } else {
            // Fallback on earlier versions
        }
    }

    func testMappingAuthorized() {
        XCTAssertEqual(STContactPermissionStatus(.authorized), .authorized)
    }
}

// MARK: - STContact 模型测试

final class STContactModelTests: XCTestCase {

    func testInitWithAllFields() {
        let contact = STContact(identifier: "id-001", fullName: "张三", phoneNumbers: ["13800138000", "02012345678"])
        XCTAssertEqual(contact.identifier, "id-001")
        XCTAssertEqual(contact.fullName, "张三")
        XCTAssertEqual(contact.phoneNumbers, ["13800138000", "02012345678"])
    }

    func testInitWithNilFullName() {
        let contact = STContact(identifier: "id-002", fullName: nil, phoneNumbers: [])
        XCTAssertEqual(contact.identifier, "id-002")
        XCTAssertNil(contact.fullName)
        XCTAssertTrue(contact.phoneNumbers.isEmpty)
    }

    func testHashableEquality() {
        let a = STContact(identifier: "id-003", fullName: "李四", phoneNumbers: ["13900139000"])
        let b = STContact(identifier: "id-003", fullName: "李四", phoneNumbers: ["13900139000"])
        XCTAssertEqual(a, b)
    }

    func testHashableInequality() {
        let a = STContact(identifier: "id-004", fullName: "王五", phoneNumbers: [])
        let b = STContact(identifier: "id-005", fullName: "王五", phoneNumbers: [])
        XCTAssertNotEqual(a, b)
    }

    func testUsableInSet() {
        let a = STContact(identifier: "dup", fullName: "赵六", phoneNumbers: [])
        let b = STContact(identifier: "dup", fullName: "赵六", phoneNumbers: [])
        let set: Set<STContact> = [a, b]
        XCTAssertEqual(set.count, 1)
    }
}

// MARK: - STContactError 测试

final class STContactErrorTests: XCTestCase {

    func testPermissionDeniedDescription() {
        let error = STContactError.permissionDenied
        XCTAssertNotNil(error.errorDescription)
    }

    func testFetchFailedDescription() {
        let underlying = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "底层错误"])
        let error = STContactError.fetchFailed(underlying)
        XCTAssertEqual(error.errorDescription, "底层错误")
    }

    func testFetchFailedPreservesUnderlyingError() {
        let underlying = NSError(domain: "com.test", code: 99, userInfo: nil)
        if case .fetchFailed(let wrapped) = STContactError.fetchFailed(underlying) {
            XCTAssertEqual((wrapped as NSError).code, 99)
        } else {
            XCTFail("应为 fetchFailed case")
        }
    }
}

// MARK: - STContactServiceProtocol Mock 测试

private final class MockContactService: STContactServiceProtocol {
    var permissionStatus: STContactPermissionStatus = .authorized
    var stubbedContacts: [STContact] = []
    var stubbedError: Error? = nil

    func requestPermissionAndFetch() async throws -> [STContact] {
        if let error = self.stubbedError { throw error }
        return self.stubbedContacts
    }
}

final class STContactServiceProtocolTests: XCTestCase {

    func testFetchReturnsStubContacts() async throws {
        let mock = MockContactService()
        mock.stubbedContacts = [
            STContact(identifier: "m-001", fullName: "Mock 张三", phoneNumbers: ["100"]),
            STContact(identifier: "m-002", fullName: nil, phoneNumbers: [])
        ]
        let results = try await mock.requestPermissionAndFetch()
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].identifier, "m-001")
        XCTAssertNil(results[1].fullName)
    }

    func testFetchThrowsPermissionDenied() async {
        let mock = MockContactService()
        mock.stubbedError = STContactError.permissionDenied
        do {
            _ = try await mock.requestPermissionAndFetch()
            XCTFail("应抛出 permissionDenied 错误")
        } catch STContactError.permissionDenied {
            // 预期路径
        } catch {
            XCTFail("抛出了非预期错误: \(error)")
        }
    }

    func testFetchThrowsFetchFailed() async {
        let mock = MockContactService()
        let underlying = NSError(domain: "net", code: 500, userInfo: nil)
        mock.stubbedError = STContactError.fetchFailed(underlying)
        do {
            _ = try await mock.requestPermissionAndFetch()
            XCTFail("应抛出 fetchFailed 错误")
        } catch STContactError.fetchFailed(let err) {
            XCTAssertEqual((err as NSError).code, 500)
        } catch {
            XCTFail("抛出了非预期错误: \(error)")
        }
    }

    func testPermissionStatusExposedByProtocol() {
        let mock = MockContactService()
        mock.permissionStatus = .denied
        let service: any STContactServiceProtocol = mock
        XCTAssertEqual(service.permissionStatus, .denied)
    }

    func testEmptyResultWhenNoContacts() async throws {
        let mock = MockContactService()
        mock.stubbedContacts = []
        let results = try await mock.requestPermissionAndFetch()
        XCTAssertTrue(results.isEmpty)
    }
}

// MARK: - STContactService 单例与实例化测试

final class STContactServiceInstanceTests: XCTestCase {

    func testSharedIsSingleton() {
        let a = STContactService.shared
        let b = STContactService.shared
        XCTAssertTrue(a === b)
    }

    func testCustomInstanceIsIndependent() {
        let custom = STContactService()
        XCTAssertFalse(custom === STContactService.shared)
    }

    func testPermissionStatusReturnsKnownCase() {
        let status = STContactService.shared.permissionStatus
        let validCases: [STContactPermissionStatus] = [.notDetermined, .restricted, .denied, .limited, .authorized]
        XCTAssertTrue(validCases.contains(status))
    }
}
