<script setup>
import { computed } from 'vue'
import state, { spots, currentRank, rankProgress, addDemoDistance } from '../store/appState'

const rank = computed(() => currentRank())
const stampedCount = computed(() => state.stampedSpotIds.length)
</script>

<template>
  <div class="screen">
    <h1>五十七次めぐり</h1>
    <p class="lede">枚方宿を歩いて、宿場印を集めよう！</p>

    <section class="card rank-card">
      <div class="rank-badge" :style="{ background: rank.color }">{{ rank.label }}</div>
      <p class="km">これまで <strong>{{ state.distanceKm }}km</strong> 歩きました（全550km中）</p>
      <div class="bar"><div class="bar-fill" :style="{ width: rankProgress + '%' }" /></div>
      <p class="note">歩数と連動して自動で増える予定（現在はデモ用ボタン）</p>
      <div class="demo-buttons">
        <button class="btn secondary" @click="addDemoDistance(10)">+10km（デモ）</button>
        <button class="btn secondary" @click="addDemoDistance(50)">+50km（デモ）</button>
      </div>
    </section>

    <section class="card" style="margin-top: 16px;">
      <h2>スタンプ帳（{{ stampedCount }} / {{ spots.length }}）</h2>
      <ul class="spot-list">
        <li v-for="spot in spots" :key="spot.id" class="spot-row">
          <span class="stamp" :class="{ got: state.stampedSpotIds.includes(spot.id) }">
            {{ state.stampedSpotIds.includes(spot.id) ? '●' : '○' }}
          </span>
          <span>{{ spot.name }}</span>
        </li>
      </ul>
    </section>

    <router-link to="/scan" class="btn" style="margin-top: 20px;">QRを読み取りに行く</router-link>
  </div>
</template>

<style scoped>
.lede { color: var(--ink-soft); margin-top: 4px; }
.rank-card { text-align: center; }
.rank-badge {
  display: inline-block;
  color: white;
  font-weight: 700;
  padding: 8px 20px;
  border-radius: 999px;
  margin-bottom: 10px;
}
.km { margin: 6px 0; }
.bar { height: 10px; background: var(--line); border-radius: 999px; overflow: hidden; margin: 10px 0; }
.bar-fill { height: 100%; background: var(--gold); }
.note { font-size: 0.85rem; color: var(--ink-soft); }
.demo-buttons { display: flex; gap: 10px; margin-top: 12px; }
.demo-buttons .btn { min-height: 44px; font-size: 0.95rem; }

.spot-list { list-style: none; padding: 0; margin: 10px 0 0; display: flex; flex-direction: column; gap: 10px; }
.spot-row { display: flex; align-items: center; gap: 10px; }
.stamp { font-size: 1.3rem; color: var(--line); }
.stamp.got { color: var(--gold); }
</style>
