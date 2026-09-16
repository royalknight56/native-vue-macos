import AppKit
import JavaScriptCore

@MainActor @objc public protocol NativeBridgeExports: JSExport {
    func createApplicationRoot() -> Int
    func createNode(_ type: String) -> Int
    func insertNode(_ childID: Int, _ parentID: Int, _ index: Int) -> Bool
    func removeNode(_ nodeID: Int) -> Bool
    func setText(_ nodeID: Int, _ value: String) -> Bool
    func setProp(_ nodeID: Int, _ name: String, _ value: JSValue) -> Bool
    func setStyle(_ nodeID: Int, _ name: String, _ value: JSValue) -> Bool
    func addEventListener(_ nodeID: Int, _ event: String, _ callbackID: Int) -> Bool
    func removeEventListener(_ nodeID: Int, _ event: String, _ callbackID: Int) -> Bool
    func showWindow(_ nodeID: Int) -> Bool
    func dispose()
    func takeLastError() -> String?
    func reportError(_ message: String, _ stack: String)
    func applyHotUpdate(_ code: String) -> Bool
}

@MainActor
public final class NativeBridge: NSObject, NativeBridgeExports {
    private let registry: NativeElementFactoryRegistry
    private var nodes: [Int: NativeNode] = [:]
    private var nextID = 1
    private var rootID: Int?
    private var lastError: String?
    weak var context: JSContext?
    var hotUpdateEvaluator: ((String) -> Bool)?

    public convenience override init() {
        self.init(registry: .shared)
    }

    public init(registry: NativeElementFactoryRegistry) {
        self.registry = registry
        super.init()
    }

    public func createApplicationRoot() -> Int {
        if let rootID { return rootID }
        let id = allocateID()
        nodes[id] = NativeNode(id: id, type: "#root")
        rootID = id
        return id
    }

    public func createNode(_ type: String) -> Int {
        perform(-1) {
            guard registry.contains(type) else { throw failure("Unknown native element <\(type)>") }
            let id = allocateID()
            switch type {
            case "mac-window":
                let content = FlippedView()
                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 720, height: 540),
                    styleMask: [.titled, .closable, .miniaturizable, .resizable],
                    backing: .buffered,
                    defer: false
                )
                window.title = "Native Vue macOS"
                window.contentView = content
                window.center()
                nodes[id] = NativeNode(id: id, type: type, view: content, window: window)
            case "#text":
                nodes[id] = NativeNode(id: id, type: type, view: NSTextField(labelWithString: ""))
            case "#comment":
                let view = NSView()
                view.isHidden = true
                nodes[id] = NativeNode(id: id, type: type, view: view)
            default:
                guard let view = registry.makeView(for: type) else { throw failure("No factory registered for <\(type)>") }
                let node = NativeNode(id: id, type: type, view: view)
                nodes[id] = node
                if let button = view as? NativeStyleButton {
                    button.stateDidChange = { [weak self, weak node] state, active in
                        guard let self, let node else { return }
                        self.setNativeState(nodeID: node.id, state: state, active: active)
                    }
                }
            }
            return id
        }
    }

    public func insertNode(_ childID: Int, _ parentID: Int, _ index: Int) -> Bool {
        perform(false) {
            guard let child = nodes[childID] else { throw failure("Unknown child node \(childID)") }
            guard let parent = nodes[parentID] else { throw failure("Unknown parent node \(parentID)") }
            guard child !== parent else { throw failure("A node cannot contain itself") }
            guard index >= 0 && index <= parent.children.count else { throw failure("Insert index \(index) is out of bounds") }

            detach(child, removeView: true)
            parent.children.insert(child, at: index)
            child.parent = parent

            if child.window != nil {
                guard parent.type == "#root" else { throw failure("<mac-window> must be attached to the application root") }
                return true
            }
            guard let childView = child.view else { throw failure("Node \(childID) has no native view") }
            guard let parentView = parent.insertionView else { throw failure("<\(parent.type)> cannot contain native views") }
            childView.translatesAutoresizingMaskIntoConstraints = false

            let isAbsolute = child.styleValues["position"] as? String == "absolute"
            if let stack = parentView as? NativeStackView, !isAbsolute {
                let nativeIndex = parent.children.prefix(index)
                    .filter { $0 !== child && ($0.styleValues["position"] as? String) != "absolute" }.count
                stack.insertNativeArrangedSubview(childView, at: nativeIndex)
            } else if let stack = parentView as? NSStackView, !isAbsolute {
                stack.insertArrangedSubview(childView, at: min(index, stack.arrangedSubviews.count))
            } else {
                let siblingViews = parent.children.compactMap(\.view).filter { $0 !== childView }
                if index < siblingViews.count {
                    parentView.addSubview(childView, positioned: .below, relativeTo: siblingViews[index])
                } else {
                    parentView.addSubview(childView)
                }
                pinToContainerIfNeeded(childView, parent: parent)
            }
            refreshLayoutAfterInsertion(child)
            return true
        }
    }

    public func removeNode(_ nodeID: Int) -> Bool {
        perform(false) {
            guard let node = nodes[nodeID] else { throw failure("Unknown node \(nodeID)") }
            removeRecursively(node)
            return true
        }
    }

    public func setText(_ nodeID: Int, _ value: String) -> Bool {
        perform(false) {
            let node = try requireNode(nodeID)
            if let field = node.view as? NSTextField {
                node.rawText = value
                field.stringValue = value
                refreshTextAppearance(node)
            } else if let button = node.view as? NSButton {
                button.title = value
            } else {
                throw failure("<\(node.type)> does not support text content")
            }
            return true
        }
    }

    public func setProp(_ nodeID: Int, _ name: String, _ value: JSValue) -> Bool {
        perform(false) {
            let node = try requireNode(nodeID)
            try applyProperty(node: node, name: name, value: value)
            return true
        }
    }

    public func setStyle(_ nodeID: Int, _ name: String, _ value: JSValue) -> Bool {
        perform(false) {
            let node = try requireNode(nodeID)
            try applyStyle(node: node, name: name, value: value)
            return true
        }
    }

    public func addEventListener(_ nodeID: Int, _ event: String, _ callbackID: Int) -> Bool {
        perform(false) {
            let node = try requireNode(nodeID)
            guard supportedEvents(for: node).contains(event) else {
                throw failure("Event \(event) is not supported by <\(node.type)>")
            }
            node.listeners[event] = callbackID
            attachEventProxy(to: node)
            return true
        }
    }

    public func removeEventListener(_ nodeID: Int, _ event: String, _ callbackID: Int) -> Bool {
        perform(false) {
            let node = try requireNode(nodeID)
            if node.listeners[event] == callbackID { node.listeners.removeValue(forKey: event) }
            return true
        }
    }

    public func showWindow(_ nodeID: Int) -> Bool {
        perform(false) {
            let node = try requireNode(nodeID)
            guard let window = node.window else { throw failure("Node \(nodeID) is not a window") }
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return true
        }
    }

    public func dispose() {
        for node in nodes.values where node.window != nil { node.window?.close() }
        nodes.removeAll()
        rootID = nil
    }

    public func takeLastError() -> String? {
        defer { lastError = nil }
        return lastError
    }

    public func reportError(_ message: String, _ stack: String) {
        fputs("[native-vue-macos] \(message)\n\(stack)\n", stderr)
    }

    public func applyHotUpdate(_ code: String) -> Bool {
        hotUpdateEvaluator?(code) ?? false
    }

    func viewForTesting(_ nodeID: Int) -> NSView? {
        nodes[nodeID]?.view
    }

    func dispatch(nodeID: Int, event: String, payload: [String: Any]) {
        guard let callbackID = nodes[nodeID]?.listeners[event], let context else { return }
        context.objectForKeyedSubscript("__nativeDispatch")?.call(withArguments: [callbackID, payload])
        if let exception = context.exception {
            reportError(exception.toString(), exception.objectForKeyedSubscript("stack")?.toString() ?? "")
            context.exception = nil
        }
    }

    func setNativeState(nodeID: Int, state: String, active: Bool) {
        guard let node = nodes[nodeID] else { return }
        if active { node.activeStates.insert(state) } else { node.activeStates.remove(state) }
        refreshStateAppearance(node)
    }

    private func allocateID() -> Int {
        defer { nextID += 1 }
        return nextID
    }

    private func requireNode(_ id: Int) throws -> NativeNode {
        guard let node = nodes[id] else { throw failure("Unknown node \(id)") }
        return node
    }

    private func perform<T>(_ fallback: T, _ body: () throws -> T) -> T {
        do { return try body() }
        catch {
            lastError = String(describing: error)
            return fallback
        }
    }

    private func failure(_ message: String) -> NSError {
        NSError(domain: "NativeVueMacOS", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func detach(_ node: NativeNode, removeView: Bool) {
        if let parent = node.parent {
            parent.children.removeAll { $0 === node }
            if removeView, let view = node.view {
                if let stack = view.superview as? NativeStackView { stack.removeNativeArrangedSubview(view) }
                else if let stack = view.superview as? NSStackView { stack.removeArrangedSubview(view) }
                view.removeFromSuperview()
            }
            node.parent = nil
        }
    }

    private func removeRecursively(_ node: NativeNode) {
        for child in node.children { removeRecursively(child) }
        node.children.removeAll()
        detach(node, removeView: true)
        node.window?.close()
        node.listeners.removeAll()
        node.actionProxy = nil
        nodes.removeValue(forKey: node.id)
    }

    private func pinToContainerIfNeeded(_ view: NSView, parent: NativeNode) {
        guard let container = parent.insertionView else { return }
        if parent.type == "mac-window" || parent.type == "mac-z-stack" || parent.type == "mac-scroll-view" {
            let constraints = [
                view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                view.topAnchor.constraint(equalTo: container.topAnchor),
                view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ]
            if parent.type == "mac-scroll-view" {
                constraints[1].priority = .defaultHigh
            }
            NSLayoutConstraint.activate(constraints)
        }
    }

    private func attachEventProxy(to node: NativeNode) {
        let proxy = node.actionProxy ?? NativeEventProxy(bridge: self, nodeID: node.id, nodeType: node.type)
        node.actionProxy = proxy
        if let button = node.view as? NSButton {
            button.target = proxy
            button.action = #selector(NativeEventProxy.activate(_:))
        }
        if let field = node.view as? NSTextField, node.type == "mac-text-field" || node.type == "mac-secure-field" {
            field.delegate = proxy
            field.target = proxy
            field.action = #selector(NativeEventProxy.submit(_:))
        }
    }

    private func supportedEvents(for node: NativeNode) -> Set<String> {
        switch node.type {
        case "mac-button": return ["click"]
        case "mac-toggle": return ["change", "click"]
        case "mac-text-field", "mac-secure-field": return ["input", "change", "submit", "focus", "blur"]
        default: return []
        }
    }
}
