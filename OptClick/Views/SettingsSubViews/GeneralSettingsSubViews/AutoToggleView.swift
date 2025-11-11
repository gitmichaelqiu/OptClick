import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct AutoToggleView: View {
    @Binding var rules: [String]
    @Binding var isExpanded: Bool
    let onRuleChange: () -> Void

    @State private var selection: String? = nil
    @State var isExpandedLocal: Bool = false
    
    init(
        rules: Binding<[String]>,
        isExpanded: Binding<Bool>,
        onRuleChange: @escaping () -> Void
    ) {
        self._rules = rules
        self._isExpanded = isExpanded
        self.onRuleChange = onRuleChange
        self._isExpandedLocal = State(initialValue: isExpanded.wrappedValue)
    }
    
    var body: some View {
        SettingsRow("Settings.General.AutoToggle.TargetApps") {
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isExpandedLocal.toggle()
                        isExpanded = isExpandedLocal
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 20, height: 16)
                }
            }
        }
        .onChange(of: isExpanded) { newExternalValue in
            guard newExternalValue != isExpandedLocal else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpandedLocal = newExternalValue
            }
        }

        if isExpandedLocal {
            VStack(alignment: .leading, spacing: 0) {
                let sortedApps = rules.map { rule -> (id: String, name: String, icon: NSImage?) in
                    if rule.hasPrefix("proc:") {
                        let kw = String(rule.dropFirst(5))
                        let procStr = String(format: NSLocalizedString("Settings.General.AutoToggle.Process", comment: "Process: "), kw)
                        return (rule, procStr, nil)
                    } else {
                        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: rule),
                           let bundle = Bundle(url: url) {
                            let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? rule
                            let icon = NSWorkspace.shared.icon(forFile: url.path)
                            return (rule, name, icon)
                        } else {
                            return (rule, rule, nil)
                        }
                    }
                }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

                List(selection: $selection) {
                    ForEach(sortedApps, id: \.id) { item in
                        HStack {
                            if let icon = item.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .cornerRadius(4)
                            }
                            Text(item.name)
                            Spacer()
                        }
                        .tag(item.id)
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
                    addButton(
                        systemImage: "plus",
                        action: addAppByBundleID
                    )

                    Divider().frame(height: 16)

                    // Add by Process Name
                    addButton(
                        systemImage: "character.textbox",
                        action: addAppByProcessName
                    )

                    Divider().frame(height: 16)

                    // Remove Selected
                    addButton(
                        systemImage: "minus",
                        action: removeSelectedRule,
                        disabled: selection == nil
                    )
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 2)
        }
    }

    private func addButton(
        systemImage: String,
        action: @escaping () -> Void,
        disabled: Bool = false
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 24, height: 14)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .disabled(disabled)
    }

    private func addAppByBundleID() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Choose Application"
        
        let hostWindow = NSApp.suitableSheetWindow(nil)!

        panel.beginSheetModal(for: hostWindow) { response in
            if response == .OK, let url = panel.url {
                self.handleSelectedApp(url)
            }
        }
    }

    private func handleSelectedApp(_ url: URL) {
        if let bundle = Bundle(url: url), let bundleId = bundle.bundleIdentifier {
            if !rules.contains(bundleId) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    rules.append(bundleId)
                    onRuleChange()
                }
            }
        }
    }
    
    private func addAppByProcessName() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Settings.General.AutoToggle.Process.Add.Msg", comment: "")
        alert.informativeText = NSLocalizedString("Settings.General.AutoToggle.Process.Add.Info", comment: "")
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = NSLocalizedString("Settings.General.AutoToggle.Process.Add.Placeholder", comment: "Process")
        alert.accessoryView = textField
        alert.addButton(withTitle: NSLocalizedString("Settings.General.AutoToggle.Process.Add.Add", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Settings.General.AutoToggle.Process.Add.Cancel", comment: ""))

        let hostWindow = NSApp.suitableSheetWindow(nil)!

        alert.beginSheetModal(for: hostWindow) { response in
            if response == .alertFirstButtonReturn {
                self.processKeyword(textField.stringValue)
            }
        }
    }
    
    private func processKeyword(_ raw: String) {
        let keyword = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !keyword.isEmpty {
            let rule = "proc:\(keyword)"
            if !rules.contains(rule) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    rules.append(rule)
                    onRuleChange()
                }
            }
        }
    }

    private func removeSelectedRule() {
        if let selected = selection,
           let idx = rules.firstIndex(of: selected) {
            withAnimation(.easeInOut(duration: 0.2)) {
                rules.remove(at: idx)
                selection = nil
                onRuleChange()
            }
        }
    }
}
