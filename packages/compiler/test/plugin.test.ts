import { describe, expect, it } from 'vitest'
import { instrumentVueModule } from '../src/plugin'

describe('instrumentVueModule', () => {
  it('routes the default component export through the stable HMR registry', () => {
    const output = instrumentVueModule('const component = {};\nexport default component;', {
      id: 'nvm-test',
      script: 'script-hash',
      template: 'template-hash'
    })
    expect(output).toContain("globalThis.__NVM_HMR__.register(\"nvm-test\"")
    expect(output).toContain('export default __nvm_registered')
    expect(output).not.toContain('export default component;')
  })
})
