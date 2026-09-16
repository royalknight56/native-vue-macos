<script setup lang="ts">
import { computed, ref } from 'vue'

const darkMode = ref(true)
const activeMenu = ref('')
const searchVisible = ref(false)
const whyVisible = ref(false)
const status = ref('Ready — rendered by Vue in JavaScriptCore and AppKit.')
const search = ref('')
let menuCloseTimer: ReturnType<typeof setTimeout> | undefined

interface MenuEntry {
  label: string
  external?: boolean
}

interface MenuGroup {
  heading?: string
  entries: MenuEntry[]
}

const navigationMenus: Record<string, MenuGroup[]> = {
  Docs: [{ entries: [
    { label: 'Quick Start' }, { label: 'Guide' }, { label: 'Tutorial' }, { label: 'Examples' },
    { label: 'API' }, { label: 'Glossary' }, { label: 'Error Reference' },
    { label: 'Vue 2 Docs', external: true }, { label: 'Migration from Vue 2', external: true }
  ] }],
  Ecosystem: [
    { heading: 'RESOURCES', entries: [
      { label: 'Themes' }, { label: 'UI Components', external: true }, { label: 'Plugins Collection', external: true },
      { label: 'Certification', external: true }, { label: 'Jobs', external: true }, { label: 'T-Shirt Shop', external: true }
    ] },
    { heading: 'OFFICIAL LIBRARIES', entries: [
      { label: 'Vue Router', external: true }, { label: 'Pinia', external: true }, { label: 'Tooling Guide' }
    ] },
    { heading: 'VIDEO COURSES', entries: [
      { label: 'Vue Mastery', external: true }, { label: 'Vue School', external: true }
    ] },
    { heading: 'HELP', entries: [
      { label: 'Discord Chat', external: true }, { label: 'GitHub Discussions', external: true }, { label: 'DEV Community', external: true }
    ] },
    { heading: 'NEWS', entries: [
      { label: 'Blog', external: true }, { label: 'Twitter', external: true },
      { label: 'Events', external: true }, { label: 'Newsletters' }
    ] }
  ],
  About: [{ entries: [
    { label: 'FAQ' }, { label: 'Team' }, { label: 'Releases' }, { label: 'Community Guide' },
    { label: 'Code of Conduct' }, { label: 'Privacy Policy' }, { label: 'The Documentary', external: true }
  ] }],
  Support: [{ entries: [{ label: 'Sponsor' }, { label: 'Partners' }] }]
}

const menuLayout: Record<string, { left: number; height: number }> = {
  Docs: { left: 450, height: 278 },
  Ecosystem: { left: 674, height: 690 },
  About: { left: 766, height: 222 },
  Support: { left: 868, height: 82 }
}

const activeMenuRows = computed(() => (navigationMenus[activeMenu.value] ?? []).flatMap(group => [
  ...(group.heading ? [{ kind: 'heading' as const, label: group.heading }] : []),
  ...group.entries.map(entry => ({ kind: 'entry' as const, ...entry }))
]))

const dropdownStyle = computed(() => {
  const layout = menuLayout[activeMenu.value] ?? menuLayout.Docs
  return {
    position: 'absolute', top: 43, left: layout.left, zIndex: 100, width: 192, height: layout.height,
    padding: { top: 12, right: 12, bottom: 12, left: 12 }, spacing: 0, alignment: 'leading',
    backgroundColor: palette.value.background, borderColor: palette.value.divider, borderWidth: 1,
    borderRadius: 8, boxShadow: { offset: { x: 0, y: 2 }, blur: 6, color: '#00000033' }
  }
})

const palette = computed(() => darkMode.value
  ? {
      background: '#1A1A1A', panel: '#202020', panelRaised: '#2F2F2F', footer: '#202020',
      text: '#FFFFFFDE', muted: '#EBEBEB99', faint: '#EBEBEB66', divider: '#54545466'
    }
  : {
      background: '#FFFFFF', panel: '#F6F6F7', panelRaised: '#EBEBEF', footer: '#F6F6F7',
      text: '#213547', muted: '#3C3C3CB2', faint: '#3C3C3C73', divider: '#3C3C3C1F'
    })

const features = [
  ['Versatile', 'A rich, incrementally adoptable ecosystem that scales between a library and a full-featured framework.'],
  ['User-friendly', 'Builds on top of standard HTML, CSS and JavaScript with intuitive API and world-class documentation.'],
  ['Efficient', 'Truly reactive, compiler-optimized rendering system that rarely requires manual optimization.']
]

const sponsors = [
  ['vuemastery.avif', 'VueMastery'], ['vehikl.avif', 'Vehikl'], ['vue-amsterdam.avif', 'Vue.js Amsterdam'],
  ['storyblok.avif', 'Storyblok'], ['chrome-frameworks.avif', 'Chrome Frameworks Fund'],
  ['javascript-certification.png', 'JavaScript Certification'], ['coderabbit.avif', 'CodeRabbit'],
  ['imagekit.svg', 'ImageKit.io'], ['greptile.avif', 'Greptile'], ['serpapi.avif', 'SerpApi']
]

const sponsorRows = computed(() => {
  const rows: typeof sponsors[] = []
  for (let index = 0; index < sponsors.length; index += 3) rows.push(sponsors.slice(index, index + 3))
  return rows
})

const footerGroups = [
  ['Docs', 'Quick Start', 'Guide', 'Tutorial', 'Examples', 'API', 'Glossary', 'Error Reference', 'Vue 2 Docs ↗'],
  ['About', 'FAQ', 'Team', 'Releases', 'Community Guide', 'Code of Conduct', 'Privacy Policy', 'The Documentary ↗'],
  ['Resources', 'Themes', 'UI Components ↗', 'Plugins Collection ↗', 'Certification ↗', 'Jobs ↗', 'T-Shirt Shop ↗'],
  ['Official Libraries', 'Vue Router ↗', 'Pinia ↗', 'Tooling Guide', '', 'Help', 'Discord Chat ↗', 'GitHub Discussions ↗', 'DEV Community ↗'],
  ['News', 'Blog ↗', 'Twitter ↗', 'Events ↗', 'Newsletters', '', 'Video Courses', 'Vue Mastery ↗', 'Vue School ↗']
]

function openMenu(menu: string) {
  cancelMenuClose()
  activeMenu.value = menu
}

function scheduleMenuClose() {
  cancelMenuClose()
  menuCloseTimer = setTimeout(() => { activeMenu.value = '' }, 140)
}

function cancelMenuClose() {
  if (menuCloseTimer !== undefined) clearTimeout(menuCloseTimer)
  menuCloseTimer = undefined
}

function choose(label: string) {
  status.value = `${label} selected — navigation is intentionally kept inside this local demo.`
  activeMenu.value = ''
  cancelMenuClose()
}
</script>

<template>
  <mac-window title="Vue.js — Native AppKit Demo" :width="1280" :height="820" :min-width="980" :min-height="680">
    <mac-z-stack :style="{ backgroundColor: palette.background }">
      <mac-v-stack :style="{ spacing: 0, alignment: 'center', backgroundColor: palette.background }">
      <mac-h-stack :style="{ width: 1248, height: 55, padding: { left: 24, right: 24 }, spacing: 14, alignment: 'center', backgroundColor: palette.background }">
        <mac-image src="assets/vue-logo.svg" content-mode="fit" :style="{ width: 28, height: 28 }" />
        <mac-text text="Vue.js" :style="{ fontSize: 17, fontWeight: 'semibold', color: palette.text }" />
        <mac-button title="⌕  Search" :bordered="false" @click="searchVisible = !searchVisible" :style="{ width: 108, height: 32, color: palette.muted, backgroundColor: palette.panel, cornerRadius: 8 }" />
        <mac-spacer />
        <mac-button title="Docs" :system-image="activeMenu === 'Docs' ? 'chevron.up' : 'chevron.down'" :bordered="false" @mouseenter="openMenu('Docs')" @mouseleave="scheduleMenuClose" @click="openMenu('Docs')" :style="{ width: 72, height: 32, color: palette.text, hoverStyle: { color: '#42B883' } }" />
        <mac-button title="Playground" :bordered="false" @click="choose('Playground')" :style="{ width: 92, height: 32, color: palette.text }" />
        <mac-button title="Ecosystem" :system-image="activeMenu === 'Ecosystem' ? 'chevron.up' : 'chevron.down'" :bordered="false" @mouseenter="openMenu('Ecosystem')" @mouseleave="scheduleMenuClose" @click="openMenu('Ecosystem')" :style="{ width: 104, height: 32, color: palette.text, hoverStyle: { color: '#42B883' } }" />
        <mac-button title="About" :system-image="activeMenu === 'About' ? 'chevron.up' : 'chevron.down'" :bordered="false" @mouseenter="openMenu('About')" @mouseleave="scheduleMenuClose" @click="openMenu('About')" :style="{ width: 78, height: 32, color: palette.text, hoverStyle: { color: '#42B883' } }" />
        <mac-button title="Support" :system-image="activeMenu === 'Support' ? 'chevron.up' : 'chevron.down'" :bordered="false" @mouseenter="openMenu('Support')" @mouseleave="scheduleMenuClose" @click="openMenu('Support')" :style="{ width: 88, height: 32, color: palette.text, hoverStyle: { color: '#42B883' } }" />
        <mac-button :title="darkMode ? '☀︎' : '◐'" :bordered="false" @click="darkMode = !darkMode" :style="{ width: 42, height: 28, color: palette.muted, backgroundColor: palette.panelRaised, cornerRadius: 14 }" />
        <mac-text text="⌘  𝕏  ◉" :style="{ width: 80, color: palette.muted }" />
      </mac-h-stack>
      <mac-divider :style="{ width: 1248 }" />

      <mac-v-stack v-if="searchVisible" :style="{ width: 1248, height: 54, padding: { left: 244, right: 244, top: 10, bottom: 10 }, spacing: 8, alignment: 'center', backgroundColor: palette.panel }">
        <mac-text-field v-model="search" placeholder="Search the Vue documentation" :style="{ width: 760 }" @submit="status = `Search submitted: ${search || 'empty query'}`" />
      </mac-v-stack>

      <mac-scroll-view :style="{ width: 1248 }">
        <mac-v-stack :style="{ width: 1248, spacing: 0, alignment: 'center', backgroundColor: palette.background }">
          <mac-spacer :style="{ height: 82 }" />
          <mac-gradient-text text="The Progressive" text-alignment="center" :style="{ width: 960, height: 86, fontSize: 72, fontWeight: 'black', gradientStartColor: '#42D392', gradientEndColor: '#647EFF' }" />
          <mac-gradient-text text="JavaScript Framework" text-alignment="center" :style="{ width: 960, height: 86, fontSize: 72, fontWeight: 'black', gradientStartColor: '#42D392', gradientEndColor: '#647EFF' }" />
          <mac-spacer :style="{ height: 20 }" />
          <mac-text text="An approachable, performant and versatile framework for building web user interfaces." text-alignment="center" :style="{ width: 960, fontSize: 22, color: palette.muted }" />
          <mac-spacer :style="{ height: 32 }" />
          <mac-h-stack :style="{ spacing: 16 }">
            <mac-button title="▶  Why Vue" :bordered="false" @click="whyVisible = !whyVisible" :style="{ width: 136, height: 40, fontSize: 16, fontWeight: 'semibold', color: '#213547', backgroundColor: '#42B883', cornerRadius: 8 }" />
            <mac-button title="Get Started →" :bordered="false" @click="choose('Get Started')" :style="{ width: 142, height: 40, fontSize: 16, fontWeight: 'medium', color: palette.text, backgroundColor: palette.panelRaised, cornerRadius: 8 }" />
            <mac-button title="Install" :bordered="false" @click="choose('Install')" :style="{ width: 84, height: 40, fontSize: 16, color: palette.text, backgroundColor: palette.panelRaised, cornerRadius: 8 }" />
            <mac-button title="Get Security Updates for Vue 2 ↗" :bordered="false" @click="choose('Security Updates')" :style="{ width: 304, height: 42, fontSize: 15, color: palette.text, backgroundColor: palette.background, borderWidth: 2, borderColor: '#42B883', cornerRadius: 8 }" />
          </mac-h-stack>
          <mac-v-stack v-if="whyVisible" :style="{ width: 760, padding: 16, spacing: 4, alignment: 'center', backgroundColor: palette.panel, cornerRadius: 8 }">
            <mac-text text="Progressive by design" text-alignment="center" :style="{ width: 700, fontWeight: 'semibold', color: '#42B883' }" />
            <mac-text text="Adopt Vue as a small library, then scale the same component model into a complete application." text-alignment="center" :number-of-lines="0" line-break-mode="wordWrap" :style="{ width: 700, color: palette.muted }" />
          </mac-v-stack>
          <mac-spacer :style="{ height: 78 }" />
          <mac-divider :style="{ width: 1248 }" />
          <mac-button title="Special Sponsor slot is now vacant — Inquire now" :bordered="false" @click="choose('Sponsor inquiry')" :style="{ width: 760, height: 48, fontSize: 13, color: palette.muted }" />
          <mac-divider :style="{ width: 1248 }" />

          <mac-spacer :style="{ height: 68 }" />
          <mac-h-stack :style="{ spacing: 64, alignment: 'top' }">
            <mac-v-stack v-for="feature in features" :key="feature[0]" :style="{ width: 245, spacing: 10, alignment: 'leading' }">
              <mac-text :text="feature[0]" :style="{ width: 245, fontSize: 20, fontWeight: 'semibold', color: palette.text }" />
              <mac-text :text="feature[1]" :number-of-lines="0" line-break-mode="wordWrap" :style="{ width: 245, fontSize: 15, color: palette.muted }" />
            </mac-v-stack>
          </mac-h-stack>

          <mac-spacer :style="{ height: 108 }" />
          <mac-text text="Platinum Sponsors" :style="{ width: 836, fontSize: 20, fontWeight: 'semibold', color: palette.text }" />
          <mac-spacer :style="{ height: 18 }" />
          <mac-v-stack :style="{ width: 836, spacing: 4, alignment: 'center' }">
            <mac-h-stack v-for="(row, rowIndex) in sponsorRows" :key="rowIndex" :style="{ spacing: 4 }">
              <mac-v-stack v-for="sponsor in row" :key="sponsor[1]" :style="{ width: 274, height: 104, padding: { top: 22, bottom: 22, left: 28, right: 28 }, alignment: 'center', backgroundColor: palette.panel }">
                <mac-image :src="`assets/${sponsor[0]}`" :accessibility-label="sponsor[1]" content-mode="fit" :template="darkMode" :style="{ width: 210, height: 58, opacity: darkMode ? 0.78 : 1, color: darkMode ? '#D0D0D0' : '#213547' }" />
              </mac-v-stack>
              <mac-v-stack v-if="row.length < 3" :style="{ width: 274, height: 104, alignment: 'center', backgroundColor: palette.panel }">
                <mac-button title="Become a Sponsor" :bordered="false" @click="choose('Become a Sponsor')" :style="{ color: palette.faint }" />
              </mac-v-stack>
            </mac-h-stack>
          </mac-v-stack>
          <mac-button title="Become a Sponsor" :bordered="false" @click="choose('Become a Sponsor')" :style="{ width: 200, height: 50, fontSize: 12, color: palette.faint }" />

          <mac-spacer :style="{ height: 72 }" />
          <mac-text text="Gold Sponsors" :style="{ width: 836, fontSize: 20, fontWeight: 'semibold', color: palette.text }" />
          <mac-spacer :style="{ height: 18 }" />
          <mac-v-stack :style="{ width: 274, height: 92, alignment: 'center', backgroundColor: palette.panel }">
            <mac-button title="Become a Sponsor" :bordered="false" @click="choose('Gold Sponsor')" :style="{ color: palette.faint }" />
          </mac-v-stack>
          <mac-spacer :style="{ height: 94 }" />

          <mac-v-stack :style="{ width: 1248, padding: { top: 64, bottom: 58, left: 104, right: 104 }, spacing: 48, alignment: 'center', backgroundColor: palette.footer }">
            <mac-h-stack :style="{ width: 1040, spacing: 40, alignment: 'top' }">
              <mac-v-stack v-for="group in footerGroups" :key="group[0]" :style="{ width: 176, spacing: 7, alignment: 'leading' }">
                <mac-text v-for="(entry, index) in group" :key="`${entry}-${index}`" :text="entry || ' '" :style="{ width: 176, fontSize: index === 0 || group[index - 1] === '' ? 16 : 14, fontWeight: index === 0 || group[index - 1] === '' ? 'medium' : 'regular', color: index === 0 || group[index - 1] === '' ? palette.text : palette.muted }" />
              </mac-v-stack>
            </mac-h-stack>
            <mac-divider :style="{ width: 1040 }" />
            <mac-text text="Released under the MIT License.   Copyright © 2014–2026 Evan You" text-alignment="center" :style="{ width: 1040, fontSize: 13, color: palette.faint }" />
          </mac-v-stack>
        </mac-v-stack>
      </mac-scroll-view>

      <mac-h-stack :style="{ width: 1248, height: 30, padding: { left: 18, right: 18 }, spacing: 8, backgroundColor: palette.panel }">
        <mac-text :text="status" :style="{ fontSize: 12, color: palette.muted }" />
        <mac-spacer />
        <mac-text text="Native AppKit • no DOM • no WebView" :style="{ fontSize: 12, color: '#42B883' }" />
      </mac-h-stack>
      </mac-v-stack>

      <mac-v-stack
        v-if="activeMenu"
        :style="dropdownStyle"
        @mouseenter="cancelMenuClose"
        @mouseleave="scheduleMenuClose"
      >
        <template v-for="(row, index) in activeMenuRows" :key="`${activeMenu}-${index}-${row.label}`">
          <mac-text
            v-if="row.kind === 'heading'"
            :text="row.label"
            :style="{ width: 166, height: 32, fontSize: 10, fontWeight: 'semibold', letterSpacing: 0.8, color: palette.faint }"
          />
          <mac-button
            v-else
            :title="row.external ? `${row.label} ↗` : row.label"
            text-alignment="left"
            :bordered="false"
            @click="choose(row.label)"
            :style="{ width: 166, height: 28, fontSize: 13, color: palette.muted, hoverStyle: { color: '#42B883', backgroundColor: palette.panelRaised } }"
          />
        </template>
      </mac-v-stack>
    </mac-z-stack>
  </mac-window>
</template>
