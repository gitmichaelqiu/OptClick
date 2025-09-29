import os.log
enum AutoToggleBehavior: String, CaseIterable {
    case disable = "disable"
    case followLast = "followLast"

    var localizedDescription: String {
        switch self {
        case .disable:
            return "Disable OptClick"
        case .followLast:
            return "Follow last setting"
        }
    }
}
import Foundation
import AppKit
import Combine

enum LaunchBehavior: String, CaseIterable {
    case enabled = "enabled"
    case disabled = "disabled"
    case lastState = "lastState"

    var localizedDescription: String {
        switch self {
        case .enabled:
            return NSLocalizedString("Settings.General.LaunchBehavior.Enabled", comment: "Enabled")
        case .disabled:
            return NSLocalizedString("Settings.General.LaunchBehavior.Disabled", comment: "Disabled")
        case .lastState:
            return NSLocalizedString("Settings.General.LaunchBehavior.LastState", comment: "Last State")
        }
    }
}

class InputManager: ObservableObject {

    // Auto toggle properties
    private var frontmostAppMonitor: Any?
    private var lastManualState: Bool = false
    private var autoToggleAppBundleId: String {
        UserDefaults.standard.string(forKey: "AutoToggleAppBundleId") ?? ""
    }
    private var autoToggleBehavior: AutoToggleBehavior {
        let raw = UserDefaults.standard.string(forKey: "AutoToggleBehavior") ?? AutoToggleBehavior.disable.rawValue
        return AutoToggleBehavior(rawValue: raw) ?? .disable
    }
    @Published var isEnabled: Bool = false {
        didSet {
            if !isAutoToggling {
                lastManualState = isEnabled
            }
            if isEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
            UserDefaults.standard.set(isEnabled, forKey: Self.lastStateKey)
        }
    }

    private var isAutoToggling = false

    private var keyDownMonitor: Any?
    private var keyUpMonitor: Any?
    static let launchBehaviorKey = "LaunchBehavior"
    static let lastStateKey = "LastState"
    
    init() {
        let behaviorString = UserDefaults.standard.string(forKey: Self.launchBehaviorKey) ?? LaunchBehavior.lastState.rawValue
        let launchBehavior = LaunchBehavior(rawValue: behaviorString) ?? .lastState

        switch launchBehavior {
        case .enabled:
            isEnabled = true
        case .disabled:
            isEnabled = false
        case .lastState:
            isEnabled = UserDefaults.standard.bool(forKey: Self.lastStateKey)
        }

        lastManualState = isEnabled

        if isEnabled {
            startMonitoring()
        }

        startFrontmostAppMonitor()
    }

    private func startFrontmostAppMonitor() {
        // Use NSWorkspace notification for frontmost app change
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleFrontmostAppChange(notification: notification)
        }
    }

    private func handleFrontmostAppChange(notification: Notification) {
        guard !autoToggleAppBundleId.isEmpty else { return }
        guard let userInfo = notification.userInfo,
              let runningApp = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleId = runningApp.bundleIdentifier else { return }

        if bundleId == autoToggleAppBundleId {
            // Target app is now frontmost
            isAutoToggling = true
            if !isEnabled {
                isEnabled = true
            }
            isAutoToggling = false
        } else {
            // Target app is no longer frontmost
            isAutoToggling = true
            switch autoToggleBehavior {
            case .disable:
                if isEnabled {
                    isEnabled = false
                }
            case .followLast:
                if isEnabled != lastManualState {
                    isEnabled = lastManualState
                }
            }
            isAutoToggling = false
        }
    }
    
    private func getCGMouseLocation() -> CGPoint {
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let loc = NSEvent.mouseLocation
        return CGPoint(x: loc.x, y: screenHeight - loc.y)
    }

    // Monitor Keyboard
    private func startMonitoring() {
        stopMonitoring() // ensure no duplicate monitors

        keyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event: event)
        }

        keyUpMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event: event)
            return event
        }
    }

    private func stopMonitoring() {
        if let monitor = keyDownMonitor {
            NSEvent.removeMonitor(monitor)
            keyDownMonitor = nil
        }
        if let monitor = keyUpMonitor {
            NSEvent.removeMonitor(monitor)
            keyUpMonitor = nil
        }
    }

    private var isOptionDown = false

    private func handleFlagsChanged(event: NSEvent) {
        let optionPressed = event.modifierFlags.contains(.option)

        if optionPressed && !isOptionDown {
            // Key just pressed
            isOptionDown = true
            simulateRightMouseDown()
        } else if !optionPressed && isOptionDown {
            // Key just released
            isOptionDown = false
            simulateRightMouseUp()
        }
    }

    // Mouse Simulation
    private func simulateRightMouseDown() {
        let location = getCGMouseLocation()
        let event = CGEvent(mouseEventSource: nil,
                            mouseType: .rightMouseDown,
                            mouseCursorPosition: location,
                            mouseButton: .right)
        event?.post(tap: .cghidEventTap)
    }

    private func simulateRightMouseUp() {
        let location = getCGMouseLocation()
        let event = CGEvent(mouseEventSource: nil,
                            mouseType: .rightMouseUp,
                            mouseCursorPosition: location,
                            mouseButton: .right)
        event?.post(tap: .cghidEventTap)
    }
}
