<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import type {
  OperationLogVO,
  OperationLogQueryDTO,
  PageResult,
} from '@ljwx/shared'
import { getOperationLogList, exportLogs } from '@/api/log'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<OperationLogVO[]>([])
const total = ref(0)

const query = reactive<OperationLogQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  username: undefined,
  module: undefined,
  status: undefined,
  startTime: undefined,
  endTime: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<OperationLogVO> = await getOperationLogList(query)
    tableData.value = res.rows
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function handleSearch(): void {
  query.pageNum = 1
  loadData()
}

function handleReset(): void {
  query.username = undefined
  query.module = undefined
  query.status = undefined
  query.startTime = undefined
  query.endTime = undefined
  query.pageNum = 1
  loadData()
}

function handleSizeChange(size: number): void {
  query.pageSize = size
  query.pageNum = 1
  loadData()
}

function handleCurrentChange(page: number): void {
  query.pageNum = page
  loadData()
}

// ─── 导出 ────────────────────────────────────────────────────
const exporting = ref(false)

async function handleExport(): Promise<void> {
  exporting.value = true
  try {
    const blob: Blob = await exportLogs()
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `operation-log-${Date.now()}.xlsx`
    a.click()
    URL.revokeObjectURL(url)
    ElMessage.success('导出成功')
  } catch {
    // error handled by interceptor
  } finally {
    exporting.value = false
  }
}

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="page-container">
    <!-- 搜索栏 -->
    <el-card class="search-card" shadow="never">
      <el-form :model="query" inline>
        <el-form-item label="操作用户">
          <el-input v-model="query.username" placeholder="请输入用户名" clearable />
        </el-form-item>
        <el-form-item label="操作模块">
          <el-input v-model="query.module" placeholder="请输入模块名" clearable />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="请选择状态" clearable style="width: 120px">
            <el-option label="成功" :value="1" />
            <el-option label="失败" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="开始时间">
          <el-date-picker
            v-model="query.startTime"
            type="datetime"
            placeholder="开始时间"
            value-format="YYYY-MM-DD HH:mm:ss"
            style="width: 180px"
          />
        </el-form-item>
        <el-form-item label="结束时间">
          <el-date-picker
            v-model="query.endTime"
            type="datetime"
            placeholder="结束时间"
            value-format="YYYY-MM-DD HH:mm:ss"
            style="width: 180px"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>操作日志列表</span>
          <el-button type="warning" :loading="exporting" @click="handleExport">导出</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="username" label="操作用户" width="120" />
        <el-table-column prop="module" label="操作模块" width="120" />
        <el-table-column prop="operation" label="操作描述" min-width="160" show-overflow-tooltip />
        <el-table-column prop="requestMethod" label="请求方式" width="90" align="center" />
        <el-table-column prop="requestUrl" label="请求URL" min-width="200" show-overflow-tooltip />
        <el-table-column prop="ip" label="IP地址" width="130" />
        <el-table-column prop="duration" label="耗时(ms)" width="90" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
              {{ row.status === 1 ? '成功' : '失败' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="操作时间" width="160" />
      </el-table>

      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="query.pageNum"
          v-model:page-size="query.pageSize"
          :total="total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.page-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.search-card {
  :deep(.el-card__body) {
    padding-bottom: 0;
  }
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.pagination-wrapper {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}
</style>
