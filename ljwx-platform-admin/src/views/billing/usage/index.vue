<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { getUsageRecords, type UsageRecordVO, type BillingQueryDTO } from '@/api/billing/billing'
import { useI18n } from 'vue-i18n'
import dayjs from 'dayjs'
import * as echarts from 'echarts'
import type { EChartsOption } from 'echarts'

const { t } = useI18n()
const loading = ref(false)
const usageRecords = ref<UsageRecordVO[]>([])
const chartRef = ref<HTMLDivElement>()
let chartInstance: echarts.ECharts | null = null

const queryForm = reactive<BillingQueryDTO>({
  startDate: dayjs().subtract(30, 'day').format('YYYY-MM-DD'),
  endDate: dayjs().format('YYYY-MM-DD'),
  metricType: ''
})

const metricTypes = [
  { label: t('billing.allMetrics'), value: '' },
  { label: t('billing.userCount'), value: 'USER_COUNT' },
  { label: t('billing.storageMb'), value: 'STORAGE_MB' },
  { label: t('billing.apiCalls'), value: 'API_CALLS' },
  { label: t('billing.loginCount'), value: 'LOGIN_COUNT' },
  { label: t('billing.fileCount'), value: 'FILE_COUNT' }
]

const loadUsageRecords = async () => {
  loading.value = true
  try {
    usageRecords.value = await getUsageRecords(queryForm)
    renderChart()
  } catch (error) {
    console.error('Failed to load usage records:', error)
  } finally {
    loading.value = false
  }
}

const renderChart = () => {
  if (!chartRef.value || !usageRecords.value.length) return

  if (!chartInstance) {
    chartInstance = echarts.init(chartRef.value)
  }

  const groupedData = usageRecords.value.reduce((acc, record) => {
    if (!acc[record.metricType]) {
      acc[record.metricType] = []
    }
    acc[record.metricType].push(record)
    return acc
  }, {} as Record<string, UsageRecordVO[]>)

  const dates = [...new Set(usageRecords.value.map(r => r.recordDate))].sort()

  const series = Object.entries(groupedData).map(([metricType, records]) => ({
    name: metricType,
    type: 'line' as const,
    smooth: true,
    data: dates.map(date => {
      const record = records.find(r => r.recordDate === date)
      return record ? record.usageValue : 0
    })
  }))

  const option: EChartsOption = {
    title: {
      text: t('billing.usageTrend'),
      left: 'center'
    },
    tooltip: {
      trigger: 'axis'
    },
    legend: {
      top: 30,
      data: Object.keys(groupedData)
    },
    xAxis: {
      type: 'category',
      data: dates.map(date => dayjs(date).format('MM-DD'))
    },
    yAxis: {
      type: 'value',
      name: t('billing.usageValue')
    },
    series
  }

  chartInstance.setOption(option)
}

const handleQuery = () => {
  loadUsageRecords()
}

const handleReset = () => {
  queryForm.startDate = dayjs().subtract(30, 'day').format('YYYY-MM-DD')
  queryForm.endDate = dayjs().format('YYYY-MM-DD')
  queryForm.metricType = ''
  loadUsageRecords()
}

onMounted(() => {
  loadUsageRecords()
  window.addEventListener('resize', () => {
    chartInstance?.resize()
  })
})
</script>

<template>
  <div class="billing-usage">
    <el-card shadow="never" class="query-card">
      <el-form :model="queryForm" inline>
        <el-form-item :label="t('billing.startDate')">
          <el-date-picker
            v-model="queryForm.startDate"
            type="date"
            :placeholder="t('common.pleaseSelect')"
            value-format="YYYY-MM-DD"
          />
        </el-form-item>
        <el-form-item :label="t('billing.endDate')">
          <el-date-picker
            v-model="queryForm.endDate"
            type="date"
            :placeholder="t('common.pleaseSelect')"
            value-format="YYYY-MM-DD"
          />
        </el-form-item>
        <el-form-item :label="t('billing.metricType')">
          <el-select v-model="queryForm.metricType" :placeholder="t('common.pleaseSelect')">
            <el-option
              v-for="item in metricTypes"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">{{ t('common.query') }}</el-button>
          <el-button @click="handleReset">{{ t('common.reset') }}</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card v-loading="loading" shadow="never" class="chart-card">
      <div ref="chartRef" class="chart-container" />
    </el-card>

    <el-card shadow="never" class="table-card">
      <el-table :data="usageRecords" border stripe>
        <el-table-column prop="recordDate" :label="t('billing.recordDate')" width="120">
          <template #default="{ row }">
            {{ dayjs(row.recordDate).format('YYYY-MM-DD') }}
          </template>
        </el-table-column>
        <el-table-column prop="metricType" :label="t('billing.metricType')" width="150" />
        <el-table-column prop="usageValue" :label="t('billing.usageValue')" align="right">
          <template #default="{ row }">
            {{ row.usageValue.toFixed(2) }}
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.billing-usage {
  padding: 20px;

  .query-card {
    margin-bottom: 20px;
  }

  .chart-card {
    margin-bottom: 20px;
  }

  .chart-container {
    width: 100%;
    height: 400px;
  }
}
</style>
