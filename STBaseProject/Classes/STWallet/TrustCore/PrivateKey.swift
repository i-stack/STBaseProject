// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

public final class PrivateKey: Hashable, CustomStringConvertible {
    /// Validates that raw data is a valid private key.
    static public func isValid(data: Data) -> Bool {
        // Check length
        if data.count != Ethereum.privateKeySize {
            return false
        }

        // Check for zero address
        guard data.contains(where: { $0 != 0 }) else {
            return false
        }

        return true
    }

    /// Raw representation of the private key.
    public private(set) var data: Data

    /// Creates a new private key.
    public init() {
        let privateAttributes: [String: Any] = [
            kSecAttrIsExtractable as String: true,
        ]
        let parameters: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: privateAttributes,
        ]

        guard let privateKey = SecKeyCreateRandomKey(parameters as CFDictionary, nil) else {
            fatalError("Failed to generate key pair")
        }
        guard var keyRepresentation = SecKeyCopyExternalRepresentation(privateKey, nil) as Data? else {
            fatalError("Failed to extract new private key")
        }
        defer {
            keyRepresentation.clear()
        }
        data = Data(keyRepresentation.suffix(32))
    }

    /// Creates a private key from a raw representation.
    public init?(data: Data) {
        if !PrivateKey.isValid(data: data) {
            return nil
        }
        self.data = Data(data)
    }

    deinit {
        // Clear memory
        data.clear()
    }

    /// Public key.
    public func publicKey(for type: BlockchainType) -> PublicKey {
        switch type {
        case .bitcoin:
            return BitcoinPublicKey(data: Crypto.getBitcoinPublicKey(from: data))!
        case .ethereum:
            return EthereumPublicKey(data: Crypto.getEthereumPublicKey(from: data))!
        }
    }

    public var description: String {
        return data.hexString
    }

    public var hashValue: Int {
        return data.hashValue
    }

    public static func == (lhs: PrivateKey, rhs: PrivateKey) -> Bool {
        return lhs.data == rhs.data
    }
}
