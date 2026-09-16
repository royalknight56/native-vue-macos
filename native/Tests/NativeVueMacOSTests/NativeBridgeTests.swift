import AppKit
import JavaScriptCore
import XCTest
@testable import NativeVueMacOS

final class NativeBridgeTests: XCTestCase {
    @MainActor
    func testBuiltInFactoriesCreateRealAppKitControls() throws {
        _ = NSApplication.shared
        let bridge = NativeBridge()
        let expected: [(String, NSView.Type)] = [
            ("mac-v-stack", NSStackView.self),
            ("mac-h-stack", NSStackView.self),
            ("mac-z-stack", NSView.self),
            ("mac-scroll-view", NSScrollView.self),
            ("mac-text", NSTextField.self),
            ("mac-button", NSButton.self),
            ("mac-text-field", NSTextField.self),
            ("mac-secure-field", NSSecureTextField.self),
            ("mac-toggle", NSButton.self),
            ("mac-progress", NSProgressIndicator.self),
            ("mac-divider", NSBox.self),
            ("mac-image", NSImageView.self)
        ]
        for (tag, type) in expected {
            let id = bridge.createNode(tag)
            XCTAssertGreaterThan(id, 0, tag)
            XCTAssertTrue(bridge.viewForTesting(id)?.isKind(of: type) == true, tag)
        }
    }

    @MainActor
    func testInsertionPropertiesAndRemoval() throws {
        _ = NSApplication.shared
        let context = JSContext()!
        let bridge = NativeBridge()
        let root = bridge.createApplicationRoot()
        let window = bridge.createNode("mac-window")
        let stack = bridge.createNode("mac-v-stack")
        let label = bridge.createNode("mac-text")

        XCTAssertTrue(bridge.insertNode(window, root, 0))
        XCTAssertTrue(bridge.insertNode(stack, window, 0))
        XCTAssertTrue(bridge.insertNode(label, stack, 0))
        XCTAssertTrue(bridge.setText(label, "Hello AppKit"))
        XCTAssertTrue(bridge.setStyle(label, "fontSize", JSValue(double: 22, in: context)))
        XCTAssertEqual((bridge.viewForTesting(label) as? NSTextField)?.stringValue, "Hello AppKit")
        XCTAssertEqual((bridge.viewForTesting(label) as? NSTextField)?.font?.pointSize, 22)

        let releasedView = bridge.viewForTesting(label)
        XCTAssertTrue(bridge.removeNode(label))
        XCTAssertNil(releasedView?.superview)
        XCTAssertNil(bridge.viewForTesting(label))
    }

    @MainActor
    func testUnknownElementsAndPropertiesReportErrors() throws {
        _ = NSApplication.shared
        let context = JSContext()!
        let bridge = NativeBridge()
        XCTAssertEqual(bridge.createNode("mac-unknown"), -1)
        XCTAssertTrue(bridge.takeLastError()?.contains("Unknown native element") == true)

        let label = bridge.createNode("mac-text")
        XCTAssertFalse(bridge.setProp(label, "madeUp", JSValue(bool: true, in: context)))
        XCTAssertTrue(bridge.takeLastError()?.contains("Invalid property") == true)
    }

    @MainActor
    func testCustomFactoryRegistry() throws {
        let registry = NativeElementFactoryRegistry()
        registry.register("mac-custom") { NSLevelIndicator() }
        let bridge = NativeBridge(registry: registry)
        let id = bridge.createNode("mac-custom")
        XCTAssertTrue(bridge.viewForTesting(id) is NSLevelIndicator)
    }
}
