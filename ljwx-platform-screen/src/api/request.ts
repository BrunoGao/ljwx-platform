import axios from 'axios'
import type { AxiosInstance, InternalAxiosRequestConfig, AxiosResponse } from 'axios'

const service: AxiosInstance = axios.create({
  baseURL: import.meta.env.VITE_APP_BASE_API,
  timeout: 15000,
})

service.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  return config
})

interface ApiResponse<T = unknown> {
  code: number
  message: string
  data: T
}

service.interceptors.response.use(
  (response: AxiosResponse<ApiResponse>) => {
    const { code, message, data } = response.data
    if (code !== 200) {
      return Promise.reject(new Error(message || '请求失败'))
    }
    return data as unknown as AxiosResponse
  },
  (error: unknown) => {
    return Promise.reject(error)
  },
)

export default service
