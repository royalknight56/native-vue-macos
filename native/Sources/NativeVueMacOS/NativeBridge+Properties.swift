import AppKit
import JavaScriptCore

@MainActor
extension NativeBridge {
    func applyProperty(node: NativeNode, name: String, value: JSValue) throws {
        if ["width", "height", "minWidth", "minHeight", "maxWidth", "maxHeight", "opacity", "hidden", "backgroundColor", "color", "fontSize", "fontWeight", "padding", "spacing", "alignment", "cornerRadius", "borderWidth", "borderColor", "gradientStartColor", "gradientEndColor"].contains(name) {
            try applyStyle(node: node, name: name, value: value)
            return
        }

        switch (node.type, name) {
        case ("mac-window", "title"):
            node.window?.title = string(value) ?? ""
        case ("mac-window", "resizable"):
            if boolean(value, default: true) { node.window?.styleMask.insert(.resizable) }
            else { node.window?.styleMask.remove(.resizable) }
        case ("mac-window", "minWidth"):
            node.window?.contentMinSize.width = number(value) ?? 0
        case ("mac-window", "minHeight"):
            node.window?.contentMinSize.height = number(value) ?? 0
        case ("mac-window", "width"):
            if let size = number(value), let window = node.window {
                window.setContentSize(NSSize(width: size, height: window.contentLayoutRect.height))
            }
        case ("mac-window", "height"):
            if let size = number(value), let window = node.window {
                window.setContentSize(NSSize(width: window.contentLayoutRect.width, height: size))
            }
        case ("mac-text", "text"), ("mac-gradient-text", "text"), ("mac-button", "title"):
            guard setText(node.id, string(value) ?? "") else { throw propertyError(node, name) }
        case ("mac-text", "selectable"), ("mac-gradient-text", "selectable"):
            (node.view as? NSTextField)?.isSelectable = boolean(value)
        case ("mac-text", "numberOfLines"), ("mac-gradient-text", "numberOfLines"):
            (node.view as? NSTextField)?.maximumNumberOfLines = Int(number(value) ?? 1)
        case ("mac-text", "textAlignment"), ("mac-gradient-text", "textAlignment"):
            guard let field = node.view as? NSTextField else { throw propertyError(node, name) }
            switch string(value) {
            case nil, "natural": field.alignment = .natural
            case "left", "leading": field.alignment = .left
            case "center": field.alignment = .center
            case "right", "trailing": field.alignment = .right
            default: throw propertyError(node, name, "expected leading, center, or trailing")
            }
        case ("mac-text", "lineBreakMode"), ("mac-gradient-text", "lineBreakMode"):
            guard let field = node.view as? NSTextField else { throw propertyError(node, name) }
            switch string(value) {
            case nil, "truncateTail": field.lineBreakMode = .byTruncatingTail
            case "wordWrap": field.lineBreakMode = .byWordWrapping
            case "charWrap": field.lineBreakMode = .byCharWrapping
            default: throw propertyError(node, name, "expected truncateTail, wordWrap, or charWrap")
            }
        case ("mac-button", "bordered"):
            (node.view as? NSButton)?.isBordered = boolean(value, default: true)
        case ("mac-button", "bezelStyle"):
            guard let button = node.view as? NSButton else { throw propertyError(node, name) }
            switch string(value) {
            case nil, "rounded": button.bezelStyle = .rounded
            case "regularSquare": button.bezelStyle = .regularSquare
            case "recessed": button.bezelStyle = .recessed
            case "texturedRounded": button.bezelStyle = .texturedRounded
            default: throw propertyError(node, name, "unsupported bezel style")
            }
        case ("mac-button", "enabled"), ("mac-text-field", "enabled"), ("mac-secure-field", "enabled"), ("mac-toggle", "enabled"):
            (node.view as? NSControl)?.isEnabled = boolean(value, default: true)
        case ("mac-text-field", "value"), ("mac-secure-field", "value"):
            (node.view as? NSTextField)?.stringValue = string(value) ?? ""
        case ("mac-text-field", "placeholder"), ("mac-secure-field", "placeholder"):
            (node.view as? NSTextField)?.placeholderString = string(value)
        case ("mac-toggle", "checked"):
            (node.view as? NSButton)?.state = boolean(value) ? .on : .off
        case ("mac-toggle", "label"), ("mac-toggle", "title"):
            (node.view as? NSButton)?.title = string(value) ?? ""
        case ("mac-progress", "value"):
            (node.view as? NSProgressIndicator)?.doubleValue = number(value) ?? 0
        case ("mac-progress", "min"):
            (node.view as? NSProgressIndicator)?.minValue = number(value) ?? 0
        case ("mac-progress", "max"):
            (node.view as? NSProgressIndicator)?.maxValue = number(value) ?? 1
        case ("mac-progress", "indeterminate"):
            let progress = node.view as? NSProgressIndicator
            progress?.isIndeterminate = boolean(value)
            if boolean(value) { progress?.startAnimation(nil) } else { progress?.stopAnimation(nil) }
        case ("mac-image", "src"):
            try setImage(node, source: string(value))
        case ("mac-image", "contentMode"):
            let image = node.view as? NSImageView
            switch string(value) {
            case "fill": image?.imageScaling = .scaleAxesIndependently
            case "fit", nil: image?.imageScaling = .scaleProportionallyUpOrDown
            case "center": image?.imageScaling = .scaleNone
            default: throw propertyError(node, name, "expected fill, fit, or center")
            }
        case ("mac-image", "template"):
            guard let imageView = node.view as? NSImageView else { throw propertyError(node, name) }
            if let copy = imageView.image?.copy() as? NSImage {
                copy.isTemplate = boolean(value)
                imageView.image = copy
                imageView.needsDisplay = true
            }
        case (_, "toolTip"):
            node.view?.toolTip = string(value)
        case (_, "accessibilityLabel"):
            node.view?.setAccessibilityLabel(string(value))
        default:
            throw propertyError(node, name)
        }
    }

    func applyStyle(node: NativeNode, name: String, value: JSValue) throws {
        guard let view = node.view else { throw propertyError(node, name, "node has no view") }
        switch name {
        case "width", "height", "minWidth", "minHeight", "maxWidth", "maxHeight":
            try updateSizeConstraint(node: node, name: name, value: value)
        case "opacity":
            view.alphaValue = CGFloat(number(value) ?? 1)
        case "hidden":
            view.isHidden = boolean(value)
        case "backgroundColor":
            view.wantsLayer = true
            view.layer?.backgroundColor = try color(value)?.cgColor
        case "color":
            let parsed = try color(value)
            if let field = view as? NSTextField { field.textColor = parsed }
            else if let control = view as? NSButton { control.contentTintColor = parsed }
            else if let image = view as? NSImageView { image.contentTintColor = parsed }
            else { throw propertyError(node, name, "only text, controls, and images support foreground color") }
        case "fontSize":
            guard let control = view as? NSControl else { throw propertyError(node, name, "only controls support fonts") }
            let size = number(value) ?? NSFont.systemFontSize
            control.font = NSFont.systemFont(ofSize: size, weight: fontWeight(control.font))
        case "fontWeight":
            guard let control = view as? NSControl else { throw propertyError(node, name, "only controls support fonts") }
            let weight = try parseFontWeight(value)
            control.font = NSFont.systemFont(ofSize: control.font?.pointSize ?? NSFont.systemFontSize, weight: weight)
        case "spacing":
            guard let stack = view as? NSStackView else { throw propertyError(node, name, "only stack containers support spacing") }
            stack.spacing = number(value) ?? 8
        case "padding":
            guard let stack = view as? NSStackView else { throw propertyError(node, name, "only stack containers support padding") }
            stack.edgeInsets = try edgeInsets(value)
        case "alignment":
            guard let stack = view as? NSStackView else { throw propertyError(node, name, "only stack containers support alignment") }
            stack.alignment = try alignment(string(value), orientation: stack.orientation)
        case "cornerRadius":
            view.wantsLayer = true
            view.layer?.cornerRadius = number(value) ?? 0
            view.layer?.masksToBounds = true
        case "borderWidth":
            view.wantsLayer = true
            view.layer?.borderWidth = number(value) ?? 0
        case "borderColor":
            view.wantsLayer = true
            view.layer?.borderColor = try color(value)?.cgColor
        case "gradientStartColor":
            guard let field = view as? GradientTextField, let parsed = try color(value) else {
                throw propertyError(node, name, "only gradient text supports gradient colors")
            }
            field.gradientStartColor = parsed
        case "gradientEndColor":
            guard let field = view as? GradientTextField, let parsed = try color(value) else {
                throw propertyError(node, name, "only gradient text supports gradient colors")
            }
            field.gradientEndColor = parsed
        default:
            throw propertyError(node, name, "unsupported native style")
        }
    }

    private func updateSizeConstraint(node: NativeNode, name: String, value: JSValue) throws {
        node.constraints[name]?.isActive = false
        node.constraints.removeValue(forKey: name)
        guard !value.isNull && !value.isUndefined else { return }
        guard let size = number(value), size >= 0, let view = node.view else {
            throw propertyError(node, name, "expected a non-negative number")
        }
        let constraint: NSLayoutConstraint
        switch name {
        case "width": constraint = view.widthAnchor.constraint(equalToConstant: size)
        case "height": constraint = view.heightAnchor.constraint(equalToConstant: size)
        case "minWidth": constraint = view.widthAnchor.constraint(greaterThanOrEqualToConstant: size)
        case "minHeight": constraint = view.heightAnchor.constraint(greaterThanOrEqualToConstant: size)
        case "maxWidth": constraint = view.widthAnchor.constraint(lessThanOrEqualToConstant: size)
        default: constraint = view.heightAnchor.constraint(lessThanOrEqualToConstant: size)
        }
        constraint.isActive = true
        node.constraints[name] = constraint
    }

    private func setImage(_ node: NativeNode, source: String?) throws {
        guard let imageView = node.view as? NSImageView else { throw propertyError(node, "src") }
        guard let source, !source.isEmpty else {
            imageView.image = nil
            return
        }
        guard !source.hasPrefix("http://") && !source.hasPrefix("https://") else {
            throw propertyError(node, "src", "network images are not supported")
        }
        let expanded = NSString(string: source).expandingTildeInPath
        var candidates: [String] = [expanded]
        if let bundled = Bundle.main.resourceURL?.appendingPathComponent(source).path { candidates.append(bundled) }
        candidates.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(source).path)
        guard let path = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }),
              let image = NSImage(contentsOfFile: path) else {
            throw propertyError(node, "src", "file not found: \(source)")
        }
        imageView.image = image
    }

    private func string(_ value: JSValue) -> String? {
        value.isNull || value.isUndefined ? nil : value.toString()
    }

    private func number(_ value: JSValue) -> CGFloat? {
        guard !value.isNull && !value.isUndefined && value.isNumber else { return nil }
        return CGFloat(value.toDouble())
    }

    private func boolean(_ value: JSValue, default fallback: Bool = false) -> Bool {
        value.isNull || value.isUndefined ? fallback : value.toBool()
    }

    private func color(_ value: JSValue) throws -> NSColor? {
        guard let raw = string(value) else { return nil }
        let semantic: [String: NSColor] = [
            "label": .labelColor,
            "secondaryLabel": .secondaryLabelColor,
            "accent": .controlAccentColor,
            "windowBackground": .windowBackgroundColor,
            "controlBackground": .controlBackgroundColor,
            "separator": .separatorColor,
            "transparent": .clear,
            "white": .white,
            "black": .black,
            "red": .systemRed,
            "green": .systemGreen,
            "blue": .systemBlue
        ]
        if let value = semantic[raw] { return value }
        guard raw.hasPrefix("#") else { throw NSError.nativeVue("Unsupported color \(raw)") }
        let hex = String(raw.dropFirst())
        guard hex.count == 6 || hex.count == 8, let bits = UInt64(hex, radix: 16) else {
            throw NSError.nativeVue("Expected #RRGGBB or #RRGGBBAA, received \(raw)")
        }
        let red = CGFloat((bits >> (hex.count == 8 ? 24 : 16)) & 0xff) / 255
        let green = CGFloat((bits >> (hex.count == 8 ? 16 : 8)) & 0xff) / 255
        let blue = CGFloat((bits >> (hex.count == 8 ? 8 : 0)) & 0xff) / 255
        let alpha = hex.count == 8 ? CGFloat(bits & 0xff) / 255 : 1
        return NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }

    private func parseFontWeight(_ value: JSValue) throws -> NSFont.Weight {
        switch string(value) {
        case nil, "regular", "400": return .regular
        case "medium", "500": return .medium
        case "semibold", "600": return .semibold
        case "bold", "700": return .bold
        case "heavy", "800": return .heavy
        case "black", "900": return .black
        default: throw NSError.nativeVue("Unsupported font weight \(string(value) ?? "")")
        }
    }

    private func fontWeight(_ font: NSFont?) -> NSFont.Weight {
        guard let font else { return .regular }
        return NSFontManager.shared.traits(of: font).contains(.boldFontMask) ? .bold : .regular
    }

    private func edgeInsets(_ value: JSValue) throws -> NSEdgeInsets {
        if value.isNumber {
            let amount = CGFloat(value.toDouble())
            return NSEdgeInsets(top: amount, left: amount, bottom: amount, right: amount)
        }
        guard let map = value.toDictionary() as? [String: Any] else {
            throw NSError.nativeVue("Padding must be a number or edge object")
        }
        func edge(_ key: String) -> CGFloat { CGFloat((map[key] as? NSNumber)?.doubleValue ?? 0) }
        return NSEdgeInsets(top: edge("top"), left: edge("left"), bottom: edge("bottom"), right: edge("right"))
    }

    private func alignment(_ raw: String?, orientation: NSUserInterfaceLayoutOrientation) throws -> NSLayoutConstraint.Attribute {
        if orientation == .vertical {
            switch raw {
            case nil, "leading": return .leading
            case "center": return .centerX
            case "trailing": return .trailing
            default: break
            }
        } else {
            switch raw {
            case nil, "center": return .centerY
            case "top": return .top
            case "bottom": return .bottom
            default: break
            }
        }
        throw NSError.nativeVue("Unsupported stack alignment \(raw ?? "")")
    }

    private func propertyError(_ node: NativeNode, _ name: String, _ detail: String? = nil) -> NSError {
        NSError.nativeVue("Invalid property \(name) on <\(node.type)>\(detail.map { ": \($0)" } ?? "")")
    }
}

extension NSError {
    static func nativeVue(_ message: String) -> NSError {
        NSError(domain: "NativeVueMacOS", code: 2, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
