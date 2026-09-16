import { describe, expect, it } from 'vitest'
import { flattenNativeStyle, registerNativeStyleSheet, resolveNativeStyle, StyleSheet, unregisterNativeStyleSheet } from '../src/style'
import type { NativeNode } from '../src/node'

describe('native runtime styles', () => {
  it('flattens conditional arrays using React Native precedence', () => {
    const styles = StyleSheet.create({ base: { color: 'label', padding: 8 }, active: { color: '#42B883' } })
    expect(flattenNativeStyle([styles.base, false, null, styles.active])).toEqual({ color: '#42B883', padding: 8 })
  })

  it('resolves tag, class, id, scoped, state, and inline styles', () => {
    registerNativeStyleSheet({
      id: 'component',
      scoped: true,
      rules: [
        { selector: { raw: 'mac-button', type: 'mac-button', classes: [] }, declarations: { color: 'label' } },
        { selector: { raw: '.primary', classes: ['primary'] }, declarations: { backgroundColor: '#42B883' } },
        { selector: { raw: '#save:hover', id: 'save', classes: [], state: 'hover' }, declarations: { opacity: 0.8 } }
      ]
    })
    const node = {
      type: 'mac-button', nativeId: 'save', classNames: ['primary'],
      scopeIds: new Set(['data-nvm-component']), inlineStyle: { color: 'white' }
    } as unknown as NativeNode
    expect(resolveNativeStyle(node)).toEqual({
      color: 'white', backgroundColor: '#42B883', hoverStyle: { opacity: 0.8 }
    })
    unregisterNativeStyleSheet('component')
  })

  it('uses CSS specificity before source order and inherits native text styles', () => {
    registerNativeStyleSheet({
      id: 'specificity',
      scoped: false,
      rules: [
        { selector: { raw: '#title', id: 'title', classes: [] }, declarations: { color: 'accent' } },
        { selector: { raw: '.title', classes: ['title'] }, declarations: { color: 'red', fontSize: 18 } }
      ]
    })
    const parent = { appliedStyle: { fontFamily: 'Helvetica Neue', letterSpacing: 1 } } as unknown as NativeNode
    const node = {
      type: 'mac-text', nativeId: 'title', classNames: ['title'], parent,
      scopeIds: new Set(), inlineStyle: {}
    } as unknown as NativeNode
    expect(resolveNativeStyle(node)).toMatchObject({
      color: 'accent', fontSize: 18, fontFamily: 'Helvetica Neue', letterSpacing: 1
    })
    unregisterNativeStyleSheet('specificity')
  })
})
