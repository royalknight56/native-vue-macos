import { createHash } from 'node:crypto'
import path from 'node:path'
import vue from '@vitejs/plugin-vue'
import { transformModel } from '@vue/compiler-core'
import type { Plugin, PluginOption } from 'vite'
import { parse } from 'vue/compiler-sfc'
import {
  assertNativeStyleProperty,
  assertNativeStyleValue,
  compileNativeStyleSheet,
  type CompiledNativeStyleSheet,
  type NativeStyleRule
} from '@native-vue-macos/style-schema'

interface DescriptorHashes {
  id: string
  script: string
  template: string
  styles?: CompiledNativeStyleSheet[]
}

const digest = (value: string) => createHash('sha256').update(value).digest('hex').slice(0, 12)

export function instrumentVueModule(code: string, hashes: DescriptorHashes): string {
  const marker = 'export default '
  const start = code.lastIndexOf(marker)
  if (start < 0) throw new Error('Unable to find the Vue component default export for HMR instrumentation')

  const before = code.slice(0, start)
  let expression = code.slice(start + marker.length).trim()
  if (expression.endsWith(';')) expression = expression.slice(0, -1)

  const hasStyles = Boolean(hashes.styles?.length)
  const styleSetup = `import { ${hasStyles ? 'registerNativeStyleSheet as __nvm_register_styles, ' : ''}unregisterNativeStyleSheet as __nvm_unregister_styles } from '@native-vue-macos/runtime';\n` +
    `__nvm_unregister_styles(${JSON.stringify(`${hashes.id}-global`)});\n` +
    `__nvm_unregister_styles(${JSON.stringify(hashes.id)});\n` +
    (hashes.styles?.map(sheet => `__nvm_register_styles(${JSON.stringify(sheet)});`).join('\n') ?? '') + '\n'
  const scopeSetup = hashes.styles?.some(sheet => sheet.scoped)
    ? `__nvm_component.__scopeId = ${JSON.stringify(`data-nvm-${hashes.id}`)};\n`
    : ''

  return `${styleSetup}${before}const __nvm_component = ${expression};\n` +
    scopeSetup +
    `const __nvm_registered = globalThis.__NVM_HMR__\n` +
    `  ? globalThis.__NVM_HMR__.register(${JSON.stringify(hashes.id)}, __nvm_component, ${JSON.stringify(hashes.script)}, ${JSON.stringify(hashes.template)})\n` +
    `  : __nvm_component;\n` +
    `export default __nvm_registered;\n`
}

export function validateInlineStyles(template: string, file: string): void {
  for (const match of template.matchAll(/(?<!:)\bstyle\s*=\s*(["'])(.*?)\1/gs)) {
    compileNativeStyleSheet(`mac-inline { ${match[2]} }`, { id: 'inline', file, scoped: false })
  }
  for (const match of template.matchAll(/(?:v-bind:|:)style\s*=\s*(["'])\s*\{([\s\S]*?)\}\s*\1/g)) {
    const expression = match[2]
    let depth = 0
    let quote = ''
    let segmentStart = 0
    for (let index = 0; index <= expression.length; index += 1) {
      const character = expression[index] ?? ','
      if (quote) {
        if (character === quote && expression[index - 1] !== '\\') quote = ''
        continue
      }
      if (character === '"' || character === "'") { quote = character; continue }
      if (character === '{' || character === '[' || character === '(') depth += 1
      else if (character === '}' || character === ']' || character === ')') depth -= 1
      else if (character === ',' && depth === 0) {
        const segment = expression.slice(segmentStart, index).trim()
        const propertyMatch = segment.match(/^(?:['"]([^'"]+)['"]|([A-Za-z_$][\w$-]*))\s*:\s*([\s\S]+)$/)
        const key = propertyMatch?.slice(1, 3).find(Boolean)
        if (key) {
          const normalized = assertNativeStyleProperty(key, file)
          const rawValue = propertyMatch?.[3]?.trim() ?? ''
          const literal = rawValue.match(/^(['"])([\s\S]*)\1$/)?.[2]
          if (literal !== undefined) assertNativeStyleValue(normalized, literal, file)
          else if (/^-?[\d.]+$/.test(rawValue)) assertNativeStyleValue(normalized, Number(rawValue), file)
          else if (rawValue === 'true' || rawValue === 'false') assertNativeStyleValue(normalized, rawValue === 'true', file)
        }
        segmentStart = index + 1
      }
    }
  }
}

export function nativeVueMacOS(root = process.cwd(), hmrSalt = ''): PluginOption[] {
  const descriptors = new Map<string, DescriptorHashes>()

  const inspect: Plugin = {
    name: 'native-vue-macos:inspect-sfc',
    enforce: 'pre',
    transform(source, rawId) {
      const id = rawId.split('?', 1)[0]
      if (!id.endsWith('.vue') || rawId.includes('?')) return null
      const { descriptor, errors } = parse(source, { filename: id })
      if (errors.length) throw errors[0]
      const stablePath = path.relative(root, id).split(path.sep).join('/')
      const componentID = `nvm-${digest(stablePath)}`
      validateInlineStyles(descriptor.template?.content ?? '', stablePath)
      const scopedRules: NativeStyleRule[] = []
      const globalRules: NativeStyleRule[] = []
      for (const [index, style] of descriptor.styles.entries()) {
        if (!Object.prototype.hasOwnProperty.call(style.attrs, 'native')) {
          this.error(`${stablePath}: <style> requires the native attribute; browser CSS cannot be rendered by AppKit`)
        }
        const sheet = compileNativeStyleSheet(style.content, {
          id: `${componentID}-${index}`,
          file: stablePath,
          scoped: Boolean(style.scoped),
          lineOffset: Math.max(0, style.loc.start.line - 1)
        })
        ;(style.scoped ? scopedRules : globalRules).push(...sheet.rules)
      }
      const styles: CompiledNativeStyleSheet[] = []
      if (globalRules.length) styles.push({ id: `${componentID}-global`, scoped: false, rules: globalRules })
      if (scopedRules.length) styles.push({ id: componentID, scoped: true, rules: scopedRules })
      descriptors.set(id, {
        id: componentID,
        script: digest(`${descriptor.script?.content ?? ''}\n${descriptor.scriptSetup?.content ?? ''}\n${hmrSalt}`),
        template: digest(descriptor.template?.content ?? ''),
        styles
      })
      if (!descriptor.styles.length) return null
      return source.replace(/\s*<style\b[^>]*>[\s\S]*?<\/style>/gi, '')
    }
  }

  const instrument: Plugin = {
    name: 'native-vue-macos:instrument-hmr',
    enforce: 'post',
    transform(code, rawId) {
      const id = rawId.split('?', 1)[0]
      if (!id.endsWith('.vue') || rawId.includes('?vue&type=')) return null
      const hashes = descriptors.get(id)
      if (!hashes) return null
      return { code: instrumentVueModule(code, hashes), map: null }
    }
  }

  return [
    inspect,
    vue({
      template: {
        compilerOptions: {
          isCustomElement: tag => tag.startsWith('mac-'),
          directiveTransforms: {
            model: transformModel
          }
        }
      }
    }),
    instrument
  ]
}
