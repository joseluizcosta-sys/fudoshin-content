import SwiftUI
import Photos

struct WallpaperView: View {
    @State private var thumbnail: UIImage?
    @State private var saveStatus: WallpaperSaveStatus = .idle
    @State private var showGuide: Bool = false
    @State private var selectedImage: String? = nil   // nil = "Muda todo dia"
    @State private var availableImages: [String] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    preview
                    gallery
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
        .onAppear {
            availableImages = WallpaperImage.available { UIImage(named: $0) != nil }
            selectedImage = SharedStore.loadPreferencesIfExists()?.wallpaperImage
            loadThumbnail()
        }
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

    // MARK: - Galeria

    private var gallery: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("wallpaper.gallery.title")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.primaryText)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    GalleryItemView(
                        isSelected: selectedImage == nil,
                        label: Text("wallpaper.gallery.daily")
                    ) {
                        ZStack {
                            Color(white: 0.10)
                            Image(systemName: "shuffle")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.white)
                        }
                    } onTap: {
                        selectImage(nil)
                    }

                    ForEach(availableImages, id: \.self) { name in
                        GalleryItemView(
                            isSelected: selectedImage == name,
                            label: nil
                        ) {
                            if let img = UIImage(named: name) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color(white: 0.15)
                            }
                        } onTap: {
                            selectImage(name)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
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

    private func selectImage(_ name: String?) {
        selectedImage = name
        savePreferenceAndRegenerate(name)
    }

    private func savePreferenceAndRegenerate(_ name: String?) {
        var prefs = SharedStore.loadPreferences()
        prefs.wallpaperImage = name
        try? SharedStore.save(prefs)

        let today = DayKey(Date())
        let pngURL = SharedStore.wallpaperURL(for: today)
        try? FileManager.default.removeItem(at: pngURL)
        let metaURL = SharedStore.wallpaperMetaURL(for: today)
        try? FileManager.default.removeItem(at: metaURL)

        thumbnail = nil
        loadThumbnail()
    }

    /// Lê o papel de parede de hoje; se ainda não existir, gera na hora (mesma função do Atalhos).
    private func loadThumbnail() {
        Task {
            guard let url = try? await wallpaperURL(),
                  let data = try? Data(contentsOf: url) else { return }
            thumbnail = UIImage(data: data)
        }
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

// MARK: - GalleryItemView

private struct GalleryItemView<Content: View>: View {
    let isSelected: Bool
    let label: Text?
    @ViewBuilder let content: () -> Content
    let onTap: () -> Void

    private let itemWidth: CGFloat = 90
    private var itemHeight: CGFloat {
        itemWidth * (UIScreen.main.bounds.height / UIScreen.main.bounds.width)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomTrailing) {
                content()
                    .frame(width: itemWidth, height: itemHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? Theme.accent : Color.clear, lineWidth: 3)
                    )

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .background(Color.white.clipShape(Circle()))
                        .offset(x: -4, y: -4)
                }

                if let label {
                    label
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(4)
                        .frame(maxWidth: .infinity)
                        .background(.black.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 0))
                        .clipShape(
                            .rect(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 10,
                                bottomTrailingRadius: 10,
                                topTrailingRadius: 0
                            )
                        )
                        .frame(width: itemWidth, alignment: .bottom)
                        .offset(y: 0)
                }
            }
            .frame(width: itemWidth, height: itemHeight)
        }
        .buttonStyle(.plain)
    }
}

private enum WallpaperSaveStatus: Equatable {
    case idle, saving, saved, failed
}
