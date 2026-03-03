<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import type {
  ReportDefVO,
  ReportExecuteDTO,
  ReportResultVO,
  FilterDefItem,
} from '@/api/report/report-def'
import { getReportDefById, executeReport } from '@/api/report/report-def'

const route = useRoute()
const reportId = computed(() => Number(route.query.id))

// ─── 报表定义 ─────────────────────────────────────────────
const reportDef = ref<ReportDefVO | null>(null)
const defLoading = ref(false)

async function loadReportDef(): Promise<void> {
  if (!reportId.value) {
    ElMessage.error('缺少报表 ID')
    return
  }
  defLoading.value = true
  try {
    reportDef.value = await getReportDefById(reportId.value)
  } finally {
    defLoading.value = false
  }
}

// ─── 过滤器表单 ─────────────────────────────────────────────
const filterParams = reactive<Record<string, unknown>>({})

function initFilterParams(): void {
  if (!reportDef.value?.filterDef) return
  reportDef.value.filterDef.forEach((filter: FilterDefItem) => {
    filterParams[filter.paramName] = filter.defaultValue || undefined
  })
}

// ─── 报表执行 ─────────────────────────────────────────────
const resultLoading = ref(false)
const resultData = ref<ReportResultVO | null>(null)
const pageNum = ref(1)
const pageSize = ref(20)

async function handleExecute(): Promise<void> {
  if (!reportId.value) return

  // 校验必填参数
  if (reportDef.value?.filterDef) {
    for (const filter of reportDef.value.filterDef) {
      if (filter.required && !filterParams[filter.paramName]) {
        ElMessage.warning(`请填写必填参数：${filter.label}`)
        return
      }
    }
  }

  resultLoading.value = true
  try {
    const executeData: ReportExecuteDTO = {
      params: filterParams,
      pageNum: pageNum.value,
      pageSize: pageSize.value,
    }
    resultData.value = await executeReport(reportId.value, executeData)

    // 显示警告信息
    if (resultData.value.warnings && resultData.value.warnings.length > 0) {
      resultData.value.warnings.forEach((warning: string) => {
        ElMessage.warning(warning)
      })
    }
  } finally {
    resultLoading.value = false
  }
}

function handleSizeChange(size: number): void {
  pageSize.value = size
  pageNum.value = 1
  handleExecute()
}

function handleCurrentChange(page: number): void {
  pageNum.value = page
  handleExecute()
}

function handleReset(): void {
  Object.keys(filterParams).forEach((key) => {
    filterParams[key] = undefined
  })
  initFilterParams()
  resultData.value = null
}

onMounted(async () => {
  await loadReportDef()
  initFilterParams()
})
</script>

<template>
  <div class="page-container">
    <!-- 报表信息 -->
    <el-card v-loading="defLoading" shadow="never">
      <template #header>
        <div class="card-header">
          <span>{{ reportDef?.reportName || '报表预览' }}</span>
          <el-tag v-if="reportDef" :type="reportDef.status === 1 ? 'success' : 'danger'" size="small">
            {{ reportDef.status === 1 ? '启用' : '停用' }}
          </el-tag>
        </div>
      </template>
      <div v-if="reportDef" class="report-info">
        <div class="info-item">
          <span class="label">报表标识：</span>
          <span class="value">{{ reportDef.reportKey }}</span>
        </div>
        <div class="info-item">
          <span class="label">数据源类型：</span>
          <span class="value">{{ reportDef.dataSourceType }}</span>
        </div>
        <div v-if="reportDef.remark" class="info-item">
          <span class="label">备注：</span>
          <span class="value">{{ reportDef.remark }}</span>
        </div>
      </div>
    </el-card>

    <!-- 过滤器 -->
    <el-card v-if="reportDef?.filterDef && reportDef.filterDef.length > 0" shadow="never">
      <template #header>
        <span>查询条件</span>
      </template>
      <el-form :model="filterParams" inline>
        <el-form-item
          v-for="filter in reportDef.filterDef"
          :key="filter.paramName"
          :label="filter.label"
          :required="filter.required"
        >
          <el-input
            v-if="filter.paramType === 'string'"
            v-model="filterParams[filter.paramName]"
            :placeholder="`请输入${filter.label}`"
            clearable
            style="width: 200px"
          />
          <el-input-number
            v-else-if="filter.paramType === 'number'"
            v-model="filterParams[filter.paramName]"
            :placeholder="`请输入${filter.label}`"
            style="width: 200px"
          />
          <el-date-picker
            v-else-if="filter.paramType === 'date'"
            v-model="filterParams[filter.paramName]"
            type="date"
            :placeholder="`请选择${filter.label}`"
            style="width: 200px"
          />
          <el-switch
            v-else-if="filter.paramType === 'boolean'"
            v-model="filterParams[filter.paramName]"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleExecute">执行查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 无过滤器时的执行按钮 -->
    <el-card v-else-if="reportDef" shadow="never">
      <el-button type="primary" @click="handleExecute">执行查询</el-button>
    </el-card>

    <!-- 查询结果 -->
    <el-card v-if="resultData" shadow="never">
      <template #header>
        <div class="card-header">
          <span>查询结果</span>
          <span class="result-count">共 {{ resultData.total }} 条记录</span>
        </div>
      </template>

      <el-table v-loading="resultLoading" :data="resultData.rows" border stripe>
        <el-table-column
          v-for="col in resultData.columns"
          :key="col.name"
          :prop="col.name"
          :label="col.title"
          :min-width="120"
          show-overflow-tooltip
        >
          <template #default="{ row }">
            <span v-if="col.type === 'date' && row[col.name]">
              {{ new Date(row[col.name]).toLocaleString() }}
            </span>
            <span v-else-if="col.type === 'boolean'">
              <el-tag :type="row[col.name] ? 'success' : 'info'" size="small">
                {{ row[col.name] ? '是' : '否' }}
              </el-tag>
            </span>
            <span v-else>{{ row[col.name] }}</span>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="pageNum"
          v-model:page-size="pageSize"
          :total="resultData.total"
          :page-sizes="[10, 20, 50, 100, 200, 500, 1000]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 空状态 -->
    <el-card v-else-if="!defLoading && !resultLoading" shadow="never">
      <el-empty description="请执行查询以查看结果" />
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.page-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.report-info {
  display: flex;
  flex-direction: column;
  gap: 12px;

  .info-item {
    display: flex;
    align-items: center;

    .label {
      font-weight: 500;
      color: #606266;
      min-width: 100px;
    }

    .value {
      color: #303133;
    }
  }
}

.result-count {
  font-size: 14px;
  color: #909399;
}

.pagination-wrapper {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}
</style>
