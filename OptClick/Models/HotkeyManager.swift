import Foundation
import AppKit
import Combine
import HotKey

class HotkeyManager: ObservableObject {
    @Published var shortcut: Shortcut {
        didSet {
            registerShortcut()
        }
    }

    @Published var isListeningForShortcut: Bool = false

    private var hotKey: HotKey?
    private var monitor: Any?
    private let defaultShortcut = Shortcut(key: .r, modifiers: [.control])

    init() {
        self.shortcut = defaultShortcut
        registerShortcut()
    }

    var shortcutDescription: String {
        isListeningForShortcut ? NSLocalizedString("Settings.Shotcuts.Hotkey.PressNew", comment: "Press new shortcut…") : shortcut.description
    }
    
    private static let functionKeys: Set<Key> = [
        .f1, .f2, .f3, .f4, .f5, .f6,
        .f7, .f8, .f9, .f10, .f11, .f12
    ]

    // MARK: - Shortcut Handling
    private func registerShortcut() {
        // Unregister existing hotkey
        unregisterShortcut()
        
        // Don't register if key is empty (unassigned)
        guard let key = shortcut.hotkeyKey,
              let modifiers = shortcut.hotkeyModifiers else {
            return
        }
        
        // Create and register the hotkey using HotKey library
        hotKey = HotKey(key: key, modifiers: modifiers)
        
        // Set up the handler
        hotKey?.keyDownHandler = {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .hotkeyTriggered, object: nil)
            }
        }
    }
    
    private func unregisterShortcut() {
        hotKey?.keyDownHandler = nil
        hotKey = nil
    }

    func startListeningForNewShortcut() {
        isListeningForShortcut = true

        // Temporarily unregister current hotkey
        unregisterShortcut()

        // Remove any existing monitor
        removeKeyListener()

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            if Shortcut.keyName(from: event) == "Escape" {
                self.shortcut = Shortcut(key: nil, modifiers: [])
                self.finishListening()
                return nil
            }
            
            guard let key = Shortcut.keyFromEvent(event) else {
                return event
            }
            
            let rawModifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
            let cleanedModifiers = self.convertToHotkeyModifiers(rawModifiers)
            
            let isFunctionKey = HotkeyManager.functionKeys.contains(key)
            let hasModifiers = !cleanedModifiers.isEmpty
            
            if hasModifiers || isFunctionKey {
                self.shortcut = Shortcut(key: key, modifiers: cleanedModifiers)
                self.finishListening()
                return nil
            } else {
                return nil
            }
        }
    }
    
    private func finishListening() {
        isListeningForShortcut = false
        removeKeyListener()
        registerShortcut()
    }
    
    private func removeKeyListener() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    private func convertToHotkeyModifiers(_ modifiers: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        var result = NSEvent.ModifierFlags()
        if modifiers.contains(.command) { result.insert(.command) }
        if modifiers.contains(.option) { result.insert(.option) }
        if modifiers.contains(.control) { result.insert(.control) }
        if modifiers.contains(.shift) { result.insert(.shift) }
        return result
    }

    func resetToDefault() {
        shortcut = defaultShortcut
    }
    
    deinit {
        unregisterShortcut()
        removeKeyListener()
    }
}

// MARK: - Shortcut Representation
struct Shortcut: Equatable {
    let key: Key?
    let modifiers: NSEvent.ModifierFlags
    
    // For backward compatibility with the UI
    var keyString: String {
        key?.description ?? ""
    }

    init(key: Key?, modifiers: NSEvent.ModifierFlags) {
        self.key = key
        self.modifiers = modifiers.intersection([.command, .option, .control, .shift])
    }

    static func == (lhs: Shortcut, rhs: Shortcut) -> Bool {
        lhs.key == rhs.key && lhs.modifiers == rhs.modifiers
    }

    var description: String {
        if key == nil { return NSLocalizedString("Settings.Shortcuts.Unassgined", comment: "Unassigned") }

        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("^") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if let key = key {
            parts.append(keyDisplayName(for: key))
        }
        return parts.joined()
    }
    
    // Convert to HotKey library Key type
    var hotkeyKey: Key? {
        return key
    }
    
    // Convert to HotKey library modifiers
    var hotkeyModifiers: NSEvent.ModifierFlags? {
        return modifiers
    }
    
    // Helper to get display name for Key
    private func keyDisplayName(for key: Key) -> String {
        switch key {
        case .a: return "A"
        case .b: return "B"
        case .c: return "C"
        case .d: return "D"
        case .e: return "E"
        case .f: return "F"
        case .g: return "G"
        case .h: return "H"
        case .i: return "I"
        case .j: return "J"
        case .k: return "K"
        case .l: return "L"
        case .m: return "M"
        case .n: return "N"
        case .o: return "O"
        case .p: return "P"
        case .q: return "Q"
        case .r: return "R"
        case .s: return "S"
        case .t: return "T"
        case .u: return "U"
        case .v: return "V"
        case .w: return "W"
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        case .zero: return "0"
        case .one: return "1"
        case .two: return "2"
        case .three: return "3"
        case .four: return "4"
        case .five: return "5"
        case .six: return "6"
        case .seven: return "7"
        case .eight: return "8"
        case .nine: return "9"
        case .f1: return "F1"
        case .f2: return "F2"
        case .f3: return "F3"
        case .f4: return "F4"
        case .f5: return "F5"
        case .f6: return "F6"
        case .f7: return "F7"
        case .f8: return "F8"
        case .f9: return "F9"
        case .f10: return "F10"
        case .f11: return "F11"
        case .f12: return "F12"
        case .leftArrow: return "←"
        case .rightArrow: return "→"
        case .downArrow: return "↓"
        case .upArrow: return "↑"
        case .escape: return "Escape"
        case .space: return " "
        case .delete: return "⌫"
        case .forwardDelete: return "⌦"
        case .return: return "⏎"
        case .tab: return "⇥"
        default: return key.description
        }
    }

    // Convert NSEvent keyCode to HotKey Key type
    static func keyFromEvent(_ event: NSEvent) -> Key? {
        switch event.keyCode {
        case 0x00: return .a
        case 0x0B: return .b
        case 0x08: return .c
        case 0x02: return .d
        case 0x0E: return .e
        case 0x03: return .f
        case 0x05: return .g
        case 0x04: return .h
        case 0x22: return .i
        case 0x26: return .j
        case 0x28: return .k
        case 0x25: return .l
        case 0x2E: return .m
        case 0x2D: return .n
        case 0x1F: return .o
        case 0x23: return .p
        case 0x0C: return .q
        case 0x0F: return .r
        case 0x01: return .s
        case 0x11: return .t
        case 0x20: return .u
        case 0x09: return .v
        case 0x0D: return .w
        case 0x07: return .x
        case 0x10: return .y
        case 0x06: return .z
        case 0x1D: return .zero
        case 0x12: return .one
        case 0x13: return .two
        case 0x14: return .three
        case 0x15: return .four
        case 0x17: return .five
        case 0x16: return .six
        case 0x1A: return .seven
        case 0x1C: return .eight
        case 0x19: return .nine
        case 0x35: return .escape
        case 0x7A: return .f1
        case 0x78: return .f2
        case 0x63: return .f3
        case 0x76: return .f4
        case 0x60: return .f5
        case 0x61: return .f6
        case 0x62: return .f7
        case 0x64: return .f8
        case 0x65: return .f9
        case 0x6D: return .f10
        case 0x67: return .f11
        case 0x6F: return .f12
        case 0x7B: return .leftArrow
        case 0x7C: return .rightArrow
        case 0x7D: return .downArrow
        case 0x7E: return .upArrow
        case 0x31: return .space
        case 0x33: return .delete
        case 0x75: return .forwardDelete
        case 0x24: return .return
        case 0x30: return .tab
        default: return nil
        }
    }
    
    // Convert NSEvent to readable key name (for UI display)
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
        case 0x31: return " "
        case 0x33: return "⌫"
        case 0x75: return "⌦"
        case 0x24: return "⏎"
        case 0x30: return "⇥"
        default:
            // For normal keys, use charactersIgnoringModifiers
            return event.charactersIgnoringModifiers?.uppercased() ?? ""
        }
    }
}

// Notification
extension Notification.Name {
    static let hotkeyTriggered = Notification.Name("HotkeyTriggered")
}
