import Foundation
import WidgetKit

protocol WidgetReloading {
    func reloadAllTimelines()
}

struct LiveWidgetReloader: WidgetReloading {
    func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct NoOpWidgetReloader: WidgetReloading {
    func reloadAllTimelines() {}
}
