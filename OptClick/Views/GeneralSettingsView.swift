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
            Text(NSLocalizedString("Settings.General.OptClick", comment: "OptClick"))
                .font(.headline)
            
            Toggle(NSLocalizedString("Settings.General.OptClick.Enable", comment: "Enable option to right click"), isOn: $inputManager.isEnabled)
                .toggleStyle(.switch)
            
            Text("\n" + NSLocalizedString("Settings.General.Launch", comment: "Launch"))
                .font(.headline)
            
            Toggle(NSLocalizedString("Settings.General.Launch.AtLogin", comment: "Launch at login"), isOn: $launchAtLogin)
                .toggleStyle(.switch)
                .onChange(of: launchAtLogin) {
                    LaunchManager.setEnabled(launchAtLogin)
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
            
            Text("\n" + NSLocalizedString("Settings.General.Update", comment: "Update"))
                .font(.headline)
            
            Toggle(NSLocalizedString("Settings.General.Update.AutoCheck", comment: "Automatically check for updates"), isOn: $autoCheckForUpdates)
                .toggleStyle(.switch)
                .onChange(of: autoCheckForUpdates) {
                    UpdateManager.isAutoCheckEnabled = autoCheckForUpdates
                }
            
            Button(NSLocalizedString("Settings.General.Update.ManualCheck", comment: "Check for Updates")) {
                UpdateManager.shared.checkForUpdate(from: nil)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
