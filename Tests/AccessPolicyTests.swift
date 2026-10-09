import XCTest
@testable import AtletaEstoico

final class AccessPolicyTests: XCTestCase {

    private let future = Date().addingTimeInterval(86400 * 5)
    private let past   = Date().addingTimeInterval(-86400)

    // MARK: - Teste em andamento → premium

    func testTrial_isPremium() {
        let snap = AccessPolicy.EntitlementSnapshot(
            expirationDate: future, isInIntroOffer: true, willAutoRenew: false
        )
        let state = AccessPolicy.state(from: snap, now: Date())
        XCTAssertTrue(state.isPremium)
        if case .trial(let exp) = state {
            XCTAssertEqual(exp, future)
        } else {
            XCTFail("Esperado .trial, obtido \(state)")
        }
    }

    // MARK: - Assinatura ativa → premium

    func testActive_isPremium() {
        let longFuture = Date().addingTimeInterval(86400 * 300)
        let snap = AccessPolicy.EntitlementSnapshot(
            expirationDate: longFuture, isInIntroOffer: false, willAutoRenew: true
        )
        let state = AccessPolicy.state(from: snap, now: Date())
        XCTAssertTrue(state.isPremium)
        if case .active(let exp, let renew) = state {
            XCTAssertEqual(exp, longFuture)
            XCTAssertTrue(renew)
        } else {
            XCTFail("Esperado .active, obtido \(state)")
        }
    }

    // MARK: - Expirada → bloqueado

    func testExpired_notPremium() {
        let snap = AccessPolicy.EntitlementSnapshot(
            expirationDate: past, isInIntroOffer: false, willAutoRenew: false
        )
        let state = AccessPolicy.state(from: snap, now: Date())
        XCTAssertFalse(state.isPremium)
        XCTAssertEqual(state, .expired)
    }

    // MARK: - Sem compra → bloqueado

    func testNoSubscription_notPremium() {
        let state = AccessPolicy.state(from: nil, now: Date())
        XCTAssertFalse(state.isPremium)
        XCTAssertEqual(state, .notSubscribed)
    }

    // MARK: - Injetabilidade de `now`

    func testExpiresInFuture_isPremiumAtNow_notPremiumAfterExpiry() {
        let exp = Date(timeIntervalSince1970: 1_000_000)
        let snap = AccessPolicy.EntitlementSnapshot(
            expirationDate: exp, isInIntroOffer: false, willAutoRenew: false
        )
        let beforeExpiry = Date(timeIntervalSince1970: 999_999)
        let afterExpiry  = Date(timeIntervalSince1970: 1_000_001)

        XCTAssertTrue(AccessPolicy.state(from: snap, now: beforeExpiry).isPremium)
        XCTAssertFalse(AccessPolicy.state(from: snap, now: afterExpiry).isPremium)
    }
}
