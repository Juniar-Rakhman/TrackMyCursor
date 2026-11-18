import AppKit
import Carbon
// SwiftUI settings form: general, colors, size. Original had separate SettingsBehaviorView/AppearanceView/MagnifierView tabs.
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: CursorModel

    var body: some View {
        Form {
            Section("General") {
                Toggle("Enabled", isOn: $model.isEnabled)
                Toggle("Use accent color", isOn: $model.useAccentColor)
                Toggle("Border only", isOn: $model.borderOnly)
            }
            Divider()
            Section("Colors") {
                ColorPicker(
                    "Primary",
                    selection: Binding(
                        get: { Color(model.primaryColor) },
                        set: { model.primaryColor = NSColor($0) }
                    ))
                Toggle("Left click color", isOn: $model.leftClickEnabled)
                if model.leftClickEnabled {
                    ColorPicker(
                        "Left click",
                        selection: Binding(
                            get: { Color(model.leftClickColor) },
                            set: { model.leftClickColor = NSColor($0) }
                        ))
                }
                Toggle("Right click color", isOn: $model.rightClickEnabled)
                if model.rightClickEnabled {
                    ColorPicker(
                        "Right click",
                        selection: Binding(
                            get: { Color(model.rightClickColor) },
                            set: { model.rightClickColor = NSColor($0) }
                        ))
                }
            }
            Divider()
            Section("Behavior") {
                Slider(value: $model.borderDisappearTime, in: 0...10, step: 0.5) {
                    Text(
                        "Disappears after: \(model.borderDisappearTime == 0 ? "Never" : String(format: "%.1f s", model.borderDisappearTime))"
                    )
                }
            }
            Divider()
            Section("Hotkey") {
                HotkeyRecorderField(
                    keyCode: $model.hotkeyKeyCode, modifiers: $model.hotkeyModifiers,
                    key: $model.hotkeyKey
                )
                .frame(height: 24)
                .help("Click the field, then press a key combination with a modifier.")
            }
            Divider()
            Section("Size") {
                Slider(value: $model.circleSize, in: 20...150) {
                    Text("Circle: \(Int(model.circleSize))")
                }
                Slider(value: $model.borderWidth, in: 1...20) {
                    Text("Border: \(Int(model.borderWidth))")
                }
            }
        }
        .padding()
        .frame(width: 400, height: 500)
    }

}

final class HotkeyCaptureTextField: NSTextField {
    var onKey: ((NSEvent) -> Void)?
    var isRecording = false
    var savedStringValue: String = ""
    override var acceptsFirstResponder: Bool { true }
    override func mouseDown(with event: NSEvent) {
        isRecording = true
        stringValue = "Press hotkey combination…"
        window?.makeFirstResponder(self)
    }
    override func keyDown(with event: NSEvent) {
        isRecording = false
        let prompt = "Press hotkey combination…"
        if stringValue == prompt { stringValue = savedStringValue }
        onKey?(event)
    }

    override func resignFirstResponder() -> Bool {
        let ok = super.resignFirstResponder()
        isRecording = false
        if !savedStringValue.isEmpty {
            stringValue = savedStringValue
        }
        return ok
    }
}

struct HotkeyRecorderField: NSViewRepresentable {
    @Binding var keyCode: Int
    @Binding var modifiers: Int
    @Binding var key: String

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> HotkeyCaptureTextField {
        let tf = HotkeyCaptureTextField()
        tf.isEditable = false
        tf.isSelectable = false
        tf.alignment = .center
        tf.bezelStyle = .roundedBezel
        tf.savedStringValue = display()
        tf.stringValue = tf.savedStringValue
        tf.onKey = { [weak contextCoordinator = context.coordinator] event in
            contextCoordinator?.handle(event)
        }
        return tf
    }

    func updateNSView(_ nsView: HotkeyCaptureTextField, context: Context) {
        let current = display()
        nsView.savedStringValue = current
        if !nsView.isRecording {
            nsView.stringValue = current
        }
        nsView.onKey = { [weak contextCoordinator = context.coordinator] event in
            contextCoordinator?.handle(event)
        }
    }

    private func display() -> String {
        var parts: [String] = []
        if modifiers & cmdKey != 0 { parts.append("Cmd") }
        if modifiers & shiftKey != 0 { parts.append("Shift") }
        if modifiers & optionKey != 0 { parts.append("Option") }
        if modifiers & controlKey != 0 { parts.append("Control") }
        parts.append(key)
        return parts.joined(separator: "+")
    }

    final class Coordinator {
        var parent: HotkeyRecorderField
        init(_ parent: HotkeyRecorderField) { self.parent = parent }
        func handle(_ event: NSEvent) {
            let mods = event.modifierFlags.intersection([.command, .shift, .option, .control])
            guard !mods.isEmpty else { return }
            parent.keyCode = Int(event.keyCode)
            parent.modifiers = CursorModel.carbonModifiers(from: mods)
            parent.key = (event.charactersIgnoringModifiers ?? "?").uppercased()
            DispatchQueue.main.async {
                if let delegate = NSApp.delegate as? AppDelegate {
                    delegate.registerHotkey()
                    delegate.buildMenu()
                }
            }
        }
    }
}
