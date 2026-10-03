import SwiftUI
import WidgetKit

// Widget provisório do T00. Será substituído no T11 (DailyProvider, LockScreenViews, HomeScreenViews).

struct PlaceholderEntry: TimelineEntry {
    let date: Date
}

struct PlaceholderProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlaceholderEntry {
        PlaceholderEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (PlaceholderEntry) -> Void) {
        completion(PlaceholderEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlaceholderEntry>) -> Void) {
        let entry = PlaceholderEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct PlaceholderWidgetView: View {
    let entry: PlaceholderEntry

    var body: some View {
        Text("widget.hello")
            .font(.headline)
            .minimumScaleFactor(0.8)
            .containerBackground(for: .widget) {
                Color.clear
            }
    }
}

struct PlaceholderWidget: Widget {
    let kind = "AtletaEstoicoPlaceholderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PlaceholderProvider()) { entry in
            PlaceholderWidgetView(entry: entry)
        }
        .configurationDisplayName("widget.name")
        .description("widget.description")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}
