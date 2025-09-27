import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
            }
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor)))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
            )
        }
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var inputManager: InputManager
    @State private var autoCheckForUpdates = UpdateManager.isAutoCheckEnabled
    @State private var launchAtLogin = LaunchManager.isEnabled
    @State private var selectedLaunchBehavior: LaunchBehavior = {
        let behaviorString = UserDefaults.standard.string(forKey: InputManager.launchBehaviorKey) ?? LaunchBehavior.lastState.rawValue
        return LaunchBehavior(rawValue: behaviorString) ?? .lastState
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsSection("Settings.General.OptClick") {
                    Toggle(
                        NSLocalizedString("Settings.General.OptClick.Enable", comment: "Enable option to right click"),
                        isOn: $inputManager.isEnabled
                    )
                    .toggleStyle(.switch)
                }

                SettingsSection("Settings.General.Launch") {
                    Toggle(
                        NSLocalizedString("Settings.General.Launch.AtLogin", comment: "Launch at login"),
                        isOn: $launchAtLogin
                    )
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) {
                        LaunchManager.setEnabled(launchAtLogin)
                    }

                    Divider()

                    Picker(
                        NSLocalizedString("Settings.General.LaunchBehavior", comment: "Launch Behavior"),
                        selection: $selectedLaunchBehavior
                    ) {
                        ForEach(LaunchBehavior.allCases, id: \.self) { behavior in
                            Text(behavior.localizedDescription).tag(behavior)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedLaunchBehavior) { _, newValue in
                        UserDefaults.standard.set(newValue.rawValue, forKey: InputManager.launchBehaviorKey)
                    }
                }

                SettingsSection("Settings.General.Update") {
                    Toggle(
                        NSLocalizedString("Settings.General.Update.AutoCheck", comment: "Automatically check for updates"),
                        isOn: $autoCheckForUpdates
                    )
                    .toggleStyle(.switch)
                    .onChange(of: autoCheckForUpdates) {
                        UpdateManager.isAutoCheckEnabled = autoCheckForUpdates
                    }

                    Divider()

                    Button(NSLocalizedString("Settings.General.Update.ManualCheck", comment: "Check for Updates")) {
                        UpdateManager.shared.checkForUpdate(from: nil)
                    }
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
