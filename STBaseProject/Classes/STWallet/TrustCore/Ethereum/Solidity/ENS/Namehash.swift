// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-137.md
public func namehash(_ name: String) -> Data {
    var node = [UInt8].init(repeating: 0x0, count: 32)
    if !name.isEmpty {
        node = name.split(separator: ".")
            .map { Array($0.utf8).sha3() }
            .reversed()
            .reduce(node) { return ($0 + $1).sha3() }
    }
    return Data(node)
}

public func labelhash(_ label: String) -> Data {
    guard let data = label.data(using: .utf8) else {
        return Data()
    }
    return Crypto.hash(data)
}
