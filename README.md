# native-vue-macos

用 Vue 3 编写真正的 macOS AppKit 界面。运行时使用 JavaScriptCore，不包含 DOM、WKWebView、Chromium 或 Electron。

```vue
<script setup lang="ts">
import { ref } from 'vue'
const count = ref(0)
</script>

<template>
  <mac-window title="Hello AppKit" :width="480" :height="320">
    <mac-v-stack :style="{ padding: 24, spacing: 12 }">
      <mac-text :text="`Count: ${count}`" />
      <mac-button title="Increment" @click="count++" />
    </mac-v-stack>
  </mac-window>
</template>
```

## 要求

- Apple Silicon Mac，macOS 13+
- Node.js 20+、npm 10+
- Swift 6 / Xcode 26

## 运行

```bash
npm install
npm run dev
```

`npm run dev` 会编译开发版 Vue runtime，启动仅监听 `127.0.0.1` 的带令牌 HMR 服务，再启动 AppKit Host。模板更新保留组件状态；脚本更新使用 Vue 标准 reload 语义，不重启进程或窗口。

```bash
npm test
npm run typecheck
npm run build
npm run package
open dist/NativeVueShowcase.app
```

最终 `.app` 位于 `dist/NativeVueShowcase.app`，使用 ad-hoc 签名，适合本地验证；对外分发仍需 Developer ID 签名和 notarization。

## 支持的原生元素

- 当前内置 48 个标签，覆盖 macOS 13 基线中可独立表示为 `NSView`/`NSControl` 的公开、非废弃 AppKit 可视控件。
- 布局与材质：Window、View、Stack、Scroll、Box、Split、Tab、Grid、Visual Effect、Clip、Scroller、Ruler 等。
- 输入与选择：Button、Radio、Switch、TextField、TextView、Search、Token、ComboBox、PopUp、Segmented、Slider、Stepper、Date、Color、Path 等。
- 数据视图：Table、Outline、Collection、Browser、RuleEditor、Scrubber 以及公开的 Table 子视图。
- `v-model` 覆盖文本、布尔、数值、索引、日期、颜色和路径值控件。
- 事件：`click`、`mouseenter`、`mouseleave`、`input`、`change`、`submit`、`focus`、`blur`
- 原生样式：StyleSheet、样式数组、class/id/标签选择器、scoped 样式、交互状态，以及尺寸、盒模型、Flex 风格布局、定位、字体、边框、阴影和变换

颜色接受 `#RRGGBB`、`#RRGGBBAA`，以及 `label`、`secondaryLabel`、`accent`、`windowBackground`、`controlBackground`、`separator` 等系统语义色。

SFC 支持 `<style native scoped>`。没有 `native` 标记的浏览器 CSS、复杂 DOM 选择器，以及 Grid、float、生成内容等无法映射到 AppKit 的属性会在编译期报告包含文件路径的错误。

## 仓库结构

- `packages/runtime`：Vue custom renderer、节点/事件/model 协议及 HMR 组件注册
- `packages/compiler`：SFC 编译、原生 `v-model` transform、bundle 与 HMR 服务
- `native`：Swift Package，包含 JavaScriptCore Host 和 AppKit bridge
- `examples/showcase`：覆盖全部首批控件的示例应用

完整标签到 AppKit 类型的映射及边界参见 [docs/elements.md](docs/elements.md)。详细设计参见 [docs/architecture.md](docs/architecture.md)，样式系统参见 [docs/styling.md](docs/styling.md)，自定义原生控件参见 [docs/custom-elements.md](docs/custom-elements.md)。
