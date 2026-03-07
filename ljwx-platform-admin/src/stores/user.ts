import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { UserInfo, LoginDTO, LoginVO, TokenVO } from '@ljwx/shared'

const ACCESS_TOKEN_STORAGE_KEY = 'ljwx_access_token'
const REFRESH_TOKEN_STORAGE_KEY = 'ljwx_refresh_token'

function normalizeStoredToken(value: string | null): string {
  if (value === null || value === 'undefined' || value === 'null') {
    return ''
  }
  return value
}

function clearPersistedTokens(): void {
  localStorage.removeItem(ACCESS_TOKEN_STORAGE_KEY)
  localStorage.removeItem(REFRESH_TOKEN_STORAGE_KEY)
}

function readPersistedTokens(): { accessToken: string; refreshToken: string } {
  const accessToken = normalizeStoredToken(localStorage.getItem(ACCESS_TOKEN_STORAGE_KEY))
  const refreshToken = normalizeStoredToken(localStorage.getItem(REFRESH_TOKEN_STORAGE_KEY))

  // Drop partially persisted auth state to avoid unusable refresh flows.
  if (Boolean(accessToken) !== Boolean(refreshToken)) {
    clearPersistedTokens()
    return {
      accessToken: '',
      refreshToken: '',
    }
  }

  return {
    accessToken,
    refreshToken,
  }
}

export const useUserStore = defineStore('user', () => {
  const persistedTokens = readPersistedTokens()
  const accessToken = ref<string>(persistedTokens.accessToken)
  const refreshToken = ref<string>(persistedTokens.refreshToken)
  const userInfo = ref<UserInfo | null>(null)

  function persistTokens(data: Pick<TokenVO, 'accessToken' | 'refreshToken'>): void {
    accessToken.value = data.accessToken
    refreshToken.value = data.refreshToken
    localStorage.setItem(ACCESS_TOKEN_STORAGE_KEY, data.accessToken)
    localStorage.setItem(REFRESH_TOKEN_STORAGE_KEY, data.refreshToken)
  }

  function setTokens(data: LoginVO): void {
    if (!data.accessToken || !data.refreshToken) {
      logout()
      throw new Error('登录响应缺少完整令牌，请联系管理员')
    }

    persistTokens(data)
    userInfo.value = data.userInfo
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
    clearPersistedTokens()
  }

  async function refreshAccessToken(): Promise<void> {
    if (!refreshToken.value) {
      logout()
      throw new Error('登录状态已失效，请重新登录')
    }

    const { refreshTokenApi } = await import('@/api/auth')
    const result: TokenVO = await refreshTokenApi(refreshToken.value)
    if (!result.accessToken || !result.refreshToken) {
      logout()
      throw new Error('登录状态刷新失败，请重新登录')
    }

    persistTokens(result)
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
