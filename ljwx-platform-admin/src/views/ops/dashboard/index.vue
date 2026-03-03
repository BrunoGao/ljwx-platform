<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getOperationsDashboard, type OperationsDashboardVO } from '@/api/ops/dashboard'
import { useI18n } from 'vue-i18n'
import dayjs from 'dayjs'
import * as echarts from 'echarts'
import type { EChartsOption } from 'echarts'

const { t } = useI18n()
const loading = ref(false)
const dashboard = ref<OperationsDashboardVO | null>(null)
const chartRef = ref<HTMLDivElement>()
let chartInstance: echarts.ECharts | null = null

const loadDashboard = async () => {
  loading.value = true
  try {
    dashboard.value = await getOperationsDashboard()
    if (dashboard.value) {
      renderChart()
    }
  } catch (error) {
    console.error('Failed to load dashboard:', error)
  } finally {
    loading.value = false
  }
}

const renderChart = () => {
  if (!chartRef.value || !dashboard.value) return

  if (!chartInstance) {
    chartInstance = echarts.init(chartRef.value)
  }

  const option: EChartsOption = {
    title: {
      text: t('ops.dauTrend'),
      left: 'center'
    },
    tooltip: {
      trigger: 'axis'
    },
    xAxis: {
      type: 'category',
      data: dashboard.value.dailyActiveUsers.map(item => dayjs(item.date).format('MM-DD'))
    },
    yAxis: {
      type: 'value',
      name: t('ops.activeUsers')
    },
    series: [
      {
        name: t('ops.dau'),
        type: 'line',
        smooth: true,
        data: dashboard.value.dailyActiveUsers.map(item => item.count),
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(64, 158, 255, 0.3)' },
            { offset: 1, color: 'rgba(64, 158, 255, 0.05)' }
          ])
        }
      }
    ]
  }

  chartInstance.setOption(option)
}

onMounted(() => {
  loadDashboard()
  window.addEventListener('resize', () => {
    chartInstance?.resize()
  })
})
</script>

<template>
  <div v-loading="loading" class="ops-dashboard">
    <el-row :gutter="20" class="stats-row">
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-item">
            <div class="stat-label">{{ t('ops.totalTenants') }}</div>
            <div class="stat-value">{{ dashboard?.totalTenants || 0 }}</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-item">
            <div class="stat-label">{{ t('ops.activeTenants') }}</div>
            <div class="stat-value">{{ dashboard?.activeTenants || 0 }}</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-item">
            <div class="stat-label">{{ t('ops.totalStorage') }}</div>
            <div class="stat-value">{{ (dashboard?.totalStorageMb || 0).toFixed(2) }} MB</div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-item">
            <div class="stat-label">{{ t('ops.apiCallsToday') }}</div>
            <div class="stat-value">{{ dashboard?.totalApiCallsToday || 0 }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" class="content-row">
      <el-col :span="16">
        <el-card shadow="hover">
          <div ref="chartRef" class="chart-container" />
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="hover">
          <template #header>
            <div class="card-header">
              <span>{{ t('ops.expiringSoon') }}</span>
              <el-tag type="warning" size="small">
                {{ dashboard?.expiringSoon.length || 0 }}
              </el-tag>
            </div>
          </template>
          <el-scrollbar height="400px">
            <div v-if="dashboard?.expiringSoon.length" class="expiring-list">
              <div
                v-for="tenant in dashboard.expiringSoon"
                :key="tenant.tenantId"
                class="expiring-item"
              >
                <div class="tenant-name">{{ tenant.tenantName }}</div>
                <div class="expire-time">
                  {{ t('ops.expireTime') }}: {{ dayjs(tenant.expireTime).format('YYYY-MM-DD') }}
                </div>
                <div class="tenant-stats">
                  <el-tag size="small">{{ t('ops.users') }}: {{ tenant.userCount }}</el-tag>
                  <el-tag size="small" type="info">
                    {{ t('ops.storage') }}: {{ tenant.storageMb.toFixed(2) }} MB
                  </el-tag>
                </div>
              </div>
            </div>
            <el-empty v-else :description="t('ops.noExpiring')" />
          </el-scrollbar>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<style scoped lang="scss">
.ops-dashboard {
  padding: 20px;

  .stats-row {
    margin-bottom: 20px;
  }

  .stat-item {
    text-align: center;
    padding: 20px 0;

    .stat-label {
      font-size: 14px;
      color: #909399;
      margin-bottom: 12px;
    }

    .stat-value {
      font-size: 28px;
      font-weight: 600;
      color: #303133;
    }
  }

  .chart-container {
    width: 100%;
    height: 400px;
  }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .expiring-list {
    .expiring-item {
      padding: 16px;
      border-bottom: 1px solid #ebeef5;

      &:last-child {
        border-bottom: none;
      }

      .tenant-name {
        font-size: 16px;
        font-weight: 600;
        margin-bottom: 8px;
      }

      .expire-time {
        font-size: 14px;
        color: #909399;
        margin-bottom: 8px;
      }

      .tenant-stats {
        display: flex;
        gap: 8px;
      }
    }
  }
}
</style>
