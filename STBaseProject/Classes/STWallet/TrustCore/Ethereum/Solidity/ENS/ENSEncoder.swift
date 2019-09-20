// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation
import BigInt

/// Encodes EthNameService function calls.
/// https://github.com/ethereum/ens/blob/master/contracts/ENS.sol
/// https://etherscan.io/address/0x314159265dd8dbb310642f98f50c066173c1259b#code
public final class ENSEncoder {
    /// Encodes a function call to `resolver`
    ///
    /// Solidity function: `function resolver(bytes32 node) public view returns (address);`
    public static func encodeResolver(node: Data) -> Data {
        let function = Function(name: "resolver", parameters: [.bytes(32)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [node])
        return encoder.data
    }

    /// Encodes a function call to `setResolver`
    ///
    /// Solidity function: `function setResolver(bytes32 node, address resolver) public;`
    public static func encodeSetResolver(node: Data, resolver: EthereumAddress) -> Data {
        let function = Function(name: "setResolver", parameters: [.bytes(32), .address])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [node, resolver])
        return encoder.data
    }

    /// Encodes a function call to `owner`
    ///
    /// Solidity function: `function owner(bytes32 node) public view returns (address);`
    public static func encodeOwner(node: Data) -> Data {
        let function = Function(name: "owner", parameters: [.bytes(32)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [node])
        return encoder.data
    }

    /// Encodes a function call to `setOwner`
    ///
    /// Solidity function: `function setOwner(bytes32 node, address owner) public;`
    public static func encodeSetOwner(node: Data, owner: EthereumAddress) -> Data {
        let function = Function(name: "setOwner", parameters: [.bytes(32), .address])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [node, owner])
        return encoder.data
    }

    /// Encodes a function call to `ttl`
    ///
    /// Solidity function: `function ttl(bytes32 node) public view returns (uint64);`
    public static func encodeTTL(node: Data) -> Data {
        let function = Function(name: "ttl", parameters: [.bytes(32)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [node])
        return encoder.data
    }

    /// Encodes a function call to `setTTL`
    ///
    /// Solidity function: `function setTTL(bytes32 node, uint64 ttl) public;`
    public static func encodeSetTTL(node: Data, ttl: UInt64) -> Data {
        let function = Function(name: "setTTL", parameters: [.bytes(32), .uint(bits: 64)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [node, BigUInt(ttl)])
        return encoder.data
    }

    /// Encodes a function call to `setSubnodeOwner`
    ///
    /// Solidity function: `function setSubnodeOwner(bytes32 node, bytes32 label, address owner) public;`
    public static func encodeSetSubnodeOwner(node: Data, label: Data, owner: EthereumAddress) -> Data {
        let function = Function(name: "setSubnodeOwner", parameters: [.bytes(32), .bytes(32), .address])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [node, label, owner])
        return encoder.data
    }
}

extension Array where Element == UInt8 {
    /// sha3 keccak 256
    public func sha3() -> [Element] {
        let data = Data(bytes: self)
        let hashed = Crypto.hash(data)
        return Array(hashed)
    }
}
