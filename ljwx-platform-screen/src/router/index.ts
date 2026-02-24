import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    component: () => import('@/layouts/ScreenLayout.vue'),
    children: [
      {
        path: '',
        name: 'Home',
        component: () => import('@/views/home/index.vue'),
      },
    ],
  },
]

export const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})
