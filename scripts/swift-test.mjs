import { execFileSync } from 'node:child_process'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const cache = path.join(root, '.native-vue', 'test-module-cache')
execFileSync('swift', [
  'test', '--disable-sandbox', '--package-path', path.join(root, 'native'),
  '--scratch-path', path.join(root, '.native-vue', 'swift-tests')
], {
  cwd: root,
  stdio: 'inherit',
  env: {
    ...process.env,
    CLANG_MODULE_CACHE_PATH: cache,
    SWIFTPM_MODULECACHE_OVERRIDE: cache
  }
})
