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

const builtins: Array<[string, NativeElementDescriptor?]> = [
  ['mac-window'],
  ['mac-v-stack'],
  ['mac-h-stack'],
  ['mac-z-stack'],
  ['mac-scroll-view'],
  ['mac-spacer'],
  ['mac-text'],
  ['mac-button'],
  ['mac-text-field', { model: { prop: 'value', event: 'input', eventValue: 'value' } }],
  ['mac-secure-field', { model: { prop: 'value', event: 'input', eventValue: 'value' } }],
  ['mac-toggle', { model: { prop: 'checked', event: 'change', eventValue: 'checked' } }],
  ['mac-progress'],
  ['mac-divider'],
  ['mac-image']
]

for (const [name, descriptor] of builtins) registerElement(name, descriptor)
