import AppKit

@MainActor
public final class NativeElementFactoryRegistry {
    public typealias Factory = @MainActor () -> NSView

    public static let shared = NativeElementFactoryRegistry(registerDefaults: true)

    private var factories: [String: Factory] = [:]

    public init(registerDefaults: Bool = false) {
        if registerDefaults { installDefaults() }
    }

    public func register(_ tag: String, factory: @escaping Factory) {
        factories[tag.lowercased()] = factory
    }

    public func contains(_ tag: String) -> Bool {
        factories[tag.lowercased()] != nil || tag == "mac-window" || tag == "#text" || tag == "#comment"
    }

    func makeView(for tag: String) -> NSView? {
        factories[tag.lowercased()]?()
    }

    private func installDefaults() {
        register("mac-v-stack") {
            let view = NSStackView()
            view.orientation = .vertical
            view.alignment = .leading
            view.spacing = 8
            return view
        }
        register("mac-h-stack") {
            let view = NSStackView()
            view.orientation = .horizontal
            view.alignment = .centerY
            view.spacing = 8
            return view
        }
        register("mac-z-stack") { FlippedView() }
        register("mac-scroll-view") {
            let scroll = NSScrollView()
            scroll.hasVerticalScroller = true
            scroll.drawsBackground = false
            let document = FlippedView()
            document.translatesAutoresizingMaskIntoConstraints = false
            scroll.documentView = document
            return scroll
        }
        register("mac-spacer") {
            let view = NSView()
            view.setContentHuggingPriority(.defaultLow, for: .horizontal)
            view.setContentHuggingPriority(.defaultLow, for: .vertical)
            return view
        }
        register("mac-text") { NSTextField(labelWithString: "") }
        register("mac-gradient-text") { GradientTextField() }
        register("mac-button") { NSButton(title: "", target: nil, action: nil) }
        register("mac-text-field") { NSTextField() }
        register("mac-secure-field") { NSSecureTextField() }
        register("mac-toggle") {
            let button = NSButton(checkboxWithTitle: "", target: nil, action: nil)
            return button
        }
        register("mac-progress") {
            let progress = NSProgressIndicator()
            progress.style = .bar
            progress.minValue = 0
            progress.maxValue = 1
            return progress
        }
        register("mac-divider") {
            let box = NSBox()
            box.boxType = .separator
            return box
        }
        register("mac-image") {
            let image = NSImageView()
            image.imageScaling = .scaleProportionallyUpOrDown
            return image
        }
    }
}

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
