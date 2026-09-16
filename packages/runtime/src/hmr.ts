import type { Component } from 'vue'

interface VueHMRRuntime {
  createRecord(id: string, component: Component): boolean
  rerender(id: string, render: Function): void
  reload(id: string, component: Component): void
}

interface ComponentRecord {
  component: Component & { render?: Function }
  scriptHash: string
  templateHash: string
}

declare global {
  var __VUE_HMR_RUNTIME__: VueHMRRuntime | undefined
  var __NVM_HMR__: {
    register(id: string, component: Component, scriptHash: string, templateHash: string): Component
  } | undefined
}

const records = new Map<string, ComponentRecord>()

export const hmrManager = {
  register(id: string, component: Component & { render?: Function }, scriptHash: string, templateHash: string): Component {
    const previous = records.get(id)
    if (!previous) {
      records.set(id, { component, scriptHash, templateHash })
      globalThis.__VUE_HMR_RUNTIME__?.createRecord(id, component)
      return component
    }

    if (previous.scriptHash !== scriptHash) {
      globalThis.__VUE_HMR_RUNTIME__?.reload(id, component)
      previous.scriptHash = scriptHash
      previous.templateHash = templateHash
      return previous.component
    }
    if (previous.templateHash !== templateHash && component.render) {
      globalThis.__VUE_HMR_RUNTIME__?.rerender(id, component.render)
      previous.templateHash = templateHash
    }
    return previous.component
  }
}

globalThis.__NVM_HMR__ = hmrManager
