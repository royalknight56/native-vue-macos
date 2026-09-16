import { describe, expect, it } from 'vitest'
import { instrumentVueModule, validateInlineStyles } from '../src/plugin'
import { compileNativeStyleSheet } from '@native-vue-macos/style-schema'

describe('instrumentVueModule', () => {
  it('routes the default component export through the stable HMR registry', () => {
    const output = instrumentVueModule('const component = {};\nexport default component;', {
      id: 'nvm-test',
      script: 'script-hash',
      template: 'template-hash'
    })
    expect(output).toContain("globalThis.__NVM_HMR__.register(\"nvm-test\"")
    expect(output).toContain('__nvm_unregister_styles')
    expect(output).toContain('export default __nvm_registered')
    expect(output).not.toContain('export default component;')
  })

  it('registers compiled scoped native styles on the component', () => {
    const sheet = compileNativeStyleSheet('.title { color: #42b883; }', {
      id: 'nvm-test', file: 'App.vue', scoped: true
    })
    const output = instrumentVueModule('const component = {};\nexport default component;', {
      id: 'nvm-test', script: 'script-hash', template: 'template-hash', styles: [sheet]
    })
    expect(output).toContain('registerNativeStyleSheet')
    expect(output).toContain('__nvm_component.__scopeId = "data-nvm-nvm-test"')
  })

  it('rejects unsupported inline style properties before bundling', () => {
    expect(() => validateInlineStyles('<mac-v-stack :style="{ gridTemplateColumns: \'1fr 1fr\' }" />', 'App.vue'))
      .toThrow('browser-only semantics')
    expect(() => validateInlineStyles('<mac-v-stack :style="{ display: \'grid\' }" />', 'App.vue'))
      .toThrow('Unsupported value "grid"')
  })
})
