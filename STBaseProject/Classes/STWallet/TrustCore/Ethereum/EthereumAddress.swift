// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation
import TrezorCrypto

/// Ethereum address.
public struct EthereumAddress: Address, Hashable {
    /// Validates that the raw data is a valid address.
    static public func isValid(data: Data) -> Bool {
        return data.count == Ethereum.addressSize
    }

    /// Validates that the string is a valid address.
    static public func isValid(string: String) -> Bool {
        guard let data = Data(hexString: string) else {
            return false
        }
        let eip55String = EthereumAddress.computeEIP55String(for: data)
        return string == eip55String
    }

    /// Raw address bytes, length 20.
    public let data: Data

    /// EIP55 representation of the address.
    public let eip55String: String

    /// Creates an address with `Data`.
    ///
    /// - Precondition: data contains exactly 20 bytes
    public init?(data: Data) {
        if !EthereumAddress.isValid(data: data) {
            return nil
        }
        self.data = data
        eip55String = EthereumAddress.computeEIP55String(for: data)
    }

    /// Creates an address with an hexadecimal string representation.
    public init?(string: String) {
        guard let data = Data(hexString: string), data.count == Ethereum.addressSize else {
            return nil
        }
        self.data = data
        eip55String = EthereumAddress.computeEIP55String(for: data)
    }

    public var description: String {
        return eip55String
    }

    public var hashValue: Int {
        return data.hashValue
    }

    public static func == (lhs: EthereumAddress, rhs: EthereumAddress) -> Bool {
        return lhs.data == rhs.data
    }
}

extension EthereumAddress {
    /// Converts the address to an EIP55 checksumed representation.
    fileprivate static func computeEIP55String(for data: Data) -> String {
        let addressString = data.hexString
        let hashInput = addressString.data(using: .ascii)!
        let hash = Crypto.hash(hashInput).hexString

        var string = "0x"
        for (a, h) in zip(addressString, hash) {
            switch (a, h) {
            case ("0", _), ("1", _), ("2", _), ("3", _), ("4", _), ("5", _), ("6", _), ("7", _), ("8", _), ("9", _):
                string.append(a)
            case (_, "8"), (_, "9"), (_, "a"), (_, "b"), (_, "c"), (_, "d"), (_, "e"), (_, "f"):
                string.append(contentsOf: String(a).uppercased())
            default:
                string.append(contentsOf: String(a).lowercased())
            }
        }

        return string
    }
}
