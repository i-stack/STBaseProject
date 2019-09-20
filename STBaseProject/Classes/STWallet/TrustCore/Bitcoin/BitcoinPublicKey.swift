// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

public final class BitcoinPublicKey: PublicKey {
    /// Validates that raw data is a valid public key.
    static public func isValid(data: Data) -> Bool {
        if data.count != 33 {
            return false
        }
        return true
    }

    /// Coin this key is for.
    public let coin = Coin.bitcoin

    /// Raw representation of the public key.
    public let data: Data

    /// Address.
    public var address: Address {
        return address(prefix: Bitcoin.MainNet.payToScriptHashAddressPrefix)
    }

    /// Returns the public key address with the given prefix.
    public func address(prefix: UInt8) -> BitcoinAddress {
        let hash = Data([prefix]) + Crypto.sha256ripemd160(data)
        return BitcoinAddress(data: hash)!
    }

    /// Creates a public key from a raw representation.
    public init?(data: Data) {
        if !BitcoinPublicKey.isValid(data: data) {
            return nil
        }
        self.data = data
    }

    public var description: String {
        return address.description
    }
}
