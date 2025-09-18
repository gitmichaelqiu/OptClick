import Foundation
import AppKit
import Combine

class HotkeyManager: ObservableObject {
    @Published var shortcut: Shortcut {
        didSet {
            registerShortcut()
        }
    }

    @Published var isListeningForShortcut: Bool = false

    private var monitor: Any?
    private let defaultShortcut = Shortcut(key: "r", modifiers: [.option, .control])

    init() {
        self.shortcut = defaultShortcut
        registerShortcut()
    }

    var shortcutDescription: String {
        isListeningForShortcut ? "Press new shortcut…" : shortcut.description
    }

    // MARK: - Shortcut Handling
    private func registerShortcut() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }

        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }

            if Shortcut(event: event) == self.shortcut {
                NotificationCenter.default.post(name: .hotkeyTriggered, object: nil)
            }
        }
    }

    func startListeningForNewShortcut() {
        isListeningForShortcut = true

        // Temporary local monitor to capture next key press
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            let newShortcut = Shortcut(event: event)
            self.shortcut = newShortcut
            self.isListeningForShortcut = false
            self.registerShortcut()
            return nil // swallow the event
        }
    }

    func resetToDefault() {
        shortcut = defaultShortcut
    }
}

// MARK: - Shortcut Representation
struct Shortcut: Equatable {
    let key: String
    let modifiers: NSEvent.ModifierFlags

    init(key: String, modifiers: NSEvent.ModifierFlags) {
        self.key = key.lowercased()
        self.modifiers = modifiers.intersection([.command, .option, .control, .shift])
    }

    init(event: NSEvent) {
        self.modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        self.key = event.charactersIgnoringModifiers?.lowercased() ?? ""
    }

    static func == (lhs: Shortcut, rhs: Shortcut) -> Bool {
        lhs.key == rhs.key && lhs.modifiers == rhs.modifiers
    }

    var description: String {
        if key.isEmpty { return "Unassigned" }

        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("^") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        parts.append(key.uppercased())
        return parts.joined()
    }
}

// MARK: - Notification
extension Notification.Name {
    static let hotkeyTriggered = Notification.Name("HotkeyTriggered")
}
