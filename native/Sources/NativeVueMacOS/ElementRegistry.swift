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
        register("mac-view") { FlippedView() }
        register("mac-v-stack") {
            let view = NativeStackView()
            view.orientation = .vertical
            view.alignment = .leading
            view.spacing = 8
            return view
        }
        register("mac-h-stack") {
            let view = NativeStackView()
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
        register("mac-button") { NativeStyleButton(title: "", target: nil, action: nil) }
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

        installStandardAppKitElements()
    }

    /// Registers every public, non-deprecated AppKit view/control that can be
    /// represented as a standalone Vue node on the macOS 13 deployment target.
    /// Controller, cell, menu and data-source objects deliberately stay outside
    /// this registry because they are not views in AppKit's ownership model.
    private func installStandardAppKitElements() {
        register("mac-box") { NSBox() }
        register("mac-clip-view") { NSClipView() }
        register("mac-split-view") { NSSplitView() }
        register("mac-tab-view") { NSTabView() }
        register("mac-grid-view") { NSGridView(frame: .zero) }
        register("mac-visual-effect-view") { NSVisualEffectView() }
        register("mac-scroller") { NSScroller() }
        register("mac-ruler-view") {
            NSRulerView(scrollView: NSScrollView(), orientation: .horizontalRuler)
        }

        register("mac-radio") { NSButton(radioButtonWithTitle: "", target: nil, action: nil) }
        register("mac-switch") { NSSwitch() }
        register("mac-text-view") { NSTextView() }
        register("mac-search-field") { NSSearchField() }
        register("mac-token-field") { NSTokenField() }
        register("mac-combo-box") { NSComboBox() }
        register("mac-pop-up-button") { NSPopUpButton() }
        register("mac-segmented-control") { NSSegmentedControl(labels: [], trackingMode: .selectOne, target: nil, action: nil) }
        register("mac-combo-button") { NSComboButton(title: "", menu: nil, target: nil, action: nil) }
        register("mac-slider") { NSSlider() }
        register("mac-stepper") { NSStepper() }
        register("mac-level-indicator") { NSLevelIndicator() }
        register("mac-date-picker") { NSDatePicker() }
        register("mac-color-well") { NSColorWell() }
        register("mac-path-control") { NSPathControl() }

        register("mac-table-view") { NSTableView() }
        register("mac-outline-view") { NSOutlineView() }
        register("mac-collection-view") {
            let view = NSCollectionView()
            view.collectionViewLayout = NSCollectionViewFlowLayout()
            return view
        }
        register("mac-browser") { NSBrowser() }
        register("mac-rule-editor") { NSRuleEditor() }
        register("mac-scrubber") { NSScrubber() }
        register("mac-table-row-view") { NSTableRowView() }
        register("mac-table-cell-view") { NSTableCellView() }
        register("mac-table-header-view") { NSTableHeaderView() }
    }
}

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
