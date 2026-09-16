import AppKit

@MainActor
final class NativeEventProxy: NSObject, NSTextFieldDelegate {
    weak var bridge: NativeBridge?
    let nodeID: Int
    let nodeType: String

    init(bridge: NativeBridge, nodeID: Int, nodeType: String) {
        self.bridge = bridge
        self.nodeID = nodeID
        self.nodeType = nodeType
    }

    @objc func activate(_ sender: Any?) {
        if let button = sender as? NSButton, nodeType == "mac-toggle" {
            bridge?.dispatch(nodeID: nodeID, event: "change", payload: ["checked": button.state == .on])
            bridge?.dispatch(nodeID: nodeID, event: "click", payload: ["checked": button.state == .on])
        } else {
            bridge?.dispatch(nodeID: nodeID, event: "click", payload: [:])
        }
    }

    @objc func submit(_ sender: Any?) {
        let value = (sender as? NSTextField)?.stringValue ?? ""
        bridge?.dispatch(nodeID: nodeID, event: "submit", payload: ["value": value])
    }

    func controlTextDidBeginEditing(_ obj: Notification) {
        bridge?.dispatch(nodeID: nodeID, event: "focus", payload: [:])
    }

    func controlTextDidChange(_ obj: Notification) {
        let value = (obj.object as? NSTextField)?.stringValue ?? ""
        bridge?.dispatch(nodeID: nodeID, event: "input", payload: ["value": value])
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        let value = (obj.object as? NSTextField)?.stringValue ?? ""
        bridge?.dispatch(nodeID: nodeID, event: "change", payload: ["value": value])
        bridge?.dispatch(nodeID: nodeID, event: "blur", payload: ["value": value])
    }
}
