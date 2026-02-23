<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import type { Component } from 'vue'
import { View, User, Timer, Warning } from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'
import dayjs from 'dayjs'

const userStore = useUserStore()
const currentTime = ref<string>('')

function updateTime(): void {
  currentTime.value = dayjs().format('YYYY-MM-DD HH:mm:ss')
}

let timer: ReturnType<typeof setInterval> | null = null

onMounted(() => {
  updateTime()
  timer = setInterval(updateTime, 1000)
})

onUnmounted(() => {
  if (timer !== null) {
    clearInterval(timer)
    timer = null
  }
})

interface StatItem {
  label: string
  value: string
  icon: Component
  color: string
}

const stats = ref<StatItem[]>([
  { label: '今日访问', value: '0', icon: View, color: '#1890ff' },
  { label: '在线用户', value: '0', icon: User, color: '#52c41a' },
  { label: '系统任务', value: '0', icon: Timer, color: '#faad14' },
  { label: '异常告警', value: '0', icon: Warning, color: '#ff4d4f' },
])
</script>

<template>
  <div class="dashboard-container">
    <div class="dashboard-header">
      <div class="welcome-section">
        <h2 class="welcome-title">
          欢迎回来，{{ userStore.userInfo?.nickname ?? userStore.userInfo?.username ?? '用户' }}！
        </h2>
        <p class="welcome-time">{{ currentTime }}</p>
      </div>
    </div>

    <el-row :gutter="16" class="stat-cards">
      <el-col
        v-for="stat in stats"
        :key="stat.label"
        :xs="24"
        :sm="12"
        :lg="6"
      >
        <el-card class="stat-card" shadow="hover">
          <div class="stat-content">
            <div class="stat-icon" :style="{ backgroundColor: stat.color + '1a' }">
              <el-icon :size="28" :style="{ color: stat.color }">
                <component :is="stat.icon" />
              </el-icon>
            </div>
            <div class="stat-info">
              <div class="stat-value">{{ stat.value }}</div>
              <div class="stat-label">{{ stat.label }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-card class="system-info" shadow="never">
      <template #header>
        <span>系统信息</span>
      </template>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="系统名称">LJWX Platform</el-descriptions-item>
        <el-descriptions-item label="版本">1.0.0</el-descriptions-item>
        <el-descriptions-item label="技术栈">Vue 3 + Element Plus</el-descriptions-item>
        <el-descriptions-item label="后端">Java 21 + Spring Boot 3.5</el-descriptions-item>
      </el-descriptions>
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.dashboard-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.dashboard-header {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 8px;
  padding: 24px;
  color: #fff;
}

.welcome-title {
  font-size: 20px;
  font-weight: 600;
  margin: 0 0 8px;
}

.welcome-time {
  font-size: 14px;
  opacity: 0.85;
  margin: 0;
}

.stat-cards {
  margin-top: 0;
}

.stat-card {
  cursor: default;
  transition: transform 0.2s;

  &:hover {
    transform: translateY(-2px);
  }
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.stat-icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: #1a1a2e;
  line-height: 1;
  margin-bottom: 4px;
}

.stat-label {
  font-size: 13px;
  color: #8c8c8c;
}

.system-info {
  :deep(.el-card__header) {
    font-weight: 600;
    color: #434343;
  }
}
</style>
