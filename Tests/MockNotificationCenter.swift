import Foundation
import UserNotifications
@testable import AtletaEstoico

/// Mock injetável para testes do LiveNotificationScheduler.
final class MockNotificationCenter: NotificationCenterProviding {
    var status: UNAuthorizationStatus = .authorized
    private(set) var pending: [UNNotificationRequest] = []

    func authorizationStatus() async -> UNAuthorizationStatus { status }

    func pendingRequests() async -> [UNNotificationRequest] { pending }

    func removeRequests(withIdentifiers ids: [String]) {
        pending.removeAll { ids.contains($0.identifier) }
    }

    func add(_ request: UNNotificationRequest) async throws {
        // Upsert: remove identifier duplicado antes de inserir.
        pending.removeAll { $0.identifier == request.identifier }
        pending.append(request)
    }
}
