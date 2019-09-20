// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation
//import TrustCore

/// Manages directories of key and wallet files and presents them as accounts.
public final class KeyStore {
    /// The key file directory.
    public let keyDirectory: URL

    /// List of wallets.
    public private(set) var wallets = [Wallet]()

    /// Creates a `KeyStore` for the given directory.
    public init(keyDirectory: URL) throws {
        self.keyDirectory = keyDirectory
        try load()
    }

    private func load() throws {
        let fileManager = FileManager.default
        try? fileManager.createDirectory(at: keyDirectory, withIntermediateDirectories: true, attributes: nil)

        let accountURLs = try fileManager.contentsOfDirectory(at: keyDirectory, includingPropertiesForKeys: [], options: [.skipsHiddenFiles])
        for url in accountURLs {
            do {
                let key = try KeystoreKey(contentsOf: url)
                let wallet = Wallet(keyURL: url, key: key)
                for account in key.activeAccounts {
                    account.wallet = wallet
                    wallet.accounts.append(account)
                }
                wallets.append(wallet)
            } catch {
                // Ignore invalid keys
            }
        }
    }

    /// Creates a new wallet. HD default by default
    public func createWallet(password: String, derivationPaths: [DerivationPath]) throws -> Wallet {
        let key = try KeystoreKey(password: password)
        return try saveCreatedWallet(for: key, password: password, derivationPaths: derivationPaths)
    }

    private func saveCreatedWallet(for key: KeystoreKey, password: String, derivationPaths: [DerivationPath]) throws -> Wallet {
        let url = makeAccountURL()
        let wallet = Wallet(keyURL: url, key: key)
        switch wallet.type {
        case .encryptedKey:
            let _ = try wallet.getAccount(password: password, coin: .ethereum)
        case .hierarchicalDeterministicWallet:
            let _ = try wallet.getAccounts(derivationPaths: derivationPaths, password: password)
        }
        wallets.append(wallet)

        try save(wallet: wallet, in: keyDirectory)

        return wallet
    }

    /// Adds accounts to a wallet.
    public func addAccounts(wallet: Wallet, derivationPaths: [DerivationPath], password: String) throws -> [Account] {
        let accounts = try wallet.getAccounts(derivationPaths: derivationPaths, password: password)
        try save(wallet: wallet, in: wallet.keyURL)
        return accounts
    }

    /// Imports an encrypted JSON key.
    ///
    /// - Parameters:
    /// - json: json wallet
    /// - password: key password
    /// - newPassword: password to use for the imported key
    /// - coin: coin to use for this wallet
    /// - Returns: new account
    public func `import`(json: Data, password: String, newPassword: String, coin: Coin) throws -> Wallet {
        let key = try JSONDecoder().decode(KeystoreKey.self, from: json)
        if let address = key.address, self.account(for: address, type: key.type) != nil {
            throw Error.accountAlreadyExists
        }

        var data = try key.decrypt(password: password)
        defer {
            data.clear()
        }

        switch key.type {
        case .encryptedKey:
            guard let privateKey = PrivateKey(data: data) else {
                throw Error.invalidKey
            }
            return try self.import(privateKey: privateKey, password: newPassword, coin: key.coin ?? coin)
        case .hierarchicalDeterministicWallet:
            guard let mnemonic = String(data: data, encoding: .ascii) else {
                throw EncryptError.invalidMnemonic
            }
            return try self.import(mnemonic: mnemonic, encryptPassword: newPassword, derivationPath: coin.derivationPath(at: 0))
        }
    }

    private func account(for address: Address, type: WalletType) -> Account? {
        return wallets.compactMap({ wallet in
            if wallet.type != type {
                return nil
            }
            return wallet.accounts.first(where: { account in
                account.address.data == address.data
            })
        }).first
    }

    /// Imports a private key.
    ///
    /// - Parameters:
    ///   - privateKey: private key to import
    ///   - password: password to use for the imported private key
    ///   - coin: coin to use for this wallet
    /// - Returns: new wallet
    public func `import`(privateKey: PrivateKey, password: String, coin: Coin) throws -> Wallet {
        let newKey = try KeystoreKey(password: password, key: privateKey, coin: coin)
        let url = makeAccountURL()
        let wallet = Wallet(keyURL: url, key: newKey)
        let _ = try wallet.getAccount(password: password, coin: coin)
        wallets.append(wallet)

        try save(wallet: wallet, in: keyDirectory)

        return wallet
    }

    /// Imports a wallet.
    ///
    /// - Parameters:
    ///   - mnemonic: wallet's mnemonic phrase
    ///   - passphrase: wallet's password
    ///   - encryptPassword: password to use for encrypting
    /// - Returns: new account
    public func `import`(mnemonic: String, passphrase: String = "", encryptPassword: String, derivationPath: DerivationPath) throws -> Wallet {
        if !Crypto.isValid(mnemonic: mnemonic) {
            throw Error.invalidMnemonic
        }

        let key = try KeystoreKey(password: encryptPassword, mnemonic: mnemonic, passphrase: passphrase)
        let url = makeAccountURL()
        let wallet = Wallet(keyURL: url, key: key)
        let _ = try wallet.getAccounts(derivationPaths: [derivationPath], password: encryptPassword)

        wallets.append(wallet)

        try save(wallet: wallet, in: keyDirectory)

        return wallet
    }

    /// Exports a wallet as JSON data.
    ///
    /// - Parameters:
    ///   - wallet: wallet to export
    ///   - password: account password
    ///   - newPassword: password to use for exported key
    /// - Returns: encrypted JSON key
    public func export(wallet: Wallet, password: String, newPassword: String) throws -> Data {
        var privateKeyData = try wallet.key.decrypt(password: password)
        defer {
            privateKeyData.resetBytes(in: 0 ..< privateKeyData.count)
        }

        let newKey: KeystoreKey
        switch wallet.key.type {
        case .encryptedKey:
            guard let privateKey = PrivateKey(data: privateKeyData) else {
                throw Error.invalidKey
            }

            newKey = try KeystoreKey(password: newPassword, key: privateKey, coin: nil)
        case .hierarchicalDeterministicWallet:
            guard let string = String(data: privateKeyData, encoding: .ascii) else {
                throw EncryptError.invalidMnemonic
            }
            newKey = try KeystoreKey(password: newPassword, mnemonic: string, passphrase: wallet.key.passphrase)
        }
        return try JSONEncoder().encode(newKey)
    }

    /// Exports a wallet as private key data.
    ///
    /// - Parameters:
    ///   - wallet: wallet to export
    ///   - password: account password
    /// - Returns: private key data for encrypted keys or menmonic phrase for HD wallets
    public func exportPrivateKey(wallet: Wallet, password: String) throws -> Data {
        return try wallet.key.decrypt(password: password)
    }

    /// Exports a wallet as a mnemonic phrase.
    ///
    /// - Parameters:
    ///   - wallet: wallet to export
    ///   - password: account password
    /// - Returns: mnemonic phrase
    /// - Throws: `EncryptError.invalidMnemonic` if the account is not an HD wallet.
    public func exportMnemonic(wallet: Wallet, password: String) throws -> String {
        var data = try wallet.key.decrypt(password: password)
        defer {
            data.resetBytes(in: 0 ..< data.count)
        }

        switch wallet.key.type {
        case .encryptedKey:
            throw EncryptError.invalidMnemonic
        case .hierarchicalDeterministicWallet:
            guard let string = String(data: data, encoding: .ascii) else {
                throw EncryptError.invalidMnemonic
            }
            if string.hasSuffix("\0") {
                return String(string.dropLast())
            } else {
                return string
            }
        }
    }

    /// Updates the password of an existing account.
    ///
    /// - Parameters:
    ///   - wallet: wallet to update
    ///   - password: current password
    ///   - newPassword: new password
    public func update(wallet: Wallet, password: String, newPassword: String) throws {
        guard let index = wallets.index(of: wallet) else {
            fatalError("Missing wallet")
        }

        var privateKeyData = try wallet.key.decrypt(password: password)
        defer {
            privateKeyData.resetBytes(in: 0 ..< privateKeyData.count)
        }

        switch wallet.key.type {
        case .encryptedKey:
            guard let privateKey = PrivateKey(data: privateKeyData) else {
                throw Error.invalidKey
            }
            wallets[index].key = try KeystoreKey(password: newPassword, key: privateKey, coin: wallet.key.coin)
        case .hierarchicalDeterministicWallet:
            guard let string = String(data: privateKeyData, encoding: .ascii) else {
                throw EncryptError.invalidMnemonic
            }
            wallets[index].key = try KeystoreKey(password: newPassword, mnemonic: string, passphrase: wallet.key.passphrase)
        }
    }

    /// Deletes an account including its key if the password is correct.
    public func delete(wallet: Wallet, password: String) throws {
        guard let index = wallets.index(of: wallet) else {
            fatalError("Missing wallet")
        }

        var privateKey = try wallet.key.decrypt(password: password)
        defer {
            privateKey.resetBytes(in: 0..<privateKey.count)
        }
        wallets.remove(at: index)

        try FileManager.default.removeItem(at: wallet.keyURL)
    }

    // MARK: Helpers

    private func makeAccountURL(for address: Address) -> URL {
        return keyDirectory.appendingPathComponent(generateFileName(identifier: address.data.hexString))
    }

    private func makeAccountURL() -> URL {
        return keyDirectory.appendingPathComponent(generateFileName(identifier: UUID().uuidString))
    }

    /// Saves the account to the given directory.
    private func save(wallet: Wallet, in directory: URL) throws {
        var newKey = wallet.key
        newKey.activeAccounts = wallet.accounts

        try save(key: newKey, to: wallet.keyURL)
    }

    /// Generates a unique file name for an address.
    func generateFileName(identifier: String, date: Date = Date(), timeZone: TimeZone = .current) -> String {
        // keyFileName implements the naming convention for keyfiles:
        // UTC--<created_at UTC ISO8601>-<address hex>
        return "UTC--\(filenameTimestamp(for: date, in: timeZone))--\(identifier)"
    }

    private func filenameTimestamp(for date: Date, in timeZone: TimeZone = .current) -> String {
        var tz = ""
        let offset = timeZone.secondsFromGMT()
        if offset == 0 {
            tz = "Z"
        } else {
            tz = String(format: "%03d00", offset/60)
        }

        let components = Calendar(identifier: .iso8601).dateComponents(in: timeZone, from: date)
        return String(format: "%04d-%02d-%02dT%02d-%02d-%02d.%09d%@", components.year!, components.month!, components.day!, components.hour!, components.minute!, components.second!, components.nanosecond!, tz)
    }

    private func save(key: KeystoreKey, to url: URL) throws {
        let json = try JSONEncoder().encode(key)
        try json.write(to: url, options: [.atomicWrite])
    }
}
