<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useUserStore } from '@/stores/user'

interface WorkItem {
  id: number
  icon: string
  title: string
  desc: string
}

const userStore = useUserStore()
const loading = ref(false)

const workItems = ref<WorkItem[]>([
  { id: 1, icon: '📋', title: '待办任务', desc: '查看待处理事项' },
  { id: 2, icon: '📊', title: '数据报表', desc: '查看业务统计' },
  { id: 3, icon: '🔔', title: '消息通知', desc: '查看系统通知' },
  { id: 4, icon: '⚙️', title: '系统设置', desc: '管理系统配置' },
  { id: 5, icon: '👥', title: '用户管理', desc: '管理系统用户' },
  { id: 6, icon: '🔐', title: '权限管理', desc: '管理角色权限' },
])

onMounted(() => {
  loading.value = true
  setTimeout(() => {
    loading.value = false
  }, 300)
})

function handleItemTap(item: WorkItem): void {
  uni.showToast({ title: item.title, icon: 'none' })
}
</script>

<template>
  <view class="work-page">
    <view class="header">
      <text class="header-title">工作台</text>
      <text class="header-sub">{{ userStore.userInfo?.nickname || '用户' }}，欢迎使用</text>
    </view>

    <view class="grid" :class="{ 'grid--loading': loading }">
      <view
        v-for="item in workItems"
        :key="item.id"
        class="grid-item"
        @tap="handleItemTap(item)"
      >
        <text class="item-icon">{{ item.icon }}</text>
        <text class="item-title">{{ item.title }}</text>
        <text class="item-desc">{{ item.desc }}</text>
      </view>
    </view>
  </view>
</template>

<style scoped lang="scss">
.work-page {
  min-height: 100vh;
  background: #f5f5f5;
}

.header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 60rpx 40rpx 40rpx;

  .header-title {
    display: block;
    font-size: 44rpx;
    font-weight: bold;
    color: #ffffff;
    margin-bottom: 8rpx;
  }

  .header-sub {
    font-size: 26rpx;
    color: rgba(255, 255, 255, 0.8);
  }
}

.grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24rpx;
  padding: 30rpx;
}

.grid-item {
  background: #ffffff;
  border-radius: 16rpx;
  padding: 40rpx 24rpx;
  display: flex;
  flex-direction: column;
  align-items: center;
  box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.06);

  .item-icon {
    font-size: 60rpx;
    margin-bottom: 16rpx;
  }

  .item-title {
    font-size: 30rpx;
    font-weight: 600;
    color: #333333;
    margin-bottom: 8rpx;
  }

  .item-desc {
    font-size: 22rpx;
    color: #999999;
    text-align: center;
  }
}
</style>
