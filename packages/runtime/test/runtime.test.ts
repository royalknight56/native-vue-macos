import { describe, expect, it } from 'vitest'
import { defineComponent, h, nextTick, ref } from 'vue'
import { installBridgeForTesting, type NativeBridge, type NativeValue } from '../src/bridge'
import { NativeNode } from '../src/node'
import { nativeRenderer } from '../src/renderer'
import { hmrManager } from '../src/hmr'
import { builtInNativeElements, getElementDescriptor, isKnownElement } from '../src/registry'

class FakeBridge implements NativeBridge {
  nextId = 1
  root = 0
  nodes = new Map<number, { type: string; parent?: number; props: Record<string, NativeValue>; text?: string }>()
  listeners = new Map<string, number>()
  error: string | null = null

  createApplicationRoot() { this.root ||= this.createNode('#root'); return this.root }
  createNode(type: string) { const id = this.nextId++; this.nodes.set(id, { type, props: {} }); return id }
  insertNode(child: number, parent: number) { this.nodes.get(child)!.parent = parent; return true }
  removeNode(id: number) { this.nodes.delete(id); return true }
  setText(id: number, value: string) { this.nodes.get(id)!.text = value; return true }
  setProp(id: number, name: string, value: NativeValue) { this.nodes.get(id)!.props[name] = value; return true }
  setStyle(id: number, name: string, value: NativeValue) { this.nodes.get(id)!.props[`style.${name}`] = value; return true }
  addEventListener(id: number, event: string, callback: number) { this.listeners.set(`${id}:${event}`, callback); return true }
  removeEventListener(id: number, event: string) { this.listeners.delete(`${id}:${event}`); return true }
  showWindow() { return true }
  dispose() { this.nodes.clear() }
  takeLastError() { const value = this.error; this.error = null; return value }
  reportError() {}
}

describe('native renderer', () => {
  it('publishes the complete macOS 13 AppKit element catalog', () => {
    expect(builtInNativeElements).toHaveLength(48)
    for (const [tag] of builtInNativeElements) expect(isKnownElement(tag), tag).toBe(true)
    expect(getElementDescriptor('mac-slider').model).toEqual({ prop: 'value', event: 'change', eventValue: 'value' })
    expect(getElementDescriptor('mac-color-well').model?.eventValue).toBe('value')
  })

  it('inserts, patches and removes native nodes', () => {
    const bridge = new FakeBridge()
    installBridgeForTesting(bridge)
    const parent = new NativeNode('mac-v-stack')
    const child = new NativeNode('mac-text')
    parent.insert(child, null)
    expect(bridge.nodes.get(child.id)?.parent).toBe(parent.id)
    parent.detach(child)
    expect(bridge.nodes.has(child.id)).toBe(false)
  })

  it('maps v-model updates to native input events', async () => {
    const bridge = new FakeBridge()
    installBridgeForTesting(bridge)
    const value = ref('before')
    const App = defineComponent(() => () => h('mac-text-field', {
      modelValue: value.value,
      'onUpdate:modelValue': (next: string) => { value.value = next }
    }))
    const app = nativeRenderer.createApp(App)
    const root = new NativeNode('#root', bridge.createApplicationRoot())
    app.mount(root)
    const input = [...bridge.nodes.entries()].find(([, node]) => node.type === 'mac-text-field')!
    const callback = bridge.listeners.get(`${input[0]}:input`)!
    globalThis.__nativeDispatch?.(callback, { value: 'after' })
    await nextTick()
    expect(value.value).toBe('after')
    expect(bridge.nodes.get(input[0])?.props.value).toBe('after')
    app.unmount()
  })
})

describe('HMR registry', () => {
  it('rerenders templates and reloads scripts through Vue HMR boundaries', () => {
    const calls: string[] = []
    globalThis.__VUE_HMR_RUNTIME__ = {
      createRecord: () => { calls.push('create'); return true },
      rerender: () => calls.push('rerender'),
      reload: () => calls.push('reload')
    }
    const first = { render: () => null }
    expect(hmrManager.register('hmr-test', first, 'script-1', 'template-1')).toBe(first)
    expect(hmrManager.register('hmr-test', { render: () => null }, 'script-1', 'template-2')).toBe(first)
    expect(hmrManager.register('hmr-test', { render: () => null }, 'script-2', 'template-3')).toBe(first)
    expect(calls).toEqual(['create', 'rerender', 'reload'])
  })
})
