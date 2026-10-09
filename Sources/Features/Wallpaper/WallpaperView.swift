import SwiftUI
import Photos

struct WallpaperView: View {
    @State private var thumbnail: UIImage?
    @State private var saveStatus: WallpaperSaveStatus = .idle
    @State private var showGuide: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    preview
                    saveButton
                    autoChangeButton
                    hint
                }
                .padding(Theme.Spacing.large)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("tab.wallpaper")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showGuide) {
            WallpaperSetupGuide()
        }
        .onAppear { loadThumbnail() }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in loadThumbnail() }
    }

    // MARK: - Prévia

    @ViewBuilder
    private var preview: some View {
        GeometryReader { geo in
            let width = geo.size.width * 0.60
            let height = width * (UIScreen.main.bounds.height / UIScreen.main.bounds.width)
            HStack {
                Spacer()
                Group {
                    if let img = thumbnail {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Theme.secondaryText.opacity(0.12)
                            ProgressView()
                        }
                    }
                }
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 8)
                Spacer()
            }
            .frame(height: height)
        }
        .frame(height: UIScreen.main.bounds.width * 0.60 *
               (UIScreen.main.bounds.height / UIScreen.main.bounds.width))
    }

    // MARK: - Salvar no Fotos

    @ViewBuilder
    private var saveButton: some View {
        Button {
            Task { await saveToPhotos() }
        } label: {
            HStack(spacing: 8) {
                if saveStatus == .saving {
                    ProgressView().tint(.white)
                } else if saveStatus == .saved {
                    Image(systemName: "checkmark.circle.fill")
                } else if saveStatus == .failed {
                    Image(systemName: "exclamationmark.circle.fill")
                }
                Text("wallpaper.save_to_photos")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.accent)
        .disabled(saveStatus == .saving || thumbnail == nil)
    }

    // MARK: - Trocar automaticamente

    private var autoChangeButton: some View {
        Button {
            showGuide = true
        } label: {
            Label("wallpaper.auto_change", systemImage: "wand.and.stars")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.bordered)
        .tint(Theme.accent)
    }

    // MARK: - Dica

    private var hint: some View {
        Text("wallpaper.hint")
            .font(.footnote)
            .foregroundStyle(Theme.secondaryText)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.small)
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

private enum WallpaperSaveStatus: Equatable {
    case idle, saving, saved, failed
}
