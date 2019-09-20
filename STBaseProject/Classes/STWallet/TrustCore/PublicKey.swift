// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

public protocol PublicKey: CustomStringConvertible {
    /// Validates that raw data is a valid public key.
    static func isValid(data: Data) -> Bool

    /// Coin this public key is for.
    var coin: Coin { get }

    /// Raw representation of the public key.
    var data: Data { get }

    /// Address.
    var address: Address { get }

    /// Creates a public key from a raw representation.
    init?(data: Data)
}
