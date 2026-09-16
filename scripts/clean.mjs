import { rm } from 'node:fs/promises'

for (const path of ['.native-vue', 'dist', 'native/.build', 'examples/showcase/dist']) {
  await rm(new URL(`../${path}`, import.meta.url), { recursive: true, force: true })
}
