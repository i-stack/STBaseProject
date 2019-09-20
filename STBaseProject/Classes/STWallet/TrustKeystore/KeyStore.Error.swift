// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

extension KeyStore {
    public enum Error: Swift.Error, LocalizedError {
        case accountAlreadyExists
        case accountNotFound
        case invalidMnemonic
        case invalidKey

        public var errorDescription: String? {
            switch self {
            case .accountAlreadyExists:
                return NSLocalizedString("Account already exists", comment: "Error message when trying to add an account that already exists")
            case .accountNotFound:
                return NSLocalizedString("Account not found", comment: "Error message when trying to access an account that does not exist")
            case .invalidMnemonic:
                return NSLocalizedString("Invalid mnemonic phrase", comment: "Error message when trying to import an invalid mnemonic phrase")
            case .invalidKey:
                return NSLocalizedString("Invalid private key", comment: "Error message when trying to import an invalid private key")
            }
        }
    }
}
