import Crypto
import Foundation

/// HKDF-SHA512 (RFC 5869) for every HAP key derivation. CryptoKit's `HKDF` needs
/// macOS 11; Station Bridge runs on macOS 10.15, where this falls back to the
/// RFC's extract-and-expand over `HMAC<SHA512>`, which 10.15 has.
enum HAPKDF {
    static func deriveKey(inputKeyMaterial: SymmetricKey, salt: Data, info: Data,
                          outputByteCount: Int) -> SymmetricKey {
        if #available(macOS 11.0, iOS 14.0, *) {
            return HKDF<SHA512>.deriveKey(inputKeyMaterial: inputKeyMaterial, salt: salt, info: info,
                                          outputByteCount: outputByteCount)
        }
        return rfc5869(inputKeyMaterial: inputKeyMaterial, salt: salt, info: info,
                       outputByteCount: outputByteCount)
    }

    static func rfc5869(inputKeyMaterial: SymmetricKey, salt: Data, info: Data,
                        outputByteCount: Int) -> SymmetricKey {
        // Extract: PRK = HMAC(salt, IKM). An empty salt is HashLen zero bytes.
        let saltKey = SymmetricKey(data: salt.isEmpty ? Data(repeating: 0, count: SHA512.byteCount) : salt)
        let ikm = inputKeyMaterial.withUnsafeBytes { Data($0) }
        let prk = SymmetricKey(data: Data(HMAC<SHA512>.authenticationCode(for: ikm, using: saltKey)))
        // Expand: T(i) = HMAC(PRK, T(i-1) | info | i).
        var okm = Data()
        var previous = Data()
        var counter: UInt8 = 1
        while okm.count < outputByteCount {
            var block = previous
            block.append(info)
            block.append(counter)
            previous = Data(HMAC<SHA512>.authenticationCode(for: block, using: prk))
            okm.append(previous)
            counter += 1
        }
        return SymmetricKey(data: okm.prefix(outputByteCount))
    }
}
