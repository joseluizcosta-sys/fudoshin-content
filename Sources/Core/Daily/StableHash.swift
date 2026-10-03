import Foundation

/// Hash determinístico (FNV-1a, 64 bits) sobre os bytes UTF-8.
/// Nunca use `Hasher`/`hashValue` para sorteios: são aleatórios a cada execução do app.
enum StableHash {
    private static let offsetBasis: UInt64 = 0xcbf29ce484222325
    private static let prime: UInt64 = 0x100000001b3

    static func fnv1a64(_ s: String) -> UInt64 {
        var hash = offsetBasis
        for byte in s.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }
        return hash
    }
}
