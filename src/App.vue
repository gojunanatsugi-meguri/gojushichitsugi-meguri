<script setup>
const tabs = [
  { to: '/', label: 'スタンプ帳', icon: '🏯' },
  { to: '/scan', label: 'QR読取', icon: '📷' },
  { to: '/quiz', label: 'クイズ', icon: '❓' },
  { to: '/coupons', label: 'クーポン', icon: '🎫' },
  { to: '/map', label: '地図', icon: '📍' },
]
</script>

<template>
  <router-view />

  <nav class="tabbar">
    <router-link
      v-for="tab in tabs"
      :key="tab.to"
      :to="tab.to"
      class="tab"
      active-class="active"
    >
      <span class="tab-icon" aria-hidden="true">{{ tab.icon }}</span>
      <span class="tab-label">{{ tab.label }}</span>
    </router-link>
  </nav>
</template>

<style scoped>
.tabbar {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  display: flex;
  background: var(--surface);
  border-top: 1px solid var(--line);
  padding-bottom: env(safe-area-inset-bottom);
}

.tab {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  padding: 10px 4px 8px;
  min-height: var(--tap-min);
  text-decoration: none;
  color: var(--ink-soft);
  font-size: 0.75rem;
}

.tab-icon { font-size: 1.4rem; }

.tab.active {
  color: var(--indigo);
  font-weight: 700;
}
</style>
