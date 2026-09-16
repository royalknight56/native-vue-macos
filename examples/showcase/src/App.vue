<script setup lang="ts">
import { computed, ref } from 'vue'

const count = ref(0)
const name = ref('原生 Vue')
const password = ref('')
const enabled = ref(true)
const progress = computed(() => (count.value % 11) / 10)
const greeting = computed(() => name.value.trim() ? `你好，${name.value}` : '请输入名称')
</script>

<template>
  <mac-window title="Native Vue macOS Showcase" :width="760" :height="620" :min-width="560" :min-height="420">
    <mac-scroll-view>
      <mac-v-stack :style="{ padding: 24, spacing: 16, alignment: 'leading' }">
        <mac-text
          text="Vue 3 → JavaScriptCore → AppKit"
          :style="{ fontSize: 24, fontWeight: 'semibold', color: 'label' }"
        />
        <mac-text
          text="这个窗口和下面的控件全部由 AppKit 创建，没有 DOM 或 WebView。"
          :style="{ color: 'secondaryLabel' }"
        />
        <mac-divider :style="{ width: 680 }" />

        <mac-h-stack :style="{ spacing: 10, alignment: 'center' }">
          <mac-button title="−" accessibility-label="减少计数" @click="count--" />
          <mac-text :text="`响应式计数：${count}`" :style="{ width: 150, fontWeight: 'medium' }" />
          <mac-button title="+" accessibility-label="增加计数" @click="count++" />
          <mac-spacer />
          <mac-progress :value="progress" :min="0" :max="1" :style="{ width: 180 }" />
        </mac-h-stack>

        <mac-v-stack :style="{ spacing: 8, width: 680 }">
          <mac-text text="输入与双向绑定" :style="{ fontWeight: 'semibold' }" />
          <mac-text-field v-model="name" placeholder="名称" :style="{ width: 320 }" @submit="count++" />
          <mac-secure-field v-model="password" placeholder="密码" :style="{ width: 320 }" />
          <mac-toggle v-model="enabled" label="启用原生交互" />
          <mac-text :text="greeting" :style="{ color: enabled ? 'accent' : 'secondaryLabel' }" />
          <mac-text :text="`密码长度：${password.length}`" :style="{ color: 'secondaryLabel' }" />
        </mac-v-stack>

        <mac-divider :style="{ width: 680 }" />
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
