import { describe, expect, it } from 'vitest'
import { compileNativeStyleSheet } from '../src/index'

describe('native style schema', () => {
  it('compiles AppKit-compatible selectors, states, values, and shorthands', () => {
    const sheet = compileNativeStyleSheet(`
      mac-button.primary:hover {
        padding: 8px 16px;
        background-color: rgba(66, 184, 131, .8);
        border-color: #fff;
        border-radius: 8px;
        transform: translateX(2px) scale(1.05);
      }
    `, { id: 'test', file: 'Button.vue', scoped: true })

    expect(sheet.rules[0].selector).toMatchObject({ type: 'mac-button', classes: ['primary'], state: 'hover' })
    expect(sheet.rules[0].declarations.padding).toEqual({ top: 8, right: 16, bottom: 8, left: 16 })
    expect(sheet.rules[0].declarations.backgroundColor).toBe('#42B883CC')
    expect(sheet.rules[0].declarations.borderColor).toBe('#FFFFFF')
    expect(sheet.rules[0].declarations.borderRadius).toBe(8)
    expect(sheet.rules[0].declarations.transform).toEqual([{ translateX: '2px' }, { scale: 1.05 }])
  })

  it('rejects browser-only properties and complex DOM selectors', () => {
    expect(() => compileNativeStyleSheet('.card { display: grid; grid-template-columns: 1fr 1fr; }', {
      id: 'test', file: 'Grid.vue', scoped: true
    })).toThrow('Unsupported value "grid"')
    expect(() => compileNativeStyleSheet('.parent > .child { color: red; }', {
      id: 'test', file: 'Selector.vue', scoped: true
    })).toThrow('Unsupported native selector')
    expect(() => compileNativeStyleSheet('.card { transform-origin: 20% 30%; }', {
      id: 'test', file: 'Transform.vue', scoped: true
    })).toThrow('does not support relative CSS units')
    expect(() => compileNativeStyleSheet('.card { width: calc(100% - 20px); }', {
      id: 'test', file: 'Calc.vue', scoped: true
    })).toThrow('requires a numeric point value')
  })
})
