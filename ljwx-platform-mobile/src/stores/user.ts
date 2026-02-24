import { defineStore } from 'pinia'
import { ref } from 'vue'
import { login, refreshToken, logout } from '@/api/auth'
import type { LoginDTO } from '@/api/auth'

export interface UserInfo {
  userId: number
  username: string
  nickname: string
  avatar: string
}

const ACCESS_TOKEN_KEY = 'mobile_access_token'
const REFRESH_TOKEN_KEY = 'mobile_refresh_token'

export const useUserStore = defineStore('user', () => {
  const accessToken = ref<string>(uni.getStorageSync(ACCESS_TOKEN_KEY) as string || '')
  const refreshTokenValue = ref<string>(uni.getStorageSync(REFRESH_TOKEN_KEY) as string || '')
  const userInfo = ref<UserInfo | null>(null)

  async function doLogin(dto: LoginDTO): Promise<void> {
    const data = await login(dto)
    accessToken.value = data.accessToken
    refreshTokenValue.value = data.refreshToken
    uni.setStorageSync(ACCESS_TOKEN_KEY, data.accessToken)
    uni.setStorageSync(REFRESH_TOKEN_KEY, data.refreshToken)
  }

  async function refreshAccessToken(): Promise<void> {
    const data = await refreshToken({ refreshToken: refreshTokenValue.value })
    accessToken.value = data.accessToken
    refreshTokenValue.value = data.refreshToken
    uni.setStorageSync(ACCESS_TOKEN_KEY, data.accessToken)
    uni.setStorageSync(REFRESH_TOKEN_KEY, data.refreshToken)
  }

  function logout(): void {
    accessToken.value = ''
    refreshTokenValue.value = ''
    userInfo.value = null
    uni.removeStorageSync(ACCESS_TOKEN_KEY)
    uni.removeStorageSync(REFRESH_TOKEN_KEY)
  }

  function isLoggedIn(): boolean {
    return !!accessToken.value
  }

  return {
    accessToken,
    refreshTokenValue,
    userInfo,
    doLogin,
    refreshAccessToken,
    logout,
    isLoggedIn,
  }
})
