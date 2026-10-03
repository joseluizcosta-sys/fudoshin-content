import SwiftUI
import HealthKit
import UserNotifications

struct PermissionsStep: View {
    let committed: Bool
    let onComplete: () -> Void

    @State private var healthHandled = false
    @State private var notifHandled = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("onboarding.permissions.title")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.primaryText)
                Text("onboarding.permissions.subtitle")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.medium)

            VStack(spacing: Theme.Spacing.medium) {
                permissionRow(
                    icon: "heart.fill",
                    titleKey: "onboarding.health.title",
                    descKey: "onboarding.health.desc",
                    allowKey: "onboarding.health.allow",
                    handled: healthHandled,
                    onAllow: { Task { await requestHealth() } },
                    onSkip: { healthHandled = true }
                )

                permissionRow(
                    icon: "bell.fill",
                    titleKey: "onboarding.notifications.title",
                    descKey: "onboarding.notifications.desc",
                    allowKey: "onboarding.notifications.allow",
                    handled: notifHandled,
                    onAllow: { Task { await requestNotifications() } },
                    onSkip: { notifHandled = true }
                )
            }
            .padding(.horizontal, Theme.Spacing.large)

            Spacer()

            Button(action: onComplete) {
                Text("onboarding.button.start").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .disabled(committed)
            .padding(Theme.Spacing.large)
        }
    }

    @ViewBuilder
    private func permissionRow(
        icon: String,
        titleKey: LocalizedStringKey,
        descKey: LocalizedStringKey,
        allowKey: LocalizedStringKey,
        handled: Bool,
        onAllow: @escaping () -> Void,
        onSkip: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.medium) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(titleKey)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText)
                Text(descKey)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            if handled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                VStack(spacing: 4) {
                    Button(action: onAllow) {
                        Text(allowKey).font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .controlSize(.small)

                    Button(action: onSkip) {
                        Text("onboarding.permissions.skip").font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .padding(Theme.Spacing.medium)
        .background(Theme.secondaryText.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func requestHealth() async {
        guard HKHealthStore.isHealthDataAvailable() else { healthHandled = true; return }
        let types: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        ]
        try? await HKHealthStore().requestAuthorization(toShare: [], read: types)
        healthHandled = true
    }

    private func requestNotifications() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
        notifHandled = true
    }
}
