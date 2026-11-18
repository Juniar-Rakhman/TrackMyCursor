// Central observable model for cursor highlight settings and runtime click state.
// Reverse-engineered from _TtC10Cursor_Pro11CursorModel (property names recovered from binary metadata).
import AppKit
import Carbon
import Combine
import SwiftUI

final class CursorModel: ObservableObject {
    static let shared = CursorModel()

    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    @Published var isEnabled: Bool = true {
        didSet {
            isBorderVisible = isEnabled
        }
    }
    @Published var primaryColor: NSColor = .systemBlue
    @Published var leftClickColor: NSColor = .systemRed
    @Published var rightClickColor: NSColor = .systemGreen
    @Published var leftClickEnabled: Bool = true
    @Published var rightClickEnabled: Bool = true
    @Published var useAccentColor: Bool = false
    @Published var circleSize: CGFloat = 70
    @Published var borderWidth: CGFloat = 7
    @Published var borderDisappearTime: Double = 5
    @Published var borderOnly: Bool = false
    @Published var hotkeyKeyCode: Int = Int(kVK_ANSI_K)
    @Published var hotkeyModifiers: Int = cmdKey | shiftKey
    @Published var hotkeyKey: String = "K"

    @Published var isLeftMouseDown: Bool = false
    @Published var isRightMouseDown: Bool = false
    @Published var isBorderVisible: Bool = true

    var effectivePrimaryColor: NSColor {
        if useAccentColor { return NSColor.controlAccentColor }
        return primaryColor
    }

    // MARK: Hotkey modifier mapping (shared by AppDelegate and SettingsView)
    static func modifierFlags(fromCarbon carbon: Int) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if carbon & cmdKey != 0 { flags.insert(.command) }
        if carbon & shiftKey != 0 { flags.insert(.shift) }
        if carbon & optionKey != 0 { flags.insert(.option) }
        if carbon & controlKey != 0 { flags.insert(.control) }
        return flags
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var carbon = 0
        if flags.contains(.command) { carbon |= cmdKey }
        if flags.contains(.shift) { carbon |= shiftKey }
        if flags.contains(.option) { carbon |= optionKey }
        if flags.contains(.control) { carbon |= controlKey }
        return carbon
    }

    private init() {
        load()
        bindPersistence()
    }

    func toggle() {
        isEnabled.toggle()
    }

    // MARK: Persistence

    private func key(_ name: String) -> String { "TrackMyCursor.\(name)" }

    private func load() {
        let d = defaults
        if d.object(forKey: key("isEnabled")) != nil {
            isEnabled = d.bool(forKey: key("isEnabled"))
        }
        if d.object(forKey: key("useAccentColor")) != nil {
            useAccentColor = d.bool(forKey: key("useAccentColor"))
        }
        if d.object(forKey: key("leftClickEnabled")) != nil {
            leftClickEnabled = d.bool(forKey: key("leftClickEnabled"))
        }
        if d.object(forKey: key("rightClickEnabled")) != nil {
            rightClickEnabled = d.bool(forKey: key("rightClickEnabled"))
        }
        if d.object(forKey: key("circleSize")) != nil {
            circleSize = CGFloat(d.double(forKey: key("circleSize")))
        }
        if d.object(forKey: key("borderWidth")) != nil {
            borderWidth = CGFloat(d.double(forKey: key("borderWidth")))
        }
        if d.object(forKey: key("borderDisappearTime")) != nil {
            borderDisappearTime = d.double(forKey: key("borderDisappearTime"))
        }
        if d.object(forKey: key("borderOnly")) != nil {
            borderOnly = d.bool(forKey: key("borderOnly"))
        }
        if d.object(forKey: key("hotkeyKeyCode")) != nil {
            hotkeyKeyCode = d.integer(forKey: key("hotkeyKeyCode"))
        }
        if d.object(forKey: key("hotkeyModifiers")) != nil {
            hotkeyModifiers = d.integer(forKey: key("hotkeyModifiers"))
        }
        if let k = d.string(forKey: key("hotkeyKey")) { hotkeyKey = k }

        if let data = d.data(forKey: key("primaryColor")),
            let c = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
        {
            primaryColor = c
        }
        if let data = d.data(forKey: key("leftClickColor")),
            let c = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
        {
            leftClickColor = c
        }
        if let data = d.data(forKey: key("rightClickColor")),
            let c = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data)
        {
            rightClickColor = c
        }
    }

    private func bindPersistence() {
        $isEnabled.dropFirst().sink { [weak self] in
            self?.defaults.set($0, forKey: self!.key("isEnabled"))
        }.store(in: &cancellables)
        $useAccentColor.dropFirst().sink { [weak self] in
            self?.defaults.set($0, forKey: self!.key("useAccentColor"))
        }.store(in: &cancellables)
        $leftClickEnabled.dropFirst().sink { [weak self] in
            self?.defaults.set($0, forKey: self!.key("leftClickEnabled"))
        }.store(in: &cancellables)
        $rightClickEnabled.dropFirst().sink { [weak self] in
            self?.defaults.set($0, forKey: self!.key("rightClickEnabled"))
        }.store(in: &cancellables)
        $circleSize.dropFirst().sink { [weak self] in
            self?.defaults.set(Double($0), forKey: self!.key("circleSize"))
        }.store(in: &cancellables)
        $borderWidth.dropFirst().sink { [weak self] in
            self?.defaults.set(Double($0), forKey: self!.key("borderWidth"))
        }.store(in: &cancellables)
        $borderDisappearTime.dropFirst().sink { [weak self] in
            self?.defaults.set($0, forKey: self!.key("borderDisappearTime"))
        }.store(in: &cancellables)
        $borderOnly.dropFirst().sink { [weak self] in
            self?.defaults.set($0, forKey: self!.key("borderOnly"))
        }.store(in: &cancellables)
        $hotkeyKeyCode.dropFirst().sink { [weak self] in
            self?.defaults.set($0, forKey: self!.key("hotkeyKeyCode"))
        }.store(in: &cancellables)
        $hotkeyModifiers.dropFirst().sink { [weak self] in
            self?.defaults.set($0, forKey: self!.key("hotkeyModifiers"))
        }.store(in: &cancellables)
        $hotkeyKey.dropFirst().sink { [weak self] in
            self?.defaults.set($0, forKey: self!.key("hotkeyKey"))
        }.store(in: &cancellables)

        $primaryColor.dropFirst().sink { [weak self] in
            guard let self = self,
                let data = try? NSKeyedArchiver.archivedData(
                    withRootObject: $0, requiringSecureCoding: false)
            else { return }
            self.defaults.set(data, forKey: self.key("primaryColor"))
        }.store(in: &cancellables)
        $leftClickColor.dropFirst().sink { [weak self] in
            guard let self = self,
                let data = try? NSKeyedArchiver.archivedData(
                    withRootObject: $0, requiringSecureCoding: false)
            else { return }
            self.defaults.set(data, forKey: self.key("leftClickColor"))
        }.store(in: &cancellables)
        $rightClickColor.dropFirst().sink { [weak self] in
            guard let self = self,
                let data = try? NSKeyedArchiver.archivedData(
                    withRootObject: $0, requiringSecureCoding: false)
            else { return }
            self.defaults.set(data, forKey: self.key("rightClickColor"))
        }.store(in: &cancellables)
    }
}
