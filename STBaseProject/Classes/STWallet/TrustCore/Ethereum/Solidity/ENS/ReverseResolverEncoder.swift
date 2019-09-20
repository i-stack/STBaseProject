// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

/// Encodes ReverseResolver function calls.
/// https://github.com/ethereum/ens/blob/master/contracts/DefaultReverseResolver.sol
public final class ReverseResolverEncoder {
    /// Encodes a function call to `ens`
    ///
    /// Solidity function: `ENS public ens;`
    public static func encodeENS() -> Data {
        let function = Function(name: "ens", parameters: [])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [])
        return encoder.data
    }

    /// Encodes a function call to `name`
    ///
    /// Solidity function: `mapping (bytes32 => string) public name;`
    public static func encodeName(_ name: Data) -> Data {
        let function = Function(name: "name", parameters: [.bytes(32)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [name])
        return encoder.data
    }

    /// Encodes a function call to `setName`
    ///
    /// Solidity function: `function setName(bytes32 node, string _name) public owner_only(node);`
    public static func encodeSetName(_ node: Data, name: String) -> Data {
        let function = Function(name: "setName", parameters: [.bytes(32), .string])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [node, name])
        return encoder.data
    }
}
