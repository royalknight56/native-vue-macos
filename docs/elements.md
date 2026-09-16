# AppKit 原生元素目录

`native-vue-macos` 的内置元素以 macOS 13 为最低版本。每个标签都由 Swift 显式创建具体 AppKit 类型，不使用 Objective-C 反射，也不会把未知属性静默写入原生对象。

## 应用与布局

| Vue 标签 | AppKit 类型 | 说明 |
| --- | --- | --- |
| `mac-window` | `NSWindow` | 主窗口；内容挂载到 `contentView` |
| `mac-view` / `mac-z-stack` | `NSView` | 通用容器 / 层叠容器 |
| `mac-v-stack` / `mac-h-stack` | `NSStackView` | 纵向 / 横向原生布局 |
| `mac-scroll-view` | `NSScrollView` | 自动创建 document view |
| `mac-spacer` | `NSView` | 低 hugging priority 的弹性空白 |
| `mac-box` | `NSBox` | 分组框 |
| `mac-divider` | `NSBox` | separator 样式 |
| `mac-clip-view` | `NSClipView` | 裁剪容器 |
| `mac-split-view` | `NSSplitView` | 分栏容器 |
| `mac-tab-view` | `NSTabView` | 原生标签页容器 |
| `mac-grid-view` | `NSGridView` | AppKit 网格布局，不等同于 CSS Grid |
| `mac-visual-effect-view` | `NSVisualEffectView` | 原生材质与模糊背景 |
| `mac-scroller` | `NSScroller` | 独立滚动条 |
| `mac-ruler-view` | `NSRulerView` | 标尺视图 |

## 内容、输入与选择

| Vue 标签 | AppKit 类型 | `v-model` / 主要值 |
| --- | --- | --- |
| `mac-text` | `NSTextField` label | `text` |
| `mac-gradient-text` | `NSTextField` 子类 | `text` |
| `mac-button` | `NSButton` | `title`, `click` |
| `mac-combo-button` | `NSComboButton` | `title`, `click` |
| `mac-toggle` | `NSButton` checkbox | `checked`, `change` |
| `mac-radio` | `NSButton` radio | `checked`, `change` |
| `mac-switch` | `NSSwitch` | `checked`, `change` |
| `mac-text-field` | `NSTextField` | `value`, `input` |
| `mac-secure-field` | `NSSecureTextField` | `value`, `input` |
| `mac-text-view` | `NSTextView` | `value`, `input` |
| `mac-search-field` | `NSSearchField` | `value`, `input` |
| `mac-token-field` | `NSTokenField` | `value`, `input` |
| `mac-combo-box` | `NSComboBox` | `value`, `items`, `input` |
| `mac-pop-up-button` | `NSPopUpButton` | `selectedIndex`, `items`, `change` |
| `mac-segmented-control` | `NSSegmentedControl` | `selectedIndex`, `labels`, `change` |
| `mac-slider` | `NSSlider` | `value`, `min`, `max`, `change` |
| `mac-stepper` | `NSStepper` | `value`, `min`, `max`, `increment`, `change` |
| `mac-progress` | `NSProgressIndicator` | `value`, `min`, `max` |
| `mac-level-indicator` | `NSLevelIndicator` | `value`, `min`, `max`, `change` |
| `mac-date-picker` | `NSDatePicker` | ISO-8601 `value`, `change` |
| `mac-color-well` | `NSColorWell` | 颜色 `value`, `change` |
| `mac-path-control` | `NSPathControl` | 本地路径 `value`, `change` |
| `mac-image` | `NSImageView` | 应用资源或本地文件 `src` |

## 数据视图

| Vue 标签 | AppKit 类型 |
| --- | --- |
| `mac-table-view` | `NSTableView` |
| `mac-outline-view` | `NSOutlineView` |
| `mac-collection-view` | `NSCollectionView` + `NSCollectionViewFlowLayout` |
| `mac-browser` | `NSBrowser` |
| `mac-rule-editor` | `NSRuleEditor` |
| `mac-scrubber` | `NSScrubber` |
| `mac-table-row-view` | `NSTableRowView` |
| `mac-table-cell-view` | `NSTableCellView` |
| `mac-table-header-view` | `NSTableHeaderView` |

这些标签创建真实控件并接受通用样式。Table、Outline、Collection、Browser、RuleEditor 和 Scrubber 的数据源/代理仍是下一层声明式 API；AppKit 的 data source、delegate、column、item、layout 和 view controller 不是视图，不能冒充 Vue 元素。

## 明确不作为内置元素的 AppKit 类型

- `NSControl`、`NSText` 等抽象基类。
- `NSCell`、`NSTableColumn`、`NSTabViewItem`、`NSMenu`、`NSToolbar`、delegate、data source 和 view controller 等非 `NSView` 对象。
- `NSOpenGLView`、`NSMatrix`、`NSForm` 等 Apple 已废弃的界面 API。
- `NSStatusBarButton` 等必须由系统所有者创建的视图。
- `NSBackgroundExtensionView`（macOS 14+）以及 Liquid Glass 视图（macOS 26+）；项目最低版本提升后再以可用性守卫加入。
- `WKWebView` 不属于 AppKit，且违反本项目无 WebView 的架构约束。

公开清单在 TypeScript 的 `builtInNativeElements` 与 Swift 的 `NativeElementFactoryRegistry` 中分别显式维护，并由两侧测试验证。新增元素必须同时补齐工厂、属性/事件契约、文档和测试。
