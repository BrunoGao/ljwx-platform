<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { getServerInfo, getJvmInfo, getCacheStats } from '@/api/monitor'
import type { ServerInfoVO, JvmInfoVO, CacheStatsVO } from '@/api/monitor'
import { ElMessage } from 'element-plus'

const loading = ref(false)
const serverInfo = ref<ServerInfoVO | null>(null)
const jvmInfo = ref<JvmInfoVO | null>(null)
const cacheStats = ref<CacheStatsVO[]>([])

let refreshTimer: ReturnType<typeof setInterval> | null = null

async function fetchAll(): Promise<void> {
  loading.value = true
  try {
    const [server, jvm, cache] = await Promise.all([
      getServerInfo(),
      getJvmInfo(),
      getCacheStats(),
    ])
    serverInfo.value = server
    jvmInfo.value = jvm
    cacheStats.value = cache
  } catch {
    ElMessage.error('获取监控数据失败')
  } finally {
    loading.value = false
  }
}

function formatBytes(mb: number): string {
  if (mb >= 1024) return `${(mb / 1024).toFixed(1)} GB`
  return `${mb.toFixed(0)} MB`
}

function formatUptime(ms: number): string {
  const s = Math.floor(ms / 1000)
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  return `${h}h ${m}m`
}

function progressStatus(usage: number): '' | 'warning' | 'exception' {
  if (usage >= 90) return 'exception'
  if (usage >= 70) return 'warning'
  return ''
}

onMounted(() => {
  fetchAll()
  refreshTimer = setInterval(fetchAll, 30000)
})

onUnmounted(() => {
  if (refreshTimer !== null) {
    clearInterval(refreshTimer)
  }
})
</script>

<template>
  <div v-loading="loading" class="monitor-page">
    <div class="page-header">
      <span class="title">服务器监控</span>
      <el-button type="primary" size="small" @click="fetchAll">刷新</el-button>
    </div>

    <!-- Server Info -->
    <el-row :gutter="16" class="section">
      <el-col :span="24">
        <el-card header="服务器信息">
          <el-descriptions v-if="serverInfo" :column="3" border>
            <el-descriptions-item label="主机名">{{ serverInfo.hostname }}</el-descriptions-item>
            <el-descriptions-item label="操作系统">{{ serverInfo.osName }}</el-descriptions-item>
            <el-descriptions-item label="架构">{{ serverInfo.osArch }}</el-descriptions-item>
            <el-descriptions-item label="CPU 核数">{{ serverInfo.cpuCores }}</el-descriptions-item>
            <el-descriptions-item label="内存总量">{{ formatBytes(serverInfo.memTotal) }}</el-descriptions-item>
            <el-descriptions-item label="磁盘总量">{{ formatBytes(serverInfo.diskTotal) }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
    </el-row>

    <!-- Usage Gauges -->
    <el-row :gutter="16" class="section">
      <el-col :xs="24" :sm="8">
        <el-card header="CPU 使用率">
          <div class="gauge-wrap">
            <el-progress
              v-if="serverInfo"
              type="dashboard"
              :percentage="Math.round(serverInfo.cpuUsage)"
              :status="progressStatus(serverInfo.cpuUsage)"
            />
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="8">
        <el-card header="内存使用率">
          <div class="gauge-wrap">
            <el-progress
              v-if="serverInfo"
              type="dashboard"
              :percentage="Math.round(serverInfo.memUsage)"
              :status="progressStatus(serverInfo.memUsage)"
            />
            <div v-if="serverInfo" class="gauge-label">
              {{ formatBytes(serverInfo.memUsed) }} / {{ formatBytes(serverInfo.memTotal) }}
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="8">
        <el-card header="磁盘使用率">
          <div class="gauge-wrap">
            <el-progress
              v-if="serverInfo"
              type="dashboard"
              :percentage="Math.round(serverInfo.diskUsage)"
              :status="progressStatus(serverInfo.diskUsage)"
            />
            <div v-if="serverInfo" class="gauge-label">
              {{ formatBytes(serverInfo.diskUsed) }} / {{ formatBytes(serverInfo.diskTotal) }}
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- JVM Info -->
    <el-row :gutter="16" class="section">
      <el-col :xs="24" :sm="12">
        <el-card header="JVM 堆内存">
          <div class="gauge-wrap">
            <el-progress
              v-if="jvmInfo"
              type="dashboard"
              :percentage="Math.round(jvmInfo.heapUsage)"
              :status="progressStatus(jvmInfo.heapUsage)"
            />
            <div v-if="jvmInfo" class="gauge-label">
              {{ formatBytes(jvmInfo.heapUsed) }} / {{ formatBytes(jvmInfo.heapMax) }}
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :xs="24" :sm="12">
        <el-card header="JVM 信息">
          <el-descriptions v-if="jvmInfo" :column="2" border>
            <el-descriptions-item label="JVM 版本">{{ jvmInfo.jvmVersion }}</el-descriptions-item>
            <el-descriptions-item label="运行时长">{{ formatUptime(jvmInfo.uptime) }}</el-descriptions-item>
            <el-descriptions-item label="GC 次数">{{ jvmInfo.gcCount }}</el-descriptions-item>
            <el-descriptions-item label="GC 耗时">{{ jvmInfo.gcTime }} ms</el-descriptions-item>
            <el-descriptions-item label="非堆内存">{{ formatBytes(jvmInfo.nonHeapUsed) }}</el-descriptions-item>
            <el-descriptions-item label="启动时间">{{ jvmInfo.startTime }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
    </el-row>

    <!-- Cache Stats -->
    <el-row :gutter="16" class="section">
      <el-col :span="24">
        <el-card header="缓存统计">
          <el-table :data="cacheStats" border stripe>
            <el-table-column prop="cacheName" label="缓存名称" />
            <el-table-column prop="size" label="缓存大小" width="100" />
            <el-table-column prop="hitCount" label="命中次数" width="110" />
            <el-table-column prop="missCount" label="未命中次数" width="120" />
            <el-table-column label="命中率" width="120">
              <template #default="{ row }">
                <el-progress
                  :percentage="Math.round((row as CacheStatsVO).hitRate * 100)"
                  :stroke-width="8"
                />
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<style scoped lang="scss">
.monitor-page {
  padding: 16px;
}

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;

  .title {
    font-size: 18px;
    font-weight: 600;
  }
}

.section {
  margin-bottom: 16px;
}

.gauge-wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 8px 0;
}

.gauge-label {
  margin-top: 8px;
  font-size: 13px;
  color: var(--el-text-color-secondary);
}
</style>
