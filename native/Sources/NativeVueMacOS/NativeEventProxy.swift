import AppKit

@MainActor
final class NativeEventProxy: NSObject, NSTextFieldDelegate, NSTextViewDelegate {
    weak var bridge: NativeBridge?
    let nodeID: Int
    let nodeType: String

    init(bridge: NativeBridge, nodeID: Int, nodeType: String) {
        self.bridge = bridge
        self.nodeID = nodeID
        self.nodeType = nodeType
    }

    @objc func activate(_ sender: Any?) {
        if let button = sender as? NSButton, nodeType == "mac-toggle" || nodeType == "mac-radio" {
            bridge?.dispatch(nodeID: nodeID, event: "change", payload: ["checked": button.state == .on])
            bridge?.dispatch(nodeID: nodeID, event: "click", payload: ["checked": button.state == .on])
        } else if let toggle = sender as? NSSwitch {
            bridge?.dispatch(nodeID: nodeID, event: "change", payload: ["checked": toggle.state == .on])
        } else if let popup = sender as? NSPopUpButton {
            bridge?.dispatch(nodeID: nodeID, event: "change", payload: [
                "selectedIndex": popup.indexOfSelectedItem,
                "title": popup.titleOfSelectedItem ?? ""
            ])
        } else if let segmented = sender as? NSSegmentedControl {
            bridge?.dispatch(nodeID: nodeID, event: "change", payload: ["selectedIndex": segmented.selectedSegment])
        } else if let datePicker = sender as? NSDatePicker {
            bridge?.dispatch(nodeID: nodeID, event: "change", payload: ["value": ISO8601DateFormatter().string(from: datePicker.dateValue)])
        } else if let colorWell = sender as? NSColorWell {
            bridge?.dispatch(nodeID: nodeID, event: "change", payload: ["value": colorWell.color.nativeVueHex])
        } else if let path = sender as? NSPathControl {
            bridge?.dispatch(nodeID: nodeID, event: "change", payload: ["value": path.url?.path ?? ""])
        } else if let control = sender as? NSControl {
            bridge?.dispatch(nodeID: nodeID, event: "change", payload: ["value": control.doubleValue])
        } else {
            bridge?.dispatch(nodeID: nodeID, event: "click", payload: [:])
        }
    }

    @objc func submit(_ sender: Any?) {
        let value = (sender as? NSTextField)?.stringValue ?? ""
        bridge?.dispatch(nodeID: nodeID, event: "submit", payload: ["value": value])
    }

    func controlTextDidBeginEditing(_ obj: Notification) {
        bridge?.setNativeState(nodeID: nodeID, state: "focus", active: true)
        bridge?.dispatch(nodeID: nodeID, event: "focus", payload: [:])
    }

    func controlTextDidChange(_ obj: Notification) {
        let value = (obj.object as? NSTextField)?.stringValue ?? ""
        bridge?.dispatch(nodeID: nodeID, event: "input", payload: ["value": value])
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        bridge?.setNativeState(nodeID: nodeID, state: "focus", active: false)
        let value = (obj.object as? NSTextField)?.stringValue ?? ""
        bridge?.dispatch(nodeID: nodeID, event: "change", payload: ["value": value])
        bridge?.dispatch(nodeID: nodeID, event: "blur", payload: ["value": value])
    }

    func textDidBeginEditing(_ notification: Notification) {
        bridge?.setNativeState(nodeID: nodeID, state: "focus", active: true)
        bridge?.dispatch(nodeID: nodeID, event: "focus", payload: [:])
    }

    func textDidChange(_ notification: Notification) {
        let value = (notification.object as? NSTextView)?.string ?? ""
        bridge?.dispatch(nodeID: nodeID, event: "input", payload: ["value": value])
    }

    func textDidEndEditing(_ notification: Notification) {
        bridge?.setNativeState(nodeID: nodeID, state: "focus", active: false)
        let value = (notification.object as? NSTextView)?.string ?? ""
        bridge?.dispatch(nodeID: nodeID, event: "change", payload: ["value": value])
        bridge?.dispatch(nodeID: nodeID, event: "blur", payload: ["value": value])
    }
}

private extension NSColor {
    var nativeVueHex: String {
        guard let color = usingColorSpace(.sRGB) else { return "#000000" }
        return String(format: "#%02X%02X%02X%02X",
                      Int(round(color.redComponent * 255)),
                      Int(round(color.greenComponent * 255)),
                      Int(round(color.blueComponent * 255)),
                      Int(round(color.alphaComponent * 255)))
    }
}
