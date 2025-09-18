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
    private let defaultShortcut = Shortcut(key: "R", modifiers: [.control, .option])

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

            let key = Shortcut.keyName(from: event)

            if key == "Escape" {
                self.shortcut = Shortcut(key: "", modifiers: [])
            } else {
                let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
                self.shortcut = Shortcut(key: key, modifiers: modifiers)
            }

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
        self.key = key
        self.modifiers = modifiers.intersection([.command, .option, .control, .shift])
    }

    init(event: NSEvent) {
        let keyName = Shortcut.keyName(from: event)
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        self.init(key: keyName, modifiers: modifiers)
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
        parts.append(key)
        return parts.joined()
    }

    // Convert NSEvent to readable key name (supports F1–F12, arrows, Esc, etc.)
    static func keyName(from event: NSEvent) -> String {
        switch event.keyCode {
        case 0x35: return "Escape"
        case 0x7A: return "F1"
        case 0x78: return "F2"
        case 0x63: return "F3"
        case 0x76: return "F4"
        case 0x60: return "F5"
        case 0x61: return "F6"
        case 0x62: return "F7"
        case 0x64: return "F8"
        case 0x65: return "F9"
        case 0x6D: return "F10"
        case 0x67: return "F11"
        case 0x6F: return "F12"
        case 0x7B: return "←"
        case 0x7C: return "→"
        case 0x7D: return "↓"
        case 0x7E: return "↑"
        default:
            // For normal keys, use charactersIgnoringModifiers
            return event.charactersIgnoringModifiers?.uppercased() ?? ""
        }
    }
}

// MARK: - Notification
extension Notification.Name {
    static let hotkeyTriggered = Notification.Name("HotkeyTriggered")
}
