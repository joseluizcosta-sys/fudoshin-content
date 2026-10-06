import SwiftUI

private let dismissedAtKey = "syncHintDismissedAt"

struct SyncHintBanner: View {
    @State private var policy: SyncHintPolicy?
    @State private var isDismissed = false
    @State private var showGuide = false

    private var shouldShowAny: Bool {
        !isDismissed && (policy?.shouldShow == true || policy?.shouldShowSyncSuspect == true)
    }

    var body: some View {
        Group {
            if shouldShowAny {
                banner
                    .sheet(isPresented: $showGuide) { SyncGuideView() }
            }
        }
        .task { await loadPolicy() }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            Task { await loadPolicy() }
        }
    }

    private var banner: some View {
        HStack(spacing: Theme.Spacing.small) {
            Button { showGuide = true } label: {
                bannerMessage
                    .font(.footnote)
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                UserDefaults.standard.set(Date(), forKey: dismissedAtKey)
                isDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
        .background(Theme.accent.opacity(0.08))
    }

    @ViewBuilder
    private var bannerMessage: some View {
        if policy?.shouldShowSyncSuspect == true,
           let days = policy?.daysSinceExternalData {
            Text(String(format: String(localized: "sync_hint.suspect_message"), Int64(days)))
        } else {
            Text("sync_hint.message")
        }
    }

    private func loadPolicy() async {
        guard let provider = AppEnvironment.shared?.healthProvider else { return }
        let dismissedAt = UserDefaults.standard.object(forKey: dismissedAtKey) as? Date

        let workoutsResult: Result<[WorkoutSummary], Error>
        let sleepResult: Result<Double?, Error>
        let externalDataResult: Result<Date?, Error>

        do {
            let w = try await provider.recentWorkouts(days: 7)
            workoutsResult = .success(w)
        } catch {
            workoutsResult = .failure(error)
        }

        do {
            let s = try await provider.lastNightSleepHours(reference: Date())
            sleepResult = .success(s)
        } catch {
            sleepResult = .failure(error)
        }

        do {
            let e = try await provider.lastExternalDataDate(within: 30)
            externalDataResult = .success(e)
        } catch {
            externalDataResult = .failure(error)
        }

        policy = SyncHintPolicy(
            workoutsResult: workoutsResult,
            sleepResult: sleepResult,
            externalDataResult: externalDataResult,
            dismissedAt: dismissedAt,
            now: Date()
        )
    }
}
