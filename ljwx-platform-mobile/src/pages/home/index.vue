<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()
const greeting = ref('')

onMounted(() => {
  const hour = new Date().getHours()
  if (hour < 12) {
    greeting.value = '早上好'
  } else if (hour < 18) {
    greeting.value = '下午好'
  } else {
    greeting.value = '晚上好'
  }
})

function handleLogout(): void {
  uni.showModal({
    title: '提示',
    content: '确定要退出登录吗？',
    success: (res) => {
      if (res.confirm) {
        userStore.logout()
        uni.reLaunch({ url: '/pages/login/index' })
      }
    },
  })
}
</script>

<template>
  <view class="home-page">
    <view class="header">
      <view class="header-content">
        <view class="greeting">
          <text class="greeting-text">{{ greeting }}，</text>
          <text class="username">{{ userStore.userInfo?.nickname || '用户' }}</text>
        </view>
        <button class="logout-btn" size="mini" @tap="handleLogout">退出</button>
      </view>
    </view>

    <view class="content">
      <view class="card-grid">
        <view class="card">
          <text class="card-icon">👥</text>
          <text class="card-title">用户管理</text>
        </view>
        <view class="card">
          <text class="card-icon">🔐</text>
          <text class="card-title">权限管理</text>
        </view>
        <view class="card">
          <text class="card-icon">📋</text>
          <text class="card-title">系统日志</text>
        </view>
        <view class="card">
          <text class="card-icon">⚙️</text>
          <text class="card-title">系统配置</text>
        </view>
      </view>
    </view>
  </view>
</template>

<style scoped lang="scss">
.home-page {
  min-height: 100vh;
  background: #f5f5f5;
}

.header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 60rpx 40rpx 40rpx;

  .header-content {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .greeting {
    display: flex;
    align-items: center;

    .greeting-text {
      font-size: 32rpx;
      color: rgba(255, 255, 255, 0.9);
    }

    .username {
      font-size: 36rpx;
      font-weight: bold;
      color: #ffffff;
    }
  }

  .logout-btn {
    background: rgba(255, 255, 255, 0.2);
    color: #ffffff;
    border: 2rpx solid rgba(255, 255, 255, 0.5);
    border-radius: 30rpx;
    font-size: 24rpx;
  }
}

.content {
  padding: 30rpx;
}

.card-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24rpx;
}

.card {
  background: #ffffff;
  border-radius: 16rpx;
  padding: 40rpx 30rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.06);

  .card-icon {
    font-size: 60rpx;
    margin-bottom: 16rpx;
  }

  .card-title {
    font-size: 28rpx;
    color: #333333;
    font-weight: 500;
  }
}
</style>
