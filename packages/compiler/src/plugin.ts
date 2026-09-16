import { createHash } from 'node:crypto'
import path from 'node:path'
import vue from '@vitejs/plugin-vue'
import { transformModel } from '@vue/compiler-core'
import type { Plugin, PluginOption } from 'vite'
import { parse } from 'vue/compiler-sfc'

interface DescriptorHashes {
  id: string
  script: string
  template: string
}

const digest = (value: string) => createHash('sha256').update(value).digest('hex').slice(0, 12)

export function instrumentVueModule(code: string, hashes: DescriptorHashes): string {
  const marker = 'export default '
  const start = code.lastIndexOf(marker)
  if (start < 0) throw new Error('Unable to find the Vue component default export for HMR instrumentation')

  const before = code.slice(0, start)
  let expression = code.slice(start + marker.length).trim()
  if (expression.endsWith(';')) expression = expression.slice(0, -1)

  return `${before}const __nvm_component = ${expression};\n` +
    `const __nvm_registered = globalThis.__NVM_HMR__\n` +
    `  ? globalThis.__NVM_HMR__.register(${JSON.stringify(hashes.id)}, __nvm_component, ${JSON.stringify(hashes.script)}, ${JSON.stringify(hashes.template)})\n` +
    `  : __nvm_component;\n` +
    `export default __nvm_registered;\n`
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
      if (descriptor.styles.length) {
        this.error(`${path.relative(root, id)}: <style> blocks are not supported; use a :style object with native properties`)
      }
      const stablePath = path.relative(root, id).split(path.sep).join('/')
      descriptors.set(id, {
        id: `nvm-${digest(stablePath)}`,
        script: digest(`${descriptor.script?.content ?? ''}\n${descriptor.scriptSetup?.content ?? ''}\n${hmrSalt}`),
        template: digest(descriptor.template?.content ?? '')
      })
      return null
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
