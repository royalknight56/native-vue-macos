import { cp, mkdir, readFile } from 'node:fs/promises'
import path from 'node:path'
import { build, type InlineConfig } from 'vite'
import { nativeVueMacOS } from './plugin'

export interface BuildOptions {
  root: string
  entry?: string
  outDir: string
  development?: boolean
  hmrSalt?: string
}

function vueDefines(development: boolean): Record<string, string> {
  return {
    'process.env.NODE_ENV': JSON.stringify(development ? 'development' : 'production'),
    __VUE_OPTIONS_API__: 'true',
    __VUE_PROD_DEVTOOLS__: 'false',
    __VUE_PROD_HYDRATION_MISMATCH_DETAILS__: 'false'
  }
}

export async function buildRuntime(repoRoot: string, outDir: string, development: boolean): Promise<string> {
  await mkdir(outDir, { recursive: true })
  const entry = path.join(repoRoot, 'packages/runtime/src/index.ts')
  await build({
    configFile: false,
    logLevel: 'warn',
    define: vueDefines(development),
    build: {
      outDir,
      emptyOutDir: false,
      sourcemap: development,
      minify: development ? false : 'esbuild',
      lib: {
        entry,
        formats: ['iife'],
        name: 'NativeVueMacOS',
        fileName: () => 'runtime.js'
      }
    }
  })
  return path.join(outDir, 'runtime.js')
}

export async function buildApplication(options: BuildOptions): Promise<string> {
  const entry = options.entry ?? path.join(options.root, 'src/main.ts')
  await mkdir(options.outDir, { recursive: true })
  const config: InlineConfig = {
    root: options.root,
    configFile: false,
    logLevel: 'warn',
    plugins: nativeVueMacOS(options.root, options.hmrSalt),
    define: vueDefines(Boolean(options.development)),
    build: {
      outDir: options.outDir,
      emptyOutDir: false,
      sourcemap: Boolean(options.development),
      minify: options.development ? false : 'esbuild',
      lib: {
        entry,
        formats: ['iife'],
        name: 'NativeVueApplication',
        fileName: () => 'app.js'
      },
      rollupOptions: {
        external: ['vue', '@native-vue-macos/runtime'],
        output: {
          globals: {
            vue: 'NativeVueMacOS',
            '@native-vue-macos/runtime': 'NativeVueMacOS'
          },
          inlineDynamicImports: true
        }
      }
    }
  }
  await build(config)
  await cp(path.join(options.root, 'assets'), path.join(options.outDir, 'assets'), {
    recursive: true,
    force: true
  }).catch((error: NodeJS.ErrnoException) => {
    if (error.code !== 'ENOENT') throw error
  })
  return path.join(options.outDir, 'app.js')
}

export async function readBundle(file: string): Promise<string> {
  return readFile(file, 'utf8')
}
