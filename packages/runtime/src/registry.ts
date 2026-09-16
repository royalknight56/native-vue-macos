export interface NativeModelDescriptor {
  prop: string
  event: string
  eventValue?: string
}

export interface NativeElementDescriptor {
  model?: NativeModelDescriptor
}

const elements = new Map<string, NativeElementDescriptor>()

export function normalizeElementName(name: string): string {
  return name.trim().toLowerCase()
}

export function registerElement(name: string, descriptor: NativeElementDescriptor = {}): void {
  const normalized = normalizeElementName(name)
  if (!normalized.startsWith('mac-')) {
    throw new Error(`Native element names must start with "mac-": ${name}`)
  }
  if (elements.has(normalized)) {
    throw new Error(`Native element is already registered: ${name}`)
  }
  elements.set(normalized, descriptor)
}

export function getElementDescriptor(name: string): NativeElementDescriptor {
  const descriptor = elements.get(normalizeElementName(name))
  if (!descriptor) throw new Error(`Unknown native element <${name}>`)
  return descriptor
}

export function isKnownElement(name: string): boolean {
  return elements.has(normalizeElementName(name))
}

export const builtInNativeElements: ReadonlyArray<readonly [string, NativeElementDescriptor?]> = [
  ['mac-window'],
  ['mac-view'],
  ['mac-v-stack'],
  ['mac-h-stack'],
  ['mac-z-stack'],
  ['mac-scroll-view'],
  ['mac-spacer'],
  ['mac-text'],
  ['mac-gradient-text'],
  ['mac-button'],
  ['mac-text-field', { model: { prop: 'value', event: 'input', eventValue: 'value' } }],
  ['mac-secure-field', { model: { prop: 'value', event: 'input', eventValue: 'value' } }],
  ['mac-toggle', { model: { prop: 'checked', event: 'change', eventValue: 'checked' } }],
  ['mac-progress'],
  ['mac-divider'],
  ['mac-image'],
  ['mac-box'],
  ['mac-clip-view'],
  ['mac-split-view'],
  ['mac-tab-view'],
  ['mac-grid-view'],
  ['mac-visual-effect-view'],
  ['mac-scroller'],
  ['mac-ruler-view'],
  ['mac-radio', { model: { prop: 'checked', event: 'change', eventValue: 'checked' } }],
  ['mac-switch', { model: { prop: 'checked', event: 'change', eventValue: 'checked' } }],
  ['mac-text-view', { model: { prop: 'value', event: 'input', eventValue: 'value' } }],
  ['mac-search-field', { model: { prop: 'value', event: 'input', eventValue: 'value' } }],
  ['mac-token-field', { model: { prop: 'value', event: 'input', eventValue: 'value' } }],
  ['mac-combo-box', { model: { prop: 'value', event: 'input', eventValue: 'value' } }],
  ['mac-pop-up-button', { model: { prop: 'selectedIndex', event: 'change', eventValue: 'selectedIndex' } }],
  ['mac-segmented-control', { model: { prop: 'selectedIndex', event: 'change', eventValue: 'selectedIndex' } }],
  ['mac-combo-button'],
  ['mac-slider', { model: { prop: 'value', event: 'change', eventValue: 'value' } }],
  ['mac-stepper', { model: { prop: 'value', event: 'change', eventValue: 'value' } }],
  ['mac-level-indicator', { model: { prop: 'value', event: 'change', eventValue: 'value' } }],
  ['mac-date-picker', { model: { prop: 'value', event: 'change', eventValue: 'value' } }],
  ['mac-color-well', { model: { prop: 'value', event: 'change', eventValue: 'value' } }],
  ['mac-path-control', { model: { prop: 'value', event: 'change', eventValue: 'value' } }],
  ['mac-table-view'],
  ['mac-outline-view'],
  ['mac-collection-view'],
  ['mac-browser'],
  ['mac-rule-editor'],
  ['mac-scrubber'],
  ['mac-table-row-view'],
  ['mac-table-cell-view'],
  ['mac-table-header-view']
]

for (const [name, descriptor] of builtInNativeElements) registerElement(name, descriptor)
