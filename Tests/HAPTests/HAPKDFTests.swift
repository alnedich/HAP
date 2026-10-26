import Crypto
@testable import HAP
import XCTest

/// The macOS 10.15 fallback must derive exactly what CryptoKit's HKDF does, or a
/// Bridge on 10.15 could never complete pairing with Apple Home.
class HAPKDFTests: XCTestCase {
    func testFallbackMatchesCryptoKit() throws {
        guard #available(macOS 11.0, iOS 14.0, *) else { throw XCTSkip("needs CryptoKit HKDF to compare") }
        let cases: [(salt: String, info: String, count: Int)] = [
            ("Control-Salt", "Control-Write-Encryption-Key", 32),
            ("Pair-Setup-Encrypt-Salt", "Pair-Setup-Encrypt-Info", 32),
            ("", "", 32),
            ("s", "longer than one block", 100),
        ]
        for c in cases {
            let ikm = SymmetricKey(size: .bits256)
            let expected = HKDF<SHA512>.deriveKey(inputKeyMaterial: ikm, salt: Data(c.salt.utf8),
                                                  info: Data(c.info.utf8), outputByteCount: c.count)
            let actual = HAPKDF.rfc5869(inputKeyMaterial: ikm, salt: Data(c.salt.utf8),
                                        info: Data(c.info.utf8), outputByteCount: c.count)
            XCTAssertEqual(expected.withUnsafeBytes { Data($0) }, actual.withUnsafeBytes { Data($0) },
                           "salt '\(c.salt)', info '\(c.info)'")
        }
    }
}
