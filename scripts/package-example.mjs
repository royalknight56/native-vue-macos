import { chmod, cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises'
import { execFileSync } from 'node:child_process'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const [exampleName, appName, bundleIdentifier] = process.argv.slice(2)
if (!exampleName || !appName || !bundleIdentifier) {
  throw new Error('Usage: package-example.mjs <example> <app-name> <bundle-identifier>')
}

const scratch = path.join(root, '.native-vue', 'swift-release')
const app = path.join(root, 'dist', `${appName}.app`)
const contents = path.join(app, 'Contents')
const macOS = path.join(contents, 'MacOS')
const resources = path.join(contents, 'Resources')
const moduleCache = path.join(root, '.native-vue', 'module-cache')
const exampleRoot = path.join(root, 'examples', exampleName)

execFileSync('swift', [
  'build', '--disable-sandbox', '--package-path', path.join(root, 'native'),
  '--scratch-path', scratch, '-c', 'release', '--arch', 'arm64'
], {
  cwd: root,
  stdio: 'inherit',
  env: {
    ...process.env,
    CLANG_MODULE_CACHE_PATH: moduleCache,
    SWIFTPM_MODULECACHE_OVERRIDE: moduleCache
  }
})

await rm(app, { recursive: true, force: true })
await mkdir(macOS, { recursive: true })
await mkdir(resources, { recursive: true })
const template = await readFile(path.join(root, 'scripts', 'Info.plist'), 'utf8')
const plist = template
  .replace('dev.native-vue-macos.showcase', bundleIdentifier)
  .replace('Native Vue Showcase', appName)
await writeFile(path.join(contents, 'Info.plist'), plist)
await cp(path.join(scratch, 'arm64-apple-macosx', 'release', 'NativeVueHost'), path.join(macOS, 'NativeVueHost'))
await chmod(path.join(macOS, 'NativeVueHost'), 0o755)
await cp(path.join(exampleRoot, 'dist', 'runtime.js'), path.join(resources, 'runtime.js'))
await cp(path.join(exampleRoot, 'dist', 'app.js'), path.join(resources, 'app.js'))
await cp(path.join(exampleRoot, 'dist', 'assets'), path.join(resources, 'assets'), { recursive: true })

execFileSync('codesign', ['--force', '--sign', '-', app], { stdio: 'inherit' })
process.stdout.write(`[native-vue-macos] packaged ${path.relative(root, app)}\n`)
