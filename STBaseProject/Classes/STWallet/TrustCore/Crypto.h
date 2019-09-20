// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

@import Foundation;

@interface Crypto : NSObject

// MARK: - Elliptic Curve Cryptography

/// Extracts the public key from a Ethereum private key.
+ (nonnull NSData *)getEthereumPublicKeyFrom:(nonnull NSData *)privateKey NS_SWIFT_NAME(getEthereumPublicKey(from:));

/// Extracts the public key from a Bitcoin private key.
+ (nonnull NSData *)getBitcoinPublicKeyFrom:(nonnull NSData *)privateKey NS_SWIFT_NAME(getBitcoinPublicKey(from:));

/// Signs a hash with a private key.
///
/// @param hash hash to sign
/// @param privateKey private key to use for signing
/// @return signature is in the 65-byte [R || S || V] format where V is 0 or 1.
+ (nonnull NSData *)signHash:(nonnull NSData *)hash privateKey:(nonnull NSData *)privateKey NS_SWIFT_NAME(sign(hash:privateKey:));

/// Verifies a hash signature.
///
/// @param signature signature to verify
/// @param message message to verify
/// @param publicKey public key to verify with
/// @return whether the signature is valid
+ (BOOL)verifySignature:(nonnull NSData *)signature message:(nonnull NSData *)message publicKey:(nonnull NSData *)publicKey NS_SWIFT_NAME(verify(signature:message:publicKey:));

// MARK: - Hash functions

/// Computes the Ethereum hash of a block of data (SHA3 Keccak 256 version).
+ (nonnull NSData *)hash:(nonnull NSData *)hash;

/// Computes the SHA256 hash of the SHA256 hash of the data.
+ (nonnull NSData *)sha256sha256:(nonnull NSData *)data;

/// Computes the RIPEMD-160 hash of the SHA256 hash of the data.
+ (nonnull NSData *)sha256ripemd160:(nonnull NSData *)data;

// MARK: - Base58

/// Encodes data as a base 58 string.
+ (nonnull NSString *)base58Encode:(nonnull NSData *)data NS_SWIFT_NAME(base58Encode(_:));

/// Decodes a base 58 string.
+ (nullable NSData *)base58Decode:(nonnull NSString *)string expectedSize:(NSInteger)expectedSize NS_SWIFT_NAME(base58Decode(_:expectedSize:));

// MARK: - HDWallet

/// Generates a mnemonic phrase with the given strength in bits.
///
/// @param strength Strength in bits, should be a multiple of 32 between 128 and 256
/// @return mnemonic string
+ (nonnull NSString *)generateMnemonicWithStrength:(NSInteger)strength NS_SWIFT_NAME(generateMnemonic(strength:));

/// Generates a mnemonic from seed data.
///
/// @param seed seed data for the mnemonic, length should be a multiple of 4 between 16 and 32
/// @return mnemonic string
+ (nonnull NSString *)generateMnemonicFromSeed:(nonnull NSData *)seed NS_SWIFT_NAME(generateMnemonic(seed:));

/// Derives the wallet seed.
///
/// @param mnemonic mnemonic string
/// @param passphrase mnemonic passphrase
/// @return wallet seed
+ (nonnull NSData *)deriveSeedFromMnemonic:(nonnull NSString *)mnemonic passphrase:(nonnull NSString *)passphrase NS_SWIFT_NAME(deriveSeed(mnemonic:passphrase:));

/// Determines if a mnemonic string is valid.
///
/// @param mnemonic mnemonic string
/// @return whether the string is valid;
+ (BOOL)isValidMnemonic:(nonnull NSString *)mnemonic NS_SWIFT_NAME(isValid(mnemonic:));

@end
