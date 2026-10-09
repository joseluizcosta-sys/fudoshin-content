import Foundation

/// Lógica pura de acesso — sem dependência de StoreKit, totalmente testável.
enum AccessPolicy {

    struct EntitlementSnapshot {
        let expirationDate: Date?
        let isInIntroOffer: Bool
        let willAutoRenew: Bool
    }

    /// Devolve o estado de assinatura a partir de um snapshot de entitlement.
    /// `now` é injetável para testes.
    static func state(from snapshot: EntitlementSnapshot?, now: Date = Date()) -> SubscriptionState {
        guard let snap = snapshot else { return .notSubscribed }
        let exp = snap.expirationDate ?? .distantFuture
        guard exp > now else { return .expired }
        return snap.isInIntroOffer
            ? .trial(expires: exp)
            : .active(expires: exp, willRenew: snap.willAutoRenew)
    }
}
