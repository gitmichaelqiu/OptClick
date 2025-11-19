import SwiftUI

enum SettingsTab: String {
    case general, shortcuts, about
}

struct SettingsView: View {
    @AppStorage("selectedSettingsTab") private var selectedTab: SettingsTab = .general
    @ObservedObject var inputManager: InputManager
    
    var body: some View {
        if #available(macOS 15.0, *) {
            TabView(selection: $selectedTab) {
                Tab(NSLocalizedString("Settings.General", comment: "General"), systemImage: "gearshape.fill", value: .general) {
                    GeneralSettingsView(inputManager: inputManager)
                }
                Tab(NSLocalizedString("Settings.Shortcuts", comment: "Shortcuts"), systemImage: "keyboard.fill", value: .shortcuts) {
                    ShortcutsSettingsView()
                }
                Tab(NSLocalizedString("Settings.About", comment: "About"), systemImage: "info.circle.fill", value: .about) {
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
