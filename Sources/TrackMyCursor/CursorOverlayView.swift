// NSView that draws the highlight ring around the cursor; colors/glow react to click state.
// Reconstructed from original CursorWindowView/CursorView drawing logic.
import AppKit

final class CursorOverlayView: NSView {
    var model: CursorModel

    init(model: CursorModel) {
        self.model = model
        super.init(frame: .zero)
        wantsLayer = true
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ dirtyRect: NSRect) {
        guard model.isEnabled else { return }
        guard model.isBorderVisible else { return }
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        let size = model.circleSize
        let rect = NSRect(x: center.x - size / 2, y: center.y - size / 2, width: size, height: size)

        var color = model.effectivePrimaryColor
        if model.isLeftMouseDown && model.leftClickEnabled {
            color = model.leftClickColor
        } else if model.isRightMouseDown && model.rightClickEnabled {
            color = model.rightClickColor
        }

        if !model.borderOnly {
            ctx.saveGState()
            let glowRect = rect.insetBy(dx: -6, dy: -6)
            let glowPath = CGPath(ellipseIn: glowRect, transform: nil)
            ctx.addPath(glowPath)
            ctx.setFillColor(color.withAlphaComponent(0.25).cgColor)
            ctx.fillPath()
            ctx.restoreGState()
        }

        ctx.saveGState()
        let path = CGPath(ellipseIn: rect, transform: nil)
        ctx.addPath(path)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(model.borderWidth)
        ctx.strokePath()
        ctx.restoreGState()

    }

    func refresh() { needsDisplay = true }
}
