import Foundation

enum SubscriptionState: Equatable {
    case unknown
    case notSubscribed
    case trial(expires: Date)
    case active(expires: Date, willRenew: Bool)
    case expired

    var isPremium: Bool {
        switch self {
        case .trial, .active: return true
        default: return false
        }
    }
}
