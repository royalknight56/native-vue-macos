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
            ("mac-gradient-text", GradientTextField.self),
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
    func testPresentationStylesUsedByWebsiteDemo() throws {
        _ = NSApplication.shared
        let context = JSContext()!
        let bridge = NativeBridge()
        let title = bridge.createNode("mac-gradient-text")
        let button = bridge.createNode("mac-button")

        XCTAssertTrue(bridge.setStyle(title, "fontWeight", JSValue(object: "900", in: context)))
        XCTAssertTrue(bridge.setStyle(title, "gradientStartColor", JSValue(object: "#42D392", in: context)))
        XCTAssertTrue(bridge.setStyle(title, "gradientEndColor", JSValue(object: "#647EFF", in: context)))
        XCTAssertTrue(bridge.setProp(button, "bordered", JSValue(bool: false, in: context)))
        XCTAssertTrue(bridge.setProp(button, "systemImage", JSValue(object: "chevron.down", in: context)))
        XCTAssertTrue(bridge.setProp(button, "textAlignment", JSValue(object: "left", in: context)))
        XCTAssertTrue(bridge.setStyle(button, "cornerRadius", JSValue(double: 8, in: context)))
        XCTAssertTrue(bridge.setStyle(button, "borderWidth", JSValue(double: 2, in: context)))
        XCTAssertTrue(bridge.setStyle(button, "borderColor", JSValue(object: "#42B883", in: context)))

        XCTAssertFalse((bridge.viewForTesting(button) as? NSButton)?.isBordered ?? true)
        XCTAssertNotNil((bridge.viewForTesting(button) as? NSButton)?.image)
        XCTAssertEqual((bridge.viewForTesting(button) as? NSButton)?.imagePosition, .imageTrailing)
        XCTAssertEqual((bridge.viewForTesting(button) as? NSButton)?.alignment, .left)
        XCTAssertEqual(bridge.viewForTesting(button)?.layer?.cornerRadius, 8)
        XCTAssertEqual(bridge.viewForTesting(button)?.layer?.borderWidth, 2)
    }

    @MainActor
    func testNativeStyleSystemMapsLayoutTypographySurfaceAndStates() throws {
        _ = NSApplication.shared
        let context = JSContext()!
        let bridge = NativeBridge()
        let stackID = bridge.createNode("mac-v-stack")
        let textID = bridge.createNode("mac-text")
        let buttonID = bridge.createNode("mac-button")

        XCTAssertTrue(bridge.setStyle(stackID, "flexDirection", JSValue(object: "row", in: context)))
        XCTAssertTrue(bridge.setStyle(stackID, "gap", JSValue(double: 18, in: context)))
        XCTAssertTrue(bridge.setStyle(stackID, "paddingHorizontal", JSValue(double: 12, in: context)))
        let stack = try XCTUnwrap(bridge.viewForTesting(stackID) as? NSStackView)
        XCTAssertEqual(stack.orientation, .horizontal)
        XCTAssertEqual(stack.spacing, 18)
        XCTAssertEqual(stack.edgeInsets.left, 12)
        XCTAssertEqual(stack.edgeInsets.right, 12)

        XCTAssertTrue(bridge.setText(textID, "Native typography"))
        XCTAssertTrue(bridge.setStyle(textID, "fontFamily", JSValue(object: "Helvetica Neue", in: context)))
        XCTAssertTrue(bridge.setStyle(textID, "fontSize", JSValue(double: 19, in: context)))
        XCTAssertTrue(bridge.setStyle(textID, "letterSpacing", JSValue(double: 1.5, in: context)))
        XCTAssertTrue(bridge.setStyle(textID, "textDecorationLine", JSValue(object: "underline", in: context)))
        let text = try XCTUnwrap(bridge.viewForTesting(textID) as? NSTextField)
        XCTAssertEqual(text.font?.pointSize, 19)
        XCTAssertEqual(text.attributedStringValue.attribute(.kern, at: 0, effectiveRange: nil) as? Double, 1.5)

        XCTAssertTrue(bridge.setStyle(buttonID, "borderRadius", JSValue(double: 10, in: context)))
        XCTAssertTrue(bridge.setStyle(buttonID, "boxShadow", JSValue(object: [
            "offset": ["x": 0, "y": 4], "blur": 12, "color": "#00000055"
        ], in: context)))
        XCTAssertTrue(bridge.setStyle(buttonID, "hoverStyle", JSValue(object: [
            "backgroundColor": "#42B883", "opacity": 0.8
        ], in: context)))
        bridge.setNativeState(nodeID: buttonID, state: "hover", active: true)
        let button = try XCTUnwrap(bridge.viewForTesting(buttonID) as? NSButton)
        XCTAssertEqual(button.layer?.cornerRadius, 10)
        XCTAssertEqual(button.layer?.shadowRadius, 12)
        XCTAssertEqual(button.alphaValue, 0.8, accuracy: 0.001)
        XCTAssertNotNil(button.layer?.backgroundColor)
    }

    @MainActor
    func testNativeStackJustificationAbsolutePositionAndWindowGeometry() throws {
        _ = NSApplication.shared
        let context = JSContext()!
        let bridge = NativeBridge()
        let rootID = bridge.createApplicationRoot()
        let windowID = bridge.createNode("mac-window")
        let stackID = bridge.createNode("mac-h-stack")
        let firstID = bridge.createNode("mac-text")
        let absoluteID = bridge.createNode("mac-text")

        XCTAssertTrue(bridge.setProp(windowID, "width", JSValue(double: 640, in: context)))
        XCTAssertTrue(bridge.setProp(windowID, "height", JSValue(double: 480, in: context)))
        XCTAssertTrue(bridge.insertNode(windowID, rootID, 0))
        XCTAssertTrue(bridge.insertNode(stackID, windowID, 0))
        XCTAssertTrue(bridge.setStyle(stackID, "justifyContent", JSValue(object: "spaceEvenly", in: context)))
        XCTAssertTrue(bridge.insertNode(firstID, stackID, 0))
        XCTAssertTrue(bridge.setStyle(absoluteID, "position", JSValue(object: "absolute", in: context)))
        XCTAssertTrue(bridge.setStyle(absoluteID, "top", JSValue(double: 6, in: context)))
        XCTAssertTrue(bridge.insertNode(absoluteID, stackID, 1))

        let stack = try XCTUnwrap(bridge.viewForTesting(stackID) as? NativeStackView)
        XCTAssertEqual(stack.contentViews.count, 1)
        XCTAssertEqual(stack.arrangedSubviews.count, 3)
        XCTAssertFalse(stack.contentViews.contains { $0 === bridge.viewForTesting(absoluteID) })
        XCTAssertEqual(bridge.viewForTesting(absoluteID)?.constraints.count, 0)

        XCTAssertTrue(bridge.setStyle(absoluteID, "position", JSValue(object: "relative", in: context)))
        XCTAssertEqual(stack.contentViews.count, 2)
        XCTAssertEqual(stack.arrangedSubviews.count, 5)
        let window = try XCTUnwrap(bridge.viewForTesting(windowID)?.window)
        XCTAssertEqual(window.contentLayoutRect.size.width, 640, accuracy: 1)
        XCTAssertEqual(window.contentLayoutRect.size.height, 480, accuracy: 1)
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

        let button = bridge.createNode("mac-button")
        let stack = bridge.createNode("mac-v-stack")
        XCTAssertTrue(bridge.addEventListener(button, "mouseenter", 1))
        XCTAssertTrue(bridge.addEventListener(button, "mouseleave", 2))
        XCTAssertTrue(bridge.addEventListener(stack, "mouseenter", 3))
        XCTAssertTrue(bridge.addEventListener(stack, "mouseleave", 4))
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
