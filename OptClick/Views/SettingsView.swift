import SwiftUI

enum SettingsTab {
    case general, shortcuts, about
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        TabView {
            Tab(NSLocalizedString("Settings.General", comment: "General"), systemImage: "gearshape.fill") {
                GeneralSettingsView()
            }
            Tab(NSLocalizedString("Settings.Shortcuts", comment: "Shortcuts"), systemImage: "keyboard.fill") {
                ShortcutsSettingsView()
            }
            Tab(NSLocalizedString("Settings.About", comment: "About"), systemImage: "info.circle.fill") {
                AboutView()
            }
        }
        .scenePadding()
    }
}
