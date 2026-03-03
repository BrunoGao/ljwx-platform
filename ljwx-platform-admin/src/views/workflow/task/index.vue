<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Check, Close, Search } from '@element-plus/icons-vue'
import {
  getMyTasks,
  approveTask,
  rejectTask,
  type WfTaskVO,
  type WfTaskQueryDTO,
  type WfTaskActionDTO
} from '@/api/workflow/task'

const loading = ref(false)
const tableData = ref<WfTaskVO[]>([])
const total = ref(0)
const queryParams = ref<WfTaskQueryDTO>({
  pageNum: 1,
  pageSize: 10
})

const actionDialogVisible = ref(false)
const actionType = ref<'approve' | 'reject'>('approve')
const currentTaskId = ref<number>()
const actionForm = ref<WfTaskActionDTO>({
  comment: ''
})

const statusOptions = [
  { label: '待处理', value: 'PENDING' },
  { label: '已通过', value: 'APPROVED' },
  { label: '已拒绝', value: 'REJECTED' }
]

async function fetchData() {
  loading.value = true
  try {
    const res = await getMyTasks(queryParams.value)
    tableData.value = res.data.rows
    total.value = res.data.total
  } finally {
    loading.value = false
  }
}

function handleQuery() {
  queryParams.value.pageNum = 1
  fetchData()
}

function handleReset() {
  queryParams.value = {
    pageNum: 1,
    pageSize: 10
  }
  fetchData()
}

function handleApprove(row: WfTaskVO) {
  actionType.value = 'approve'
  currentTaskId.value = row.id
  actionForm.value = { comment: '' }
  actionDialogVisible.value = true
}

function handleReject(row: WfTaskVO) {
  actionType.value = 'reject'
  currentTaskId.value = row.id
  actionForm.value = { comment: '' }
  actionDialogVisible.value = true
}

async function handleSubmitAction() {
  if (!currentTaskId.value) return

  try {
    if (actionType.value === 'approve') {
      await approveTask(currentTaskId.value, actionForm.value)
      ElMessage.success('审批通过')
    } else {
      await rejectTask(currentTaskId.value, actionForm.value)
      ElMessage.success('审批拒绝')
    }
    actionDialogVisible.value = false
    fetchData()
  } catch (error) {
    ElMessage.error('操作失败')
  }
}

function handlePageChange(page: number) {
  queryParams.value.pageNum = page
  fetchData()
}

function getStatusType(status: string) {
  const map: Record<string, 'warning' | 'success' | 'danger'> = {
    PENDING: 'warning',
    APPROVED: 'success',
    REJECTED: 'danger'
  }
  return map[status] || 'warning'
}

function getStatusLabel(status: string) {
  const map: Record<string, string> = {
    PENDING: '待处理',
    APPROVED: '已通过',
    REJECTED: '已拒绝'
  }
  return map[status] || status
}

function getTaskTypeLabel(type: string) {
  const map: Record<string, string> = {
    APPROVAL: '审批',
    NOTIFY: '通知'
  }
  return map[type] || type
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="workflow-task-container">
    <el-card class="search-card">
      <el-form :model="queryParams" inline>
        <el-form-item label="状态">
          <el-select v-model="queryParams.status" placeholder="请选择状态" clearable>
            <el-option
              v-for="item in statusOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :icon="Search" @click="handleQuery">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card">
      <template #header>
        <span>我的待办任务</span>
      </template>

      <el-table v-loading="loading" :data="tableData" border>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="instanceId" label="实例ID" width="100" />
        <el-table-column prop="taskName" label="任务名称" width="200" />
        <el-table-column prop="taskType" label="任务类型" width="100">
          <template #default="{ row }">
            {{ getTaskTypeLabel(row.taskType) }}
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="comment" label="审批意见" min-width="200" show-overflow-tooltip />
        <el-table-column prop="handleTime" label="处理时间" width="180" />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" fixed="right" width="180">
          <template #default="{ row }">
            <template v-if="row.status === 'PENDING'">
              <el-button type="success" :icon="Check" link @click="handleApprove(row)">通过</el-button>
              <el-button type="danger" :icon="Close" link @click="handleReject(row)">拒绝</el-button>
            </template>
            <span v-else>-</span>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="queryParams.pageNum"
        :page-size="queryParams.pageSize"
        :total="total"
        layout="total, prev, pager, next"
        @current-change="handlePageChange"
      />
    </el-card>

    <el-dialog
      v-model="actionDialogVisible"
      :title="actionType === 'approve' ? '审批通过' : '审批拒绝'"
      width="500px"
    >
      <el-form :model="actionForm" label-width="100px">
        <el-form-item label="审批意见">
          <el-input
            v-model="actionForm.comment"
            type="textarea"
            :rows="4"
            placeholder="请输入审批意见（可选）"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="actionDialogVisible = false">取消</el-button>
        <el-button
          :type="actionType === 'approve' ? 'success' : 'danger'"
          @click="handleSubmitAction"
        >
          确定
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.workflow-task-container {
  padding: 20px;

  .search-card {
    margin-bottom: 20px;
  }

  .table-card {
    .el-pagination {
      margin-top: 20px;
      justify-content: flex-end;
    }
  }
}
</style>
