import Foundation
import AppKit
import Combine
import Carbon

class HotkeyManager: ObservableObject {
    @Published var shortcut: Shortcut {
        didSet {
            registerShortcut()
        }
    }

    @Published var isListeningForShortcut: Bool = false

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var monitor: Any?
    private let defaultShortcut = Shortcut(key: "R", modifiers: [.control])
    private let hotKeyID = EventHotKeyID(signature: OSType(0x4B455920), id: 1) // 'KEY '

    init() {
        self.shortcut = defaultShortcut
        setupCarbonEventHandler()
        registerShortcut()
    }

    var shortcutDescription: String {
        isListeningForShortcut ? "Press new shortcut…" : shortcut.description
    }

    // MARK: - Carbon Event Handler Setup
    private func setupCarbonEventHandler() {
        var eventTypes = [EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))]
        
        let callback: EventHandlerProcPtr = { (nextHandler, theEvent, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
            
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(theEvent, OSType(kEventParamDirectObject), OSType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            if status == noErr && hotKeyID.id == manager.hotKeyID.id {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .hotkeyTriggered, object: nil)
                }
            }
            
            return noErr
        }
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetEventDispatcherTarget(), callback, 1, &eventTypes, selfPtr, &eventHandler)
    }

    // MARK: - Shortcut Handling
    private func registerShortcut() {
        // Unregister existing hotkey
        unregisterShortcut()
        
        // Don't register if key is empty (unassigned)
        guard !shortcut.key.isEmpty,
              let keyCode = shortcut.carbonKeyCode(),
              let modifierFlags = shortcut.carbonModifierFlags() else {
            return
        }
        
        // Register the global hotkey using Carbon
        let status = RegisterEventHotKey(
            keyCode,
            modifierFlags,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if status != noErr {
            print("Failed to register hotkey: \(status)")
        }
    }
    
    private func unregisterShortcut() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    func startListeningForNewShortcut() {
        isListeningForShortcut = true

        // Temporarily unregister current hotkey
        unregisterShortcut()

        // Remove any existing monitor
        removeKeyListener()

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
            self.removeKeyListener()
            self.registerShortcut()
            return nil // swallow the event
        }
    }
    
    private func removeKeyListener() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    func resetToDefault() {
        shortcut = defaultShortcut
    }
    
    deinit {
        unregisterShortcut()
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
        removeKeyListener()
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

    // Convert to Carbon key code
    func carbonKeyCode() -> UInt32? {
        switch key {
        case "A": return 0x00
        case "B": return 0x0B
        case "C": return 0x08
        case "D": return 0x02
        case "E": return 0x0E
        case "F": return 0x03
        case "G": return 0x05
        case "H": return 0x04
        case "I": return 0x22
        case "J": return 0x26
        case "K": return 0x28
        case "L": return 0x25
        case "M": return 0x2E
        case "N": return 0x2D
        case "O": return 0x1F
        case "P": return 0x23
        case "Q": return 0x0C
        case "R": return 0x0F
        case "S": return 0x01
        case "T": return 0x11
        case "U": return 0x20
        case "V": return 0x09
        case "W": return 0x0D
        case "X": return 0x07
        case "Y": return 0x10
        case "Z": return 0x06
        case "0": return 0x1D
        case "1": return 0x12
        case "2": return 0x13
        case "3": return 0x14
        case "4": return 0x15
        case "5": return 0x17
        case "6": return 0x16
        case "7": return 0x1A
        case "8": return 0x1C
        case "9": return 0x19
        case "F1": return 0x7A
        case "F2": return 0x78
        case "F3": return 0x63
        case "F4": return 0x76
        case "F5": return 0x60
        case "F6": return 0x61
        case "F7": return 0x62
        case "F8": return 0x64
        case "F9": return 0x65
        case "F10": return 0x6D
        case "F11": return 0x67
        case "F12": return 0x6F
        case "←": return 0x7B
        case "→": return 0x7C
        case "↓": return 0x7D
        case "↑": return 0x7E
        case "Escape": return 0x35
        case " ": return 0x31
        case "⌫": return 0x33
        case "⌦": return 0x75
        case "⏎": return 0x24
        case "⇥": return 0x30
        default: return nil
        }
    }
    
    // Convert to Carbon modifier flags
    func carbonModifierFlags() -> UInt32? {
        var carbonModifiers: UInt32 = 0
        
        if modifiers.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if modifiers.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        if modifiers.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        
        return carbonModifiers
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

// MARK: - Notification
extension Notification.Name {
    static let hotkeyTriggered = Notification.Name("HotkeyTriggered")
}
