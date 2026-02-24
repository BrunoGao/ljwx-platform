<script setup lang="ts">
import { onMounted } from 'vue'
import { useUserStore } from '@/stores/user'
import { getUserProfile } from '@/api/user'

const userStore = useUserStore()

onMounted(async () => {
  try {
    const res = await getUserProfile()
    if (res.data) {
      userStore.userInfo = {
        userId: res.data.id,
        username: res.data.username,
        nickname: res.data.nickname,
        avatar: res.data.avatar,
      }
    }
  } catch {
    // profile load failure is non-critical
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
  <view class="mine-page">
    <view class="profile">
      <view class="avatar-wrap">
        <image class="avatar" src="/static/avatar.png" mode="aspectFill" />
      </view>
      <text class="nickname">{{ userStore.userInfo?.nickname || '未登录' }}</text>
      <text class="username">@{{ userStore.userInfo?.username || '' }}</text>
    </view>

    <view class="menu-list">
      <view class="menu-item">
        <text class="menu-label">个人信息</text>
        <text class="menu-arrow">›</text>
      </view>
      <view class="menu-item">
        <text class="menu-label">修改密码</text>
        <text class="menu-arrow">›</text>
      </view>
      <view class="menu-item">
        <text class="menu-label">关于</text>
        <text class="menu-arrow">›</text>
      </view>
    </view>

    <button class="logout-btn" @tap="handleLogout">退出登录</button>
  </view>
</template>

<style scoped lang="scss">
.mine-page {
  min-height: 100vh;
  background: #f5f5f5;
}

.profile {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 60rpx 40rpx 50rpx;
  display: flex;
  flex-direction: column;
  align-items: center;

  .avatar-wrap {
    width: 140rpx;
    height: 140rpx;
    border-radius: 50%;
    overflow: hidden;
    border: 4rpx solid rgba(255, 255, 255, 0.5);
    margin-bottom: 20rpx;
  }

  .avatar {
    width: 100%;
    height: 100%;
  }

  .nickname {
    font-size: 36rpx;
    font-weight: bold;
    color: #ffffff;
    margin-bottom: 8rpx;
  }

  .username {
    font-size: 26rpx;
    color: rgba(255, 255, 255, 0.8);
  }
}

.menu-list {
  background: #ffffff;
  margin: 30rpx;
  border-radius: 16rpx;
  overflow: hidden;
  box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.06);
}

.menu-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 36rpx 40rpx;
  border-bottom: 1rpx solid #f0f0f0;

  &:last-child {
    border-bottom: none;
  }

  .menu-label {
    font-size: 30rpx;
    color: #333333;
  }

  .menu-arrow {
    font-size: 36rpx;
    color: #cccccc;
  }
}

.logout-btn {
  margin: 0 30rpx;
  background: #ffffff;
  color: #ff4d4f;
  border: 2rpx solid #ff4d4f;
  border-radius: 16rpx;
  font-size: 30rpx;
  height: 88rpx;
}
</style>
