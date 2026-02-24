<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { getScreenOverview, getScreenRealtime, getScreenTrend } from '@/api/screen'
import type { ScreenOverviewVO, ScreenRealtimeVO, ScreenTrendVO } from '@ljwx/shared'
import BarChart from '@/components/charts/BarChart.vue'
import LineChart from '@/components/charts/LineChart.vue'
import PieChart from '@/components/charts/PieChart.vue'
import GaugeChart from '@/components/charts/GaugeChart.vue'
import RingChart from '@/components/charts/RingChart.vue'
import NumberFlip from '@/components/widgets/NumberFlip.vue'
import ScrollTable from '@/components/widgets/ScrollTable.vue'

const overview = ref<ScreenOverviewVO | null>(null)
const realtime = ref<ScreenRealtimeVO | null>(null)
const trend = ref<ScreenTrendVO | null>(null)
const loading = ref(false)

let realtimeTimer: ReturnType<typeof setInterval> | null = null

// ── Derived chart data ──────────────────────────────────────────────────────

const trendXData = ref<string[]>([])
const userTrendData = ref<number[]>([])
const loginTrendData = ref<number[]>([])

const roleDistData = ref([
  { name: '管理员', value: 12 },
  { name: '普通用户', value: 88 },
  { name: '访客', value: 24 },
])

const tenantBarData = ref({
  xData: ['租户A', '租户B', '租户C', '租户D', '租户E'],
  series: [{ name: '用户数', data: [120, 85, 200, 60, 145] }],
})

const scrollColumns = [
  { key: 'username', label: '用户名', width: '120px' },
  { key: 'action', label: '操作', width: '100px' },
  { key: 'time', label: '时间' },
]

const scrollData = ref([
  { username: 'admin', action: '登录', time: '10:01:23' },
  { username: 'user01', action: '查询', time: '10:02:11' },
  { username: 'user02', action: '新增', time: '10:03:05' },
  { username: 'user03', action: '修改', time: '10:04:44' },
  { username: 'user04', action: '删除', time: '10:05:30' },
  { username: 'user05', action: '导出', time: '10:06:18' },
  { username: 'user06', action: '登录', time: '10:07:02' },
])

// ── Data fetching ───────────────────────────────────────────────────────────

async function fetchOverview() {
  loading.value = true
  try {
    overview.value = await getScreenOverview()
  } finally {
    loading.value = false
  }
}

async function fetchRealtime() {
  try {
    realtime.value = await getScreenRealtime()
  } catch {
    // silently ignore polling errors
  }
}

async function fetchTrend() {
  try {
    trend.value = await getScreenTrend()
    if (trend.value) {
      trendXData.value = trend.value.userTrend.map((t) => t.date)
      userTrendData.value = trend.value.userTrend.map((t) => t.value)
      loginTrendData.value = trend.value.loginTrend.map((t) => t.value)
    }
  } catch {
    // silently ignore
  }
}

onMounted(async () => {
  await Promise.all([fetchOverview(), fetchRealtime(), fetchTrend()])
  realtimeTimer = setInterval(fetchRealtime, 5000)
})

onUnmounted(() => {
  if (realtimeTimer !== null) {
    clearInterval(realtimeTimer)
  }
})
</script>

<template>
  <div class="home-view" v-loading="loading">
    <!-- Header -->
    <header class="screen-header">
      <dv-decoration-8 class="header-deco header-deco--left" />
      <div class="header-center">
        <dv-decoration-5 class="header-deco-top" />
        <h1 class="screen-title">LJWX 数据大屏</h1>
      </div>
      <dv-decoration-8 class="header-deco header-deco--right" :reverse="true" />
    </header>

    <!-- Main grid -->
    <main class="screen-main">
      <!-- Left column -->
      <section class="col col--left">
        <!-- KPI cards -->
        <dv-border-box-11 title="核心指标" class="panel">
          <div class="kpi-grid">
            <NumberFlip
              :value="overview?.totalUsers ?? 0"
              label="用户总数"
              color="#00d4ff"
            />
            <NumberFlip
              :value="overview?.todayUsers ?? 0"
              label="今日新增"
              color="#00ff88"
            />
            <NumberFlip
              :value="overview?.totalTenants ?? 0"
              label="租户总数"
              color="#ffaa00"
            />
            <NumberFlip
              :value="overview?.todayLoginCount ?? 0"
              label="今日登录"
              color="#aa44ff"
            />
          </div>
        </dv-border-box-11>

        <!-- Tenant bar chart -->
        <dv-border-box-8 class="panel">
          <div class="panel-title">租户用户分布</div>
          <BarChart
            :x-data="tenantBarData.xData"
            :series="tenantBarData.series"
            height="200px"
          />
        </dv-border-box-8>

        <!-- Role ring chart -->
        <dv-border-box-8 class="panel">
          <div class="panel-title">角色分布</div>
          <RingChart :data="roleDistData" center-text="角色" height="200px" />
        </dv-border-box-8>
      </section>

      <!-- Center column -->
      <section class="col col--center">
        <!-- Realtime metrics -->
        <div class="realtime-row">
          <dv-border-box-12 class="realtime-card">
            <div class="realtime-label">在线用户</div>
            <div class="realtime-value realtime-value--cyan">
              {{ realtime?.onlineUsers ?? 0 }}
            </div>
          </dv-border-box-12>
          <dv-border-box-12 class="realtime-card">
            <div class="realtime-label">实时 QPS</div>
            <div class="realtime-value realtime-value--green">
              {{ realtime?.qps ?? 0 }}
            </div>
          </dv-border-box-12>
          <dv-border-box-12 class="realtime-card">
            <div class="realtime-label">CPU 使用率</div>
            <div class="realtime-value realtime-value--orange">
              {{ realtime?.cpuUsage ?? 0 }}%
            </div>
          </dv-border-box-12>
          <dv-border-box-12 class="realtime-card">
            <div class="realtime-label">内存使用率</div>
            <div class="realtime-value realtime-value--purple">
              {{ realtime?.memoryUsage ?? 0 }}%
            </div>
          </dv-border-box-12>
        </div>

        <!-- Trend line chart -->
        <dv-border-box-8 class="panel panel--tall">
          <div class="panel-title">近 7 天趋势</div>
          <LineChart
            :x-data="trendXData"
            :series="[
              { name: '新增用户', data: userTrendData },
              { name: '登录次数', data: loginTrendData },
            ]"
            height="240px"
          />
        </dv-border-box-8>

        <!-- Gauge row -->
        <div class="gauge-row">
          <dv-border-box-8 class="panel panel--gauge">
            <GaugeChart
              title="CPU"
              :value="realtime?.cpuUsage ?? 0"
              unit="%"
              height="180px"
            />
          </dv-border-box-8>
          <dv-border-box-8 class="panel panel--gauge">
            <GaugeChart
              title="内存"
              :value="realtime?.memoryUsage ?? 0"
              unit="%"
              height="180px"
            />
          </dv-border-box-8>
        </div>
      </section>

      <!-- Right column -->
      <section class="col col--right">
        <!-- Pie chart -->
        <dv-border-box-8 class="panel">
          <div class="panel-title">用户状态分布</div>
          <PieChart
            :data="[
              { name: '活跃', value: 68 },
              { name: '非活跃', value: 22 },
              { name: '禁用', value: 10 },
            ]"
            height="200px"
          />
        </dv-border-box-8>

        <!-- Scroll table -->
        <dv-border-box-11 title="操作日志" class="panel panel--scroll">
          <ScrollTable
            :columns="scrollColumns"
            :data="scrollData"
            :visible-rows="6"
            :interval="2500"
          />
        </dv-border-box-11>

        <!-- Decoration -->
        <dv-border-box-8 class="panel">
          <div class="panel-title">系统状态</div>
          <dv-active-ring-chart
            :config="{
              data: [
                { name: '正常', value: 95 },
                { name: '警告', value: 4 },
                { name: '异常', value: 1 },
              ],
              radius: '60%',
            }"
            style="height: 180px"
          />
        </dv-border-box-8>
      </section>
    </main>

    <!-- Footer decoration -->
    <footer class="screen-footer">
      <dv-decoration-3 style="width: 200px; height: 30px" />
      <dv-decoration-4 style="width: 200px; height: 30px" />
      <dv-decoration-3 style="width: 200px; height: 30px" />
    </footer>
  </div>
</template>

<style scoped lang="scss">
.home-view {
  width: 1920px;
  height: 1080px;
  display: flex;
  flex-direction: column;
  background: #0a0e1a;
  color: #c0caf5;
  padding: 16px;
  box-sizing: border-box;
  overflow: hidden;
}

// ── Header ──────────────────────────────────────────────────────────────────
.screen-header {
  display: flex;
  align-items: center;
  height: 80px;
  flex-shrink: 0;
}

.header-deco {
  flex: 1;
  height: 60px;
}

.header-center {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex-shrink: 0;
  width: 600px;
}

.header-deco-top {
  width: 100%;
  height: 20px;
}

.screen-title {
  font-size: 28px;
  font-weight: 700;
  color: #00d4ff;
  letter-spacing: 6px;
  text-shadow: 0 0 20px rgba(0, 212, 255, 0.6);
  margin: 0;
}

// ── Main grid ────────────────────────────────────────────────────────────────
.screen-main {
  flex: 1;
  display: grid;
  grid-template-columns: 380px 1fr 380px;
  gap: 12px;
  min-height: 0;
}

.col {
  display: flex;
  flex-direction: column;
  gap: 12px;
  min-height: 0;
}

// ── Panels ───────────────────────────────────────────────────────────────────
.panel {
  flex: 1;
  padding: 12px;
  min-height: 0;

  &--tall {
    flex: 2;
  }

  &--gauge {
    flex: none;
  }

  &--scroll {
    flex: 2;
  }
}

.panel-title {
  font-size: 13px;
  color: #7a8ab8;
  margin-bottom: 8px;
  padding-left: 4px;
  border-left: 2px solid #00d4ff;
}

// ── KPI grid ─────────────────────────────────────────────────────────────────
.kpi-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  padding: 8px;
}

// ── Realtime row ─────────────────────────────────────────────────────────────
.realtime-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
  flex-shrink: 0;
}

.realtime-card {
  padding: 12px;
  text-align: center;
}

.realtime-label {
  font-size: 12px;
  color: #7a8ab8;
  margin-bottom: 6px;
}

.realtime-value {
  font-size: 24px;
  font-weight: 700;

  &--cyan { color: #00d4ff; text-shadow: 0 0 10px rgba(0, 212, 255, 0.5); }
  &--green { color: #00ff88; text-shadow: 0 0 10px rgba(0, 255, 136, 0.5); }
  &--orange { color: #ffaa00; text-shadow: 0 0 10px rgba(255, 170, 0, 0.5); }
  &--purple { color: #aa44ff; text-shadow: 0 0 10px rgba(170, 68, 255, 0.5); }
}

// ── Gauge row ────────────────────────────────────────────────────────────────
.gauge-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
  flex-shrink: 0;
}

// ── Footer ───────────────────────────────────────────────────────────────────
.screen-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 36px;
  flex-shrink: 0;
  padding: 0 40px;
}
</style>

