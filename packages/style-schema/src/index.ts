export type NativeStylePrimitive = string | number | boolean | null
export type NativeStyleValue = NativeStylePrimitive | NativeStyleValue[] | { [key: string]: NativeStyleValue }
export type NativeStyleRecord = Record<string, NativeStyleValue>

export type NativeStyleState = 'hover' | 'active' | 'focus' | 'disabled'

export interface NativeStyleSelector {
  raw: string
  type?: string
  id?: string
  classes: string[]
  state?: NativeStyleState
}

export interface NativeStyleRule {
  selector: NativeStyleSelector
  declarations: NativeStyleRecord
}

export interface CompiledNativeStyleSheet {
  id: string
  scoped: boolean
  rules: NativeStyleRule[]
}

const supported = [
  // Sizing and native Auto Layout.
  'width', 'height', 'minWidth', 'minHeight', 'maxWidth', 'maxHeight', 'aspectRatio',
  // Box model.
  'margin', 'marginTop', 'marginRight', 'marginBottom', 'marginLeft', 'marginHorizontal', 'marginVertical',
  'padding', 'paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft', 'paddingHorizontal', 'paddingVertical',
  // Flex/stack layout.
  'display', 'flexDirection', 'flexGrow', 'flexShrink', 'flexBasis', 'flexWrap',
  'justifyContent', 'alignItems', 'alignSelf', 'alignment', 'gap', 'rowGap', 'columnGap', 'spacing',
  // Positioning.
  'position', 'top', 'right', 'bottom', 'left', 'zIndex',
  // Visibility and clipping.
  'opacity', 'hidden', 'visibility', 'overflow',
  // Surface and borders.
  'backgroundColor', 'borderColor', 'borderWidth', 'borderRadius', 'cornerRadius',
  'borderTopColor', 'borderRightColor', 'borderBottomColor', 'borderLeftColor',
  'borderTopWidth', 'borderRightWidth', 'borderBottomWidth', 'borderLeftWidth',
  'borderTopLeftRadius', 'borderTopRightRadius', 'borderBottomRightRadius', 'borderBottomLeftRadius',
  // Shadows.
  'boxShadow', 'shadowColor', 'shadowOpacity', 'shadowRadius', 'shadowOffset', 'elevation',
  // Text.
  'color', 'fontSize', 'fontWeight', 'fontFamily', 'fontStyle', 'lineHeight', 'letterSpacing',
  'textAlign', 'textDecorationLine', 'textDecorationColor', 'textTransform',
  // Images and controls.
  'objectFit', 'resizeMode', 'tintColor', 'cursor',
  // Transforms.
  'transform', 'transformOrigin',
  // Native interaction states. These are style objects rather than CSS declarations.
  'hoverStyle', 'pressedStyle', 'focusStyle', 'disabledStyle',
  // Native gradient extension used by mac-gradient-text.
  'gradientStartColor', 'gradientEndColor'
] as const

export type NativeStyleProperty = typeof supported[number]
export const supportedNativeStyleProperties = new Set<string>(supported)

export const browserOnlyStyleProperties = new Set([
  'float', 'clear', 'content', 'quotes', 'captionSide', 'emptyCells',
  'grid', 'gridArea', 'gridTemplate', 'gridTemplateAreas', 'gridTemplateColumns', 'gridTemplateRows',
  'gridColumn', 'gridRow', 'gridAutoColumns', 'gridAutoRows', 'gridAutoFlow',
  'columns', 'columnCount', 'columnFill', 'columnRule', 'columnSpan', 'columnWidth',
  'shapeOutside', 'clipPath', 'mask', 'filter', 'backdropFilter', 'mixBlendMode',
  'counterIncrement', 'counterReset', 'listStyle', 'listStyleImage', 'listStylePosition', 'listStyleType',
  'pageBreakAfter', 'pageBreakBefore', 'pageBreakInside', 'orphans', 'widows',
  'tableLayout', 'borderCollapse', 'borderSpacing', 'verticalAlign',
  'animation', 'animationName', 'animationDuration', 'transition', 'transitionProperty'
])

const aliases: Record<string, string> = {
  cornerRadius: 'borderRadius',
  spacing: 'gap'
}

export function normalizeNativeStyleProperty(name: string): string {
  const camel = name.trim().replace(/-([a-z])/g, (_, letter: string) => letter.toUpperCase())
  return aliases[camel] ?? camel
}

export function assertNativeStyleProperty(name: string, file = '<style>', line?: number): NativeStyleProperty {
  const normalized = normalizeNativeStyleProperty(name)
  if (supportedNativeStyleProperties.has(normalized) || supportedNativeStyleProperties.has(name)) return normalized as NativeStyleProperty
  const location = `${file}${line ? `:${line}` : ''}`
  if (browserOnlyStyleProperties.has(normalized)) {
    throw new Error(`${location}: CSS property "${name}" has browser-only semantics and cannot be represented by AppKit`)
  }
  throw new Error(`${location}: Unknown native style property "${name}"`)
}

const enumValues: Partial<Record<string, string[]>> = {
  display: ['flex', 'none'],
  flexDirection: ['row', 'column'],
  flexWrap: ['nowrap'],
  position: ['relative', 'absolute'],
  overflow: ['visible', 'hidden'],
  visibility: ['visible', 'hidden'],
  justifyContent: ['flexStart', 'center', 'flexEnd', 'spaceBetween', 'spaceAround', 'spaceEvenly'],
  alignItems: ['start', 'end', 'flexStart', 'flexEnd', 'center', 'stretch', 'leading', 'trailing', 'top', 'bottom'],
  alignment: ['start', 'end', 'flexStart', 'flexEnd', 'center', 'stretch', 'leading', 'trailing', 'top', 'bottom'],
  alignSelf: ['auto', 'start', 'end', 'center', 'stretch', 'flexStart', 'flexEnd'],
  textAlign: ['left', 'right', 'center', 'start', 'end', 'natural'],
  textTransform: ['none', 'uppercase', 'lowercase', 'capitalize'],
  fontStyle: ['normal', 'italic'],
  objectFit: ['contain', 'cover', 'fill', 'center', 'none'],
  resizeMode: ['contain', 'cover', 'fill', 'center', 'none'],
  cursor: ['default', 'pointer', 'text', 'crosshair', 'notAllowed'],
  textDecorationLine: ['none', 'underline', 'lineThrough', 'underline lineThrough'],
  transformOrigin: ['center', 'topLeft', 'top', 'topRight', 'left', 'right', 'bottomLeft', 'bottom', 'bottomRight']
}

const numericProperties = new Set([
  'width', 'height', 'minWidth', 'minHeight', 'maxWidth', 'maxHeight', 'aspectRatio',
  'marginTop', 'marginRight', 'marginBottom', 'marginLeft', 'marginHorizontal', 'marginVertical',
  'paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft', 'paddingHorizontal', 'paddingVertical',
  'flexGrow', 'flexShrink', 'flexBasis', 'gap', 'rowGap', 'columnGap',
  'top', 'right', 'bottom', 'left', 'zIndex', 'opacity',
  'borderWidth', 'borderRadius', 'borderTopWidth', 'borderRightWidth', 'borderBottomWidth', 'borderLeftWidth',
  'borderTopLeftRadius', 'borderTopRightRadius', 'borderBottomRightRadius', 'borderBottomLeftRadius',
  'shadowOpacity', 'shadowRadius', 'elevation', 'fontSize', 'lineHeight', 'letterSpacing'
])

const colorProperties = new Set([
  'backgroundColor', 'borderColor', 'borderTopColor', 'borderRightColor', 'borderBottomColor', 'borderLeftColor',
  'shadowColor', 'color', 'textDecorationColor', 'tintColor', 'gradientStartColor', 'gradientEndColor'
])

const semanticColors = new Set([
  'label', 'secondaryLabel', 'accent', 'windowBackground', 'controlBackground', 'separator',
  'transparent', 'white', 'black', 'red', 'green', 'blue', 'gray', 'orange', 'yellow', 'purple', 'pink'
])

export function assertNativeStyleValue(property: string, value: NativeStyleValue, source = '<runtime style>'): void {
  if (value == null) return
  if (enumValues[property] && (typeof value !== 'string' || !enumValues[property]?.includes(value))) {
    throw new Error(`${source}: Unsupported value "${String(value)}" for native style property "${property}"`)
  }
  if (property === 'transform') {
    if (!Array.isArray(value)) throw new Error(`${source}: transform must be an array of native transform objects`)
    const supportedTransforms = new Set(['translateX', 'translateY', 'scale', 'scaleX', 'scaleY', 'rotate'])
    for (const transform of value) {
      if (!transform || typeof transform !== 'object' || Array.isArray(transform)) throw new Error(`${source}: Invalid native transform entry`)
      for (const name of Object.keys(transform)) if (!supportedTransforms.has(name)) throw new Error(`${source}: Unsupported native transform "${name}"`)
    }
  }
  if (numericProperties.has(property)) {
    const permitsAuto = ['width', 'height', 'minWidth', 'minHeight', 'maxWidth', 'maxHeight', 'flexBasis'].includes(property)
    if (typeof value !== 'number' && !(permitsAuto && value === 'auto')) {
      throw new Error(`${source}: Native style property "${property}" requires a numeric point value${permitsAuto ? ' or auto' : ''}`)
    }
  }
  if ((property === 'margin' || property === 'padding') && typeof value !== 'number' && (typeof value !== 'object' || Array.isArray(value))) {
    throw new Error(`${source}: Native style property "${property}" requires a number or edge object`)
  }
  if (property === 'hidden' && typeof value !== 'boolean') {
    throw new Error(`${source}: Native style property "hidden" requires a boolean`)
  }
  if (colorProperties.has(property) && (typeof value !== 'string' || (!semanticColors.has(value) && !/^#[0-9a-f]{6}(?:[0-9a-f]{2})?$/i.test(value)))) {
    throw new Error(`${source}: Native color "${String(value)}" must be a supported semantic color, #RRGGBB, or #RRGGBBAA`)
  }
  if (property === 'boxShadow' && value !== 'none' && (typeof value !== 'object' || Array.isArray(value))) {
    throw new Error(`${source}: boxShadow requires a native shadow object or a supported CSS shadow`)
  }
  if (property === 'shadowOffset' && (typeof value !== 'object' || Array.isArray(value))) {
    throw new Error(`${source}: shadowOffset requires an { x, y } object`)
  }
  if (property === 'fontWeight') {
    const allowed = new Set(['thin', 'ultralight', 'light', 'regular', 'medium', 'semibold', 'bold', 'heavy', 'black', '100', '200', '300', '400', '500', '600', '700', '800', '900'])
    if (!allowed.has(String(value))) throw new Error(`${source}: Unsupported native fontWeight "${String(value)}"`)
  }
}

function parseColor(value: string): string | undefined {
  const rgb = value.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([\d.]+))?\s*\)$/i)
  if (!rgb) return undefined
  const byte = (part: string) => Math.max(0, Math.min(255, Number(part))).toString(16).padStart(2, '0')
  const alpha = rgb[4] == null ? '' : byte(String(Math.round(Math.max(0, Math.min(1, Number(rgb[4]))) * 255)))
  return `#${byte(rgb[1])}${byte(rgb[2])}${byte(rgb[3])}${alpha}`.toUpperCase()
}

function parseEdges(value: string): NativeStyleRecord | undefined {
  const parts = value.trim().split(/\s+/).map(part => part.match(/^(-?[\d.]+)(?:px)?$/)?.[1]).map(Number)
  if (!parts.length || parts.length > 4 || parts.some(Number.isNaN)) return undefined
  const [top, second = top, third = top, fourth = second] = parts
  return parts.length === 1
    ? { top, right: top, bottom: top, left: top }
    : parts.length === 2
      ? { top, right: second, bottom: top, left: second }
      : parts.length === 3
        ? { top, right: second, bottom: third, left: second }
        : { top, right: second, bottom: third, left: fourth }
}

function parseShadow(value: string): NativeStyleRecord | undefined {
  const match = value.trim().match(/^(-?[\d.]+)px\s+(-?[\d.]+)px\s+([\d.]+)px(?:\s+([\d.]+)px)?\s+(.+)$/)
  if (!match) return undefined
  return {
    offset: { x: Number(match[1]), y: Number(match[2]) },
    blur: Number(match[3]),
    spread: Number(match[4] ?? 0),
    color: parseColor(match[5]) ?? match[5].trim()
  }
}

function parseTransform(value: string): NativeStyleValue[] | undefined {
  const transforms: NativeStyleValue[] = []
  const matcher = /([a-zA-Z]+)\(([^)]+)\)/g
  let match: RegExpExecArray | null
  let consumed = ''
  while ((match = matcher.exec(value))) {
    consumed += match[0]
    const raw = match[2].trim()
    if (!['translateX', 'translateY', 'scale', 'scaleX', 'scaleY', 'rotate'].includes(match[1])) return undefined
    const numeric = raw.match(/^(-?[\d.]+)(px|deg|rad)?$/)
    if (!numeric) return undefined
    transforms.push({ [match[1]]: numeric[2] ? `${numeric[1]}${numeric[2]}` : Number(numeric[1]) })
  }
  return consumed.replace(/\s/g, '') === value.replace(/\s/g, '') && transforms.length ? transforms : undefined
}

export function parseNativeStyleValue(property: string, rawValue: string): NativeStyleValue {
  const value = rawValue.trim()
  const keywordValue = value.replace(/-([a-z])/g, (_, letter: string) => letter.toUpperCase())
  if (/(?:%|rem|em|vw|vh|vmin|vmax)$/.test(value)) {
    throw new Error(`Native style property "${property}" does not support relative CSS units; use points or reactive window metrics`)
  }
  if (enumValues[property] && !enumValues[property]?.includes(keywordValue)) {
    throw new Error(`Unsupported value "${value}" for native style property "${property}"`)
  }
  if (property === 'margin' || property === 'padding') return parseEdges(value) ?? value
  if (property === 'boxShadow') {
    if (value === 'none') return value
    const shadow = parseShadow(value)
    if (!shadow) throw new Error(`Unsupported native box-shadow "${value}"; use x y blur [spread] color`)
    return shadow
  }
  if (property === 'transform') {
    if (value === 'none') return []
    const transform = parseTransform(value)
    if (!transform) throw new Error(`Unsupported native transform "${value}"`)
    return transform
  }
  const shortHex = value.match(/^#([0-9a-f]{3,4})$/i)?.[1]
  if (shortHex) return `#${[...shortHex].map(part => part + part).join('')}`.toUpperCase()
  const color = parseColor(value)
  if (color) return color
  const numeric = value.match(/^(-?[\d.]+)(?:px|pt)?$/)
  if (numeric) return Number(numeric[1])
  if (value === 'true') return true
  if (value === 'false') return false
  const quoted = value.match(/^(['"])(.*)\1$/)
  return quoted ? quoted[2] : keywordValue
}

function parseSelector(raw: string, file: string, line: number): NativeStyleSelector {
  const selector = raw.trim()
  const match = selector.match(/^(mac-[a-z0-9-]+)?(?:#([A-Za-z_][\w-]*))?((?:\.[A-Za-z_][\w-]*)*)(?::(hover|active|focus|disabled))?$/)
  if (!match || !selector) {
    throw new Error(`${file}:${line}: Unsupported native selector "${selector}"; use a mac-* tag, #id, .class, and optional :hover/:active/:focus/:disabled`)
  }
  return {
    raw: selector,
    type: match[1] || undefined,
    id: match[2] || undefined,
    classes: match[3] ? match[3].slice(1).split('.') : [],
    state: match[4] as NativeStyleState | undefined
  }
}

export function compileNativeStyleSheet(css: string, options: { id: string; file: string; scoped: boolean; lineOffset?: number }): CompiledNativeStyleSheet {
  const source = css.replace(/\/\*[\s\S]*?\*\//g, '')
  if (/@[\w-]+/.test(source)) {
    const token = source.match(/@[\w-]+/)?.[0]
    throw new Error(`${options.file}: Native styles do not support ${token}; use Vue reactivity for responsive and conditional styling`)
  }
  const rules: NativeStyleRule[] = []
  const matcher = /([^{}]+)\{([^{}]*)\}/g
  let match: RegExpExecArray | null
  let consumed = ''
  while ((match = matcher.exec(source))) {
    consumed += match[0]
    const line = source.slice(0, match.index).split('\n').length + (options.lineOffset ?? 0)
    const declarations: NativeStyleRecord = {}
    for (const declaration of match[2].split(';')) {
      if (!declaration.trim()) continue
      const separator = declaration.indexOf(':')
      if (separator < 1) throw new Error(`${options.file}:${line}: Invalid native style declaration "${declaration.trim()}"`)
      const rawName = declaration.slice(0, separator).trim()
      const property = assertNativeStyleProperty(rawName, options.file, line)
      try {
        const value = parseNativeStyleValue(property, declaration.slice(separator + 1))
        assertNativeStyleValue(property, value, `${options.file}:${line}`)
        declarations[property] = value
      } catch (error) {
        throw new Error(`${options.file}:${line}: ${error instanceof Error ? error.message : String(error)}`)
      }
    }
    for (const rawSelector of match[1].split(',')) {
      rules.push({ selector: parseSelector(rawSelector, options.file, line), declarations: { ...declarations } })
    }
  }
  if (consumed.replace(/\s/g, '') !== source.replace(/\s/g, '')) {
    throw new Error(`${options.file}: Unable to parse native stylesheet`)
  }
  return { id: options.id, scoped: options.scoped, rules }
}
