import AppKit

@MainActor
final class NativeStyleButton: NSButton {
    var stateDidChange: ((String, Bool) -> Void)?
    private var hoverArea: NSTrackingArea?

    override func updateTrackingAreas() {
        if let hoverArea { removeTrackingArea(hoverArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        hoverArea = area
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) {
        stateDidChange?("hover", true)
        super.mouseEntered(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        stateDidChange?("hover", false)
        super.mouseExited(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        stateDidChange?("pressed", true)
        super.mouseDown(with: event)
        stateDidChange?("pressed", false)
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result { stateDidChange?("focus", true) }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result { stateDidChange?("focus", false) }
        return result
    }
}
