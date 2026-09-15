<script setup>
import { useRouter } from 'vue-router'
import state, { spots, stampSpot } from '../store/appState'

const router = useRouter()

function simulateScan(spotId) {
  // TODO: @capacitor-mlkit/barcode-scanning に置き換える（Week2 技術検証タスク）
  stampSpot(spotId)
  state.lastScannedSpotId = spotId
  router.push('/quiz')
}
</script>

<template>
  <div class="screen">
    <h1>QR読取</h1>
    <p class="lede">協力店に設置されたQRコードを読み取ると、その場でスタンプがもらえます。</p>

    <div class="card notice">
      実際のカメラ読み取りは <code>@capacitor-mlkit/barcode-scanning</code> を組み込んで実装予定です。
      今はどのお店のQRを読んだかをボタンで選ぶデモ画面になっています。
    </div>

    <section class="card" style="margin-top: 16px;">
      <h2>お店を選んでQRを読んだことにする（デモ）</h2>
      <ul class="spot-list">
        <li v-for="spot in spots" :key="spot.id">
          <button class="btn secondary" @click="simulateScan(spot.id)">
            {{ spot.name }}（{{ spot.category }}）のQRを読む
          </button>
        </li>
      </ul>
    </section>
  </div>
</template>

<style scoped>
.lede { color: var(--ink-soft); margin-top: 4px; }
.notice { font-size: 0.9rem; color: var(--ink-soft); }
.notice code { background: var(--indigo-soft); padding: 2px 6px; border-radius: 6px; }
.spot-list { list-style: none; padding: 0; margin: 10px 0 0; display: flex; flex-direction: column; gap: 10px; }
</style>
