import { bridge, checked } from './bridge'

export class NativeNode {
  readonly id: number
  readonly type: string
  parent: NativeNode | null = null
  readonly children: NativeNode[] = []

  constructor(type: string, id = bridge().createNode(type)) {
    if (id < 0) {
      const detail = bridge().takeLastError()
      throw new Error(`createNode(${type}) failed${detail ? `: ${detail}` : ''}`)
    }
    this.type = type
    this.id = id
  }

  insert(child: NativeNode, anchor: NativeNode | null): void {
    if (child === this) throw new Error('A native node cannot contain itself')
    if (child.parent) child.parent.detach(child, false)
    const anchorIndex = anchor ? this.children.indexOf(anchor) : -1
    if (anchor && anchorIndex < 0) throw new Error('Insert anchor is not a child of the target parent')
    const index = anchorIndex < 0 ? this.children.length : anchorIndex
    checked(bridge().insertNode(child.id, this.id, index), `insertNode(${child.type}, ${this.type})`)
    this.children.splice(index, 0, child)
    child.parent = this
  }

  detach(child: NativeNode, removeNative = true): void {
    const index = this.children.indexOf(child)
    if (index < 0) return
    if (removeNative) checked(bridge().removeNode(child.id), `removeNode(${child.type})`)
    this.children.splice(index, 1)
    child.parent = null
  }
}

export function createRootNode(): NativeNode {
  const id = bridge().createApplicationRoot()
  if (id < 0) throw new Error(bridge().takeLastError() ?? 'Unable to create application root')
  return new NativeNode('#root', id)
}
