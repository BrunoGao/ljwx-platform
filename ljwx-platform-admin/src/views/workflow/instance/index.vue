<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { View, Search } from '@element-plus/icons-vue'
import {
  getInstanceList,
  getInstance,
  type WfInstanceVO,
  type WfInstanceQueryDTO
} from '@/api/workflow/instance'

const loading = ref(false)
const tableData = ref<WfInstanceVO[]>([])
const total = ref(0)
const queryParams = ref<WfInstanceQueryDTO>({
  pageNum: 1,
  pageSize: 10
})

const detailDialogVisible = ref(false)
const currentInstance = ref<WfInstanceVO>()

const statusOptions = [
  { label: '运行中', value: 'RUNNING' },
  { label: '已完成', value: 'COMPLETED' },
  { label: '已拒绝', value: 'REJECTED' },
  { label: '已取消', value: 'CANCELLED' }
]

async function fetchData() {
  loading.value = true
  try {
    const res = await getInstanceList(queryParams.value)
    tableData.value = res.rows
    total.value = res.total
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

async function handleView(row: WfInstanceVO) {
  try {
    currentInstance.value = await getInstance(row.id)
    detailDialogVisible.value = true
  } catch (error) {
    ElMessage.error('获取详情失败')
  }
}

function handlePageChange(page: number) {
  queryParams.value.pageNum = page
  fetchData()
}

function getStatusType(status: string) {
  const map: Record<string, 'primary' | 'success' | 'danger' | 'info'> = {
    RUNNING: 'primary',
    COMPLETED: 'success',
    REJECTED: 'danger',
    CANCELLED: 'info'
  }
  return map[status] || 'info'
}

function getStatusLabel(status: string) {
  const map: Record<string, string> = {
    RUNNING: '运行中',
    COMPLETED: '已完成',
    REJECTED: '已拒绝',
    CANCELLED: '已取消'
  }
  return map[status] || status
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="workflow-instance-container">
    <el-card class="search-card">
      <el-form :model="queryParams" inline>
        <el-form-item label="业务主键">
          <el-input v-model="queryParams.businessKey" placeholder="请输入业务主键" clearable />
        </el-form-item>
        <el-form-item label="业务类型">
          <el-input v-model="queryParams.businessType" placeholder="请输入业务类型" clearable />
        </el-form-item>
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
        <span>流程实例列表</span>
      </template>

      <el-table v-loading="loading" :data="tableData" border>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="businessKey" label="业务主键" width="150" />
        <el-table-column prop="businessType" label="业务类型" width="120" />
        <el-table-column prop="initiatorId" label="发起人ID" width="100" />
        <el-table-column prop="currentNode" label="当前节点" width="150" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="startTime" label="开始时间" width="180" />
        <el-table-column prop="endTime" label="结束时间" width="180" />
        <el-table-column label="操作" fixed="right" width="120">
          <template #default="{ row }">
            <el-button type="primary" :icon="View" link @click="handleView(row)">查看</el-button>
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
      v-model="detailDialogVisible"
      title="流程实例详情"
      width="700px"
    >
      <el-descriptions v-if="currentInstance" :column="2" border>
        <el-descriptions-item label="实例ID">{{ currentInstance.id }}</el-descriptions-item>
        <el-descriptions-item label="定义ID">{{ currentInstance.definitionId }}</el-descriptions-item>
        <el-descriptions-item label="业务主键">{{ currentInstance.businessKey }}</el-descriptions-item>
        <el-descriptions-item label="业务类型">{{ currentInstance.businessType }}</el-descriptions-item>
        <el-descriptions-item label="发起人ID">{{ currentInstance.initiatorId }}</el-descriptions-item>
        <el-descriptions-item label="当前节点">{{ currentInstance.currentNode }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="getStatusType(currentInstance.status)">
            {{ getStatusLabel(currentInstance.status) }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="开始时间">{{ currentInstance.startTime }}</el-descriptions-item>
        <el-descriptions-item label="结束时间">{{ currentInstance.endTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ currentInstance.createdTime }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ currentInstance.updatedTime }}</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.workflow-instance-container {
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
