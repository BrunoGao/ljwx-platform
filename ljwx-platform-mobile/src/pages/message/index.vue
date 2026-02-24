<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getNoticeList } from '@/api/notice'
import type { SysNoticeVO } from '@ljwx/shared'

const loading = ref(false)
const notices = ref<SysNoticeVO[]>([])
const hasMore = ref(true)
const page = ref(1)
const pageSize = 10

async function loadNotices(reset = false): Promise<void> {
  if (loading.value) return
  if (reset) {
    page.value = 1
    notices.value = []
    hasMore.value = true
  }
  loading.value = true
  try {
    const res = await getNoticeList({ pageNum: page.value, pageSize, status: 1 })
    const rows = res.data?.rows ?? []
    notices.value = reset ? rows : [...notices.value, ...rows]
    hasMore.value = rows.length === pageSize
    page.value += 1
  } catch {
    uni.showToast({ title: '加载失败', icon: 'none' })
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadNotices(true)
})

onPullDownRefresh(() => {
  loadNotices(true).then(() => {
    uni.stopPullDownRefresh()
  })
})

onReachBottom(() => {
  if (hasMore.value) {
    loadNotices()
  }
})

function getTypeLabel(type: number): string {
  return type === 1 ? '通知' : '公告'
}

function getTypeClass(type: number): string {
  return type === 1 ? 'tag-notice' : 'tag-announce'
}
</script>

<template>
  <view class="message-page">
    <view class="page-header">
      <text class="page-title">消息</text>
    </view>

    <view v-if="loading && notices.length === 0" class="loading-wrap">
      <text class="loading-text">加载中...</text>
    </view>

    <view v-else-if="notices.length === 0" class="empty-wrap">
      <text class="empty-icon">📭</text>
      <text class="empty-text">暂无消息</text>
    </view>

    <view v-else class="notice-list">
      <view
        v-for="item in notices"
        :key="item.id"
        class="notice-item"
      >
        <view class="notice-header">
          <text :class="['type-tag', getTypeClass(item.type)]">{{ getTypeLabel(item.type) }}</text>
          <text class="notice-time">{{ item.createdTime }}</text>
        </view>
        <text class="notice-title">{{ item.title }}</text>
        <text class="notice-content">{{ item.content }}</text>
      </view>

      <view v-if="!hasMore" class="no-more">
        <text class="no-more-text">没有更多了</text>
      </view>
    </view>
  </view>
</template>

<style scoped lang="scss">
.message-page {
  min-height: 100vh;
  background: #f5f5f5;
}

.page-header {
  background: #ffffff;
  padding: 50rpx 40rpx 30rpx;
  border-bottom: 1rpx solid #f0f0f0;

  .page-title {
    font-size: 40rpx;
    font-weight: bold;
    color: #333333;
  }
}

.loading-wrap,
.empty-wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 120rpx 0;

  .empty-icon {
    font-size: 100rpx;
    margin-bottom: 24rpx;
  }

  .empty-text,
  .loading-text {
    font-size: 28rpx;
    color: #999999;
  }
}

.notice-list {
  padding: 20rpx 30rpx;
}

.notice-item {
  background: #ffffff;
  border-radius: 16rpx;
  padding: 30rpx;
  margin-bottom: 20rpx;
  box-shadow: 0 4rpx 20rpx rgba(0, 0, 0, 0.06);

  .notice-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 16rpx;
  }

  .type-tag {
    font-size: 22rpx;
    padding: 4rpx 16rpx;
    border-radius: 20rpx;

    &.tag-notice {
      background: #e6f7ff;
      color: #1890ff;
    }

    &.tag-announce {
      background: #fff7e6;
      color: #fa8c16;
    }
  }

  .notice-time {
    font-size: 22rpx;
    color: #cccccc;
  }

  .notice-title {
    display: block;
    font-size: 30rpx;
    font-weight: 600;
    color: #333333;
    margin-bottom: 12rpx;
  }

  .notice-content {
    font-size: 26rpx;
    color: #666666;
    line-height: 1.6;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
}

.no-more {
  text-align: center;
  padding: 30rpx 0;

  .no-more-text {
    font-size: 24rpx;
    color: #cccccc;
  }
}
</style>
