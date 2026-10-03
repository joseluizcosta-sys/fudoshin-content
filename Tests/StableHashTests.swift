import XCTest
@testable import AtletaEstoico

final class StableHashTests: XCTestCase {
    // Valores de referência conferidos com uma implementação independente em Python.
    func testKnownFNV1aVectors() {
        XCTAssertEqual(StableHash.fnv1a64(""), 0xcbf29ce484222325)
        XCTAssertEqual(StableHash.fnv1a64("a"), 0xaf63dc4c8601ec8c)
        XCTAssertEqual(StableHash.fnv1a64("abc"), 0xe71fa2190541574b)
        XCTAssertEqual(StableHash.fnv1a64("foobar"), 0x85944171f73967e8)
        XCTAssertEqual(StableHash.fnv1a64("hello world"), 0x779a65e7023cd2e7)
    }

    func testUsesUTF8Bytes() {
        // "ação" e "中" escritos com escapes para não depender da normalização do arquivo.
        XCTAssertEqual(StableHash.fnv1a64("a\u{00E7}\u{00E3}o"), 0x74b2e70b31a1c349)
        XCTAssertEqual(StableHash.fnv1a64("\u{4E2D}"), 0x1e59811b678a02d4)
    }

    func testSameInputSameOutput() {
        XCTAssertEqual(StableHash.fnv1a64("install-A|msg|ciclo0"), 0xdc7595940c8dd55d)
        XCTAssertEqual(StableHash.fnv1a64("install-A|msg|ciclo0"), StableHash.fnv1a64("install-A|msg|ciclo0"))
        XCTAssertNotEqual(StableHash.fnv1a64("install-A|msg|ciclo0"), StableHash.fnv1a64("install-A|msg|ciclo1"))
    }
}
