import { camelize, createRenderer, type Component, type RendererOptions } from '@vue/runtime-core'
import { bridge, checked, type NativeValue } from './bridge'
import { disposeEvents, patchEvent } from './events'
import { NativeNode, createRootNode } from './node'
import { getElementDescriptor, isKnownElement } from './registry'
import { flattenNativeStyle, normalizeNativeClass, resolveNativeStyle, setNativeStyleInvalidator, type NativeClassInput, type NativeStyleInput } from './style'
import type { NativeStyleProperty } from '@native-vue-macos/style-schema'

function insert(child: NativeNode, parent: NativeNode, anchor: NativeNode | null = null): void {
  // Positioning affects whether Swift inserts into NSStackView's arrangedSubviews.
  // Apply the node's own rules before insertion, then resolve inherited values once
  // the native and renderer parent relationships have both been established.
  applyResolvedStyle(child)
  parent.insert(child, anchor)
  applyResolvedStyle(child)
  if (child.type === 'mac-window') checked(bridge().showWindow(child.id), 'showWindow')
}

function remove(node: NativeNode): void {
  disposeEvents(node)
  for (const child of [...node.children]) remove(child)
  node.parent?.detach(node)
}

function createElement(type: string): NativeNode {
  if (!isKnownElement(type)) throw new Error(`Unknown native element <${type}>`)
  return new NativeNode(type)
}

function createText(text: string): NativeNode {
  const node = new NativeNode('#text')
  checked(bridge().setText(node.id, text), 'setText')
  return node
}

function createComment(): NativeNode {
  return new NativeNode('#comment')
}

function setText(node: NativeNode, text: string): void {
  checked(bridge().setText(node.id, text), `setText(${node.type})`)
}

function setElementText(node: NativeNode, text: string): void {
  setText(node, text)
}

function parentNode(node: NativeNode): NativeNode | null {
  return node.parent
}

function nextSibling(node: NativeNode): NativeNode | null {
  if (!node.parent) return null
  const index = node.parent.children.indexOf(node)
  return node.parent.children[index + 1] ?? null
}

function applyResolvedStyle(node: NativeNode): void {
  const before = node.appliedStyle
  const after = resolveNativeStyle(node)
  for (const key of new Set<NativeStyleProperty>([
    ...Object.keys(before) as NativeStyleProperty[],
    ...Object.keys(after) as NativeStyleProperty[]
  ])) {
    checked(bridge().setStyle(node.id, key, after[key] ?? null), `setStyle(${node.type}.${key})`)
  }
  node.appliedStyle = after
  for (const child of node.children) applyResolvedStyle(child)
}

function patchStyle(node: NativeNode, next: unknown): void {
  node.inlineStyle = flattenNativeStyle(next as NativeStyleInput)
  applyResolvedStyle(node)
}

function patchProp(node: NativeNode, key: string, previous: unknown, next: unknown): void {
  if (key === 'style') return patchStyle(node, next)
  if (key === 'class') {
    node.classNames = normalizeNativeClass(next as NativeClassInput)
    applyResolvedStyle(node)
    return
  }
  if (key === 'id') {
    node.nativeId = next == null ? undefined : String(next)
    applyResolvedStyle(node)
    return
  }

  const model = getElementDescriptor(node.type).model
  if (key === 'modelValue' && model) {
    checked(bridge().setProp(node.id, model.prop, (next ?? null) as NativeValue), `setProp(${node.type}.${model.prop})`)
    return
  }
  if (key === 'onUpdate:modelValue' && model) {
    const wrapped = next
      ? (payload: unknown) => {
          const value = payload && typeof payload === 'object'
            ? (payload as Record<string, unknown>)[model.eventValue ?? model.prop]
            : payload
          ;(next as (value: unknown) => void)(value)
        }
      : null
    patchEvent(node, key, wrapped, model.event)
    return
  }
  if (/^on[A-Z:]/.test(key)) {
    patchEvent(node, key, next as ((payload: unknown) => void) | null)
    return
  }
  const nativeKey = camelize(key)
  checked(bridge().setProp(node.id, nativeKey, (next ?? null) as NativeValue), `setProp(${node.type}.${nativeKey})`)
}

const options: RendererOptions<NativeNode, NativeNode> = {
  insert,
  remove,
  createElement,
  createText,
  createComment,
  setText,
  setElementText,
  parentNode,
  nextSibling,
  patchProp,
  setScopeId(node, id) {
    node.scopeIds.add(id)
    applyResolvedStyle(node)
  },
  cloneNode: node => node,
  insertStaticContent(content, parent, anchor) {
    const node = createText(content)
    insert(node, parent, anchor)
    return [node, node]
  }
}

export const nativeRenderer = createRenderer(options)

interface RuntimeSession {
  app?: NativeApp
  root?: NativeNode
  proxy?: unknown
}

const session: RuntimeSession = {}

setNativeStyleInvalidator(() => {
  for (const child of session.root?.children ?? []) applyResolvedStyle(child)
})

export type NativeApp = Omit<ReturnType<typeof nativeRenderer.createApp>, 'mount'> & {
  mount(container?: NativeNode): unknown
}

export function createNativeApp(rootComponent: Component, rootProps?: Record<string, unknown> | null): NativeApp {
  if (session.app) return session.app

  const app = nativeRenderer.createApp(rootComponent, rootProps ?? null)
  const originalMount = app.mount.bind(app)
  app.config.errorHandler = (error, instance, info) => {
    const value = error instanceof Error ? error : new Error(String(error))
    bridge().reportError(`${value.message}\nVue: ${info}`, value.stack ?? '')
  }
  app.mount = ((container?: NativeNode) => {
    if (session.proxy) return session.proxy
    session.root = container ?? createRootNode()
    session.proxy = originalMount(session.root)
    return session.proxy
  }) as typeof app.mount
  session.app = app as NativeApp
  return session.app
}

export function disposeApplication(): void {
  session.app?.unmount()
  bridge().dispose()
  session.app = undefined
  session.root = undefined
  session.proxy = undefined
}
