<script setup>
import { ref, onBeforeUnmount } from 'vue'
import { useRouter } from 'vue-router'
import jsQR from 'jsqr'
import state, { spots, stampSpot, findSpotByQrValue } from '../store/appState'

const router = useRouter()

const videoEl = ref(null)
const canvasEl = ref(null)
const cameraOn = ref(false)
const errorMsg = ref('')

let stream = null
let rafId = null

async function startCamera() {
  errorMsg.value = ''
  try {
    stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } })
    videoEl.value.srcObject = stream
    await videoEl.value.play()
    cameraOn.value = true
    tick()
  } catch (err) {
    errorMsg.value = 'カメラを使えませんでした。ブラウザの権限設定を確認するか、下の手動選択を使ってください。（' + err.message + '）'
  }
}

function stopCamera() {
  cameraOn.value = false
  if (rafId) cancelAnimationFrame(rafId)
  if (stream) {
    stream.getTracks().forEach((t) => t.stop())
    stream = null
  }
}

function tick() {
  if (!cameraOn.value) return
  const video = videoEl.value
  const canvas = canvasEl.value
  if (video && canvas && video.readyState === video.HAVE_ENOUGH_DATA) {
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    const ctx = canvas.getContext('2d')
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
    const code = jsQR(imageData.data, imageData.width, imageData.height)
    if (code) {
      handleDecoded(code.data)
      return
    }
  }
  rafId = requestAnimationFrame(tick)
}

function handleDecoded(value) {
  const spot = findSpotByQrValue(value)
  stopCamera()
  if (!spot) {
    errorMsg.value = 'このQRコードは登録されているスポットのものではありません（読み取った内容: ' + value + '）'
    return
  }
  simulateScan(spot.id)
}

function simulateScan(spotId) {
  // 手動選択・カメラ読み取り、どちらから来ても同じ処理
  stampSpot(spotId)
  state.lastScannedSpotId = spotId
  router.push('/quiz')
}

onBeforeUnmount(stopCamera)
</script>

<template>
  <div class="screen">
    <h1>QR読取</h1>
    <p class="lede">協力店に設置されたQRコードを読み取ると、その場でスタンプがもらえます。</p>

    <div class="card camera-card">
      <video ref="videoEl" class="video" :class="{ hidden: !cameraOn }" playsinline muted></video>
      <canvas ref="canvasEl" class="hidden-canvas"></canvas>

      <template v-if="!cameraOn">
        <button class="btn" @click="startCamera">カメラでQRを読み取る</button>
        <p v-if="errorMsg" class="error">{{ errorMsg }}</p>
        <p class="hint">
          テスト用QR（<router-link to="/test-qr">/test-qr</router-link>）を別の端末に表示して、それを映してみてください。
        </p>
      </template>
      <button v-else class="btn secondary" @click="stopCamera">カメラを止める</button>
    </div>

    <section class="card" style="margin-top: 16px;">
      <h2>またはお店を選ぶ（手動・デモ用）</h2>
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
.camera-card { display: flex; flex-direction: column; align-items: center; gap: 12px; }
.video { width: 100%; max-width: 360px; border-radius: 10px; background: black; }
.video.hidden { display: none; }
.hidden-canvas { display: none; }
.error { color: #b23a2e; font-size: 0.85rem; }
.hint { font-size: 0.85rem; color: var(--ink-soft); text-align: center; }
.spot-list { list-style: none; padding: 0; margin: 10px 0 0; display: flex; flex-direction: column; gap: 10px; }
</style>
