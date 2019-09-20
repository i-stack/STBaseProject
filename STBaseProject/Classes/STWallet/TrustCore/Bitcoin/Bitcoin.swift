// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

public enum Bitcoin {
    public static let privateKeySize = 32
    public static let addressSize = 20

    public enum MainNet {
        /// Public key hash address prefix.
        public static let publicKeyHashAddressPrefix: UInt8 = 0x00

        /// Private key prefix.
        public static let privateKeyPrefix: UInt8 = 0x80

        /// Pay to script hash (P2SH) address prefix.
        public static let payToScriptHashAddressPrefix: UInt8 = 0x05
    }

    public enum TestNet {
        /// Public key hash address prefix.
        public static let publicKeyHashAddressPrefix: UInt8 = 0x6f

        /// Private key prefix.
        public static let privateKeyPrefix: UInt8 = 0xef

        /// Pay to script hash (P2SH) address prefix.
        public static let payToScriptHashAddressPrefix: UInt8 = 0x0c
    }
}
