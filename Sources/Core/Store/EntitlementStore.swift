import StoreKit
import Foundation

@Observable
@MainActor
final class EntitlementStore {
    static let productID = "com.atletaestoico.app.anual"

    private(set) var state: SubscriptionState = .unknown
    private(set) var product: Product? = nil
    private(set) var isPurchasing = false
    private(set) var purchaseError: String? = nil

    // nonisolated(unsafe): não há acesso fora do main actor, só cancelamento no deinit.
    nonisolated(unsafe) private var updatesTask: Task<Void, Never>? = nil

    var isPremium: Bool {
        #if DEBUG
        if let override = debugOverride { return override }
        #endif
        return state.isPremium
    }

    #if DEBUG
    var debugOverride: Bool? = nil
    #endif

    init() {
        let task = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handleVerification(update)
            }
        }
        updatesTask = task
        Task { await refreshState() }
        Task { await loadProduct() }
    }

    // MARK: - Produto

    private func loadProduct() async {
        product = try? await Product.products(for: [Self.productID]).first
    }

    // MARK: - Compra

    func clearPurchaseError() { purchaseError = nil }

    func purchase() async {
        guard let product else { return }
        isPurchasing = true
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handleVerification(verification)
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
        isPurchasing = false
    }

    // MARK: - Restaurar

    func restore() async {
        isPurchasing = true
        try? await AppStore.sync()
        await refreshState()
        isPurchasing = false
    }

    // MARK: - Estado

    func refreshState() async {
        var snapshot: AccessPolicy.EntitlementSnapshot? = nil

        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result,
                  tx.productID == Self.productID
            else { continue }

            // introductoryOffer rawValue == 1 em StoreKit 2
            var isInIntro = isIntroductoryOffer(tx.offerType)
            var willRenew = false

            var prod = product
            if prod == nil {
                prod = try? await Product.products(for: [Self.productID]).first
            }
            if let prod, let statuses = try? await prod.subscription?.status {
                for status in statuses {
                    if case .verified(let info) = status.renewalInfo {
                        willRenew = info.willAutoRenew
                    }
                    if case .verified(let renewTx) = status.transaction {
                        isInIntro = isIntroductoryOffer(renewTx.offerType)
                    }
                }
            }

            snapshot = AccessPolicy.EntitlementSnapshot(
                expirationDate: tx.expirationDate,
                isInIntroOffer: isInIntro,
                willAutoRenew: willRenew
            )
            break
        }

        let newState = AccessPolicy.state(from: snapshot)
        let wasInTrial = isTrial(state)
        state = newState
        persistToPremiumFlag()

        if case .trial(let exp) = newState, !wasInTrial {
            await scheduleTrialReminder(trialEnd: exp)
        } else if !newState.isPremium {
            await TrialReminder.cancel()
        }
    }

    // MARK: - Privados

    private func handleVerification(_ result: VerificationResult<Transaction>) async {
        if case .verified(let tx) = result {
            await tx.finish()
        }
        await refreshState()
    }

    private func persistToPremiumFlag() {
        var prefs = SharedStore.loadPreferences()
        let premium = state.isPremium
        guard prefs.isPremium != premium else { return }
        prefs.isPremium = premium
        try? SharedStore.save(prefs)
    }

    private func isTrial(_ s: SubscriptionState) -> Bool {
        if case .trial = s { return true }
        return false
    }

    // Transaction.OfferType é um struct RawRepresentable; rawValue 1 = introductoryOffer.
    private func isIntroductoryOffer(_ offerType: Transaction.OfferType?) -> Bool {
        offerType.map { $0 == Transaction.OfferType(rawValue: 1) } ?? false
    }

    private func scheduleTrialReminder(trialEnd: Date) async {
        let price = product?.displayPrice ?? ""
        guard let fireDate = TrialReminder.fireDate(trialEnd: trialEnd) else { return }
        await TrialReminder.schedule(fireDate: fireDate, price: price)
    }
}
