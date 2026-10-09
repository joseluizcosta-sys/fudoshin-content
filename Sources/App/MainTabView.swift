import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem { Label("tab.today", systemImage: "sun.horizon.fill") }
                .tag(0)

            RaceView()
                .tabItem { Label("tab.race", systemImage: "flag.checkered") }
                .tag(1)

            JournalView()
                .tabItem { Label("tab.journal", systemImage: "book.fill") }
                .tag(2)

            WallpaperView()
                .tabItem { Label("tab.wallpaper", systemImage: "iphone.gen3") }
                .tag(3)
        }
        .tint(Theme.accent)
        .onOpenURL { url in
            if url.scheme == "atletaestoico", url.host == "today" {
                selectedTab = 0
            }
        }
    }
}
