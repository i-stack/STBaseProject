// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import CryptoSwift
import Foundation

/// Encrypted private key and crypto parameters.
public struct KeystoreKeyHeader {
    /// Encrypted data.
    public var cipherText: Data

    /// Cipher algorithm.
    public var cipher: String = "aes-128-ctr"

    /// Cipher parameters.
    public var cipherParams: CipherParams

    /// Key derivation function, must be scrypt.
    public var kdf: String = "scrypt"

    /// Key derivation function parameters.
    public var kdfParams: ScryptParams

    /// Message authentication code.
    public var mac: Data

    /// Initializes a `KeystoreKeyHeader` with standard values.
    public init(cipherText: Data, cipherParams: CipherParams, kdfParams: ScryptParams, mac: Data) {
        self.cipherText = cipherText
        self.cipherParams = cipherParams
        self.kdfParams = kdfParams
        self.mac = mac
    }

    /// Initializes a `KeystoreKeyHeader` by encrypting data with a password with standard values.
    public init(password: String, data: Data) throws {
        let cipherParams = CipherParams()
        let kdfParams = ScryptParams()

        let scrypt = Scrypt(params: kdfParams)
        let derivedKey = try scrypt.calculate(password: password)

        let encryptionKey = derivedKey[0...15]
        let aecCipher = try AES(key: encryptionKey.bytes, blockMode: CTR(iv: cipherParams.iv.bytes), padding: .noPadding)

        let encryptedKey = try aecCipher.encrypt(data.bytes)
        let prefix = derivedKey[(derivedKey.count - 16) ..< derivedKey.count]
        let mac = KeystoreKey.computeMAC(prefix: prefix, key: Data(bytes: encryptedKey))

        self.init(cipherText: Data(bytes: encryptedKey), cipherParams: cipherParams, kdfParams: kdfParams, mac: mac)
    }
}

extension KeystoreKeyHeader: Codable {
    enum CodingKeys: String, CodingKey {
        case cipherText = "ciphertext"
        case cipher
        case cipherParams = "cipherparams"
        case kdf
        case kdfParams = "kdfparams"
        case mac
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        cipherText = try values.decodeHexString(forKey: .cipherText)
        cipher = try values.decode(String.self, forKey: .cipher)
        cipherParams = try values.decode(CipherParams.self, forKey: .cipherParams)
        kdf = try values.decode(String.self, forKey: .kdf)
        kdfParams = try values.decode(ScryptParams.self, forKey: .kdfParams)
        mac = try values.decodeHexString(forKey: .mac)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cipherText.hexString, forKey: .cipherText)
        try container.encode(cipher, forKey: .cipher)
        try container.encode(cipherParams, forKey: .cipherParams)
        try container.encode(kdf, forKey: .kdf)
        try container.encode(kdfParams, forKey: .kdfParams)
        try container.encode(mac.hexString, forKey: .mac)
    }
}

// AES128 parameters.
public struct CipherParams {
    public static let blockSize = 16
    public var iv: Data

    /// Initializes `CipherParams` with a random `iv` for AES 128.
    public init() {
        iv = Data(repeating: 0, count: CipherParams.blockSize)
        let result = iv.withUnsafeMutableBytes { p in
            SecRandomCopyBytes(kSecRandomDefault, CipherParams.blockSize, p)
        }
        precondition(result == errSecSuccess, "Failed to generate random number")
    }
}

extension CipherParams: Codable {
    enum CodingKeys: String, CodingKey {
        case iv
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        iv = try values.decodeHexString(forKey: .iv)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(iv.hexString, forKey: .iv)
    }
}
