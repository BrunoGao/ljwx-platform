import axios, { isAxiosError } from 'axios'
import type { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse, AxiosRequestConfig } from 'axios'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import router from '@/router'

// Augment InternalAxiosRequestConfig to support the retry flag
declare module 'axios' {
  interface InternalAxiosRequestConfig {
    _retry?: boolean
  }
}

const service: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_APP_BASE_API,
  timeout: 15000,
})

// Request interceptor: inject Authorization header
service.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const userStore = useUserStore()
  if (userStore.accessToken) {
    config.headers.Authorization = `Bearer ${userStore.accessToken}`
  }
  return config
})

// 401 refresh queue
let isRefreshing = false
let failedQueue: Array<{
  resolve: (value?: unknown) => void
  reject: (reason?: unknown) => void
}> = []

// Response interceptor: handle business errors and 401 refresh
service.interceptors.response.use(
  (response: AxiosResponse) => {
    const resData = response.data as { code: number; message: string; data: unknown }
    if (resData.code !== 200) {
      ElMessage.error(resData.message || '请求失败')
      return Promise.reject(new Error(resData.message))
    }
    return resData.data as AxiosResponse
  },
  async (error: unknown) => {
    if (isAxiosError(error)) {
      const originalRequest = error.config
      if (error.response?.status === 401 && originalRequest && !originalRequest._retry) {
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
        } catch (refreshError: unknown) {
          failedQueue.forEach(({ reject }) => reject(refreshError))
          failedQueue = []
          const userStore = useUserStore()
          userStore.logout()
          router.push('/login')
          return Promise.reject(refreshError)
        } finally {
          isRefreshing = false
        }
      }
      const errMsg = (error.response?.data as { message?: string } | undefined)?.message ?? '网络错误'
      ElMessage.error(errMsg)
    }
    return Promise.reject(error)
  },
)

// Typed request wrapper — avoids exposing AxiosResponse generics in API layer
const request = {
  get<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    return service.get(url, config) as unknown as Promise<T>
  },
  post<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    return service.post(url, data, config) as unknown as Promise<T>
  },
  put<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    return service.put(url, data, config) as unknown as Promise<T>
  },
  delete<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    return service.delete(url, config) as unknown as Promise<T>
  },
  patch<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    return service.patch(url, data, config) as unknown as Promise<T>
  },
}

export default request
