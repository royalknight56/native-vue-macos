export type NativeValue = string | number | boolean | null | NativeValue[] | { [key: string]: NativeValue }

export interface NativeBridge {
  createApplicationRoot(): number
  createNode(type: string): number
  insertNode(childId: number, parentId: number, index: number): boolean
  removeNode(nodeId: number): boolean
  setText(nodeId: number, value: string): boolean
  setProp(nodeId: number, name: string, value: NativeValue): boolean
  setStyle(nodeId: number, name: string, value: NativeValue): boolean
  addEventListener(nodeId: number, event: string, callbackId: number): boolean
  removeEventListener(nodeId: number, event: string, callbackId: number): boolean
  showWindow(nodeId: number): boolean
  dispose(): void
  takeLastError(): string | null
  reportError(message: string, stack: string): void
}

declare global {
  // Injected by NativeVueHost before the runtime bundle is evaluated.
  var __nativeBridge: NativeBridge | undefined
  var __nativeDispatch: ((callbackId: number, payload: unknown) => void) | undefined
}

let installedBridge: NativeBridge | undefined

export function installBridgeForTesting(bridge?: NativeBridge): void {
  installedBridge = bridge
}

export function bridge(): NativeBridge {
  const value = installedBridge ?? globalThis.__nativeBridge
  if (!value) {
    throw new Error('Native bridge is unavailable. Run this bundle with NativeVueHost.')
  }
  return value
}

export function checked(ok: boolean, operation: string): void {
  if (ok) return
  const detail = bridge().takeLastError()
  throw new Error(`${operation} failed${detail ? `: ${detail}` : ''}`)
}
