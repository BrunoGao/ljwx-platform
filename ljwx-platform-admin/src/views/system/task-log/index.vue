<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { TaskExecutionLogVO, TaskExecutionLogQueryDTO, PageResult } from '@ljwx/shared'
import { getTaskLogList, getTaskLogDetail, deleteTaskLog, cleanOldTaskLogs } from '@/api/taskLog'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<TaskExecutionLogVO[]>([])
const total = ref(0)

const query = reactive<TaskExecutionLogQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  taskName: undefined,
  taskGroup: undefined,
  status: undefined,
  startTimeBegin: undefined,
  startTimeEnd: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<TaskExecutionLogVO> = await getTaskLogList(query)
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
  query.taskName = undefined
  query.taskGroup = undefined
  query.status = undefined
  query.startTimeBegin = undefined
  query.startTimeEnd = undefined
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

// ─── 详情弹窗 ────────────────────────────────────────────────
const detailVisible = ref(false)
const detailData = ref<TaskExecutionLogVO | null>(null)

async function handleViewDetail(row: TaskExecutionLogVO): Promise<void> {
  try {
    detailData.value = await getTaskLogDetail(row.id)
    detailVisible.value = true
  } catch {
    // error handled by interceptor
  }
}

// ─── 删除操作 ────────────────────────────────────────────────
async function handleDelete(row: TaskExecutionLogVO): Promise<void> {
  try {
    await ElMessageBox.confirm(`确定删除任务日志 "${row.taskName}" 吗？`, '删除确认', {
      type: 'warning',
    })
    await deleteTaskLog(row.id)
    ElMessage.success('删除成功')
    loadData()
  } catch {
    // cancelled or error
  }
}

// ─── 清理历史日志 ────────────────────────────────────────────
async function handleClean(): Promise<void> {
  try {
    await ElMessageBox.confirm('确定清理 30 天前的历史日志吗？', '清理确认', {
      type: 'warning',
    })
    const count = await cleanOldTaskLogs()
    ElMessage.success(`清理成功，共删除 ${count} 条日志`)
    loadData()
  } catch {
    // cancelled or error
  }
}

// ─── 状态标签 ────────────────────────────────────────────────
function getStatusType(status: string): 'success' | 'danger' | 'warning' {
  if (status === 'SUCCESS') return 'success'
  if (status === 'FAILURE') return 'danger'
  return 'warning'
}

function getStatusText(status: string): string {
  if (status === 'SUCCESS') return '成功'
  if (status === 'FAILURE') return '失败'
  return '运行中'
}

// ─── 格式化耗时 ────────────────────────────────────────────────
function formatDuration(duration: number): string {
  if (duration < 1000) return `${duration}ms`
  if (duration < 60000) return `${(duration / 1000).toFixed(2)}s`
  return `${(duration / 60000).toFixed(2)}min`
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
        <el-form-item label="任务名称">
          <el-input v-model="query.taskName" placeholder="请输入任务名称" clearable />
        </el-form-item>
        <el-form-item label="任务分组">
          <el-input v-model="query.taskGroup" placeholder="请输入任务分组" clearable />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="请选择状态" clearable style="width: 120px">
            <el-option label="成功" value="SUCCESS" />
            <el-option label="失败" value="FAILURE" />
            <el-option label="运行中" value="RUNNING" />
          </el-select>
        </el-form-item>
        <el-form-item label="开始时间">
          <el-date-picker
            v-model="query.startTimeBegin"
            type="datetime"
            placeholder="开始时间"
            value-format="YYYY-MM-DD HH:mm:ss"
            style="width: 180px"
          />
        </el-form-item>
        <el-form-item label="至">
          <el-date-picker
            v-model="query.startTimeEnd"
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
          <span>任务执行日志</span>
          <el-button type="danger" @click="handleClean">清理历史日志</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="taskName" label="任务名称" min-width="160" show-overflow-tooltip />
        <el-table-column prop="taskGroup" label="任务分组" width="120" />
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)" size="small">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="startTime" label="开始时间" width="160" />
        <el-table-column prop="endTime" label="结束时间" width="160" />
        <el-table-column label="耗时" width="100" align="center">
          <template #default="{ row }">
            {{ row.duration ? formatDuration(row.duration) : '-' }}
          </template>
        </el-table-column>
        <el-table-column prop="serverIp" label="服务器地址" width="140" />
        <el-table-column prop="serverName" label="服务器名称" width="140" show-overflow-tooltip />
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="handleViewDetail(row)">
              详情
            </el-button>
            <el-button type="danger" link size="small" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
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

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailVisible" title="任务执行日志详情" width="800px" destroy-on-close>
      <el-descriptions v-if="detailData" :column="2" border>
        <el-descriptions-item label="任务名称">{{ detailData.taskName }}</el-descriptions-item>
        <el-descriptions-item label="任务分组">{{ detailData.taskGroup }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="getStatusType(detailData.status)" size="small">
            {{ getStatusText(detailData.status) }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="耗时">
          {{ detailData.duration ? formatDuration(detailData.duration) : '-' }}
        </el-descriptions-item>
        <el-descriptions-item label="开始时间">{{ detailData.startTime }}</el-descriptions-item>
        <el-descriptions-item label="结束时间">
          {{ detailData.endTime || '-' }}
        </el-descriptions-item>
        <el-descriptions-item label="服务器地址">{{ detailData.serverIp }}</el-descriptions-item>
        <el-descriptions-item label="服务器名称">
          {{ detailData.serverName }}
        </el-descriptions-item>
        <el-descriptions-item label="任务参数" :span="2">
          <pre class="detail-text">{{ detailData.taskParams || '-' }}</pre>
        </el-descriptions-item>
        <el-descriptions-item label="执行结果" :span="2">
          <pre class="detail-text">{{ detailData.result || '-' }}</pre>
        </el-descriptions-item>
        <el-descriptions-item v-if="detailData.errorMessage" label="错误信息" :span="2">
          <pre class="detail-text error-text">{{ detailData.errorMessage }}</pre>
        </el-descriptions-item>
        <el-descriptions-item v-if="detailData.errorStack" label="错误堆栈" :span="2">
          <pre class="detail-text error-text">{{ detailData.errorStack }}</pre>
        </el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailVisible = false">关闭</el-button>
      </template>
    </el-dialog>
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

.detail-text {
  margin: 0;
  padding: 8px;
  background-color: #f5f7fa;
  border-radius: 4px;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  line-height: 1.5;
  white-space: pre-wrap;
  word-break: break-all;
  max-height: 300px;
  overflow-y: auto;
}

.error-text {
  background-color: #fef0f0;
  color: #f56c6c;
}
</style>



