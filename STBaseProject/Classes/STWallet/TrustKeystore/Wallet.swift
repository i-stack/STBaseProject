// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation
//import TrustCore

/// Coin wallet.
public final class Wallet: Hashable {
    /// Unique wallet identifier.
    public let identifier: String

    /// URL for the key file on disk.
    public var keyURL: URL

    /// Encrypted wallet key
    public var key: KeystoreKey

    /// Wallet type.
    public var type: WalletType {
        return key.type
    }

    /// Wallet accounts.
    public internal(set) var accounts = [Account]()

    /// Creates a `Wallet` from an encrypted key.
    public init(keyURL: URL, key: KeystoreKey) {
        identifier = keyURL.lastPathComponent
        self.keyURL = keyURL
        self.key = key
    }

    /// Returns the only account for non HD-wallets.
    ///
    /// - Parameters:
    ///   - password: wallet encryption password
    ///   - type: blockchain type
    /// - Returns: the account
    /// - Throws: `WalletError.invalidKeyType` if this is an HD wallet `DecryptError.invalidPassword` if the
    ///           password is incorrect.
    public func getAccount(password: String, coin: Coin) throws -> Account {
        guard key.type == .encryptedKey else {
            throw WalletError.invalidKeyType
        }

        if let account = accounts.first {
            return account
        }

        guard let address = PrivateKey(data: try key.decrypt(password: password))?.publicKey(for: coin.blockchain.type).address else {
            throw DecryptError.invalidPassword
        }

        let account = Account(wallet: self, address: address, derivationPath: coin.derivationPath(at: 0))
        account.wallet = self
        accounts.append(account)
        return account
    }

    /// Returns accounts for specific derivation paths.
    ///
    /// - Parameters:
    ///   - coin: coin this account is for
    ///   - derivationPaths: array of HD derivation paths
    ///   - password: wallet encryption password
    /// - Returns: the accounts
    /// - Throws: `WalletError.invalidKeyType` if this is not an HD wallet `DecryptError.invalidPassword` if the
    ///           password is incorrect.
    public func getAccounts(derivationPaths: [DerivationPath], password: String) throws -> [Account] {
        guard key.type == .hierarchicalDeterministicWallet else {
            throw WalletError.invalidKeyType
        }

        guard var mnemonic = String(data: try key.decrypt(password: password), encoding: .ascii) else {
            throw DecryptError.invalidPassword
        }
        defer {
            mnemonic.clear()
        }

        var accounts = [Account]()
        let wallet = HDWallet(mnemonic: mnemonic, passphrase: key.passphrase)
        for derivationPath in derivationPaths {
            let coin = Coin(coinType: derivationPath.coinType)
            let account = getAccount(wallet: wallet, coin: coin, derivationPath: derivationPath)
            accounts.append(account)
        }

        return accounts
    }

    private func getAccount(wallet: HDWallet, coin: Coin, derivationPath: DerivationPath) -> Account {
        let address = wallet.getKey(at: derivationPath).publicKey(for: coin.blockchain.type).address

        if let account = accounts.first(where: { $0.derivationPath == derivationPath }) {
            return account
        }

        let account = Account(wallet: self, address: address, derivationPath: derivationPath)
        account.wallet = self
        accounts.append(account)
        return account
    }

    public var hashValue: Int {
        return identifier.hashValue
    }

    public static func == (lhs: Wallet, rhs: Wallet) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

/// Support account types.
public enum WalletType {
    case encryptedKey
    case hierarchicalDeterministicWallet
}

public enum WalletError: LocalizedError {
    case invalidKeyType
}
