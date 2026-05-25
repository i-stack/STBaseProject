import CryptoKit
import XCTest
import STBaseProject
@testable import STBaseProjectExample

final class STSecurityTests: XCTestCase {
    private var keychainTestKeys: [String] = []

    override func tearDown() {
        for key in keychainTestKeys {
            try? STKeychainHelper.st_delete(key)
        }
        keychainTestKeys.removeAll()
        try? STKeychainHelper.st_delete("ssl_pinning_config")
        try? STKeychainHelper.st_delete("encryption_config")
        try? STKeychainHelper.st_delete("anti_debug_config")
        super.tearDown()
    }

    private func trackKeychainKey(_ key: String) {
        keychainTestKeys.append(key)
    }

    // MARK: - STKeychainHelper

    func testKeychainSaveLoadStringRoundTrip() throws {
        let key = "st_security_tests_string_\(UUID().uuidString)"
        trackKeychainKey(key)
        let value = "value-测试-\(UUID().uuidString)"
        try STKeychainHelper.st_save(key, value: value)
        XCTAssertTrue(STKeychainHelper.st_exists(key))
        let loaded = try STKeychainHelper.st_load(key)
        XCTAssertEqual(loaded, value)
        try STKeychainHelper.st_delete(key)
        XCTAssertFalse(STKeychainHelper.st_exists(key))
        keychainTestKeys.removeAll { $0 == key }
    }

    func testKeychainBoolIntDoubleAndData() throws {
        let base = UUID().uuidString
        let kBool = "st_security_tests_bool_\(base)"
        let kInt = "st_security_tests_int_\(base)"
        let kDouble = "st_security_tests_double_\(base)"
        let kData = "st_security_tests_data_\(base)"
        [kBool, kInt, kDouble, kData].forEach(trackKeychainKey)

        try STKeychainHelper.st_saveBool(kBool, value: true)
        XCTAssertTrue(try STKeychainHelper.st_loadBool(kBool))
        try STKeychainHelper.st_saveInt(kInt, value: -42)
        XCTAssertEqual(try STKeychainHelper.st_loadInt(kInt), -42)
        try STKeychainHelper.st_saveDouble(kDouble, value: 3.14159)
        XCTAssertEqual(try STKeychainHelper.st_loadDouble(kDouble), 3.14159, accuracy: 1e-9)

        let payload = Data([0x00, 0xFF, 0x0A])
        try STKeychainHelper.st_saveData(kData, data: payload)
        XCTAssertEqual(try STKeychainHelper.st_loadData(kData), payload)
    }

    func testKeychainSaveBatchGetAllKeysDeleteBatch() throws {
        let id = UUID().uuidString
        let k1 = "st_security_tests_batch_a_\(id)"
        let k2 = "st_security_tests_batch_b_\(id)"
        trackKeychainKey(k1)
        trackKeychainKey(k2)

        try STKeychainHelper.st_saveBatch([
            k1: "one",
            k2: 2,
        ])
        let all = try STKeychainHelper.st_getAllKeys()
        XCTAssertTrue(all.contains(k1))
        XCTAssertTrue(all.contains(k2))
        XCTAssertEqual(try STKeychainHelper.st_load(k1), "one")
        XCTAssertEqual(try STKeychainHelper.st_loadInt(k2), 2)

        try STKeychainHelper.st_deleteBatch([k1, k2])
        XCTAssertFalse(STKeychainHelper.st_exists(k1))
        XCTAssertFalse(STKeychainHelper.st_exists(k2))
        keychainTestKeys.removeAll { $0 == k1 || $0 == k2 }
    }

    func testKeychainItemCountReflectsOperations() throws {
        let key = "st_security_tests_count_\(UUID().uuidString)"
        trackKeychainKey(key)
        try STKeychainHelper.st_save(key, value: "x")
        let afterAdd = try STKeychainHelper.st_getItemCount()
        XCTAssertGreaterThanOrEqual(afterAdd, 1)
        try STKeychainHelper.st_delete(key)
        keychainTestKeys.removeAll { $0 == key }
    }

    func testKeychainBiometricAPIsReturnConsistentTypes() {
        _ = STKeychainHelper.st_isBiometricAvailable()
        _ = STKeychainHelper.st_getBiometricType()
    }

    func testSTKeychainErrorDescriptions() {
        let e: STKeychainError = .itemNotFound
        XCTAssertFalse((e.errorDescription ?? "").isEmpty)
    }

    // MARK: - STEncrypt / STEncryptionUtils

    func testStringHashesMatchExpectedFormats() {
        XCTAssertEqual("hello".st_md5(), "5d41402abc4b2a76b9719d911017c592")
        XCTAssertEqual("hello".st_sha256().count, 64)
        XCTAssertEqual("hello".st_sha1().count, 40)
        XCTAssertEqual("hello".st_sha384().count, 96)
        XCTAssertEqual("hello".st_sha512().count, 128)
    }

    func testDataHashDelegatesToSameHexFormat() {
        let d = Data("hello".utf8)
        XCTAssertEqual(d.st_hash(algorithm: .md5), "hello".st_md5())
    }

    func testHMACSHA256IsStableForSameInputs() {
        let msg = "payload"
        let key = "secret"
        let a = msg.st_hmacSha256(key: key)
        let b = msg.st_hmacSha256(key: key)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.count, 64)
    }

    func testPBKDF2DerivesExpectedLength() throws {
        let derived = try "password".st_pbkdf2(salt: "salt", iterations: 1000, keyLength: 32)
        XCTAssertEqual(derived.count, 32)
    }

    func testPBKDF2InvalidIterationsThrows() {
        XCTAssertThrowsError(try Data("p".utf8).st_pbkdf2(salt: Data("s".utf8), iterations: 0, keyLength: 32)) { err in
            XCTAssertTrue(err is STCryptoError)
        }
    }

    func testSTEncryptionUtilsKeyStrengthAndSecureCompare() {
        XCTAssertGreaterThan(STEncryptionUtils.st_validateKeyStrength("abcDEF12!"), 0)
        XCTAssertTrue(STEncryptionUtils.st_secureCompare("token", "token"))
        XCTAssertFalse(STEncryptionUtils.st_secureCompare("token", "tokem"))
    }

    func testRandomStringAndHexHelpers() {
        let s = String.st_randomString(length: 16)
        XCTAssertEqual(s.count, 16)
        let hex = String.st_randomHexString(length: 8)
        XCTAssertEqual(hex.count, 8)
    }

    func testDataAES256GCMRoundTripWithCryptoKitTag() throws {
        let key = STEncryptionUtils.st_generateRandomKey(length: 32)
        let plain = Data("round-trip".utf8)
        let symmetricKey = SymmetricKey(data: key)
        let nonce = AES.GCM.Nonce()
        let sealed = try AES.GCM.seal(plain, using: symmetricKey, nonce: nonce)
        let opened = try AES.GCM.open(sealed, using: symmetricKey)
        XCTAssertEqual(opened, plain)
    }

    func testSTCryptoErrorDescription() {
        let e: STCryptoError = .invalidKey
        XCTAssertFalse((e.errorDescription ?? "").isEmpty)
    }

    func testStringAES256GCMRoundTripRequiresTag() throws {
        let key = "12345678901234567890123456789012"
        let encrypted = try "payload".st_encryptAES256GCM(key: key)
        let decrypted = try "payload".st_decryptAES256GCM(
            ciphertext: encrypted.ciphertext,
            key: key,
            nonce: encrypted.nonce,
            tag: encrypted.tag
        )
        XCTAssertEqual(decrypted, "payload")
    }

    // MARK: - STCryptoService

    func testSTCryptoServiceGCMRoundTrip() throws {
        let key = "unit-test-secret-key-string"
        let plain = "你好 NetworkCrypto"
        let enc = try STCryptoService.st_encryptString(plain, keyString: key)
        let dec = try STCryptoService.st_decryptToString(enc, keyString: key)
        XCTAssertEqual(dec, plain)
    }

    func testSTCryptoServiceCBCRoundTrip() throws {
        let key = "cbc-secret-key-pad-32bytes!!"
        let plain = Data("cbc-bytes".utf8)
        let enc = try STCryptoService.st_encryptData(plain, keyString: key, config: .aes256CBC)
        let dec = try STCryptoService.st_decryptData(enc, keyString: key, config: .aes256CBC)
        XCTAssertEqual(dec, plain)
    }

    func testSTCryptoServiceChaCha20RoundTrip() throws {
        let key = "chacha20-secret-key-string"
        let plain = Data("chacha20-bytes".utf8)
        let enc = try STCryptoService.st_encryptData(plain, keyString: key, config: .chaCha20Poly1305)
        let dec = try STCryptoService.st_decryptData(enc, keyString: key, config: .chaCha20Poly1305)
        XCTAssertEqual(dec, plain)
    }

    func testSTCryptoServiceSignAndVerify() {
        let data = Data("sign-me".utf8)
        let secret = "hmac-secret"
        let ts: TimeInterval = 1_700_000_000
        let sig = STCryptoService.st_signData(data, secret: secret, timestamp: ts)
        XCTAssertTrue(STCryptoService.st_verifySignature(data, signature: sig, secret: secret, timestamp: ts))
        XCTAssertFalse(STCryptoService.st_verifySignature(data, signature: sig, secret: "wrong", timestamp: ts))
    }

    func testSTCryptoServiceDictionaryRoundTrip() throws {
        let key = "dict-crypto-key-unique-12345"
        let dict: [String: Any] = ["n": 1, "s": "x", "b": true]
        let enc = try STCryptoService.st_encryptDictionary(dict, keyString: key)
        let out = try STCryptoService.st_decryptToDictionary(enc, keyString: key)
        XCTAssertEqual(out["n"] as? Int, 1)
        XCTAssertEqual(out["s"] as? String, "x")
        XCTAssertEqual(out["b"] as? Bool, true)
    }

    func testSTCryptoServiceEmptyInputThrows() {
        XCTAssertThrowsError(try STCryptoService.st_encryptData(Data(), keyString: "k"))
        XCTAssertThrowsError(try STCryptoService.st_encryptData(Data("a".utf8), keyString: ""))
    }

    func testSTCryptoServiceBatchAndIntegrity() throws {
        let key = "batch-key-\(UUID().uuidString)"
        let parts = [Data("a".utf8), Data("b".utf8)]
        let enc = try STCryptoService.st_encryptBatch(parts, keyString: key)
        let dec = try STCryptoService.st_decryptBatch(enc, keyString: key)
        XCTAssertEqual(dec, parts)
        let one = Data("integrity".utf8)
        let e = try STCryptoService.st_encryptData(one, keyString: key)
        XCTAssertTrue(STCryptoService.st_verifyDataIntegrity(one, encryptedData: e, keyString: key))
        XCTAssertFalse(STCryptoService.st_verifyDataIntegrity(Data("other".utf8), encryptedData: e, keyString: key))
    }

    func testSTCryptoServiceGenerateKeyAndSharedConfig() {
        _ = STCryptoService.st_generateRandomKey()
        _ = STCryptoService.st_generateKey(from: "hello", config: .aes256GCM)

        let crypto = STCryptoService.shared
        crypto.st_setDefaultConfig(.aes256CBC)
        XCTAssertEqual(crypto.st_getDefaultConfig().algorithm, .aes256CBC)
        crypto.st_setDefaultConfig(.aes256GCM)
        crypto.st_clearKeyCache()
    }

    func testSTCryptoServiceEncryptAsync() {
        let key = "async-key-\(UUID().uuidString)"
        let data = Data("async-payload".utf8)
        let exp = expectation(description: "encrypt async")
        STCryptoService.st_encryptDataAsync(data, keyString: key) { result in
            switch result {
            case .success(let enc):
                XCTAssertFalse(enc.isEmpty)
            case .failure:
                XCTFail("expected success")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }

    // MARK: - Security Detection APIs

    func testSecurityDetectionAPIsAreCallable() {
        _ = STSecurityConfig.st_detectProxy()
        _ = STSecurityConfig.st_detectDebugging()
        _ = STDeviceInfo.st_detectJailbreak()
        _ = STDeviceInfo.st_detectSimulator()
        _ = STDeviceInfo.st_detectNetworkConnection()
        _ = STSecurityConfig.st_detectSSLPinning()
        _ = STSecurityConfig.st_detectAppIntegrity()
    }

    func testDetectSSLPinningTracksSessionConfiguration() {
        let disabled = STHTTPSession(sslPinningConfig: STSSLPinningConfig(enabled: false))
        XCTAssertFalse(STSecurityConfig.st_detectSSLPinning(session: disabled))

        let noCertificates = STHTTPSession(sslPinningConfig: STSSLPinningConfig(enabled: true, certificates: [], publicKeyHashes: [], validateHost: true, allowInvalidCertificates: false))
        XCTAssertFalse(STSecurityConfig.st_detectSSLPinning(session: noCertificates))

        let pinned = STHTTPSession(sslPinningConfig: STSSLPinningConfig(enabled: true, certificates: [Data([0x01])], publicKeyHashes: [], validateHost: true, allowInvalidCertificates: false))
        XCTAssertTrue(STSecurityConfig.st_detectSSLPinning(session: pinned))

        let publicKeyPinned = STHTTPSession(sslPinningConfig: STSSLPinningConfig(enabled: true, certificates: [], publicKeyHashes: ["abc"], validateHost: true, allowInvalidCertificates: false))
        XCTAssertTrue(STSecurityConfig.st_detectSSLPinning(session: publicKeyPinned))
    }

    func testSSLPinningConfigPublicKeyHashRejectsInvalidCertificateData() {
        XCTAssertThrowsError(try STSSLPinningConfig.st_publicKeyHash(from: Data([0x00, 0x01, 0x02])))
    }

    func testSimulatorFlagMatchesCompileTarget() {
        #if targetEnvironment(simulator)
        XCTAssertTrue(STDeviceInfo.st_detectSimulator())
        #else
        XCTAssertFalse(STDeviceInfo.st_detectSimulator())
        #endif
    }

    // MARK: - STSecurityConfig & related types

    func testSecurityConfigSaveAndLoadRoundTrip() throws {
        let ssl = STSSLPinningConfig(enabled: false, validateHost: false)
        let enc = STEncryptionConfig(enabled: true, algorithm: .aes256GCM, keyRotationInterval: 3600, enableRequestSigning: true, enableResponseSigning: false)
        let anti = STAntiDebugConfig(enabled: false, checkInterval: 1, enableAntiDebugging: false, enableAntiHooking: true, enableAntiTampering: false)

        let cfg = STSecurityConfig.shared
        try cfg.st_saveSSLPinningConfig(ssl)
        try cfg.st_saveEncryptionConfig(enc)
        try cfg.st_saveAntiDebugConfig(anti)

        XCTAssertEqual(cfg.st_getSSLPinningConfig().enabled, false)
        XCTAssertEqual(cfg.st_getEncryptionConfig().enableResponseSigning, false)
        XCTAssertEqual(cfg.st_getAntiDebugConfig()?.enabled, false)
    }

    func testSecurityConfigAppliesToSharedNetworkRuntime() throws {
        let ssl = STSSLPinningConfig(enabled: true, validateHost: false)
        let enc = STEncryptionConfig(enabled: true, algorithm: .aes256CBC, keyRotationInterval: 60, enableRequestSigning: true, enableResponseSigning: true)

        let cfg = STSecurityConfig.shared
        try cfg.st_saveSSLPinningConfig(ssl)
        try cfg.st_saveEncryptionConfig(enc)
        cfg.st_applySecurityConfiguration()

        XCTAssertTrue(STHTTPSession.shared.sslPinningConfig.enabled)
        XCTAssertEqual(STCryptoService.shared.st_getDefaultConfig().algorithm, .aes256CBC)
    }

    func testPerformSecurityCheckReturnsResult() {
        let result = STSecurityConfig.shared.st_performSecurityCheck()
        XCTAssertEqual(result.isSecure, result.issues.isEmpty)
    }

    func testPerformSecurityCheckIncludesSSLPinningFailureWhenConfigEnabledWithoutPins() throws {
        let cfg = STSecurityConfig.shared
        try cfg.st_saveSSLPinningConfig(STSSLPinningConfig(enabled: true, certificates: [], publicKeyHashes: [], validateHost: true, allowInvalidCertificates: false))
        cfg.st_applySecurityConfiguration()

        let result = cfg.st_performSecurityCheck()
        XCTAssertTrue(result.issues.contains(.sslPinningFailed))
    }

    func testSTSecurityIssueMetadata() {
        XCTAssertEqual(STSecurityIssue.proxyDetected.rawValue, "proxy_detected")
        XCTAssertFalse(STSecurityIssue.jailbreakDetected.description.isEmpty)
        XCTAssertEqual(STSecurityIssue.sslPinningFailed.severity, .critical)
        XCTAssertEqual(STSecurityIssue.simulatorDetected.severity, .medium)
    }

    func testSTSecurityCheckResultInitSetsTimestamp() {
        let r = STSecurityCheckResult(issues: [], isSecure: true)
        XCTAssertTrue(r.isSecure)
        XCTAssertTrue(r.issues.isEmpty)
        XCTAssertLessThanOrEqual(r.timestamp.timeIntervalSinceNow, 1)
    }

    func testSTAntiDebugMonitorStopIsSafe() {
        let m = STAntiDebugMonitor(config: STAntiDebugConfig())
        m.st_stopMonitoring()
        m.st_stopMonitoring()
    }

    func testSTAntiDebugMonitorCallbackIsInvoked() {
        let config = STAntiDebugConfig(
            enabled: true,
            checkInterval: 0.05,
            enableAntiDebugging: true,
            enableAntiHooking: false,
            enableAntiTampering: false
        )
        let issueExp = expectation(description: "issue callback")
        issueExp.assertForOverFulfill = false

        let monitor = STAntiDebugMonitor(
            config: config,
            securityCheck: {
                STSecurityCheckResult(issues: [.debuggingDetected], isSecure: false)
            }
        )
        monitor.onSecurityIssue = { issue in
            XCTAssertEqual(issue, .debuggingDetected)
            issueExp.fulfill()
        }
        monitor.st_startMonitoring()
        wait(for: [issueExp], timeout: 2)
        monitor.st_stopMonitoring()
    }

    func testSecurityConfigCanClearOptionalAntiDebugConfig() throws {
        let cfg = STSecurityConfig.shared
        try cfg.st_saveAntiDebugConfig(STAntiDebugConfig(enabled: false))
        XCTAssertNotNil(cfg.st_getAntiDebugConfig())

        try cfg.st_clearAntiDebugConfig()
        XCTAssertNil(cfg.st_getAntiDebugConfig())
    }

    func testSTSecuritySeverityRawValues() {
        XCTAssertEqual(STSecuritySeverity.critical.rawValue, "critical")
    }

    func testSTCryptoAlgorithmRawValues() {
        XCTAssertEqual(STCryptoAlgorithm.aes256GCM.rawValue, "AES-256-GCM")
        XCTAssertEqual(STCryptoAlgorithm.aes256CBC.rawValue, "AES-256-CBC")
        XCTAssertEqual(STCryptoAlgorithm.chaCha20Poly1305.rawValue, "ChaCha20-Poly1305")
    }

    func testSTEncryptionConfigCodesRoundTripWithEnumAlgorithm() throws {
        let original = STEncryptionConfig(enabled: true, algorithm: .chaCha20Poly1305, keyRotationInterval: 120, enableRequestSigning: false, enableResponseSigning: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(STEncryptionConfig.self, from: data)
        XCTAssertEqual(decoded.algorithm, .chaCha20Poly1305)
        XCTAssertEqual(decoded.keyRotationInterval, 120)
    }
}
