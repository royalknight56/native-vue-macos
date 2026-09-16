import AppKit

/// A native NSTextField that fills its glyphs with an AppKit gradient.
final class GradientTextField: NSTextField {
    var gradientStartColor = NSColor.systemGreen { didSet { needsDisplay = true } }
    var gradientEndColor = NSColor.systemBlue { didSet { needsDisplay = true } }

    init() {
        super.init(frame: .zero)
        isEditable = false
        isSelectable = false
        isBezeled = false
        drawsBackground = false
        lineBreakMode = .byWordWrapping
        maximumNumberOfLines = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        guard bounds.width > 0, bounds.height > 0 else {
            super.draw(dirtyRect)
            return
        }
        let image = NSImage(size: bounds.size)
        image.lockFocus()
        NSGradient(starting: gradientStartColor, ending: gradientEndColor)?
            .draw(in: NSRect(origin: .zero, size: bounds.size), angle: 0)
        image.unlockFocus()
        textColor = NSColor(patternImage: image)
        super.draw(dirtyRect)
    }
}
