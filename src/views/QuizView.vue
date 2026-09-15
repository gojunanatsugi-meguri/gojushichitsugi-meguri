<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import state, { spots, obtainCoupon } from '../store/appState'

const router = useRouter()

const scannedSpot = computed(() => spots.find((s) => s.id === state.lastScannedSpotId))

// 仮のクイズ。実際は地点ごとに「次の地点の周辺」をヒントにした問題をFirestoreに登録する
const question = '次の地点に向かう途中、甘い香りがするお店は何のお店？'
const options = ['どら焼き屋', '本屋', '床屋']
const correctAnswer = 'どら焼き屋'

const answered = ref(false)
const isCorrect = ref(false)

const candidateSpots = computed(() =>
  spots.filter((s) => s.id !== state.lastScannedSpotId && !state.obtainedCoupons.find((c) => c.id === s.id))
)

function answer(choice) {
  answered.value = true
  isCorrect.value = choice === correctAnswer
}

function pickCoupon(spotId) {
  obtainCoupon(spotId)
  router.push('/coupons')
}
</script>

<template>
  <div class="screen">
    <h1>クイズ</h1>

    <div v-if="!scannedSpot" class="card">
      まだQRを読み取っていません。先に「QR読取」からスタンプを獲得してください。
      <router-link to="/scan" class="btn" style="margin-top: 14px;">QR読取へ</router-link>
    </div>

    <template v-else>
      <p class="lede">{{ scannedSpot.name }}でスタンプ獲得！ 続けてクイズに挑戦しよう。</p>

      <section class="card">
        <h2>{{ question }}</h2>
        <div class="options">
          <button
            v-for="opt in options"
            :key="opt"
            class="btn secondary"
            :disabled="answered"
            @click="answer(opt)"
          >
            {{ opt }}
          </button>
        </div>
      </section>

      <section v-if="answered" class="card result" style="margin-top: 16px;">
        <p v-if="isCorrect">🎉 正解！ 次の地点周辺のお店から1店を選んでクーポンを獲得しよう。</p>
        <p v-else>残念、不正解でした。でもスタンプは獲得済み。次のスポットに進もう。</p>

        <ul v-if="isCorrect" class="spot-list">
          <li v-for="spot in candidateSpots" :key="spot.id">
            <button class="btn" @click="pickCoupon(spot.id)">
              {{ spot.name }}（{{ spot.coupon }}）
            </button>
          </li>
        </ul>
        <router-link v-else to="/" class="btn secondary" style="margin-top: 10px;">スタンプ帳に戻る</router-link>
      </section>
    </template>
  </div>
</template>

<style scoped>
.lede { color: var(--ink-soft); margin: 4px 0 16px; }
.options { display: flex; flex-direction: column; gap: 10px; margin-top: 10px; }
.result p { margin: 0 0 10px; }
.spot-list { list-style: none; padding: 0; margin: 10px 0 0; display: flex; flex-direction: column; gap: 10px; }
</style>
