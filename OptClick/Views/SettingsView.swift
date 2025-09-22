import SwiftUI

enum SettingsTab {
    case general, shortcuts, about
}

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @ObservedObject var inputManager: InputManager
    
    var body: some View {
        if #available(macOS 15.0, *) {
            TabView {
                Tab(NSLocalizedString("Settings.General", comment: "General"), systemImage: "gearshape.fill") {
                    GeneralSettingsView(inputManager: inputManager)
                }
                Tab(NSLocalizedString("Settings.Shortcuts", comment: "Shortcuts"), systemImage: "keyboard.fill") {
                    ShortcutsSettingsView()
                }
                Tab(NSLocalizedString("Settings.About", comment: "About"), systemImage: "info.circle.fill") {
                    AboutView()
                }
            }
            .scenePadding()
        } else {
            TabView(selection: $selectedTab) {
                GeneralSettingsView(inputManager: inputManager)
                   .tabItem {
                       Label(
                           NSLocalizedString("Settings.General", comment: "General"),
                           systemImage: "gearshape.fill"
                       )
                   }
                   .tag(SettingsTab.general)

                ShortcutsSettingsView()
                   .tabItem {
                       Label(
                           NSLocalizedString("Settings.Shortcuts", comment: "Shortcuts"),
                           systemImage: "keyboard.fill"
                       )
                   }
                   .tag(SettingsTab.shortcuts)

                AboutView()
                   .tabItem {
                       Label(
                           NSLocalizedString("Settings.About", comment: "About"),
                           systemImage: "info.circle.fill"
                       )
                   }
                   .tag(SettingsTab.about)
                }
                .scenePadding()
        }
    }
}
