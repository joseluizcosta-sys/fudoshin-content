import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(EntitlementStore.self) private var store

    var body: some View {
        ZStack {
            background
            content
        }
        .ignoresSafeArea()
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
                    Text(LocalizedStringKey("paywall.benefit.\(n)"))
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

            if let product = store.product {
                Text(String(format: String(localized: "paywall.legal"), product.displayPrice))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ProgressView()
                    .tint(.white.opacity(0.5))
                    .scaleEffect(0.7)
            }

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
}
