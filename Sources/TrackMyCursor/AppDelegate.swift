// Application delegate: menu-bar (accessory) lifecycle, status item, global cursor overlay, settings window, URL scheme handling.
import AppKit
import Carbon
import Combine
import SwiftUI

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public override init() { super.init() }
    let model = CursorModel.shared
    var statusItem: NSStatusItem!
    var overlayWindow: CursorOverlayWindow!
    var settingsWindow: NSWindow?
    var trackingTimer: Timer?
    var hotKeyRef: EventHotKeyRef?
    var registeredHotkeyKeyCode: Int?
    var registeredHotkeyModifiers: Int?
    var hotkeyRegistered: Bool = false
    var nextHotkeyID: UInt32 = 1
    var cancellables = Set<AnyCancellable>()
    var lastMouseLocation: NSPoint?
    var lastMoveTime: Date = Date()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        overlayWindow = CursorOverlayWindow(model: model)
        overlayWindow.orderFrontRegardless()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "cursorarrow.rays", accessibilityDescription: "Track My Cursor")
        }

        buildMenu()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ in
                DispatchQueue.main.async {
                    CursorModel.shared.toggle()
                    if let delegate = NSApp.delegate as? AppDelegate {
                        delegate.buildMenu()
                    }
                }
                return noErr
            }, 1, &eventType, nil, nil)
        registerHotkey()

        model.$hotkeyKeyCode.combineLatest(model.$hotkeyModifiers).combineLatest(model.$hotkeyKey)
            .sink { [weak self] _, _ in
                self?.registerHotkey()
                self?.buildMenu()
            }.store(in: &cancellables)

        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) {
            [weak self] _ in
            guard let self = self else { return }
            let loc = NSEvent.mouseLocation
            let moved =
                self.lastMouseLocation == nil || self.lastMouseLocation!.x != loc.x
                || self.lastMouseLocation!.y != loc.y
            if moved {
                self.lastMouseLocation = loc
                self.lastMoveTime = Date()
                if !self.model.isBorderVisible {
                    self.model.isBorderVisible = true
                }
            }
            guard self.model.isEnabled else { return }
            self.overlayWindow.updatePosition(loc)
            self.updateIdleVisibility(now: Date())
        }

        NSEvent.addGlobalMonitorForEvents(matching: [
            .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
        ]) { [weak self] event in
            guard let self = self else { return }
            let beforeLeft = self.model.isLeftMouseDown
            let beforeRight = self.model.isRightMouseDown
            switch event.type {
            case .leftMouseDown: self.model.isLeftMouseDown = true
            case .leftMouseUp: self.model.isLeftMouseDown = false
            case .rightMouseDown: self.model.isRightMouseDown = true
            case .rightMouseUp: self.model.isRightMouseDown = false
            default: break
            }
            if beforeLeft != self.model.isLeftMouseDown
                || beforeRight != self.model.isRightMouseDown {
                self.overlayWindow.overlayView.refresh()
            }
        }

    }

    func buildMenu() {
        let menu = NSMenu()
        let toggleKey = model.hotkeyKey.lowercased()
        let toggle = NSMenuItem(
            title: model.isEnabled ? "Disable" : "Enable", action: #selector(toggleEnabled),
            keyEquivalent: toggleKey)
        toggle.keyEquivalentModifierMask = CursorModel.modifierFlags(fromCarbon: model.hotkeyModifiers)
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(NSMenuItem.separator())
        let settings = NSMenuItem(
            title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit Track My Cursor", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
    }

    func registerHotkey() {
        let newKeyCode = model.hotkeyKeyCode
        let newModifiers = model.hotkeyModifiers

        // Nothing to do if the combo is unchanged and currently registered.
        if hotKeyRef != nil,
            hotkeyRegistered,
            registeredHotkeyKeyCode == newKeyCode,
            registeredHotkeyModifiers == newModifiers {
            return
        }

        // Register the new hotkey first, while the previous one (if any) is still active.
        let hotKeyID = EventHotKeyID(signature: OSType(0x464D_4352), id: nextHotkeyID)
        nextHotkeyID &+= 1
        var newRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(newKeyCode), UInt32(newModifiers), hotKeyID,
            GetApplicationEventTarget(), 0, &newRef)

        guard status == noErr, let ref = newRef else {
            // Keep the previous registration (and combo) intact; warn instead of failing silently.
            NSLog("TrackMyCursor: failed to register global hotkey (OSStatus %d); keeping previous combo.", status)
            hotkeyRegistered = false
            return
        }

        // Only now that registration succeeded, drop the previous hotkey.
        if let oldRef = hotKeyRef {
            UnregisterEventHotKey(oldRef)
        }
        hotKeyRef = ref
        registeredHotkeyKeyCode = newKeyCode
        registeredHotkeyModifiers = newModifiers
        hotkeyRegistered = true
    }

    public func updateIdleVisibility(now: Date = Date()) {
        if model.borderDisappearTime <= 0 {
            if !model.isBorderVisible { model.isBorderVisible = true }
        } else {
            let idle = now.timeIntervalSince(lastMoveTime)
            if idle >= model.borderDisappearTime && model.isBorderVisible {
                model.isBorderVisible = false
            }
        }
    }

    @objc func toggleEnabled() {
        model.toggle()
        buildMenu()
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView(model: model)
            let hosting = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: hosting)
            window.title = "Track My Cursor Settings"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 420, height: 520))
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

}
