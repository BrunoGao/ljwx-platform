<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Search, Refresh, View } from '@element-plus/icons-vue'
import {
  listInstances,
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
const detailData = ref<WfInstanceVO | null>(null)

const statusOptions = [
  { label: '运行中', value: 'RUNNING' },
  { label: '已完成', value: 'COMPLETED' },
  { label: '已拒绝', value: 'REJECTED' },
  { label: '已取消', value: 'CANCELLED' }
]

async function fetchList() {
  loading.value = true
  try {
    const res = await listInstances(queryParams.value)
    tableData.value = res.data.rows
    total.value = res.data.total
  } catch (error) {
    ElMessage.error('获取流程实例列表失败')
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

async function handleView(id: number) {
  try {
    const res = await getInstance(id)
    detailData.value = res.data
    detailDialogVisible.value = true
  } catch (error) {
    ElMessage.error('获取流程实例详情失败')
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
  <div class="instance-container">
    <el-card class="search-card">
      <el-form :inline="true" :model="queryParams">
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
          <el-button :icon="Refresh" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>流程实例列表</span>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="definitionId" label="流程定义ID" width="120" />
        <el-table-column prop="businessKey" label="业务主键" width="150" />
        <el-table-column prop="businessType" label="业务类型" width="120" />
        <el-table-column prop="initiatorId" label="发起人ID" width="100" />
        <el-table-column prop="currentNode" label="当前节点" min-width="120" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.status === 'RUNNING'" type="primary">运行中</el-tag>
            <el-tag v-else-if="row.status === 'COMPLETED'" type="success">已完成</el-tag>
            <el-tag v-else-if="row.status === 'REJECTED'" type="danger">已拒绝</el-tag>
            <el-tag v-else-if="row.status === 'CANCELLED'" type="info">已取消</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="startTime" label="开始时间" width="180" />
        <el-table-column prop="endTime" label="结束时间" width="180" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" :icon="View" link @click="handleView(row.id)">查看</el-button>
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
      v-model="detailDialogVisible"
      title="流程实例详情"
      width="700px"
    >
      <el-descriptions v-if="detailData" :column="2" border>
        <el-descriptions-item label="实例ID">{{ detailData.id }}</el-descriptions-item>
        <el-descriptions-item label="流程定义ID">{{ detailData.definitionId }}</el-descriptions-item>
        <el-descriptions-item label="业务主键">{{ detailData.businessKey }}</el-descriptions-item>
        <el-descriptions-item label="业务类型">{{ detailData.businessType }}</el-descriptions-item>
        <el-descriptions-item label="发起人ID">{{ detailData.initiatorId }}</el-descriptions-item>
        <el-descriptions-item label="当前节点">{{ detailData.currentNode }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag v-if="detailData.status === 'RUNNING'" type="primary">运行中</el-tag>
          <el-tag v-else-if="detailData.status === 'COMPLETED'" type="success">已完成</el-tag>
          <el-tag v-else-if="detailData.status === 'REJECTED'" type="danger">已拒绝</el-tag>
          <el-tag v-else-if="detailData.status === 'CANCELLED'" type="info">已取消</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="开始时间">{{ detailData.startTime }}</el-descriptions-item>
        <el-descriptions-item label="结束时间">{{ detailData.endTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detailData.createdTime }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ detailData.updatedTime }}</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.instance-container {
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
