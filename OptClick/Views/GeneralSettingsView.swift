import AppKit
import SwiftUI

struct SettingsRow<Content: View>: View {
    let title: LocalizedStringKey
    let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
            content
                .frame(alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
    }
}

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
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(backgroundColor.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial) // blur overlay
                    )
            )
        }
    }

    private var backgroundColor: Color {
        let nsColor = NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(calibratedWhite: 0.20, alpha: 1.0)
            } else {
                return NSColor(calibratedWhite: 1.00, alpha: 1.0)
            }
        }
        return Color(nsColor: nsColor)
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
    @State private var autoToggleAppBundleId: String = UserDefaults.standard.string(forKey: "AutoToggleAppBundleId") ?? ""
    @State private var autoToggleBehavior: AutoToggleBehavior = {
        let raw = UserDefaults.standard.string(forKey: "AutoToggleBehavior") ?? AutoToggleBehavior.disable.rawValue
        return AutoToggleBehavior(rawValue: raw) ?? .disable
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SettingsSection("Settings.General.OptClick") {
                    SettingsRow("Settings.General.OptClick.Enable") {
                        Toggle("", isOn: $inputManager.isEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }

                // --- Auto Toggle Section ---
                SettingsSection("Auto Toggle") {
                    SettingsRow("Target App Bundle ID") {
                        TextField("com.example.app", text: $autoToggleAppBundleId)
                            .onChange(of: autoToggleAppBundleId) { newValue in
                                UserDefaults.standard.set(newValue, forKey: "AutoToggleAppBundleId")
                            }
                            .frame(width: 220)
                    }
                    
                    Divider()
                    
                    SettingsRow("When no longer frontmost") {
                        Picker("", selection: $autoToggleBehavior) {
                            ForEach(AutoToggleBehavior.allCases, id: \.self) { behavior in
                                Text(behavior.localizedDescription).tag(behavior)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .onChange(of: autoToggleBehavior) { newValue in
                            UserDefaults.standard.set(newValue.rawValue, forKey: "AutoToggleBehavior")
                        }
                    }
                }

                SettingsSection("Settings.General.Launch") {
                    SettingsRow("Settings.General.Launch.AtLogin") {
                        Toggle("", isOn: $launchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: launchAtLogin) { newValue in
                                LaunchManager.setEnabled(newValue)
                            }
                    }

                    Divider()

                    SettingsRow("Settings.General.LaunchBehavior") {
                        Picker("", selection: $selectedLaunchBehavior) {
                            ForEach(LaunchBehavior.allCases, id: \.self) { behavior in
                                Text(behavior.localizedDescription).tag(behavior)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .onChange(of: selectedLaunchBehavior) { newValue in
                            UserDefaults.standard.set(newValue.rawValue, forKey: InputManager.launchBehaviorKey)
                        }
                    }
                }

                SettingsSection("Settings.General.Update") {
                    SettingsRow("Settings.General.Update.AutoCheck") {
                        Toggle("", isOn: $autoCheckForUpdates)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: autoCheckForUpdates) { newValue in
                                UpdateManager.isAutoCheckEnabled = newValue
                            }
                    }

                    Divider()

                    SettingsRow("Settings.General.Update.ManualCheck") {
                        Button(NSLocalizedString("Settings.General.Update.ManualCheck", comment: "")) {
                            UpdateManager.shared.checkForUpdate(from: nil)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
