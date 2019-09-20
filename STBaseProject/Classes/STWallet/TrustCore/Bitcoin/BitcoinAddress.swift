// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

public struct BitcoinAddress: Address, Hashable {
    static let validAddressPrefixes = [
        Bitcoin.MainNet.publicKeyHashAddressPrefix,
        Bitcoin.MainNet.payToScriptHashAddressPrefix,
        Bitcoin.TestNet.publicKeyHashAddressPrefix,
        Bitcoin.TestNet.payToScriptHashAddressPrefix,
    ]

    /// Validates that the raw data is a valid address.
    static public func isValid(data: Data) -> Bool {
        if data.count != Bitcoin.addressSize + 1 {
            return false
        }

        // Verify address prefix
        if !validAddressPrefixes.contains(data[0]) {
            return false
        }

        return true
    }

    /// Validates that the string is a valid address.
    static public func isValid(string: String) -> Bool {
        guard let decoded = Crypto.base58Decode(string, expectedSize: Bitcoin.addressSize + 1) else {
            return false
        }

        // Verify size
        if decoded.count != 1 + Bitcoin.addressSize {
            return false
        }

        // Verify address prefix
        let prefix = decoded[0]
        if !validAddressPrefixes.contains(prefix) {
            return false
        }

        return true
    }

    /// Raw representation of the address.
    public let data: Data

    /// Creates an address from a raw representation.
    public init?(data: Data) {
        if !BitcoinAddress.isValid(data: data) {
            return nil
        }
        self.data = data
    }

    /// Creates an address from a string representation.
    public init?(string: String) {
        guard let decoded = Crypto.base58Decode(string, expectedSize: Bitcoin.addressSize + 1) else {
            return nil
        }
        self.init(data: decoded)
    }

    public var description: String {
        return Crypto.base58Encode(data)
    }

    public var hashValue: Int {
        return data.hashValue
    }

    public static func == (lhs: BitcoinAddress, rhs: BitcoinAddress) -> Bool {
        return lhs.data == rhs.data
    }
}
