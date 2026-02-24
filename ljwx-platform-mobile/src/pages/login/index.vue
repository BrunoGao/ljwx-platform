<script setup lang="ts">
import { ref, reactive } from 'vue'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()

const loading = ref(false)
const form = reactive({
  username: '',
  password: '',
})

const rules = {
  username: [{ required: true, message: '请输入用户名' }],
  password: [{ required: true, message: '请输入密码' }],
}

async function handleLogin(): Promise<void> {
  if (!form.username.trim()) {
    uni.showToast({ title: '请输入用户名', icon: 'none' })
    return
  }
  if (!form.password.trim()) {
    uni.showToast({ title: '请输入密码', icon: 'none' })
    return
  }

  loading.value = true
  try {
    await userStore.doLogin({ username: form.username, password: form.password })
    uni.switchTab({ url: '/pages/home/index' })
  } catch {
    // error handled by request interceptor
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <view class="login-page">
    <view class="login-header">
      <image class="logo" src="/static/logo.png" mode="aspectFit" />
      <text class="title">LJWX Platform</text>
      <text class="subtitle">企业级管理平台</text>
    </view>

    <view class="login-form">
      <view class="form-item">
        <text class="label">用户名</text>
        <input
          v-model="form.username"
          class="input"
          type="text"
          placeholder="请输入用户名"
          :disabled="loading"
        />
      </view>

      <view class="form-item">
        <text class="label">密码</text>
        <input
          v-model="form.password"
          class="input"
          type="password"
          placeholder="请输入密码"
          :disabled="loading"
        />
      </view>

      <button
        class="login-btn"
        :loading="loading"
        :disabled="loading"
        @tap="handleLogin"
      >
        {{ loading ? '登录中...' : '登录' }}
      </button>
    </view>
  </view>
</template>

<style scoped lang="scss">
.login-page {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 40rpx;
}

.login-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 60rpx;

  .logo {
    width: 120rpx;
    height: 120rpx;
    margin-bottom: 20rpx;
  }

  .title {
    font-size: 48rpx;
    font-weight: bold;
    color: #ffffff;
    margin-bottom: 10rpx;
  }

  .subtitle {
    font-size: 28rpx;
    color: rgba(255, 255, 255, 0.8);
  }
}

.login-form {
  width: 100%;
  background: #ffffff;
  border-radius: 20rpx;
  padding: 50rpx 40rpx;
  box-shadow: 0 20rpx 60rpx rgba(0, 0, 0, 0.15);

  .form-item {
    margin-bottom: 30rpx;

    .label {
      display: block;
      font-size: 28rpx;
      color: #333333;
      margin-bottom: 12rpx;
      font-weight: 500;
    }

    .input {
      width: 100%;
      height: 88rpx;
      border: 2rpx solid #e0e0e0;
      border-radius: 10rpx;
      padding: 0 24rpx;
      font-size: 30rpx;
      color: #333333;
      background: #fafafa;
      box-sizing: border-box;
    }
  }

  .login-btn {
    width: 100%;
    height: 96rpx;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: #ffffff;
    font-size: 34rpx;
    font-weight: bold;
    border-radius: 48rpx;
    border: none;
    margin-top: 20rpx;
    letter-spacing: 4rpx;
  }
}
</style>
