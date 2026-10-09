import XCTest
@testable import AtletaEstoico

final class ReflectionPersonalizerTests: XCTestCase {

    // MARK: - TemplatePersonalizer

    func testTemplateReturnsOriginal() async {
        let p = TemplatePersonalizer()
        let result = await p.personalize(reflection: "Texto original", why: "treinar", trigger: .geral)
        XCTAssertEqual(result, "Texto original")
    }

    func testTemplateIgnoresEmptyReflection() async {
        let p = TemplatePersonalizer()
        let result = await p.personalize(reflection: "", why: "treinar", trigger: .geral)
        XCTAssertEqual(result, "")
    }

    // MARK: - personalizeWithTimeout

    func testTimeoutFallbackWhenOperationIsSlow() async {
        let start = Date()
        let result = await personalizeWithTimeout(
            timeout: 0.1,
            fallback: "fallback",
            operation: {
                try await Task.sleep(nanoseconds: 10_000_000_000)  // 10 s
                return "RESULTADO LENTO"
            }
        )
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertEqual(result, "fallback", "Deve retornar o fallback quando a operação demora mais que o timeout")
        XCTAssertLessThan(elapsed, 2.0, "Não deve bloquear por 10 s — deve cancelar antes de 2 s")
    }

    func testNoTimeoutWhenOperationIsFast() async {
        let result = await personalizeWithTimeout(
            timeout: 3,
            fallback: "fallback",
            operation: { "rápido" }
        )
        XCTAssertEqual(result, "rápido")
    }

    func testFallbackWhenOperationThrows() async {
        struct TestError: Error {}
        let result = await personalizeWithTimeout(
            timeout: 3,
            fallback: "fallback",
            operation: { throw TestError() }
        )
        XCTAssertEqual(result, "fallback")
    }
}
