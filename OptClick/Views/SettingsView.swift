import SwiftUI

enum SettingsTab {
    case general, shortcuts, about
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape.fill") {
                GeneralSettingsView()
            }
            Tab("Shortcuts", systemImage: "keyboard.fill") {
                ShortcutsSettingsView()
            }
            Tab("About", systemImage: "info.circle.fill") {
                AboutView()
            }
        }
        .scenePadding()
        .frame(maxWidth: 350, minHeight: 100)
    }
}
