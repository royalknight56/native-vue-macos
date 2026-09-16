import type { NativeNode } from './node'
import { bridge, checked } from './bridge'

type Handler = ((payload: unknown) => void) | Array<(payload: unknown) => void>

interface Listener {
  id: number
  handler: Handler
  nativeEvent: string
}

let nextCallbackId = 1
const callbacks = new Map<number, Listener>()
const nodeListeners = new WeakMap<NativeNode, Map<string, Listener>>()

globalThis.__nativeDispatch = (callbackId, payload) => {
  const listener = callbacks.get(callbackId)
  if (!listener) return
  try {
    if (Array.isArray(listener.handler)) {
      for (const handler of listener.handler) handler(payload)
    } else {
      listener.handler(payload)
    }
  } catch (error) {
    const value = error instanceof Error ? error : new Error(String(error))
    bridge().reportError(value.message, value.stack ?? '')
  }
}

export function patchEvent(node: NativeNode, key: string, next: Handler | null, nativeEvent?: string): void {
  let listeners = nodeListeners.get(node)
  if (!listeners) {
    listeners = new Map()
    nodeListeners.set(node, listeners)
  }

  const existing = listeners.get(key)
  if (existing && next) {
    existing.handler = next
    return
  }
  if (existing) {
    checked(
      bridge().removeEventListener(node.id, existing.nativeEvent, existing.id),
      `removeEventListener(${existing.nativeEvent})`
    )
    callbacks.delete(existing.id)
    listeners.delete(key)
  }
  if (!next) return

  const listener: Listener = {
    id: nextCallbackId++,
    handler: next,
    nativeEvent: nativeEvent ?? eventNameFromProp(key)
  }
  callbacks.set(listener.id, listener)
  listeners.set(key, listener)
  checked(
    bridge().addEventListener(node.id, listener.nativeEvent, listener.id),
    `addEventListener(${listener.nativeEvent})`
  )
}

export function disposeEvents(node: NativeNode): void {
  const listeners = nodeListeners.get(node)
  if (!listeners) return
  for (const listener of listeners.values()) callbacks.delete(listener.id)
  listeners.clear()
}

export function eventNameFromProp(key: string): string {
  if (key.startsWith('on:')) return key.slice(3)
  return key.slice(2).replace(/^[A-Z]/, value => value.toLowerCase())
}
