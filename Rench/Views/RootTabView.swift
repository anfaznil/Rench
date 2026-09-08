import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                AgendaListView()
            }
            .tabItem {
                Label("Agenda", systemImage: "list.bullet")
            }

            NavigationStack {
                MonthCalendarView()
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .font(.system(size: 17))
    }
}
