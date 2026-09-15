import { reactive, computed } from 'vue'

// 仮データ：実際のスポット・クイズ内容は枚方信用金庫様・協力店との
// 打ち合わせを踏まえて Firestore 側に置き換える（Week 1-2 で確定）
export const spots = [
  { id: 'spot1', name: '枚方涼氷', category: 'かき氷', coupon: '練乳シングルをサービス' },
  { id: 'spot2', name: 'KAORU COFFEE', category: 'カフェ', coupon: 'ドリンク10%引き' },
  { id: 'spot3', name: '呼人堂', category: 'どら焼き', coupon: '1,500円以上で1個増量' },
  { id: 'spot4', name: 'うつわとカフェ Lau', category: 'カフェ', coupon: 'お会計より100円引き' },
  { id: 'spot5', name: 'くらわんか餅巴堂', category: '餅菓子', coupon: '500円以上でやきもち1個' },
]

// 位（ランク）の段階。歩いた距離(km)の累計で判定する
export const ranks = [
  { key: 'tabibito', label: '旅人', color: '#B08D57', minKm: 0 },
  { key: 'hikyaku', label: '飛脚', color: '#8C8C8C', minKm: 110 },
  { key: 'tonya', label: '問屋', color: '#C9A227', minKm: 220 },
  { key: 'honjin', label: '本陣', color: '#C9A227', minKm: 330 },
  { key: 'daimyo', label: '大名行列', color: '#D4AF37', minKm: 440 },
]

const state = reactive({
  // デモ用の暫定値。実際は Health 連携プラグインから取得した歩数を距離に換算する
  distanceKm: 42,
  stampedSpotIds: [],
  obtainedCoupons: [],
  lastScannedSpotId: null,
})

export function currentRank() {
  let current = ranks[0]
  for (const r of ranks) {
    if (state.distanceKm >= r.minKm) current = r
  }
  return current
}

export function addDemoDistance(km) {
  state.distanceKm = Math.min(550, Math.round((state.distanceKm + km) * 10) / 10)
}

export function stampSpot(spotId) {
  if (!state.stampedSpotIds.includes(spotId)) {
    state.stampedSpotIds.push(spotId)
  }
}

export function obtainCoupon(spotId) {
  const spot = spots.find((s) => s.id === spotId)
  if (spot && !state.obtainedCoupons.find((c) => c.id === spotId)) {
    state.obtainedCoupons.push(spot)
  }
}

export const rankProgress = computed(() => Math.min(100, Math.round((state.distanceKm / 550) * 100)))

export default state
