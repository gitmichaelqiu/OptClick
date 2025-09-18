import Foundation
import AppKit
import Combine

class InputManager: ObservableObject {
    @Published var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }

    private var keyDownMonitor: Any?
    private var keyUpMonitor: Any?
    
    
    private func getCGMouseLocation() -> CGPoint {
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let loc = NSEvent.mouseLocation
        return CGPoint(x: loc.x, y: screenHeight - loc.y)
    }

    // MARK: - Monitor Keyboard
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

    // MARK: - Mouse Simulation
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
