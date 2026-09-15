<script setup>
import { ref, onMounted } from 'vue'
import QRCode from 'qrcode'
import { spots } from '../store/appState'

const images = ref({})

onMounted(async () => {
  for (const spot of spots) {
    images.value[spot.id] = await QRCode.toDataURL(spot.qrValue, { width: 260, margin: 2 })
  }
})
</script>

<template>
  <div class="screen">
    <h1>テスト用QRコード</h1>
    <p class="lede">
      本物の店舗QRができるまでの代用品です。この画面をスマホで開いて表示し、
      別の端末（Macなど）の「QR読取」画面で読み取るテストに使えます。
    </p>

    <section v-for="spot in spots" :key="spot.id" class="card qr-card">
      <img v-if="images[spot.id]" :src="images[spot.id]" :alt="spot.name + 'のテストQR'" />
      <div class="qr-label">{{ spot.name }}</div>
    </section>
  </div>
</template>

<style scoped>
.lede { color: var(--ink-soft); margin: 4px 0 16px; }
.qr-card { display: flex; flex-direction: column; align-items: center; gap: 8px; margin-top: 14px; }
.qr-card img { width: 100%; max-width: 260px; height: auto; }
.qr-label { font-weight: 700; }
</style>
