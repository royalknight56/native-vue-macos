import AppKit

@MainActor
final class NativeNode {
    let id: Int
    let type: String
    let view: NSView?
    let window: NSWindow?
    weak var parent: NativeNode?
    var children: [NativeNode] = []
    var listeners: [String: Int] = [:]
    var constraints: [String: NSLayoutConstraint] = [:]
    var actionProxy: NativeEventProxy?

    init(id: Int, type: String, view: NSView? = nil, window: NSWindow? = nil) {
        self.id = id
        self.type = type
        self.view = view
        self.window = window
    }

    var insertionView: NSView? {
        if let scroll = view as? NSScrollView { return scroll.documentView }
        return view
    }
}
