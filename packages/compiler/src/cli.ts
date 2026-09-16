#!/usr/bin/env node
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'
import { buildApplication, buildRuntime } from './build'
import { runDevelopmentServer } from './dev'

const command = process.argv[2] ?? 'build'
const appRoot = process.cwd()
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../..')

if (command === 'dev') {
  await runDevelopmentServer({ repoRoot, appRoot })
} else if (command === 'build') {
  const outDir = path.join(appRoot, 'dist')
  await buildRuntime(repoRoot, outDir, false)
  await buildApplication({ root: appRoot, outDir, development: false })
  process.stdout.write(`[native-vue-macos] built ${path.relative(repoRoot, outDir)}\n`)
} else {
  process.stderr.write(`Unknown command: ${command}\n`)
  process.exitCode = 1
}
