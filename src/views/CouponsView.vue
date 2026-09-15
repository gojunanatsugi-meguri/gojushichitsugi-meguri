<script setup>
import state from '../store/appState'
</script>

<template>
  <div class="screen">
    <h1>獲得クーポン</h1>
    <p class="lede">クイズに正解してもらったクーポンの一覧です。お店でこの画面を見せてください。</p>

    <p v-if="state.obtainedCoupons.length === 0" class="card empty">
      まだクーポンがありません。QRを読み取ってクイズに正解すると、ここに増えていきます。
    </p>

    <ul v-else class="coupon-list">
      <li v-for="coupon in state.obtainedCoupons" :key="coupon.id" class="card coupon">
        <div class="coupon-store">{{ coupon.name }}</div>
        <div class="coupon-benefit">{{ coupon.coupon }}</div>
      </li>
    </ul>
  </div>
</template>

<style scoped>
.lede { color: var(--ink-soft); margin: 4px 0 16px; }
.empty { color: var(--ink-soft); text-align: center; }
.coupon-list { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 12px; }
.coupon { display: flex; justify-content: space-between; align-items: center; border-left: 4px solid var(--gold); }
.coupon-store { font-weight: 700; }
.coupon-benefit { color: var(--indigo); font-weight: 700; }
</style>
