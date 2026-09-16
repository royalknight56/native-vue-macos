import { defineComponent, h, type Component } from 'vue'
import './hmr'

export { createNativeApp as createApp, disposeApplication, nativeRenderer } from './renderer'
export { registerElement, isKnownElement } from './registry'
export { installBridgeForTesting, type NativeBridge, type NativeValue } from './bridge'
export { NativeNode } from './node'
export * from 'vue'

export function defineNativeComponent(tag: string): Component {
  return defineComponent({
    name: `Native(${tag})`,
    inheritAttrs: false,
    setup(_, { attrs, slots }) {
      return () => h(tag, attrs, slots.default?.())
    }
  })
}
