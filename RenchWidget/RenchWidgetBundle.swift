import WidgetKit
import SwiftUI

struct RenchHomeWidget: Widget {
    let kind = "RenchHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextAppointmentProvider()) { entry in
            RenchHomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Appointment")
        .description("Shows your next upcoming appointment.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RenchLockScreenWidget: Widget {
    let kind = "RenchLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextAppointmentProvider()) { entry in
            RenchLockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Appointment")
        .description("Shows your next upcoming appointment on the Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

@main
struct RenchWidgetBundle: WidgetBundle {
    var body: some Widget {
        RenchHomeWidget()
        RenchLockScreenWidget()
    }
}
