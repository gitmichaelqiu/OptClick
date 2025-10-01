import AppKit
import SwiftUI
import UniformTypeIdentifiers

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
    @State private var autoToggleAppBundleIds: [String] = (UserDefaults.standard.stringArray(forKey: "AutoToggleAppBundleIds") ?? [])
    @State private var selection: String? = nil
    @State private var isAppTableExpanded: Bool = false
    @State private var isAppPickerPresented: Bool = false
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

                SettingsSection("Settings.General.AutoToggle") {
                    SettingsRow("Settings.General.AutoToggle.TargetApps") {
                        HStack(spacing: 8) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isAppTableExpanded.toggle()
                                }
                            }) {
                                Image(systemName: isAppTableExpanded ? "chevron.down" : "chevron.right")
                                    .frame(width: 20, height: 16)
                            }
                        }
                    }
                if isAppTableExpanded {
                    VStack(alignment: .leading, spacing: 0) {
                        let sortedApps = autoToggleAppBundleIds.map { rule -> (String, String, NSImage?) in
                            if rule.hasPrefix("proc:") {
                                let kw = String(rule.dropFirst(5))
                                return (rule, "Process: \(kw)", nil)
                            } else {
                                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: rule),
                                   let bundle = Bundle(url: url) {
                                    let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? rule
                                    let icon = NSWorkspace.shared.icon(forFile: url.path)
                                    return (rule, name, icon)
                                } else {
                                    return (rule, "⚠️ \(rule)", nil)
                                }
                            }
                        }.sorted { $0.1.localizedCaseInsensitiveCompare($1.1) == .orderedAscending }

                        List(selection: $selection) {
                            ForEach(sortedApps, id: \ .0) { (bundleId, name, icon) in
                                HStack {
                                    if let icon = icon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .cornerRadius(4)
                                    }
                                    Text(name)
                                    Spacer()
                                }
                                .tag(bundleId)
                            }
                        }
                        .frame(height: min(160, CGFloat(sortedApps.count) * 28 + 28))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                        )
                        HStack {
                            // Add App (by bundle ID)
                            Button(action: {
                                let panel = NSOpenPanel()
                                panel.allowedContentTypes = [.application]
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = false
                                panel.title = "Choose Application"
                                if panel.runModal() == .OK, let url = panel.url {
                                    if let bundle = Bundle(url: url), let bundleId = bundle.bundleIdentifier {
                                        if !autoToggleAppBundleIds.contains(bundleId) {
                                            autoToggleAppBundleIds.append(bundleId)
                                            UserDefaults.standard.set(autoToggleAppBundleIds, forKey: "AutoToggleAppBundleIds")
                                            inputManager.refreshAutoToggleState()
                                        }
                                    }
                                }
                            }) {
                                Image(systemName: "plus")
                                    .frame(width: 24, height: 14)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .help("Add App by Bundle ID")

                            Divider().frame(height: 16)

                            // Add by Window Title
                            Button(action: {
                                let alert = NSAlert()
                                alert.messageText = "Add App by Process Name"
                                alert.informativeText = "Enter the exact process name (case-sensitive):"
                                let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
                                textField.placeholderString = "Process"
                                alert.accessoryView = textField
                                alert.addButton(withTitle: "Add")
                                alert.addButton(withTitle: "Cancel")
                                
                                if alert.runModal() == .alertFirstButtonReturn {
                                    let keyword = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !keyword.isEmpty {
                                        let rule = "proc:\(keyword)"
                                        if !autoToggleAppBundleIds.contains(rule) {
                                            autoToggleAppBundleIds.append(rule)
                                            UserDefaults.standard.set(autoToggleAppBundleIds, forKey: "AutoToggleAppBundleIds")
                                            inputManager.refreshAutoToggleState()
                                        }
                                    }
                                }
                            }) {
                                Image(systemName: "character.textbox")
                                    .frame(width: 24, height: 14)
                            }
                            .buttonStyle(.borderless)
                            .help("Add by Process Name (exact, case-sensitive)")

                            Divider().frame(height: 16)

                            // Remove Selected
                            Button(action: {
                                if let selected = selection {
                                    if let idx = autoToggleAppBundleIds.firstIndex(of: selected) {
                                        autoToggleAppBundleIds.remove(at: idx)
                                        UserDefaults.standard.set(autoToggleAppBundleIds, forKey: "AutoToggleAppBundleIds")
                                        selection = nil
                                        inputManager.refreshAutoToggleState()
                                    }
                                }
                            }) {
                                Image(systemName: "minus")
                                    .frame(width: 24, height: 14)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)
                            .disabled(selection == nil)
                            .help("Remove Selected App")
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                        .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 2)
                }
                    Divider()
                    SettingsRow("Settings.General.AutoToggle.NotFrontmost") {
                        Picker("", selection: $autoToggleBehavior) {
                            ForEach(AutoToggleBehavior.allCases, id: \.self) { behavior in
                                Text(behavior.localizedDescription).tag(behavior)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .onChange(of: autoToggleBehavior) { newValue in
                            UserDefaults.standard.set(newValue.rawValue, forKey: "AutoToggleBehavior")
                            inputManager.refreshAutoToggleState()
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
