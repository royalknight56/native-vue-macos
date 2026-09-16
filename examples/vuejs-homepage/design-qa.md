# Design QA — Vue.js Homepage Native Demo

## Reference

- Source: <https://vuejs.org/>
- Source capture: Codex in-app browser, 2026-09-16
- Desktop reference viewport: 1440 × 900; full page height observed at 2439 px
- Mobile reference viewport: 390 × 844; full page height observed at 3812 px
- Captured states: desktop default, desktop Docs/Ecosystem/About/Support flyouts, mobile default, mobile navigation open
- Target: `/Users/admin/Desktop/my/myproject/native-vue-macos/dist/VueWebsiteDemo.app`
- Target window: 1280 × 820, macOS native desktop layout

The browser and native screenshots were captured through the computer-use session. That API exposes image bytes for visual comparison but does not provide persistent screenshot file paths. The final focused comparison emitted the source and implementation together in one comparison result: source capture 1224 × 1308 px and native capture 1154 × 768 px. Because the native target is a fixed 1280 × 820 AppKit window while the browser capture includes the current promotional banner, QA compared the shared navigation region by relative alignment and component dimensions rather than claiming pixel-for-pixel viewport parity.

## Comparison

| Category | Result | Evidence |
| --- | --- | --- |
| Overall composition | Passed | Fixed 55 px navigation, centered two-line hero, CTA row, sponsor strip, three-column value propositions, sponsor matrix, gold tier, and multi-column footer all match the reference hierarchy. |
| Typography | Passed | Hero uses 72 pt black-weight native text versus the reference 76 px/900; supporting copy uses 22 pt; section headings use 20 pt semibold. |
| Color and treatment | Passed | Dark `#1A1A1A` surface, muted copy, `#42B883` accent, green-to-blue native gradient title, raised dark buttons, and bordered security CTA reproduce the reference system. |
| Spacing and alignment | Passed | Hero, feature row, 836 px sponsor content width, 3-column sponsor cells, long-page spacing, and centered footer align with the desktop reference proportions. |
| Assets | Passed | Vue logo and ten sponsor assets were exported from the rendered source page and copied locally. The app performs no runtime hotlinking. |
| Scrolling and long page | Passed | AppKit `NSScrollView` reaches sponsor and footer sections cleanly while navigation and status bar remain fixed. |
| Navigation flyouts | Passed | Docs, Ecosystem, About, and Support use native hover/click flyouts. The 192 pt overlay, 8 pt radius, 28 pt rows, right-aligned placement, complete menu copy, and foreground stacking match the source navigation behavior. |
| Icons | Passed | Navigation disclosure marks use 9 pt semibold SF Symbols (`chevron.down` / `chevron.up`) with trailing image placement instead of baseline text glyphs. |
| Interaction | Passed | Verified native hover event registration, Docs/Ecosystem flyout switching, search reveal/input/submit, CTA feedback, Why Vue expansion, dark/light theme toggle, and sponsor/footer scrolling in the packaged app. |
| Accessibility | Passed | AppKit accessibility tree exposes window, navigation buttons, text field, CTA buttons, scroll area, and sponsor image labels. |
| Platform fit | Passed | Mobile reference behavior was captured to understand content reflow; implementation intentionally targets a resizable macOS window with a 980 px minimum width, consistent with this framework's macOS-only scope. |

## Runtime verification

- `npm run typecheck`: passed
- `npm test`: passed (11 TypeScript tests and 7 Swift XCTest cases)
- `npm run demo:vue:build`: passed
- `npm run demo:vue:package`: passed
- Packaged executable: Mach-O 64-bit arm64
- Code signing: ad-hoc signature verified with `codesign --verify --deep --strict`
- Linked UI/runtime frameworks: AppKit and JavaScriptCore; no WebKit, WKWebView, Electron, or Chromium runtime linked

## Navigation QA iteration history

1. Initial finding — P1: the Demo exposed its menu only after click and inserted a full-width row that pushed the hero downward. The disclosure arrow was a text glyph attached to the title and sat on the wrong baseline.
2. First fix: added native `mouseenter` / `mouseleave` bridge events, component-level close delay, an absolute overlay panel, complete source menu content, and trailing SF Symbols.
3. First post-fix capture — P1: the 192 pt panel rendered correctly, but `mac-z-stack` also pinned the absolute child to all four edges; the conflicting width/height constraints collapsed the window to the flyout size.
4. Final fix: absolute children now skip container-edge pinning and use only their explicit Auto Layout position and size constraints.
5. Final paired visual evidence: the full native window remains 1280 × 820, Docs and Ecosystem panels overlay the hero without reflow, menu bounds/radius/row rhythm align with the source, and disclosure symbols are vertically centered. No P0/P1/P2 navigation findings remain.

## Follow-up polish

- P3: AppKit text rasterization is slightly heavier than the browser font at small menu sizes; retain the native rendering for platform consistency.

final result: passed
