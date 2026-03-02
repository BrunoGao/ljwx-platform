<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Upload, Download, Refresh } from '@element-plus/icons-vue'
import { importData, exportData, listTasks, getTask } from '@/api/system/import-export'
import type { ImportExportTaskVO, ImportExportTaskQueryDTO } from '@/api/system/import-export'
import type { UploadProps, UploadFile } from 'element-plus'

const loading = ref(false)
const tasks = ref<ImportExportTaskVO[]>([])
const total = ref(0)
const queryParams = ref<ImportExportTaskQueryDTO>({
  pageNum: 1,
  pageSize: 10
})

const importDialogVisible = ref(false)
const exportDialogVisible = ref(false)
const businessTypeOptions = [
  { label: '用户', value: 'USER' },
  { label: '角色', value: 'ROLE' },
  { label: '部门', value: 'DEPT' },
  { label: '菜单', value: 'MENU' }
]

const importForm = ref({
  businessType: '',
  file: null as File | null
})

const exportForm = ref({
  businessType: '',
  fileName: ''
})

let pollingTimer: number | null = null

const statusTypeMap: Record<string, 'success' | 'info' | 'warning' | 'danger'> = {
  PENDING: 'info',
  PROCESSING: 'warning',
  SUCCESS: 'success',
  FAILURE: 'danger'
}

const statusTextMap: Record<string, string> = {
  PENDING: '等待中',
  PROCESSING: '处理中',
  SUCCESS: '成功',
  FAILURE: '失败'
}

async function loadTasks() {
  loading.value = true
  try {
    const res = await listTasks(queryParams.value)
    tasks.value = res.data.rows
    total.value = res.data.total
  } finally {
    loading.value = false
  }
}

function handleQuery() {
  queryParams.value.pageNum = 1
  loadTasks()
}

function handleReset() {
  queryParams.value = {
    pageNum: 1,
    pageSize: 10
  }
  loadTasks()
}

function handlePageChange(page: number) {
  queryParams.value.pageNum = page
  loadTasks()
}

function openImportDialog() {
  importDialogVisible.value = true
  importForm.value = {
    businessType: '',
    file: null
  }
}

function openExportDialog() {
  exportDialogVisible.value = true
  exportForm.value = {
    businessType: '',
    fileName: ''
  }
}

const handleFileChange: UploadProps['onChange'] = (uploadFile: UploadFile) => {
  if (uploadFile.raw) {
    importForm.value.file = uploadFile.raw
  }
}

async function handleImport() {
  if (!importForm.value.businessType) {
    ElMessage.warning('请选择业务类型')
    return
  }
  if (!importForm.value.file) {
    ElMessage.warning('请选择导入文件')
    return
  }

  const formData = new FormData()
  formData.append('taskType', 'IMPORT')
  formData.append('businessType', importForm.value.businessType)
  formData.append('fileName', importForm.value.file.name)
  formData.append('file', importForm.value.file)

  loading.value = true
  try {
    const res = await importData(formData)
    ElMessage.success(`导入任务已创建，任务ID: ${res.data}`)
    importDialogVisible.value = false
    loadTasks()
    startPolling()
  } catch (error) {
    ElMessage.error('导入任务创建失败')
  } finally {
    loading.value = false
  }
}

async function handleExport() {
  if (!exportForm.value.businessType) {
    ElMessage.warning('请选择业务类型')
    return
  }
  if (!exportForm.value.fileName) {
    ElMessage.warning('请输入文件名')
    return
  }

  loading.value = true
  try {
    const res = await exportData({
      taskType: 'EXPORT',
      businessType: exportForm.value.businessType,
      fileName: exportForm.value.fileName
    })
    ElMessage.success(`导出任务已创建，任务ID: ${res.data}`)
    exportDialogVisible.value = false
    loadTasks()
    startPolling()
  } catch (error) {
    ElMessage.error('导出任务创建失败')
  } finally {
    loading.value = false
  }
}

function startPolling() {
  if (pollingTimer) return
  pollingTimer = window.setInterval(() => {
    const hasProcessing = tasks.value.some(
      task => task.status === 'PENDING' || task.status === 'PROCESSING'
    )
    if (hasProcessing) {
      loadTasks()
    } else {
      stopPolling()
    }
  }, 3000)
}

function stopPolling() {
  if (pollingTimer) {
    clearInterval(pollingTimer)
    pollingTimer = null
  }
}

function handleDownload(row: ImportExportTaskVO) {
  if (!row.fileUrl) {
    ElMessage.warning('文件不存在')
    return
  }
  window.open(row.fileUrl, '_blank')
}

function getProgressPercentage(row: ImportExportTaskVO): number {
  if (row.totalCount === 0) return 0
  return Math.round((row.successCount / row.totalCount) * 100)
}

onMounted(() => {
  loadTasks()
  startPolling()
})

onUnmounted(() => {
  stopPolling()
})
</script>

<template>
  <div class="import-export-container">
    <el-card class="search-card">
      <el-form :model="queryParams" inline>
        <el-form-item label="任务类型">
          <el-select v-model="queryParams.taskType" placeholder="请选择" clearable style="width: 150px">
            <el-option label="导入" value="IMPORT" />
            <el-option label="导出" value="EXPORT" />
          </el-select>
        </el-form-item>
        <el-form-item label="业务类型">
          <el-select v-model="queryParams.businessType" placeholder="请选择" clearable style="width: 150px">
            <el-option
              v-for="item in businessTypeOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryParams.status" placeholder="请选择" clearable style="width: 150px">
            <el-option label="等待中" value="PENDING" />
            <el-option label="处理中" value="PROCESSING" />
            <el-option label="成功" value="SUCCESS" />
            <el-option label="失败" value="FAILURE" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>导入导出任务</span>
          <div>
            <el-button type="primary" :icon="Upload" @click="openImportDialog">导入</el-button>
            <el-button type="success" :icon="Download" @click="openExportDialog">导出</el-button>
            <el-button :icon="Refresh" @click="loadTasks">刷新</el-button>
          </div>
        </div>
      </template>

      <el-table v-loading="loading" :data="tasks" border stripe>
        <el-table-column prop="id" label="任务ID" width="100" />
        <el-table-column prop="taskType" label="任务类型" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.taskType === 'IMPORT'" type="primary">导入</el-tag>
            <el-tag v-else type="success">导出</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="businessType" label="业务类型" width="120">
          <template #default="{ row }">
            {{ businessTypeOptions.find(item => item.value === row.businessType)?.label || row.businessType }}
          </template>
        </el-table-column>
        <el-table-column prop="fileName" label="文件名" min-width="200" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="statusTypeMap[row.status]">
              {{ statusTextMap[row.status] }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="进度" width="200">
          <template #default="{ row }">
            <div v-if="row.status === 'PROCESSING' || row.status === 'SUCCESS'">
              <el-progress
                :percentage="getProgressPercentage(row)"
                :status="row.status === 'SUCCESS' ? 'success' : undefined"
              />
              <div class="progress-text">
                {{ row.successCount }} / {{ row.totalCount }}
                <span v-if="row.failureCount > 0" class="failure-count">
                  (失败: {{ row.failureCount }})
                </span>
              </div>
            </div>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 'SUCCESS' && row.fileUrl"
              type="primary"
              link
              @click="handleDownload(row)"
            >
              下载
            </el-button>
            <el-tooltip v-if="row.status === 'FAILURE' && row.errorMessage" :content="row.errorMessage">
              <el-button type="danger" link>查看错误</el-button>
            </el-tooltip>
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
        @size-change="loadTasks"
      />
    </el-card>

    <el-dialog v-model="importDialogVisible" title="导入数据" width="500px">
      <el-form :model="importForm" label-width="100px">
        <el-form-item label="业务类型" required>
          <el-select v-model="importForm.businessType" placeholder="请选择业务类型" style="width: 100%">
            <el-option
              v-for="item in businessTypeOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="导入文件" required>
          <el-upload
            :auto-upload="false"
            :limit="1"
            :on-change="handleFileChange"
            accept=".xlsx,.xls"
            drag
          >
            <el-icon class="el-icon--upload"><Upload /></el-icon>
            <div class="el-upload__text">
              拖拽文件到此处或<em>点击上传</em>
            </div>
            <template #tip>
              <div class="el-upload__tip">
                仅支持 .xlsx 或 .xls 格式文件
              </div>
            </template>
          </el-upload>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="importDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="loading" @click="handleImport">确定</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="exportDialogVisible" title="导出数据" width="500px">
      <el-form :model="exportForm" label-width="100px">
        <el-form-item label="业务类型" required>
          <el-select v-model="exportForm.businessType" placeholder="请选择业务类型" style="width: 100%">
            <el-option
              v-for="item in businessTypeOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="文件名" required>
          <el-input v-model="exportForm.fileName" placeholder="请输入文件名（不含扩展名）" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="exportDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="loading" @click="handleExport">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.import-export-container {
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

    .el-table {
      margin-bottom: 20px;
    }

    .progress-text {
      margin-top: 5px;
      font-size: 12px;
      color: #606266;

      .failure-count {
        color: #f56c6c;
        margin-left: 5px;
      }
    }
  }

  .el-icon--upload {
    font-size: 67px;
    color: #c0c4cc;
    margin: 40px 0 16px;
  }
}
</style>
