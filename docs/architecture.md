# 架构

应用由两个 JavaScript bundle 和一个 Swift Host 组成：

1. `runtime.js` 只加载一次，包含 Vue、custom renderer、桥接节点和 HMR registry。
2. `app.js` 包含 SFC 应用，Vue 和 runtime 被 external 到全局 `NativeVueMacOS`。
3. `NativeVueHost` 在主线程创建 `JSContext`，注入 `__nativeBridge`，依次执行两个 bundle。

Renderer 的 `createElement / insert / remove / patchProp` 使用整数句柄调用 Swift。Swift 维护句柄到 AppKit 对象的注册表；JS 不持有原生对象。原生事件只把 callback ID 和 JSON payload 发回 `__nativeDispatch`。计时器需要跨异步边界保存 JS 函数，因此使用 `JSManagedValue` 并在执行或取消后解除 managed reference。

样式由 `@native-vue-macos/style-schema` 统一定义。编译器把 `<style native scoped>` 解析成带作用域、优先级和原生状态的规则；runtime 合并继承样式、规则和内联数组，再只把差量属性通过句柄传给 Swift。Swift 将布局映射为 `NSStackView`/Auto Layout，将表面与变换映射为 `CALayer`，将文字映射为 `NSFont`/`NSAttributedString`。浏览器专属属性、复杂选择器、相对单位和无法映射的枚举值在 SFC 编译阶段直接报错。

开发服务器每次重新生成完整 `app.js`，但不会替换 runtime 或 `JSContext`。编译器给每个 `.vue` 文件生成稳定 ID，并分别计算 script/template hash：

- 首次加载向 Vue HMR runtime 注册组件。
- 只改模板时调用 `rerender`，现有组件实例和状态保留。
- 改脚本时调用 `reload`，遵守 Vue 的标准组件重载语义。
- 普通 TypeScript/资源依赖变化无法建立单一 SFC 边界时，重载组件边界，但仍保留进程、`JSContext` 和窗口。
- 编译失败时不发送新代码，当前原生界面继续运行。

HMR WebSocket 只绑定 `127.0.0.1`，每次启动生成随机令牌。发布版不启动 HMR 服务。
