<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { getDataChangeLogs } from '@/api/dataChangeLog'
import type { DataChangeLogVO, DataChangeLogQuery } from '@/api/dataChangeLog'

const loading = ref(false)
const tableData = ref<DataChangeLogVO[]>([])
const total = ref(0)

const queryForm = reactive<DataChangeLogQuery>({
  tableName: '',
  recordId: undefined,
  startTime: '',
  endTime: '',
  pageNum: 1,
  pageSize: 10
})

const dateRange = ref<[Date, Date] | null>(null)

async function fetchData() {
  loading.value = true
  try {
    if (dateRange.value) {
      queryForm.startTime = dateRange.value[0].toISOString()
      queryForm.endTime = dateRange.value[1].toISOString()
    } else {
      queryForm.startTime = ''
      queryForm.endTime = ''
    }
    const result = await getDataChangeLogs(queryForm)
    tableData.value = result.rows
    total.value = result.total
  } catch (error) {
    ElMessage.error('获取数据变更日志失败')
  } finally {
    loading.value = false
  }
}

function handleSearch() {
  queryForm.pageNum = 1
  fetchData()
}

function handleReset() {
  queryForm.tableName = ''
  queryForm.recordId = undefined
  dateRange.value = null
  queryForm.startTime = ''
  queryForm.endTime = ''
  queryForm.pageNum = 1
  fetchData()
}

function handlePageChange(page: number) {
  queryForm.pageNum = page
  fetchData()
}

function handleSizeChange(size: number) {
  queryForm.pageSize = size
  queryForm.pageNum = 1
  fetchData()
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="data-change-log-container">
    <el-card class="search-card">
      <el-form :model="queryForm" inline>
        <el-form-item label="表名">
          <el-input
            v-model="queryForm.tableName"
            placeholder="请输入表名"
            clearable
            style="width: 200px"
          />
        </el-form-item>
        <el-form-item label="记录ID">
          <el-input
            v-model.number="queryForm.recordId"
            placeholder="请输入记录ID"
            clearable
            style="width: 200px"
          />
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker
            v-model="dateRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            style="width: 360px"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card">
      <el-table
        v-loading="loading"
        :data="tableData"
        border
        stripe
        style="width: 100%"
      >
        <el-table-column prop="tableName" label="表名" width="150" />
        <el-table-column prop="recordId" label="记录ID" width="100" />
        <el-table-column prop="fieldName" label="字段名" width="150" />
        <el-table-column prop="oldValue" label="变更前值" min-width="150" show-overflow-tooltip />
        <el-table-column prop="newValue" label="变更后值" min-width="150" show-overflow-tooltip />
        <el-table-column prop="operateType" label="操作类型" width="100" />
        <el-table-column prop="createdBy" label="操作人" width="120" />
        <el-table-column prop="createdTime" label="操作时间" width="180" />
      </el-table>

      <el-pagination
        v-model:current-page="queryForm.pageNum"
        v-model:page-size="queryForm.pageSize"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        style="margin-top: 20px; justify-content: flex-end"
        @current-change="handlePageChange"
        @size-change="handleSizeChange"
      />
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.data-change-log-container {
  padding: 20px;

  .search-card {
    margin-bottom: 20px;
  }

  .table-card {
    .el-pagination {
      display: flex;
    }
  }
}
</style>
