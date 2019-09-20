// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

/// Scrypt function parameters.
public struct ScryptParams {
    /// The N parameter of Scrypt encryption algorithm, using 256MB memory and taking approximately 1s CPU time on a
    /// modern processor.
    public static let standardN = 1 << 18

    /// The P parameter of Scrypt encryption algorithm, using 256MB memory and taking approximately 1s CPU time on a
    /// modern processor.
    public static let standardP = 1

    /// The N parameter of Scrypt encryption algorithm, using 4MB memory and taking approximately 100ms CPU time on a
    /// modern processor.
    public static let lightN = 1 << 12

    /// The P parameter of Scrypt encryption algorithm, using 4MB memory and taking approximately 100ms CPU time on a
    /// modern processor.
    public static let lightP = 6

    /// Default `R` parameter of Scrypt encryption algorithm.
    public static let defaultR = 8

    /// Default desired key length of Scrypt encryption algorithm.
    public static let defaultDesiredKeyLength = 32

    /// Random salt.
    public var salt: Data

    /// Desired key length in bytes.
    public var desiredKeyLength = defaultDesiredKeyLength

    /// CPU/Memory cost factor.
    public var n = lightN

    /// Parallelization factor (1..232-1 * hLen/MFlen).
    public var p = lightP

    /// Block size factor.
    public var r = defaultR

    /// Initializes with default scrypt parameters and a random salt.
    public init() {
        let length = 32
        var data = Data(repeating: 0, count: length)
        let result = data.withUnsafeMutableBytes { p in
            SecRandomCopyBytes(kSecRandomDefault, length, p)
        }
        precondition(result == errSecSuccess, "Failed to generate random number")
        salt = data
    }

    /// Initializes `ScryptParams` with all values.
    public init(salt: Data, n: Int, r: Int, p: Int, desiredKeyLength: Int) throws {
        self.salt = salt
        self.n = n
        self.r = r
        self.p = p
        self.desiredKeyLength = desiredKeyLength
        if let error = validate() {
            throw error
        }
    }

    /// Validates the parameters.
    ///
    /// - Returns: a `ValidationError` or `nil` if the parameters are valid.
    public func validate() -> ValidationError? {
        if desiredKeyLength > ((1 << 32 as Int64) - 1 as Int64) * 32 {
            return ValidationError.desiredKeyLengthTooLarge
        }
        if UInt64(r) * UInt64(p) >= (1 << 30) {
            return ValidationError.blockSizeTooLarge
        }
        if n & (n - 1) != 0 || n < 2 {
            return ValidationError.invalidCostFactor
        }
        if (r > Int.max / 128 / p) || (n > Int.max / 128 / r) {
            return ValidationError.overflow
        }
        return nil
    }

    public enum ValidationError: Error {
        case desiredKeyLengthTooLarge
        case blockSizeTooLarge
        case invalidCostFactor
        case overflow
    }
}

extension ScryptParams: Codable {
    enum CodingKeys: String, CodingKey {
        case salt
        case desiredKeyLength = "dklen"
        case n
        case p
        case r
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        salt = try values.decodeHexString(forKey: .salt)
        desiredKeyLength = try values.decode(Int.self, forKey: .desiredKeyLength)
        n = try values.decode(Int.self, forKey: .n)
        p = try values.decode(Int.self, forKey: .p)
        r = try values.decode(Int.self, forKey: .r)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(salt.hexString, forKey: .salt)
        try container.encode(desiredKeyLength, forKey: .desiredKeyLength)
        try container.encode(n, forKey: .n)
        try container.encode(p, forKey: .p)
        try container.encode(r, forKey: .r)
    }
}
