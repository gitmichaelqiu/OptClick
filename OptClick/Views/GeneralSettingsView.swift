import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var inputManager: InputManager
    @State private var autoCheckForUpdates = UpdateManager.isAutoCheckEnabled
    @State private var launchAtLogin = LaunchManager.isEnabled
    @State private var selectedLaunchBehavior: LaunchBehavior = {
        let behaviorString = UserDefaults.standard.string(forKey: InputManager.launchBehaviorKey) ?? LaunchBehavior.lastState.rawValue
        return LaunchBehavior(rawValue: behaviorString) ?? .lastState
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle(NSLocalizedString("Settings.General.Option.Enable", comment: "Enable option to right click"), isOn: $inputManager.isEnabled)
            
            Toggle(NSLocalizedString("Settings.General.Launch", comment: "Launch at login"), isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) {
                    LaunchManager.setEnabled(launchAtLogin)
                }
            
            Toggle(NSLocalizedString("Settings.General.Update.AutoCheck", comment: "Automatically check for updates"), isOn: $autoCheckForUpdates)
                .onChange(of: autoCheckForUpdates) {
                    UpdateManager.isAutoCheckEnabled = autoCheckForUpdates
                }
            
            Button(NSLocalizedString("Settings.General.Update.ManualCheck", comment: "Check for Updates")) {
                UpdateManager.shared.checkForUpdate(from: nil)
            }
            
            Picker(NSLocalizedString("Settings.General.LaunchBehavior", comment: "Launch Behavior"), selection: $selectedLaunchBehavior) {
                ForEach(LaunchBehavior.allCases, id: \.self) { behavior in
                    Text(behavior.localizedDescription).tag(behavior)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedLaunchBehavior) { _, newValue in
                UserDefaults.standard.set(newValue.rawValue, forKey: InputManager.launchBehaviorKey)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
