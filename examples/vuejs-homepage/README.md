# Vue.js Homepage — Native AppKit Demo

这是一个使用 `native-vue-macos` 渲染的 Vue 官网首页复刻。Vue Composition API 和 SFC 在 JavaScriptCore 中运行，界面由 `NSWindow`、`NSStackView`、`NSTextField`、`NSButton`、`NSImageView` 等 AppKit 对象构成。

它没有 DOM、Chromium、Electron 或 WebView。页面中的导航展开、搜索框、主题切换、Why Vue 展开和 CTA 状态反馈均可交互。

```bash
npm run demo:vue:dev
npm run demo:vue:build
npm run demo:vue:package
```

打包结果位于 `dist/VueWebsiteDemo.app`。

## 素材来源

视觉与文案参考 [vuejs.org](https://vuejs.org/)。Vue 标识与赞助商图片由官网页面素材清单导出并保存到 `assets/`，没有运行时热链。Vue 及各赞助商商标归其各自权利人所有，本项目只用于本地技术演示。
