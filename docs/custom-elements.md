# 注册自定义 AppKit 控件

自定义 Host 可以在启动 JavaScriptCore 前注册 Swift 工厂：

```swift
import AppKit
import NativeVueMacOS

@MainActor
func makeRuntime() -> NativeRuntime {
    let registry = NativeElementFactoryRegistry(registerDefaults: true)
    registry.register("mac-level") {
        let level = NSLevelIndicator()
        level.levelIndicatorStyle = .continuousCapacity
        return level
    }
    return NativeRuntime(registry: registry)
}
```

Vue runtime 侧还需要在创建应用之前声明标签：

```ts
import { registerElement } from '@native-vue-macos/runtime'

registerElement('mac-level')
```

工厂扩展点负责创建 AppKit `NSView`。如果控件需要新的属性或事件，应在 Swift bridge 中增加显式、类型化映射；框架不会通过 Objective-C 反射把任意 AppKit API 暴露给 JavaScript。
