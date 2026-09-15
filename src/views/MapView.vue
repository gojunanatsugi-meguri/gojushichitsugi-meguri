<script setup>
import state, { spots } from '../store/appState'
</script>

<template>
  <div class="screen">
    <h1>地図</h1>
    <p class="lede">現在地とスポットの位置だけを表示するシンプルな地図（位置情報はこの表示だけに使用）。</p>

    <div class="card map-placeholder">
      📍 実際の地図は Google Maps 等と連携予定（川村さんタスク）
    </div>

    <section class="card" style="margin-top: 16px;">
      <h2>スポット一覧</h2>
      <ul class="spot-list">
        <li v-for="spot in spots" :key="spot.id" class="spot-row">
          <span class="stamp" :class="{ got: state.stampedSpotIds.includes(spot.id) }">
            {{ state.stampedSpotIds.includes(spot.id) ? '●' : '○' }}
          </span>
          <span>{{ spot.name }}（{{ spot.category }}）</span>
        </li>
      </ul>
    </section>
  </div>
</template>

<style scoped>
.lede { color: var(--ink-soft); margin: 4px 0 16px; }
.map-placeholder {
  height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  color: var(--ink-soft);
  background: var(--indigo-soft);
}
.spot-list { list-style: none; padding: 0; margin: 10px 0 0; display: flex; flex-direction: column; gap: 10px; }
.spot-row { display: flex; align-items: center; gap: 10px; }
.stamp { font-size: 1.3rem; color: var(--line); }
.stamp.got { color: var(--gold); }
</style>
