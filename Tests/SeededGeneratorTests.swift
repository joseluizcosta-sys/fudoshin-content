import XCTest
@testable import AtletaEstoico

final class SeededGeneratorTests: XCTestCase {
    // Vetores de referência do SplitMix64 (seed 0 e seed 1234567), conferidos em Python.
    func testSplitMix64SeedZero() {
        var generator = SeededGenerator(seed: 0)
        XCTAssertEqual(generator.next(), 0xe220a8397b1dcdaf)
        XCTAssertEqual(generator.next(), 0x6e789e6aa1b965f4)
        XCTAssertEqual(generator.next(), 0x06c45d188009454f)
    }

    func testSplitMix64KnownSeed() {
        var generator = SeededGenerator(seed: 1234567)
        XCTAssertEqual(generator.next(), 6457827717110365317)
        XCTAssertEqual(generator.next(), 3203168211198807973)
    }

    func testSameSeedSameSequence() {
        var a = SeededGenerator(seed: 42)
        var b = SeededGenerator(seed: 42)
        for _ in 0..<20 {
            XCTAssertEqual(a.next(), b.next())
        }
    }

    func testDifferentSeedsDiffer() {
        var a = SeededGenerator(seed: 1)
        var b = SeededGenerator(seed: 2)
        XCTAssertNotEqual(a.next(), b.next())
    }

    func testWorksAsRandomNumberGenerator() {
        var generator = SeededGenerator(seed: 7)
        let value = Int.random(in: 0..<10, using: &generator)
        XCTAssertTrue((0..<10).contains(value))
    }
}
