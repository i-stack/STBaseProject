// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

/// Coin types for Level 2 of BIP44.
///
/// - SeeAlso: https://github.com/satoshilabs/slips/blob/master/slip-0044.md
public struct Coin: Equatable {
    public var coinType: Int
    public var blockchain: Blockchain

    public init(coinType: Int, blockchain: Blockchain) {
        self.coinType = coinType
        self.blockchain = blockchain
    }

    public init(coinType: Int) {
        self.coinType = coinType
        switch coinType {
        case Coin.bitcoin.coinType, Coin.bitcoinTestNet.coinType:
            blockchain = .bitcoin
        case Coin.ethereumTestNet.coinType:
            blockchain = .ropsten
        case Coin.ethereumClassic.coinType:
            blockchain = .ethereumClassic
        default:
            blockchain = .ethereum
        }
    }
}

extension Coin {
    public static let bitcoin = Coin(coinType: 0, blockchain: .bitcoin)
    public static let bitcoinTestNet = Coin(coinType: 1, blockchain: .bitcoin)

    public static let ethereum = Coin(coinType: 60, blockchain: .ethereum)
    public static let ethereumTestNet = Coin(coinType: 1, blockchain: .ropsten)

    public static let ethereumClassic = Coin(coinType: 61, blockchain: .ethereumClassic)
    public static let poa = Coin(coinType: 178, blockchain: .ethereum)
    public static let callisto = Coin(coinType: 820, blockchain: .ethereum)
    public static let gochain = Coin(coinType: 6060, blockchain: .ethereum)
}
