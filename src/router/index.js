import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import ScanView from '../views/ScanView.vue'
import QuizView from '../views/QuizView.vue'
import CouponsView from '../views/CouponsView.vue'
import MapView from '../views/MapView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', name: 'home', component: HomeView },
    { path: '/scan', name: 'scan', component: ScanView },
    { path: '/quiz', name: 'quiz', component: QuizView },
    { path: '/coupons', name: 'coupons', component: CouponsView },
    { path: '/map', name: 'map', component: MapView },
  ],
})

export default router
