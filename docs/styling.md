# Native styling

`native-vue-macos` implements a React Native/NativeScript-style system. It accepts familiar CSS names, but resolves them into AppKit properties and Auto Layout constraints rather than creating a DOM or running a browser CSS engine.

## Inline, arrays, and StyleSheet

```vue
<script setup lang="ts">
import { StyleSheet } from '@native-vue-macos/runtime'

const styles = StyleSheet.create({
  card: {
    padding: 16,
    gap: 12,
    backgroundColor: '#202020',
    borderRadius: 12,
    boxShadow: {
      offset: { x: 0, y: 6 },
      blur: 18,
      color: '#00000055'
    }
  }
})
</script>

<template>
  <mac-v-stack :style="[styles.card, selected && { borderColor: '#42B883' }]" />
</template>
```

Later entries override earlier entries. Falsy array entries are ignored. Unknown properties throw during compilation when statically visible and during rendering for dynamic style objects.

## Native stylesheets

```vue
<template>
  <mac-button id="save" class="primary" title="Save" />
</template>

<style native scoped>
mac-button.primary {
  padding: 8px 16px;
  color: white;
  background-color: #42b883;
  border-radius: 8px;
}

#save:hover {
  opacity: 0.82;
  transform: translateY(-1px) scale(1.02);
}

#save:active {
  transform: scale(0.98);
}
</style>
```

Supported selectors are `mac-*` element names, `.class`, `#id`, combinations of those, comma-separated selectors, and `:hover`, `:active`, `:focus`, and `:disabled`. Scoped rules are restricted by the component scope ID. A `<style>` block without `native` is rejected.

Complex DOM selectors, combinators, pseudo-elements, at-rules, cascade-specific browser behavior, and browser-only properties produce compiler errors with the SFC filename and source line.

## Supported properties

| Area | Properties |
| --- | --- |
| Size | `width`, `height`, `minWidth`, `minHeight`, `maxWidth`, `maxHeight`, `aspectRatio` |
| Margin | `margin`, `marginTop`, `marginRight`, `marginBottom`, `marginLeft`, `marginHorizontal`, `marginVertical` |
| Padding | `padding`, `paddingTop`, `paddingRight`, `paddingBottom`, `paddingLeft`, `paddingHorizontal`, `paddingVertical` |
| Stack/Flex | `display`, `flexDirection`, `flexGrow`, `flexShrink`, `flexBasis`, `flexWrap`, `justifyContent`, `alignItems`, `alignSelf`, `gap`, `rowGap`, `columnGap` |
| Position | `position`, `top`, `right`, `bottom`, `left`, `zIndex` |
| Visibility | `opacity`, `hidden`, `visibility`, `overflow` |
| Surface | `backgroundColor`, `borderColor`, `borderWidth`, `borderRadius`, per-edge border colors/widths, per-corner radii |
| Shadow | `boxShadow`, `shadowColor`, `shadowOpacity`, `shadowRadius`, `shadowOffset`, `elevation` |
| Typography | `color`, `fontSize`, `fontWeight`, `fontFamily`, `fontStyle`, `lineHeight`, `letterSpacing`, `textAlign`, `textDecorationLine`, `textDecorationColor`, `textTransform` |
| Image/control | `objectFit`, `resizeMode`, `tintColor`, `cursor` |
| Transform | `transform`, `transformOrigin` |
| State objects | `hoverStyle`, `pressedStyle`, `focusStyle`, `disabledStyle` |
| Native extension | `gradientStartColor`, `gradientEndColor` on `mac-gradient-text` |

Both camelCase inline names and kebab-case stylesheet names are accepted. Numeric stylesheet values accept unitless values, `px`, and `pt`; AppKit interprets them as logical points.

## AppKit semantics

- Horizontal and vertical flex layouts are backed by `NSStackView`.
- Sizes, aspect ratio, absolute edges, and alignment are Auto Layout constraints.
- `flexGrow` and `flexShrink` map to content-hugging and compression-resistance priorities.
- Padding maps to `NSStackView.edgeInsets`; margin maps to arranged-subview custom spacing.
- Surface, clipping, borders, shadows, z-order, opacity, and transforms map to `CALayer`.
- Typography maps to `NSFont`, `NSAttributedString`, and `NSMutableParagraphStyle`.
- Hover, pressed, focus, and disabled styles are applied by native control state tracking.

`flexWrap: wrap`, reverse stack directions, CSS Grid, floats, generated content, filters, multi-column layout, table layout, pagination, and selector combinators do not have direct AppKit equivalents and are rejected. Use nested stacks, Vue conditional rendering, and native components for those layouts.
