// Borderless, transparent, top-most overlay window that follows the mouse pointer across all spaces.
import AppKit

final class CursorOverlayWindow: NSWindow {
    let overlayView: CursorOverlayView

    init(model: CursorModel) {
        self.overlayView = CursorOverlayView(model: model)
        let size: CGFloat = 200
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: size, height: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false)
        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        ignoresMouseEvents = true
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        contentView = overlayView
    }

    func updatePosition(_ point: NSPoint) {
        let size = frame.size
        let origin = NSPoint(x: point.x - size.width / 2, y: point.y - size.height / 2)
        setFrameOrigin(origin)
        overlayView.refresh()
    }
}
