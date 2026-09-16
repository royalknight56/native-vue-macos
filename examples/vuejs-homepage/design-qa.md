# Design QA — Vue.js Homepage Native Demo

## Reference

- Source: <https://vuejs.org/>
- Source capture: Codex in-app browser, 2026-09-16
- Desktop reference viewport: 1440 × 900; full page height observed at 2439 px
- Mobile reference viewport: 390 × 844; full page height observed at 3812 px
- Captured states: desktop default, desktop Docs flyout, mobile default, mobile navigation open
- Target: `/Users/admin/Desktop/my/myproject/native-vue-macos/dist/VueWebsiteDemo.app`
- Target window: 1280 × 820, macOS native desktop layout

The browser and native screenshots were captured through the computer-use session. That API exposes image bytes for visual comparison but does not provide persistent screenshot file paths.

## Comparison

| Category | Result | Evidence |
| --- | --- | --- |
| Overall composition | Passed | Fixed 55 px navigation, centered two-line hero, CTA row, sponsor strip, three-column value propositions, sponsor matrix, gold tier, and multi-column footer all match the reference hierarchy. |
| Typography | Passed | Hero uses 72 pt black-weight native text versus the reference 76 px/900; supporting copy uses 22 pt; section headings use 20 pt semibold. |
| Color and treatment | Passed | Dark `#1A1A1A` surface, muted copy, `#42B883` accent, green-to-blue native gradient title, raised dark buttons, and bordered security CTA reproduce the reference system. |
| Spacing and alignment | Passed | Hero, feature row, 836 px sponsor content width, 3-column sponsor cells, long-page spacing, and centered footer align with the desktop reference proportions. |
| Assets | Passed | Vue logo and ten sponsor assets were exported from the rendered source page and copied locally. The app performs no runtime hotlinking. |
| Scrolling and long page | Passed | AppKit `NSScrollView` reaches sponsor and footer sections cleanly while navigation and status bar remain fixed. |
| Interaction | Passed | Verified Docs flyout, search reveal/input/submit, CTA feedback, Why Vue expansion, dark/light theme toggle, and sponsor/footer scrolling in the packaged app. |
| Accessibility | Passed | AppKit accessibility tree exposes window, navigation buttons, text field, CTA buttons, scroll area, and sponsor image labels. |
| Platform fit | Passed | Mobile reference behavior was captured to understand content reflow; implementation intentionally targets a resizable macOS window with a 980 px minimum width, consistent with this framework's macOS-only scope. |

## Runtime verification

- `npm run typecheck`: passed
- `npm test`: passed (TypeScript tests and 5 Swift XCTest cases)
- `npm run demo:vue:build`: passed
- `npm run demo:vue:package`: passed
- Packaged executable: Mach-O 64-bit arm64
- Code signing: ad-hoc signature verified with `codesign --verify --deep --strict`
- Linked UI/runtime frameworks: AppKit and JavaScriptCore; no WebKit, WKWebView, Electron, or Chromium runtime linked

final result: passed
