import AppKit
import JavaScriptCore

private let nativeStylePropertyNames: Set<String> = [
    "width", "height", "minWidth", "minHeight", "maxWidth", "maxHeight", "aspectRatio",
    "margin", "marginTop", "marginRight", "marginBottom", "marginLeft", "marginHorizontal", "marginVertical",
    "padding", "paddingTop", "paddingRight", "paddingBottom", "paddingLeft", "paddingHorizontal", "paddingVertical",
    "display", "flexDirection", "flexGrow", "flexShrink", "flexBasis", "flexWrap",
    "justifyContent", "alignItems", "alignSelf", "alignment", "gap", "rowGap", "columnGap", "spacing",
    "position", "top", "right", "bottom", "left", "zIndex",
    "opacity", "hidden", "visibility", "overflow", "backgroundColor",
    "borderColor", "borderWidth", "borderRadius", "cornerRadius",
    "borderTopColor", "borderRightColor", "borderBottomColor", "borderLeftColor",
    "borderTopWidth", "borderRightWidth", "borderBottomWidth", "borderLeftWidth",
    "borderTopLeftRadius", "borderTopRightRadius", "borderBottomRightRadius", "borderBottomLeftRadius",
    "boxShadow", "shadowColor", "shadowOpacity", "shadowRadius", "shadowOffset", "elevation",
    "color", "fontSize", "fontWeight", "fontFamily", "fontStyle", "lineHeight", "letterSpacing",
    "textAlign", "textDecorationLine", "textDecorationColor", "textTransform",
    "objectFit", "resizeMode", "tintColor", "cursor", "transform", "transformOrigin",
    "hoverStyle", "pressedStyle", "focusStyle", "disabledStyle",
    "gradientStartColor", "gradientEndColor"
]

@MainActor
extension NativeBridge {
    func applyProperty(node: NativeNode, name: String, value: JSValue) throws {
        let windowGeometry = node.type == "mac-window" && ["width", "height", "minWidth", "minHeight", "maxWidth", "maxHeight"].contains(name)
        if nativeStylePropertyNames.contains(name) && !windowGeometry {
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
        case ("mac-window", "maxWidth"):
            node.window?.contentMaxSize.width = number(value) ?? .greatestFiniteMagnitude
        case ("mac-window", "maxHeight"):
            node.window?.contentMaxSize.height = number(value) ?? .greatestFiniteMagnitude
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
        case ("mac-button", "systemImage"):
            guard let button = node.view as? NSButton else { throw propertyError(node, name) }
            if let symbol = string(value), !symbol.isEmpty {
                let configuration = NSImage.SymbolConfiguration(pointSize: 9, weight: .semibold)
                button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
                    .withSymbolConfiguration(configuration)
                button.imagePosition = .imageTrailing
                button.imageHugsTitle = true
            } else {
                button.image = nil
            }
        case ("mac-button", "textAlignment"):
            guard let button = node.view as? NSButton else { throw propertyError(node, name) }
            switch string(value) {
            case nil, "natural": button.alignment = .natural
            case "left", "leading": button.alignment = .left
            case "center": button.alignment = .center
            case "right", "trailing": button.alignment = .right
            default: throw propertyError(node, name, "expected leading, center, or trailing")
            }
        case (_, "enabled") where node.view is NSControl:
            let enabled = boolean(value, default: true)
            (node.view as? NSControl)?.isEnabled = enabled
            setNativeState(nodeID: node.id, state: "disabled", active: !enabled)
        case ("mac-text-field", "value"), ("mac-secure-field", "value"), ("mac-search-field", "value"),
             ("mac-token-field", "value"), ("mac-combo-box", "value"):
            (node.view as? NSTextField)?.stringValue = string(value) ?? ""
        case ("mac-text-field", "placeholder"), ("mac-secure-field", "placeholder"), ("mac-search-field", "placeholder"),
             ("mac-token-field", "placeholder"), ("mac-combo-box", "placeholder"):
            (node.view as? NSTextField)?.placeholderString = string(value)
        case ("mac-text-view", "value"):
            (node.view as? NSTextView)?.string = string(value) ?? ""
        case ("mac-text-view", "editable"):
            (node.view as? NSTextView)?.isEditable = boolean(value, default: true)
        case ("mac-toggle", "checked"), ("mac-radio", "checked"):
            (node.view as? NSButton)?.state = boolean(value) ? .on : .off
        case ("mac-toggle", "label"), ("mac-toggle", "title"), ("mac-radio", "label"), ("mac-radio", "title"):
            (node.view as? NSButton)?.title = string(value) ?? ""
        case ("mac-switch", "checked"):
            (node.view as? NSSwitch)?.state = boolean(value) ? .on : .off
        case ("mac-combo-box", "items"):
            guard let combo = node.view as? NSComboBox, let items = value.toArray() as? [String] else {
                throw propertyError(node, name, "expected a string array")
            }
            combo.removeAllItems(); combo.addItems(withObjectValues: items)
        case ("mac-pop-up-button", "items"):
            guard let popup = node.view as? NSPopUpButton, let items = value.toArray() as? [String] else {
                throw propertyError(node, name, "expected a string array")
            }
            popup.removeAllItems(); popup.addItems(withTitles: items)
        case ("mac-pop-up-button", "selectedIndex"):
            (node.view as? NSPopUpButton)?.selectItem(at: Int(number(value) ?? -1))
        case ("mac-segmented-control", "labels"):
            guard let segmented = node.view as? NSSegmentedControl, let labels = value.toArray() as? [String] else {
                throw propertyError(node, name, "expected a string array")
            }
            segmented.segmentCount = labels.count
            for (index, label) in labels.enumerated() { segmented.setLabel(label, forSegment: index) }
        case ("mac-segmented-control", "selectedIndex"):
            (node.view as? NSSegmentedControl)?.selectedSegment = Int(number(value) ?? -1)
        case ("mac-combo-button", "title"):
            (node.view as? NSComboButton)?.title = string(value) ?? ""
        case ("mac-slider", "value"), ("mac-stepper", "value"), ("mac-level-indicator", "value"):
            (node.view as? NSControl)?.doubleValue = Double(number(value) ?? 0)
        case ("mac-slider", "min"), ("mac-stepper", "min"), ("mac-level-indicator", "min"):
            if let control = node.view as? NSSlider { control.minValue = Double(number(value) ?? 0) }
            else if let control = node.view as? NSStepper { control.minValue = Double(number(value) ?? 0) }
            else { (node.view as? NSLevelIndicator)?.minValue = Double(number(value) ?? 0) }
        case ("mac-slider", "max"), ("mac-stepper", "max"), ("mac-level-indicator", "max"):
            if let control = node.view as? NSSlider { control.maxValue = Double(number(value) ?? 100) }
            else if let control = node.view as? NSStepper { control.maxValue = Double(number(value) ?? 100) }
            else { (node.view as? NSLevelIndicator)?.maxValue = Double(number(value) ?? 100) }
        case ("mac-stepper", "increment"):
            (node.view as? NSStepper)?.increment = Double(number(value) ?? 1)
        case ("mac-date-picker", "value"):
            guard let raw = string(value), let date = ISO8601DateFormatter().date(from: raw) else {
                throw propertyError(node, name, "expected an ISO-8601 date string")
            }
            (node.view as? NSDatePicker)?.dateValue = date
        case ("mac-color-well", "value"):
            guard let parsed = try color(value) else { throw propertyError(node, name, "expected a color") }
            (node.view as? NSColorWell)?.color = parsed
        case ("mac-path-control", "value"):
            let raw = string(value) ?? ""
            (node.view as? NSPathControl)?.url = raw.isEmpty ? nil : URL(fileURLWithPath: raw)
        case ("mac-box", "title"):
            (node.view as? NSBox)?.title = string(value) ?? ""
        case ("mac-split-view", "vertical"):
            (node.view as? NSSplitView)?.isVertical = boolean(value, default: true)
        case ("mac-scroll-view", "hasVerticalScroller"):
            (node.view as? NSScrollView)?.hasVerticalScroller = boolean(value, default: true)
        case ("mac-scroll-view", "hasHorizontalScroller"):
            (node.view as? NSScrollView)?.hasHorizontalScroller = boolean(value)
        case ("mac-scroller", "value"):
            (node.view as? NSScroller)?.doubleValue = Double(number(value) ?? 0)
        case ("mac-scroller", "knobProportion"):
            (node.view as? NSScroller)?.knobProportion = number(value) ?? 0
        case ("mac-table-view", "rowHeight"), ("mac-outline-view", "rowHeight"):
            (node.view as? NSTableView)?.rowHeight = number(value) ?? 17
        case ("mac-table-view", "alternatingRows"), ("mac-outline-view", "alternatingRows"):
            (node.view as? NSTableView)?.usesAlternatingRowBackgroundColors = boolean(value)
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
        let canonical = name == "cornerRadius" ? "borderRadius" : (name == "spacing" ? "gap" : name)
        if value.isNull || value.isUndefined {
            node.styleValues.removeValue(forKey: canonical)
        } else if let object = value.toObject() {
            node.styleValues[canonical] = object
        }

        switch canonical {
        case "width", "height", "minWidth", "minHeight", "maxWidth", "maxHeight":
            try updateSizeConstraint(node: node, name: canonical, value: value)
        case "aspectRatio":
            updateAspectRatio(node)
        case "margin", "marginTop", "marginRight", "marginBottom", "marginLeft", "marginHorizontal", "marginVertical":
            updateMargins(node)
        case "padding", "paddingTop", "paddingRight", "paddingBottom", "paddingLeft", "paddingHorizontal", "paddingVertical":
            guard let stack = view as? NSStackView else { throw propertyError(node, name, "padding requires a stack container") }
            stack.edgeInsets = resolvedInsets(node.styleValues, prefix: "padding")
        case "gap", "rowGap", "columnGap":
            guard let stack = view as? NSStackView else { throw propertyError(node, name, "gap requires a stack container") }
            let directional = stack.orientation == .vertical ? styleNumber(node, "rowGap") : styleNumber(node, "columnGap")
            stack.spacing = directional ?? styleNumber(node, "gap") ?? 8
        case "display", "visibility", "hidden":
            let display = styleString(node, "display")
            let visibility = styleString(node, "visibility")
            view.isHidden = styleBool(node, "hidden") || display == "none" || visibility == "hidden"
        case "flexDirection":
            guard let stack = view as? NSStackView else { throw propertyError(node, name, "flexDirection requires a stack container") }
            switch styleString(node, "flexDirection") {
            case nil, "column": stack.orientation = .vertical
            case "row": stack.orientation = .horizontal
            case "columnReverse", "rowReverse": throw propertyError(node, name, "reverse direction is not supported by NSStackView")
            default: throw propertyError(node, name, "expected row or column")
            }
            (stack as? NativeStackView)?.rebuildArrangement()
        case "flexGrow", "flexShrink":
            updateFlexPriorities(node)
        case "flexBasis":
            updateFlexBasis(node)
        case "flexWrap":
            guard styleString(node, "flexWrap") == nil || styleString(node, "flexWrap") == "nowrap" else {
                throw propertyError(node, name, "NSStackView does not support wrapping; use nested stacks")
            }
        case "justifyContent":
            guard let stack = view as? NSStackView else { throw propertyError(node, name, "justifyContent requires a stack container") }
            switch styleString(node, "justifyContent") {
            case "spaceBetween", "spaceAround", "spaceEvenly", nil, "flexStart", "center", "flexEnd": stack.distribution = .fill
            default: throw propertyError(node, name, "unsupported justifyContent value")
            }
            (stack as? NativeStackView)?.nativeJustifyContent = styleString(node, "justifyContent")
        case "alignItems", "alignment":
            guard let stack = view as? NSStackView else { throw propertyError(node, name, "alignItems requires a stack container") }
            stack.alignment = try alignment(styleString(node, canonical), orientation: stack.orientation)
        case "alignSelf":
            updateAlignSelf(node)
        case "position", "top", "right", "bottom", "left":
            updatePosition(node)
        case "zIndex":
            view.wantsLayer = true
            view.layer?.zPosition = styleNumber(node, "zIndex") ?? 0
        case "opacity", "overflow", "backgroundColor",
             "borderColor", "borderWidth", "borderRadius",
             "borderTopColor", "borderRightColor", "borderBottomColor", "borderLeftColor",
             "borderTopWidth", "borderRightWidth", "borderBottomWidth", "borderLeftWidth",
             "borderTopLeftRadius", "borderTopRightRadius", "borderBottomRightRadius", "borderBottomLeftRadius",
             "boxShadow", "shadowColor", "shadowOpacity", "shadowRadius", "shadowOffset", "elevation",
             "color", "tintColor", "transform", "transformOrigin",
             "hoverStyle", "pressedStyle", "focusStyle", "disabledStyle":
            refreshStateAppearance(node)
        case "fontSize", "fontWeight", "fontFamily", "fontStyle", "lineHeight", "letterSpacing",
             "textAlign", "textDecorationLine", "textDecorationColor", "textTransform":
            guard view is NSControl else { throw propertyError(node, name, "text styles require a native control") }
            refreshTextAppearance(node)
        case "objectFit", "resizeMode":
            guard let image = view as? NSImageView else { throw propertyError(node, name, "objectFit requires an image") }
            switch styleString(node, canonical) {
            case nil, "contain": image.imageScaling = .scaleProportionallyUpOrDown
            case "cover", "fill": image.imageScaling = .scaleAxesIndependently
            case "center", "none": image.imageScaling = .scaleNone
            default: throw propertyError(node, name, "expected contain, cover, fill, center, or none")
            }
        case "cursor":
            let cursor: NSCursor
            switch styleString(node, "cursor") {
            case nil, "default": cursor = .arrow
            case "pointer": cursor = .pointingHand
            case "text": cursor = .iBeam
            case "crosshair": cursor = .crosshair
            case "notAllowed": cursor = .operationNotAllowed
            default: throw propertyError(node, name, "unsupported cursor")
            }
            view.addCursorRect(view.bounds, cursor: cursor)
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

    func refreshStateAppearance(_ node: NativeNode) {
        guard let view = node.view else { return }
        var styles = node.styleValues
        let stateKeys = ["hoverStyle", "pressedStyle", "focusStyle", "disabledStyle"]
        for key in stateKeys { styles.removeValue(forKey: key) }
        for state in ["hover", "focus", "pressed", "disabled"] where node.activeStates.contains(state) {
            if let stateStyle = node.styleValues["\(state)Style"] as? [String: Any] {
                styles.merge(stateStyle) { _, active in active }
            }
        }

        view.wantsLayer = true
        view.alphaValue = CGFloat(anyNumber(styles["opacity"]) ?? 1)
        view.layer?.backgroundColor = try? anyColor(styles["backgroundColor"])?.cgColor
        view.layer?.masksToBounds = (styles["overflow"] as? String) == "hidden"
        let radii = ["borderRadius", "borderTopLeftRadius", "borderTopRightRadius", "borderBottomRightRadius", "borderBottomLeftRadius"]
            .compactMap { anyNumber(styles[$0]) }
        view.layer?.cornerRadius = radii.max() ?? 0
        updateBorderLayers(node, styles: styles)

        var shadowColor = styles["shadowColor"]
        var shadowOpacity = anyNumber(styles["shadowOpacity"])
        var shadowRadius = anyNumber(styles["shadowRadius"])
        var shadowOffset = styles["shadowOffset"] as? [String: Any]
        if let shadow = styles["boxShadow"] as? [String: Any] {
            shadowColor = shadow["color"] ?? shadowColor
            shadowOpacity = shadowOpacity ?? 1
            shadowRadius = anyNumber(shadow["blur"]) ?? shadowRadius
            shadowOffset = shadow["offset"] as? [String: Any] ?? shadowOffset
        }
        view.layer?.shadowColor = try? anyColor(shadowColor)?.cgColor
        view.layer?.shadowOpacity = Float(shadowOpacity ?? (shadowColor == nil ? 0 : 1))
        view.layer?.shadowRadius = shadowRadius ?? anyNumber(styles["elevation"]) ?? 0
        view.layer?.shadowOffset = CGSize(
            width: anyNumber(shadowOffset?["x"]) ?? 0,
            height: -(anyNumber(shadowOffset?["y"]) ?? 0)
        )

        if let color = try? anyColor(styles["color"] ?? styles["tintColor"]) {
            if let field = view as? NSTextField { field.textColor = color }
            else if let button = view as? NSButton { button.contentTintColor = color }
            else if let image = view as? NSImageView { image.contentTintColor = color }
        }
        applyTransformOrigin(styles["transformOrigin"], to: view)
        applyTransform(styles["transform"], to: view)
        refreshTextAppearance(node, styles: styles)
    }

    func refreshLayoutAfterInsertion(_ node: NativeNode) {
        updateMargins(node)
        updateFlexPriorities(node)
        updateFlexBasis(node)
        updateAlignSelf(node)
        updatePosition(node)
    }

    func refreshTextAppearance(_ node: NativeNode, styles explicitStyles: [String: Any]? = nil) {
        guard let control = node.view as? NSControl else { return }
        let styles = explicitStyles ?? node.styleValues
        let size = anyNumber(styles["fontSize"]) ?? control.font?.pointSize ?? NSFont.systemFontSize
        let weight = parseFontWeight(styles["fontWeight"])
        let family = styles["fontFamily"] as? String
        var font = family.flatMap { NSFont(name: $0, size: size) } ?? NSFont.systemFont(ofSize: size, weight: weight)
        if styles["fontStyle"] as? String == "italic" {
            font = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
        }
        control.font = font
        guard let field = control as? NSTextField else { return }

        switch styles["textAlign"] as? String {
        case "center": field.alignment = .center
        case "right", "end": field.alignment = .right
        case "left", "start": field.alignment = .left
        default: break
        }
        guard !(field is GradientTextField) else { return }

        var text = node.rawText.isEmpty ? field.stringValue : node.rawText
        switch styles["textTransform"] as? String {
        case "uppercase": text = text.uppercased()
        case "lowercase": text = text.lowercased()
        case "capitalize": text = text.capitalized
        default: break
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = field.alignment
        if let lineHeight = anyNumber(styles["lineHeight"]) {
            paragraph.minimumLineHeight = lineHeight
            paragraph.maximumLineHeight = lineHeight
        }
        var attributes: [NSAttributedString.Key: Any] = [.font: font, .paragraphStyle: paragraph]
        if let color = try? anyColor(styles["color"]) { attributes[.foregroundColor] = color }
        if let spacing = anyNumber(styles["letterSpacing"]) { attributes[.kern] = spacing }
        if let decoration = styles["textDecorationLine"] as? String {
            if decoration.contains("underline") { attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue }
            if decoration.contains("lineThrough") { attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue }
        }
        if let decorationColor = try? anyColor(styles["textDecorationColor"]) {
            attributes[.underlineColor] = decorationColor
            attributes[.strikethroughColor] = decorationColor
        }
        field.attributedStringValue = NSAttributedString(string: text, attributes: attributes)
    }

    private func updateAspectRatio(_ node: NativeNode) {
        node.constraints["aspectRatio"]?.isActive = false
        node.constraints.removeValue(forKey: "aspectRatio")
        guard let view = node.view, let ratio = styleNumber(node, "aspectRatio"), ratio > 0 else { return }
        let constraint = view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: ratio)
        constraint.isActive = true
        node.constraints["aspectRatio"] = constraint
    }

    private func updateMargins(_ node: NativeNode) {
        guard let view = node.view, let stack = view.superview as? NSStackView,
              stack.arrangedSubviews.contains(where: { $0 === view }) else { return }
        let insets = resolvedInsets(node.styleValues, prefix: "margin")
        let trailing = stack.orientation == .vertical ? insets.bottom : insets.right
        stack.setCustomSpacing(stack.spacing + trailing, after: view)
    }

    private func updateFlexPriorities(_ node: NativeNode) {
        guard let view = node.view else { return }
        let grow = styleNumber(node, "flexGrow") ?? 0
        let shrink = styleNumber(node, "flexShrink") ?? 0
        let hugging: NSLayoutConstraint.Priority = grow > 0 ? .defaultLow : .defaultHigh
        let compression: NSLayoutConstraint.Priority = shrink > 0 ? .defaultLow : .defaultHigh
        view.setContentHuggingPriority(hugging, for: .horizontal)
        view.setContentHuggingPriority(hugging, for: .vertical)
        view.setContentCompressionResistancePriority(compression, for: .horizontal)
        view.setContentCompressionResistancePriority(compression, for: .vertical)
    }

    private func updateFlexBasis(_ node: NativeNode) {
        node.constraints["flexBasis"]?.isActive = false
        node.constraints.removeValue(forKey: "flexBasis")
        guard let view = node.view, let basis = styleNumber(node, "flexBasis") else { return }
        let vertical = (view.superview as? NSStackView)?.orientation == .vertical
        let constraint = vertical ? view.heightAnchor.constraint(greaterThanOrEqualToConstant: basis) : view.widthAnchor.constraint(greaterThanOrEqualToConstant: basis)
        constraint.isActive = true
        node.constraints["flexBasis"] = constraint
    }

    private func updateAlignSelf(_ node: NativeNode) {
        for key in ["alignSelf.leading", "alignSelf.trailing", "alignSelf.center"] {
            node.constraints[key]?.isActive = false
            node.constraints.removeValue(forKey: key)
        }
        guard let view = node.view, let parent = node.parent?.insertionView, let value = styleString(node, "alignSelf") else { return }
        let constraint: NSLayoutConstraint?
        switch value {
        case "start", "flexStart": constraint = view.leadingAnchor.constraint(equalTo: parent.leadingAnchor)
        case "end", "flexEnd": constraint = view.trailingAnchor.constraint(equalTo: parent.trailingAnchor)
        case "center": constraint = view.centerXAnchor.constraint(equalTo: parent.centerXAnchor)
        case "stretch": constraint = view.widthAnchor.constraint(equalTo: parent.widthAnchor)
        default: constraint = nil
        }
        constraint?.isActive = true
        if let constraint { node.constraints["alignSelf.\(value)"] = constraint }
    }

    func updatePosition(_ node: NativeNode) {
        for edge in ["top", "right", "bottom", "left"] {
            node.constraints["position.\(edge)"]?.isActive = false
            node.constraints.removeValue(forKey: "position.\(edge)")
        }
        guard let view = node.view, let parentNode = node.parent, let parent = parentNode.insertionView else { return }
        let isAbsolute = styleString(node, "position") == "absolute"
        if let stack = parent as? NativeStackView {
            let isArranged = stack.contentViews.contains { $0 === view }
            if isAbsolute && isArranged {
                stack.removeNativeArrangedSubview(view)
                stack.addSubview(view)
            } else if !isAbsolute && !isArranged {
                view.removeFromSuperview()
                let nativeIndex = parentNode.children.prefix { $0 !== node }
                    .filter { ($0.styleValues["position"] as? String) != "absolute" }.count
                stack.insertNativeArrangedSubview(view, at: nativeIndex)
            }
        }
        guard isAbsolute else { return }
        let top = styleNumber(node, "top")
        let left = styleNumber(node, "left")
        let right = styleNumber(node, "right")
        let bottom = styleNumber(node, "bottom")
        let anchors: [(String, CGFloat?, NSLayoutConstraint)] = [
            ("top", top, view.topAnchor.constraint(equalTo: parent.topAnchor, constant: top ?? 0)),
            ("left", left, view.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: left ?? 0)),
            ("right", right, view.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -(right ?? 0))),
            ("bottom", bottom, view.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -(bottom ?? 0)))
        ]
        for (key, value, constraint) in anchors where value != nil {
            constraint.isActive = true
            node.constraints["position.\(key)"] = constraint
        }
    }

    private func resolvedInsets(_ values: [String: Any], prefix: String) -> NSEdgeInsets {
        var result = NSEdgeInsets()
        if let amount = anyNumber(values[prefix]) {
            result = NSEdgeInsets(top: amount, left: amount, bottom: amount, right: amount)
        } else if let map = values[prefix] as? [String: Any] {
            result = NSEdgeInsets(
                top: anyNumber(map["top"]) ?? 0,
                left: anyNumber(map["left"]) ?? 0,
                bottom: anyNumber(map["bottom"]) ?? 0,
                right: anyNumber(map["right"]) ?? 0
            )
        }
        if let vertical = anyNumber(values["\(prefix)Vertical"]) { result.top = vertical; result.bottom = vertical }
        if let horizontal = anyNumber(values["\(prefix)Horizontal"]) { result.left = horizontal; result.right = horizontal }
        if let top = anyNumber(values["\(prefix)Top"]) { result.top = top }
        if let right = anyNumber(values["\(prefix)Right"]) { result.right = right }
        if let bottom = anyNumber(values["\(prefix)Bottom"]) { result.bottom = bottom }
        if let left = anyNumber(values["\(prefix)Left"]) { result.left = left }
        return result
    }

    private func styleNumber(_ node: NativeNode, _ key: String) -> CGFloat? { anyNumber(node.styleValues[key]) }
    private func styleString(_ node: NativeNode, _ key: String) -> String? { node.styleValues[key] as? String }
    private func styleBool(_ node: NativeNode, _ key: String) -> Bool { (node.styleValues[key] as? NSNumber)?.boolValue ?? false }

    private func anyNumber(_ value: Any?) -> CGFloat? {
        if let number = value as? NSNumber { return CGFloat(number.doubleValue) }
        if let number = value as? Double { return CGFloat(number) }
        if let number = value as? Int { return CGFloat(number) }
        return nil
    }

    private func anyColor(_ value: Any?) throws -> NSColor? {
        guard let raw = value as? String else { return nil }
        return try parseColor(raw)
    }

    private func updateBorderLayers(_ node: NativeNode, styles: [String: Any]) {
        guard let view = node.view, let root = view.layer else { return }
        let baseWidth = anyNumber(styles["borderWidth"]) ?? 0
        let baseColor = styles["borderColor"]
        let sideKeys = ["top", "right", "bottom", "left"]
        let hasPerSide = sideKeys.contains { styles["border\($0.capitalized)Width"] != nil || styles["border\($0.capitalized)Color"] != nil }
        if !hasPerSide {
            root.borderWidth = baseWidth
            root.borderColor = try? anyColor(baseColor)?.cgColor
            for layer in node.decorationLayers.values { layer.removeFromSuperlayer() }
            node.decorationLayers.removeAll()
            return
        }
        root.borderWidth = 0
        for side in sideKeys {
            let layer = node.decorationLayers[side] ?? CALayer()
            if layer.superlayer == nil { root.addSublayer(layer); node.decorationLayers[side] = layer }
            let width = anyNumber(styles["border\(side.capitalized)Width"]) ?? baseWidth
            let color = styles["border\(side.capitalized)Color"] ?? baseColor
            layer.backgroundColor = try? anyColor(color)?.cgColor
            switch side {
            case "top":
                layer.frame = CGRect(x: 0, y: root.bounds.height - width, width: root.bounds.width, height: width)
                layer.autoresizingMask = [.layerWidthSizable, .layerMinYMargin]
            case "right":
                layer.frame = CGRect(x: root.bounds.width - width, y: 0, width: width, height: root.bounds.height)
                layer.autoresizingMask = [.layerHeightSizable, .layerMinXMargin]
            case "bottom":
                layer.frame = CGRect(x: 0, y: 0, width: root.bounds.width, height: width)
                layer.autoresizingMask = [.layerWidthSizable, .layerMaxYMargin]
            default:
                layer.frame = CGRect(x: 0, y: 0, width: width, height: root.bounds.height)
                layer.autoresizingMask = [.layerHeightSizable, .layerMaxXMargin]
            }
            layer.isHidden = width <= 0
        }
    }

    private func applyTransformOrigin(_ value: Any?, to view: NSView) {
        guard let layer = view.layer, let raw = value as? String else { return }
        let next: CGPoint
        switch raw {
        case "topLeft": next = CGPoint(x: 0, y: 1)
        case "top": next = CGPoint(x: 0.5, y: 1)
        case "topRight": next = CGPoint(x: 1, y: 1)
        case "left": next = CGPoint(x: 0, y: 0.5)
        case "right": next = CGPoint(x: 1, y: 0.5)
        case "bottomLeft": next = CGPoint(x: 0, y: 0)
        case "bottom": next = CGPoint(x: 0.5, y: 0)
        case "bottomRight": next = CGPoint(x: 1, y: 0)
        default: next = CGPoint(x: 0.5, y: 0.5)
        }
        let oldFrame = layer.frame
        layer.anchorPoint = next
        layer.frame = oldFrame
    }

    private func applyTransform(_ value: Any?, to view: NSView) {
        guard let transforms = value as? [[String: Any]] else {
            view.layer?.setAffineTransform(.identity)
            return
        }
        var result = CGAffineTransform.identity
        for transform in transforms {
            for (name, raw) in transform {
                let numeric = transformNumber(raw)
                switch name {
                case "translateX": result = result.translatedBy(x: numeric, y: 0)
                case "translateY": result = result.translatedBy(x: 0, y: numeric)
                case "scale": result = result.scaledBy(x: numeric, y: numeric)
                case "scaleX": result = result.scaledBy(x: numeric, y: 1)
                case "scaleY": result = result.scaledBy(x: 1, y: numeric)
                case "rotate": result = result.rotated(by: transformAngle(raw))
                default: break
                }
            }
        }
        view.layer?.setAffineTransform(result)
    }

    private func transformNumber(_ value: Any) -> CGFloat {
        if let number = anyNumber(value) { return number }
        if let string = value as? String { return CGFloat(Double(string.replacingOccurrences(of: "px", with: "")) ?? 0) }
        return 0
    }

    private func transformAngle(_ value: Any) -> CGFloat {
        guard let string = value as? String else { return transformNumber(value) }
        if string.hasSuffix("deg") { return CGFloat((Double(string.dropLast(3)) ?? 0) * .pi / 180) }
        if string.hasSuffix("rad") { return CGFloat(Double(string.dropLast(3)) ?? 0) }
        return transformNumber(value)
    }

    private func updateSizeConstraint(node: NativeNode, name: String, value: JSValue) throws {
        node.constraints[name]?.isActive = false
        node.constraints.removeValue(forKey: name)
        guard !value.isNull && !value.isUndefined else { return }
        if value.isString && value.toString() == "auto" { return }
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
        return try parseColor(raw)
    }

    private func parseColor(_ raw: String) throws -> NSColor? {
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
            "blue": .systemBlue,
            "gray": .systemGray,
            "orange": .systemOrange,
            "yellow": .systemYellow,
            "purple": .systemPurple,
            "pink": .systemPink
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
        parseFontWeight(string(value))
    }

    private func parseFontWeight(_ value: Any?) -> NSFont.Weight {
        let raw: String?
        if let string = value as? String { raw = string }
        else if let number = value as? NSNumber { raw = number.stringValue }
        else { raw = nil }
        switch raw {
        case nil, "regular", "400": return .regular
        case "thin", "100": return .thin
        case "ultralight", "200": return .ultraLight
        case "light", "300": return .light
        case "medium", "500": return .medium
        case "semibold", "600": return .semibold
        case "bold", "700": return .bold
        case "heavy", "800": return .heavy
        case "black", "900": return .black
        default: return .regular
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
            case nil, "start", "flexStart", "leading": return .leading
            case "center": return .centerX
            case "end", "flexEnd", "trailing": return .trailing
            case "stretch": return .width
            default: break
            }
        } else {
            switch raw {
            case nil, "center": return .centerY
            case "start", "flexStart", "top": return .top
            case "end", "flexEnd", "bottom": return .bottom
            case "stretch": return .height
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
