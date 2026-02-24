import axios from 'axios'
import type { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse } from 'axios'
import { useUserStore } from '@/stores/user'

const service: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_APP_BASE_API as string,
  timeout: 15000,
})

service.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const userStore = useUserStore()
  if (userStore.accessToken) {
    config.headers.Authorization = `Bearer ${userStore.accessToken}`
  }
  return config
})

let isRefreshing = false
let failedQueue: Array<{
  resolve: (value?: unknown) => void
  reject: (reason?: unknown) => void
}> = []

service.interceptors.response.use(
  (response: AxiosResponse) => {
    const { code, message, data } = response.data as { code: number; message: string; data: unknown }
    if (code !== 200) {
      uni.showToast({ title: message || '请求失败', icon: 'none' })
      return Promise.reject(new Error(message))
    }
    return data
  },
  async (error: { config: InternalAxiosRequestConfig & { _retry?: boolean }; response?: { status: number; data?: { message?: string } } }) => {
    const originalRequest = error.config
    if (error.response?.status === 401 && !originalRequest._retry) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject })
        }).then(() => service(originalRequest))
      }
      originalRequest._retry = true
      isRefreshing = true
      try {
        const userStore = useUserStore()
        await userStore.refreshAccessToken()
        failedQueue.forEach(({ resolve }) => resolve(undefined))
        failedQueue = []
        return service(originalRequest)
      } catch (refreshError) {
        failedQueue.forEach(({ reject }) => reject(refreshError))
        failedQueue = []
        const userStore = useUserStore()
        userStore.logout()
        uni.reLaunch({ url: '/pages/login/index' })
        return Promise.reject(refreshError)
      } finally {
        isRefreshing = false
      }
    }
    uni.showToast({ title: error.response?.data?.message || '网络错误', icon: 'none' })
    return Promise.reject(error)
  },
)

export default service
