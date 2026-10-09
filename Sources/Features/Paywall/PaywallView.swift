import SwiftUI
import StoreKit
import Network

struct PaywallView: View {
    @Environment(EntitlementStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var pathMonitor = NetworkPathMonitor()

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { background }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active && store.product == nil {
                    Task { await store.retryLoadProduct() }
                }
            }
            .onChange(of: pathMonitor.isConnected) { _, connected in
                if connected && store.product == nil {
                    Task { await store.retryLoadProduct() }
                }
            }
            .onAppear { pathMonitor.start() }
            .onDisappear { pathMonitor.stop() }
    }

    // MARK: - Fundo

    private var background: some View {
        ZStack {
            if let img = UIImage(named: "Wallpaper_epico_4") {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.black
            }
            Color.black.opacity(0.60)
        }
        .ignoresSafeArea()
    }

    // MARK: - Conteúdo

    private var content: some View {
        VStack(spacing: 0) {
            Spacer()

            title

            Spacer().frame(height: 36)

            benefits

            Spacer()

            ctaSection

            Spacer().frame(height: 32)
        }
        .padding(.horizontal, 28)
    }

    private var title: some View {
        Text("paywall.title")
            .font(.system(size: 30, weight: .bold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(1...4, id: \.self) { n in
                Label {
                    Text(LocalizedStringKey(String("paywall.benefit.") + String(n)))
                        .font(.body)
                        .foregroundStyle(.white)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ctaSection: some View {
        VStack(spacing: 16) {
            if let error = store.purchaseError {
                HStack(spacing: 8) {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                    Button("paywall.error.retry") {
                        store.clearPurchaseError()
                    }
                    .font(.footnote.bold())
                    .foregroundStyle(.white)
                }
            }

            Button {
                Task { await store.purchase() }
            } label: {
                Group {
                    if store.isPurchasing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.black)
                    } else {
                        Text("paywall.cta")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .background(.white)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .disabled(store.isPurchasing || store.product == nil)

            priceOrOfflineState

            HStack(spacing: 20) {
                Button("paywall.restore") {
                    Task { await store.restore() }
                }
                Link("paywall.terms", destination: Links.termsURL)
                Link("paywall.privacy", destination: Links.privacyURL)
            }
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.8))
        }
    }

    @ViewBuilder
    private var priceOrOfflineState: some View {
        if let product = store.product {
            Text(String(format: String(localized: "paywall.legal"), product.displayPrice))
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        } else if store.productLoadFailed {
            VStack(spacing: 8) {
                Text("paywall.offline.message")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                Button("paywall.offline.retry") {
                    Task { await store.retryLoadProduct() }
                }
                .font(.footnote.bold())
                .foregroundStyle(.white)
            }
        } else {
            ProgressView()
                .tint(.white.opacity(0.5))
                .scaleEffect(0.7)
        }
    }
}

// MARK: - NetworkPathMonitor

@Observable
final class NetworkPathMonitor {
    private(set) var isConnected = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.atletaestoico.netmonitor")

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
