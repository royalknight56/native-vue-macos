import {
  assertNativeStyleProperty,
  assertNativeStyleValue,
  type CompiledNativeStyleSheet,
  type NativeStyleProperty,
  type NativeStyleRule,
  type NativeStyleValue
} from '@native-vue-macos/style-schema'
import type { NativeNode } from './node'

export type NativeStyle = Partial<Record<NativeStyleProperty, NativeStyleValue>>
export type NativeStyleInput = NativeStyle | false | null | undefined | NativeStyleInput[]
export type NativeClassInput = string | string[] | Record<string, boolean> | false | null | undefined

const sheets = new Map<string, CompiledNativeStyleSheet>()
let invalidateStyles: (() => void) | undefined

export const StyleSheet = {
  create<T extends Record<string, NativeStyle>>(styles: T): T {
    for (const [name, style] of Object.entries(styles)) validateNativeStyle(style, `StyleSheet.${name}`)
    return Object.freeze(styles) as T
  },
  flatten(style: NativeStyleInput): NativeStyle {
    return flattenNativeStyle(style)
  },
  compose(first: NativeStyleInput, second: NativeStyleInput): NativeStyleInput {
    return [first, second]
  }
}

export function registerNativeStyleSheet(sheet: CompiledNativeStyleSheet): void {
  sheets.set(sheet.id, sheet)
  invalidateStyles?.()
}

export function unregisterNativeStyleSheet(id: string): void {
  if (sheets.delete(id)) invalidateStyles?.()
}

export function setNativeStyleInvalidator(invalidator: (() => void) | undefined): void {
  invalidateStyles = invalidator
}

export function flattenNativeStyle(input: NativeStyleInput): NativeStyle {
  const output: NativeStyle = {}
  const visit = (value: NativeStyleInput): void => {
    if (!value) return
    if (Array.isArray(value)) {
      for (const item of value) visit(item)
      return
    }
    if (typeof value !== 'object') throw new Error('Native style values must be objects, arrays, or falsy conditions')
    for (const [rawName, rawValue] of Object.entries(value)) {
      const name = assertNativeStyleProperty(rawName, '<runtime style>')
      if (['hoverStyle', 'pressedStyle', 'focusStyle', 'disabledStyle'].includes(name) && rawValue && typeof rawValue === 'object' && !Array.isArray(rawValue)) {
        output[name] = flattenNativeStyle(rawValue as NativeStyle)
      } else {
        assertNativeStyleValue(name, rawValue as NativeStyleValue, '<runtime style>')
        output[name] = rawValue as NativeStyleValue
      }
    }
  }
  visit(input)
  return output
}

export function normalizeNativeClass(value: NativeClassInput): string[] {
  if (!value) return []
  if (typeof value === 'string') return value.trim().split(/\s+/).filter(Boolean)
  if (Array.isArray(value)) return value.flatMap(normalizeNativeClass)
  return Object.entries(value).filter(([, enabled]) => enabled).map(([name]) => name)
}

export function validateNativeStyle(style: NativeStyle, source = '<runtime style>'): void {
  for (const name of Object.keys(style)) assertNativeStyleProperty(name, source)
}

function matches(rule: NativeStyleRule, node: NativeNode): boolean {
  const selector = rule.selector
  if (selector.type && selector.type !== node.type) return false
  if (selector.id && selector.id !== node.nativeId) return false
  if (selector.classes.some(name => !node.classNames.includes(name))) return false
  return true
}

export function resolveNativeStyle(node: NativeNode): NativeStyle {
  const resolved: NativeStyle = {}
  const stateStyles: Record<string, NativeStyle> = {}
  const inherited: NativeStyleProperty[] = ['color', 'fontSize', 'fontWeight', 'fontFamily', 'fontStyle', 'lineHeight', 'letterSpacing', 'textAlign', 'textDecorationColor']
  for (const property of inherited) {
    const value = node.parent?.appliedStyle[property]
    if (value !== undefined) resolved[property] = value
  }
  const matched: Array<{ rule: NativeStyleRule; specificity: number; order: number }> = []
  let order = 0
  for (const sheet of sheets.values()) {
    if (sheet.scoped && !node.scopeIds.has(`data-nvm-${sheet.id}`)) continue
    for (const rule of sheet.rules) {
      order += 1
      if (!matches(rule, node)) continue
      const specificity = (rule.selector.id ? 100 : 0) + (rule.selector.classes.length + (rule.selector.state ? 1 : 0)) * 10 + (rule.selector.type ? 1 : 0)
      matched.push({ rule, specificity, order })
    }
  }
  matched.sort((left, right) => left.specificity - right.specificity || left.order - right.order)
  for (const { rule } of matched) {
    if (rule.selector.state) {
        const stateName = rule.selector.state === 'active' ? 'pressedStyle' : `${rule.selector.state}Style`
        Object.assign(stateStyles[stateName] ??= {}, rule.declarations)
    } else {
      Object.assign(resolved, rule.declarations)
    }
  }
  Object.assign(resolved, node.inlineStyle)
  for (const [name, style] of Object.entries(stateStyles)) {
    const property = name as NativeStyleProperty
    resolved[property] = { ...style, ...((resolved[property] as NativeStyle | undefined) ?? {}) }
  }
  return resolved
}
