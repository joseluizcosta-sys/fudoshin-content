import SwiftUI
import Photos

struct WallpaperSetupGuide: View {
    @Environment(\.dismiss) private var dismiss
    @State private var saveStatus: SaveStatus = .idle

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                    intro
                    steps
                    standbyNote
                }
                .padding(Theme.Spacing.large)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("wallpaper.guide.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("race_edit.cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Intro

    private var intro: some View {
        Text("wallpaper.guide.intro")
            .font(.body)
            .foregroundStyle(Theme.primaryText)
    }

    // MARK: - Passos

    private var steps: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            step(1, title: "wallpaper.guide.step1.title", body: "wallpaper.guide.step1.body",
                 icon: "app.badge")
            step(2, title: "wallpaper.guide.step2.title", body: "wallpaper.guide.step2.body",
                 icon: "clock.arrow.2.circlepath")
            step(3, title: "wallpaper.guide.step3.title", body: "wallpaper.guide.step3.body",
                 icon: "checkmark.square")
            step(4, title: "wallpaper.guide.step4.title", body: "wallpaper.guide.step4.body",
                 icon: "photo")
            step(5, title: "wallpaper.guide.step5.title", body: "wallpaper.guide.step5.body",
                 icon: "bell.slash")
        }
    }

    @ViewBuilder
    private func step(_ n: Int, title: String, body: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack(spacing: Theme.Spacing.small) {
                Text("\(n)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Theme.accent, in: Circle())
                Label(LocalizedStringKey(title), systemImage: icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText)
            }
            Text(LocalizedStringKey(body))
                .font(.body)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Nota StandBy

    private var standbyNote: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("wallpaper.guide.standby.title", systemImage: "moon.stars")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Theme.primaryText)
            Text("wallpaper.guide.standby.body")
                .font(.body)
                .foregroundStyle(Theme.secondaryText)
        }
    }
}

// MARK: - Seção em Ajustes

struct WallpaperSettingsSection: View {
    @State private var thumbnail: UIImage?
    @State private var saveStatus: SaveStatus = .idle
    @Binding var showGuide: Bool

    var body: some View {
        Section("wallpaper.section.title") {
            thumbnailRow
            saveButton
            autoChangeButton
        }
        .onAppear { loadThumbnail() }
    }

    // MARK: - Miniatura

    private var thumbnailRow: some View {
        HStack {
            if let img = thumbnail {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.secondaryText.opacity(0.15))
                    .frame(width: 56, height: 100)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(Theme.secondaryText)
                    }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Salvar no Fotos

    @ViewBuilder
    private var saveButton: some View {
        Button {
            Task { await saveToPhotos() }
        } label: {
            HStack {
                Text("wallpaper.save_to_photos")
                Spacer()
                statusIcon
            }
        }
        .foregroundStyle(Theme.primaryText)
        .disabled(saveStatus == .saving || thumbnail == nil)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch saveStatus {
        case .idle:    EmptyView()
        case .saving:  ProgressView().controlSize(.small)
        case .saved:   Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed:  Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
        }
    }

    // MARK: - Trocar automaticamente

    private var autoChangeButton: some View {
        Button {
            showGuide = true
        } label: {
            Label("wallpaper.auto_change", systemImage: "wand.and.stars")
        }
        .foregroundStyle(Theme.primaryText)
    }

    // MARK: - Helpers

    private func loadThumbnail() {
        let url = SharedStore.wallpaperURL(for: DayKey(Date()))
        guard let data = try? Data(contentsOf: url) else { return }
        thumbnail = UIImage(data: data)
    }

    private func saveToPhotos() async {
        guard let img = thumbnail else { return }
        saveStatus = .saving

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            saveStatus = .failed
            return
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: img)
            }
            saveStatus = .saved
        } catch {
            saveStatus = .failed
        }
    }
}

// MARK: - SaveStatus

private enum SaveStatus: Equatable {
    case idle, saving, saved, failed
}
