<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Refresh, Check, Close } from '@element-plus/icons-vue'
import {
  getMyTasks,
  approveTask,
  rejectTask,
  type WfTaskVO,
  type WfTaskActionDTO,
  type WfTaskQueryDTO
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
const actionFormRef = ref()
const actionFormData = ref<WfTaskActionDTO>({
  comment: ''
})
const currentTaskId = ref<number | null>(null)

const statusOptions = [
  { label: '待处理', value: 'PENDING' },
  { label: '已通过', value: 'APPROVED' },
  { label: '已拒绝', value: 'REJECTED' }
]

const taskTypeOptions = [
  { label: '审批', value: 'APPROVAL' },
  { label: '通知', value: 'NOTIFY' }
]

async function fetchList() {
  loading.value = true
  try {
    const res = await getMyTasks(queryParams.value)
    tableData.value = res.data.rows
    total.value = res.data.total
  } catch (error) {
    ElMessage.error('获取任务列表失败')
  } finally {
    loading.value = false
  }
}

function handleQuery() {
  queryParams.value.pageNum = 1
  fetchList()
}

function handleReset() {
  queryParams.value = {
    pageNum: 1,
    pageSize: 10
  }
  fetchList()
}

function handleApprove(row: WfTaskVO) {
  actionType.value = 'approve'
  currentTaskId.value = row.id
  actionFormData.value = { comment: '' }
  actionDialogVisible.value = true
}

function handleReject(row: WfTaskVO) {
  actionType.value = 'reject'
  currentTaskId.value = row.id
  actionFormData.value = { comment: '' }
  actionDialogVisible.value = true
}

async function handleActionSubmit() {
  if (!currentTaskId.value) return

  try {
    if (actionType.value === 'approve') {
      await approveTask(currentTaskId.value, actionFormData.value)
      ElMessage.success('审批通过')
    } else {
      await rejectTask(currentTaskId.value, actionFormData.value)
      ElMessage.success('审批拒绝')
    }
    actionDialogVisible.value = false
    fetchList()
  } catch (error) {
    ElMessage.error('操作失败')
  }
}

function handlePageChange(page: number) {
  queryParams.value.pageNum = page
  fetchList()
}

function handleSizeChange(size: number) {
  queryParams.value.pageSize = size
  queryParams.value.pageNum = 1
  fetchList()
}

onMounted(() => {
  fetchList()
})
</script>

<template>
  <div class="task-container">
    <el-card class="search-card">
      <el-form :inline="true" :model="queryParams">
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
          <el-button :icon="Refresh" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>我的待办任务</span>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="instanceId" label="流程实例ID" width="120" />
        <el-table-column prop="taskName" label="任务名称" min-width="150" />
        <el-table-column prop="taskType" label="任务类型" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.taskType === 'APPROVAL'" type="primary">审批</el-tag>
            <el-tag v-else-if="row.taskType === 'NOTIFY'" type="info">通知</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="assigneeId" label="处理人ID" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.status === 'PENDING'" type="warning">待处理</el-tag>
            <el-tag v-else-if="row.status === 'APPROVED'" type="success">已通过</el-tag>
            <el-tag v-else-if="row.status === 'REJECTED'" type="danger">已拒绝</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="comment" label="审批意见" min-width="150" show-overflow-tooltip />
        <el-table-column prop="handleTime" label="处理时间" width="180" />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="180" fixed="right">
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
        v-model:page-size="queryParams.pageSize"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        @current-change="handlePageChange"
        @size-change="handleSizeChange"
      />
    </el-card>

    <el-dialog
      v-model="actionDialogVisible"
      :title="actionType === 'approve' ? '审批通过' : '审批拒绝'"
      width="500px"
      :close-on-click-modal="false"
    >
      <el-form ref="actionFormRef" :model="actionFormData" label-width="100px">
        <el-form-item label="审批意见">
          <el-input
            v-model="actionFormData.comment"
            type="textarea"
            :rows="4"
            placeholder="请输入审批意见（可选）"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="actionDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleActionSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.task-container {
  padding: 20px;

  .search-card {
    margin-bottom: 20px;
  }

  .table-card {
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .el-pagination {
      margin-top: 20px;
      justify-content: flex-end;
    }
  }
}
</style>
