// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import BigInt
import Foundation

/// Encodes ERC20 function calls.
public final class ERC20Encoder {
    /// Encodes a function call to `totalSupply`
    ///
    /// Solidity function: `function totalSupply() public constant returns (uint);`
    public static func encodeTotalSupply() -> Data {
        let function = Function(name: "totalSupply", parameters: [])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [])
        return encoder.data
    }

    /// Encodes a function call to `name`
    ///
    /// Solidity function: `string public constant name = "Token Name";`
    public static func encodeName() -> Data {
        let function = Function(name: "name", parameters: [])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [])
        return encoder.data
    }

    /// Encodes a function call to `symbol`
    ///
    /// Solidity function: `string public constant symbol = "SYM";`
    public static func encodeSymbol() -> Data {
        let function = Function(name: "symbol", parameters: [])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [])
        return encoder.data
    }

    /// Encodes a function call to `decimals`
    ///
    /// Solidity function: `uint8 public constant decimals = 18;`
    public static func encodeDecimals() -> Data {
        let function = Function(name: "decimals", parameters: [])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [])
        return encoder.data
    }

    /// Encodes a function call to `balanceOf`
    ///
    /// Solidity function: `function balanceOf(address tokenOwner) public constant returns (uint balance);`
    public static func encodeBalanceOf(address: EthereumAddress) -> Data {
        let function = Function(name: "balanceOf", parameters: [.address])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [address])
        return encoder.data
    }

    /// Encodes a function call to `allowance`
    ///
    /// Solidity function: `function allowance(address tokenOwner, address spender) public constant returns (uint remaining);`
    public static func encodeAllowance(owner: EthereumAddress, spender: EthereumAddress) -> Data {
        let function = Function(name: "allowance", parameters: [.address, .address])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [owner, spender])
        return encoder.data
    }

    /// Encodes a function call to `transfer`
    ///
    /// Solidity function: `function transfer(address to, uint tokens) public returns (bool success);`
    public static func encodeTransfer(to: EthereumAddress, tokens: BigUInt) -> Data {
        let function = Function(name: "transfer", parameters: [.address, .uint(bits: 256)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [to, tokens])
        return encoder.data
    }

    /// Encodes a function call to `approve`
    ///
    /// Solidity function: `function approve(address spender, uint tokens) public returns (bool success);`
    public static func encodeApprove(spender: EthereumAddress, tokens: BigUInt) -> Data {
        let function = Function(name: "approve", parameters: [.address, .uint(bits: 256)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [spender, tokens])
        return encoder.data
    }

    /// Encodes a function call to `transferFrom`
    ///
    /// Solidity function: `function transferFrom(address from, address to, uint tokens) public returns (bool success);`
    public static func encodeTransfer(from: EthereumAddress, to: EthereumAddress, tokens: BigUInt) -> Data {
        let function = Function(name: "transferFrom", parameters: [.address, .address, .uint(bits: 256)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [from, to, tokens])
        return encoder.data
    }
}
