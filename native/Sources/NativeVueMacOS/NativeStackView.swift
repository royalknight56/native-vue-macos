import AppKit

@MainActor
final class NativeStackView: NSStackView, NativeStateTrackable {
    private(set) var contentViews: [NSView] = []
    var nativeJustifyContent: String? { didSet { rebuildArrangement() } }
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

    func insertNativeArrangedSubview(_ view: NSView, at index: Int) {
        contentViews.removeAll { $0 === view }
        contentViews.insert(view, at: min(index, contentViews.count))
        rebuildArrangement()
    }

    func removeNativeArrangedSubview(_ view: NSView) {
        contentViews.removeAll { $0 === view }
        removeArrangedSubview(view)
        rebuildArrangement()
    }

    func rebuildArrangement() {
        for arranged in arrangedSubviews {
            removeArrangedSubview(arranged)
            if !contentViews.contains(where: { $0 === arranged }) { arranged.removeFromSuperview() }
        }
        guard let justify = nativeJustifyContent, justify != "flexStart", contentViews.count > 0 else {
            for view in contentViews { addArrangedSubview(view) }
            return
        }

        let makeSpacer: () -> NSView = {
            let spacer = NSView()
            spacer.translatesAutoresizingMaskIntoConstraints = false
            spacer.setContentHuggingPriority(.init(1), for: self.orientation == .horizontal ? .horizontal : .vertical)
            spacer.setContentCompressionResistancePriority(.init(1), for: self.orientation == .horizontal ? .horizontal : .vertical)
            return spacer
        }

        var spacers: [NSView] = []
        switch justify {
        case "center":
            let leading = makeSpacer(), trailing = makeSpacer()
            spacers = [leading, trailing]
            addArrangedSubview(leading)
            for view in contentViews { addArrangedSubview(view) }
            addArrangedSubview(trailing)
        case "flexEnd":
            let leading = makeSpacer()
            spacers = [leading]
            addArrangedSubview(leading)
            for view in contentViews { addArrangedSubview(view) }
        case "spaceBetween":
            for (index, view) in contentViews.enumerated() {
                addArrangedSubview(view)
                if index < contentViews.count - 1 { let spacer = makeSpacer(); spacers.append(spacer); addArrangedSubview(spacer) }
            }
        case "spaceAround", "spaceEvenly":
            for view in contentViews {
                let spacer = makeSpacer(); spacers.append(spacer); addArrangedSubview(spacer)
                addArrangedSubview(view)
            }
            let trailing = makeSpacer(); spacers.append(trailing); addArrangedSubview(trailing)
        default:
            for view in contentViews { addArrangedSubview(view) }
        }
        guard let first = spacers.first else { return }
        for (index, spacer) in spacers.dropFirst().enumerated() {
            let multiplier: CGFloat = justify == "spaceAround" && index < spacers.count - 2 ? 2 : 1
            let constraint = orientation == .horizontal
                ? spacer.widthAnchor.constraint(equalTo: first.widthAnchor, multiplier: multiplier)
                : spacer.heightAnchor.constraint(equalTo: first.heightAnchor, multiplier: multiplier)
            constraint.isActive = true
        }
    }
}
