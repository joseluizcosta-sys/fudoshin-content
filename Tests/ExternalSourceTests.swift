import XCTest
@testable import AtletaEstoico

final class ExternalSourceTests: XCTestCase {

    // Garmin Connect: bundle externo, productType do iPhone do usuário → externo
    func testGarminIsExternal() {
        XCTAssertTrue(HealthKitService.isExternalSource(
            bundleID: "com.garmin.connect.mobile",
            productType: "iPhone15,2"
        ))
    }

    // iPhone Health nativo: bundle "com.apple.health.*", productType iPhone → NÃO externo
    func testIPhoneIsNotExternal() {
        XCTAssertFalse(HealthKitService.isExternalSource(
            bundleID: "com.apple.health.81A2FCD9-2034-4E3C-A8D8-9E3C2C0E0B4C",
            productType: "iPhone15,2"
        ))
    }

    // Apple Watch: bundle "com.apple.health.*" mas productType começa com "Watch" → externo
    func testAppleWatchIsExternal() {
        XCTAssertTrue(HealthKitService.isExternalSource(
            bundleID: "com.apple.health.9F3B1234-5678-9ABC-DEF0-1234567890AB",
            productType: "Watch6,1"
        ))
    }

    // Strava: bundle externo, sem productType → externo
    func testStravaIsExternal() {
        XCTAssertTrue(HealthKitService.isExternalSource(
            bundleID: "com.strava.stravaride",
            productType: nil
        ))
    }

    // Bundle "com.apple.health" sem UUID adicional (edge case) + productType Watch → externo
    func testAppleHealthPrefixWithWatchProductType() {
        XCTAssertTrue(HealthKitService.isExternalSource(
            bundleID: "com.apple.health",
            productType: "Watch7,1"
        ))
    }

    // Variante Watch mais nova
    func testAppleWatchSeriesVariant() {
        XCTAssertTrue(HealthKitService.isExternalSource(
            bundleID: "com.apple.health.ABCD",
            productType: "Watch8,1"
        ))
    }
}
