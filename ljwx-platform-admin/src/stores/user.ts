import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { UserInfo, LoginDTO, LoginVO, TokenVO } from '@ljwx/shared'

export const useUserStore = defineStore('user', () => {
  const accessToken = ref<string>(localStorage.getItem('ljwx_access_token') ?? '')
  const refreshToken = ref<string>(localStorage.getItem('ljwx_refresh_token') ?? '')
  const userInfo = ref<UserInfo | null>(null)

  function setTokens(data: LoginVO): void {
    accessToken.value = data.accessToken
    refreshToken.value = data.refreshToken
    userInfo.value = data.userInfo
    localStorage.setItem('ljwx_access_token', data.accessToken)
    localStorage.setItem('ljwx_refresh_token', data.refreshToken)
  }

  async function login(data: LoginDTO): Promise<void> {
    const { loginApi } = await import('@/api/auth')
    const result = await loginApi(data)
    setTokens(result)
  }

  function logout(): void {
    accessToken.value = ''
    refreshToken.value = ''
    userInfo.value = null
    localStorage.removeItem('ljwx_access_token')
    localStorage.removeItem('ljwx_refresh_token')
  }

  async function refreshAccessToken(): Promise<void> {
    if (!refreshToken.value) {
      throw new Error('No refresh token available')
    }
    const { refreshTokenApi } = await import('@/api/auth')
    const result: TokenVO = await refreshTokenApi(refreshToken.value)
    accessToken.value = result.accessToken
    refreshToken.value = result.refreshToken
    localStorage.setItem('ljwx_access_token', result.accessToken)
    localStorage.setItem('ljwx_refresh_token', result.refreshToken)
  }

  function hasAuthority(authority: string): boolean {
    return userInfo.value?.authorities?.includes(authority) ?? false
  }

  return {
    accessToken,
    refreshToken,
    userInfo,
    login,
    logout,
    refreshAccessToken,
    hasAuthority,
  }
})
