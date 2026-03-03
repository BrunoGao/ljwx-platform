interface ApiResult<T = unknown> {
  code: number
  message: string
  data: T
}

const BASE_URL = import.meta.env.VITE_APP_BASE_API || '/api'

function request<T>(options: UniApp.RequestOptions): Promise<T> {
  const token = uni.getStorageSync('token')
  const tenantId = uni.getStorageSync('tenantId')

  return new Promise((resolve, reject) => {
    uni.request({
      ...options,
      url: `${BASE_URL}${options.url}`,
      header: {
        Authorization: token ? `Bearer ${token}` : '',
        'X-Tenant-Id': tenantId || '',
        'Content-Type': 'application/json',
        ...options.header,
      },
      success: (res) => {
        const data = res.data as ApiResult<T>
        if (data.code === 200) {
          resolve(data.data)
        } else if (data.code === 401) {
          uni.removeStorageSync('token')
          uni.removeStorageSync('tenantId')
          uni.redirectTo({ url: '/pages/login/index' })
          reject(new Error('UNAUTHORIZED'))
        } else {
          uni.showToast({ title: data.message || '请求失败', icon: 'none' })
          reject(new Error(data.message))
        }
      },
      fail: (err) => {
        uni.showToast({ title: '网络错误', icon: 'none' })
        reject(err)
      },
    })
  })
}

export default request
