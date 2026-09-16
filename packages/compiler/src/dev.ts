import { randomBytes } from 'node:crypto'
import { spawn } from 'node:child_process'
import path from 'node:path'
import process from 'node:process'
import chokidar from 'chokidar'
import { WebSocketServer, type WebSocket } from 'ws'
import { buildApplication, buildRuntime, readBundle } from './build'

export interface DevOptions {
  repoRoot: string
  appRoot: string
}

export async function runDevelopmentServer(options: DevOptions): Promise<void> {
  const output = path.join(options.appRoot, '.native-vue')
  const runtimeFile = await buildRuntime(options.repoRoot, output, true)
  const appFile = await buildApplication({ root: options.appRoot, outDir: output, development: true })
  const token = randomBytes(24).toString('hex')
  const clients = new Set<WebSocket>()
  const server = new WebSocketServer({
    host: '127.0.0.1',
    port: 0,
    verifyClient: (info: { req: { url?: string } }) => new URL(info.req.url ?? '/', 'ws://127.0.0.1').searchParams.get('token') === token
  })

  await new Promise<void>((resolve, reject) => {
    server.once('listening', resolve)
    server.once('error', reject)
  })
  server.on('connection', socket => {
    clients.add(socket)
    socket.once('close', () => clients.delete(socket))
  })

  const address = server.address()
  if (!address || typeof address === 'string') throw new Error('Unable to determine HMR server port')
  const hmrURL = `ws://127.0.0.1:${address.port}/hmr?token=${token}`
  const host = spawn(
    'swift',
    [
      'run', '--package-path', path.join(options.repoRoot, 'native'), 'NativeVueHost',
      '--runtime', runtimeFile,
      '--bundle', appFile,
      '--hmr-url', hmrURL
    ],
    { cwd: options.appRoot, stdio: 'inherit' }
  )

  let building = false
  let pending = false
  let pendingPath: string | undefined
  let dependencyRevision = 0
  const rebuild = async (changedPath?: string) => {
    if (building) {
      pending = true
      pendingPath = changedPath ?? pendingPath
      return
    }
    building = true
    try {
      const isSFC = changedPath?.endsWith('.vue') ?? true
      if (!isSFC) dependencyRevision += 1
      await buildApplication({
        root: options.appRoot,
        outDir: output,
        development: true,
        hmrSalt: dependencyRevision ? `dependency-${dependencyRevision}` : undefined
      })
      const code = await readBundle(appFile)
      const message = JSON.stringify({ type: 'update', code })
      for (const client of clients) if (client.readyState === client.OPEN) client.send(message)
      process.stdout.write('[native-vue-macos] hot update applied\n')
    } catch (error) {
      const message = error instanceof Error ? error.stack ?? error.message : String(error)
      for (const client of clients) if (client.readyState === client.OPEN) {
        client.send(JSON.stringify({ type: 'error', message }))
      }
      process.stderr.write(`${message}\n`)
    } finally {
      building = false
      if (pending) {
        pending = false
        const nextPath = pendingPath
        pendingPath = undefined
        void rebuild(nextPath)
      }
    }
  }

  const watcher = chokidar.watch(path.join(options.appRoot, 'src'), { ignoreInitial: true })
  watcher.on('add', path => void rebuild(path))
    .on('change', path => void rebuild(path))
    .on('unlink', path => void rebuild(path))

  const shutdown = async () => {
    await watcher.close()
    server.close()
    if (!host.killed) host.kill('SIGTERM')
  }
  process.once('SIGINT', () => void shutdown().finally(() => process.exit(0)))
  process.once('SIGTERM', () => void shutdown().finally(() => process.exit(0)))
  host.once('exit', code => void shutdown().finally(() => process.exit(code ?? 0)))
}
