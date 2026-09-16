<script setup lang="ts">
import { computed, ref } from 'vue'

const count = ref(0)
const name = ref('原生 Vue')
const password = ref('')
const enabled = ref(true)
const nativeSwitch = ref(true)
const radioSelected = ref(false)
const search = ref('AppKit')
const notes = ref('多行文本同样由 NSTextView 原生渲染。')
const comboValue = ref('Swift')
const popupIndex = ref(0)
const segmentIndex = ref(0)
const volume = ref(42)
const stepValue = ref(3)
const selectedDate = ref('2026-09-16T12:00:00Z')
const selectedColor = ref('#42B883FF')
const selectedPath = ref('/Applications')
const progress = computed(() => (count.value % 11) / 10)
const greeting = computed(() => name.value.trim() ? `你好，${name.value}` : '请输入名称')
const popupItems = ['概览', '控件', '数据视图']
const segmentLabels = ['Vue', 'AppKit', 'JSC']
const comboItems = ['Swift', 'TypeScript', 'Vue']
</script>

<template>
  <mac-window title="Native Vue macOS Showcase" :width="860" :height="720" :min-width="680" :min-height="520">
    <mac-scroll-view>
      <mac-v-stack :style="{ padding: 24, spacing: 18, alignment: 'leading' }">
        <mac-text
          class="hero-title"
          text="Vue 3 → JavaScriptCore → AppKit"
        />
        <mac-text
          text="这个窗口和下面的控件全部由 AppKit 创建，没有 DOM 或 WebView。"
          :style="{ color: 'secondaryLabel' }"
        />
        <mac-divider :style="{ width: 780 }" />

        <mac-h-stack :style="{ spacing: 10, alignment: 'center' }">
          <mac-button title="−" accessibility-label="减少计数" @click="count--" />
          <mac-text :text="`响应式计数：${count}`" :style="{ width: 150, fontWeight: 'medium' }" />
          <mac-button title="+" accessibility-label="增加计数" @click="count++" />
          <mac-spacer />
          <mac-progress :value="progress" :min="0" :max="1" :style="{ width: 180 }" />
        </mac-h-stack>

        <mac-v-stack :style="{ spacing: 8, width: 780 }">
          <mac-text text="输入与双向绑定" :style="{ fontWeight: 'semibold' }" />
          <mac-text-field v-model="name" placeholder="名称" :style="{ width: 320 }" @submit="count++" />
          <mac-secure-field v-model="password" placeholder="密码" :style="{ width: 320 }" />
          <mac-toggle v-model="enabled" label="启用原生交互" />
          <mac-search-field v-model="search" placeholder="搜索原生控件" :style="{ width: 320 }" />
          <mac-text-view v-model="notes" :style="{ width: 480, height: 72 }" />
          <mac-text :text="greeting" :style="{ color: enabled ? 'accent' : 'secondaryLabel' }" />
          <mac-text :text="`密码长度：${password.length} · 搜索：${search}`" :style="{ color: 'secondaryLabel' }" />
        </mac-v-stack>

        <mac-divider :style="{ width: 780 }" />
        <mac-v-stack :style="{ spacing: 10, width: 780 }">
          <mac-text text="选择与数值控件" :style="{ fontWeight: 'semibold' }" />
          <mac-h-stack :style="{ spacing: 14, alignment: 'center' }">
            <mac-switch v-model="nativeSwitch" />
            <mac-radio v-model="radioSelected" label="原生单选按钮" />
            <mac-text
              :text="`Switch ${nativeSwitch ? '开' : '关'} · Radio ${radioSelected ? '已选' : '未选'}`"
              :style="{ color: 'secondaryLabel' }"
            />
          </mac-h-stack>
          <mac-h-stack :style="{ spacing: 12, alignment: 'center' }">
            <mac-pop-up-button v-model="popupIndex" :items="popupItems" :style="{ width: 150 }" />
            <mac-segmented-control v-model="segmentIndex" :labels="segmentLabels" :style="{ width: 240 }" />
            <mac-combo-box v-model="comboValue" :items="comboItems" :style="{ width: 160 }" />
          </mac-h-stack>
          <mac-h-stack :style="{ spacing: 12, alignment: 'center' }">
            <mac-text text="音量" :style="{ width: 48 }" />
            <mac-slider v-model="volume" :min="0" :max="100" :style="{ width: 260 }" />
            <mac-stepper v-model="stepValue" :min="0" :max="10" :increment="1" />
            <mac-level-indicator :value="volume" :min="0" :max="100" :style="{ width: 140 }" />
            <mac-text :text="`${Math.round(volume)} / ${stepValue}`" :style="{ color: 'secondaryLabel' }" />
          </mac-h-stack>
          <mac-h-stack :style="{ spacing: 12, alignment: 'center' }">
            <mac-date-picker v-model="selectedDate" :style="{ width: 220 }" />
            <mac-color-well v-model="selectedColor" :style="{ width: 52, height: 28 }" />
            <mac-path-control v-model="selectedPath" :style="{ width: 360 }" />
          </mac-h-stack>
          <mac-text
            :text="`选择：${popupItems[popupIndex] ?? '-'} · 分段：${segmentLabels[segmentIndex] ?? '-'} · ${comboValue}`"
            :style="{ color: 'secondaryLabel' }"
          />
        </mac-v-stack>

        <mac-divider :style="{ width: 780 }" />
        <mac-v-stack :style="{ spacing: 6, width: 780 }">
          <mac-text text="已注册原生元素（48）" :style="{ fontWeight: 'semibold' }" />
          <mac-text
            text="应用与布局：window、view、v/h/z-stack、scroll、spacer、box、divider、clip、split、tab、grid、visual-effect、scroller、ruler"
            :style="{ color: 'secondaryLabel' }"
          />
          <mac-text
            text="输入与选择：text、gradient-text、button、combo-button、toggle、radio、switch、text/secure/search/token-field、text-view、combo-box、pop-up、segmented"
            :style="{ color: 'secondaryLabel' }"
          />
          <mac-text
            text="数值与内容：slider、stepper、progress、level-indicator、date-picker、color-well、path-control、image"
            :style="{ color: 'secondaryLabel' }"
          />
          <mac-text
            text="数据视图：table、outline、collection、browser、rule-editor、scrubber、table-row、table-cell、table-header"
            :style="{ color: 'secondaryLabel' }"
          />
        </mac-v-stack>

        <mac-divider :style="{ width: 780 }" />
        <mac-text text="本地图片" :style="{ fontWeight: 'semibold' }" />
        <mac-image src="assets/native-vue.svg" content-mode="fit" :style="{ width: 120, height: 120 }" />
        <mac-text
          text="保存 App.vue 后，开发服务器会在同一个进程和窗口中应用 Vue HMR 更新。"
          :style="{ color: 'secondaryLabel' }"
        />
      </mac-v-stack>
    </mac-scroll-view>
  </mac-window>
</template>

<style native scoped>
mac-text.hero-title {
  color: label;
  font-size: 24px;
  font-weight: 600;
  letter-spacing: 0.2px;
}

mac-button:hover {
  opacity: 0.82;
}
</style>
