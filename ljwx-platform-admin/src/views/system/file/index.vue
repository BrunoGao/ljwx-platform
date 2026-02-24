<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { SysFileVO, FileQueryDTO, PageResult } from '@ljwx/shared'
import { getFileList, uploadFile, deleteFile, getDownloadUrl } from '@/api/file'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<SysFileVO[]>([])
const total = ref(0)

const query = reactive<FileQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  originalName: undefined,
  mimeType: undefined,
  startTime: undefined,
  endTime: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<SysFileVO> = await getFileList(query)
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
  query.originalName = undefined
  query.mimeType = undefined
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

// ─── 上传 ────────────────────────────────────────────────────
const uploading = ref(false)

async function handleUpload(event: Event): Promise<void> {
  const input = event.target as HTMLInputElement
  if (!input.files || input.files.length === 0) return
  const file = input.files[0]
  uploading.value = true
  try {
    const formData = new FormData()
    formData.append('file', file)
    await uploadFile(formData)
    ElMessage.success('上传成功')
    loadData()
  } catch {
    // error handled by interceptor
  } finally {
    uploading.value = false
    input.value = ''
  }
}

// ─── 删除 ────────────────────────────────────────────────────
async function handleDelete(row: SysFileVO): Promise<void> {
  try {
    await ElMessageBox.confirm(`确定删除文件 "${row.originalName}" 吗？`, '删除确认', {
      type: 'warning',
    })
    await deleteFile(row.id)
    ElMessage.success('删除成功')
    loadData()
  } catch {
    // cancelled or error
  }
}

// ─── 下载 ────────────────────────────────────────────────────
function handleDownload(row: SysFileVO): void {
  const url = getDownloadUrl(row.id)
  const a = document.createElement('a')
  a.href = url
  a.download = row.originalName
  a.click()
}

// ─── 文件大小格式化 ──────────────────────────────────────────
function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
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
        <el-form-item label="文件名">
          <el-input v-model="query.originalName" placeholder="请输入文件名" clearable />
        </el-form-item>
        <el-form-item label="文件类型">
          <el-input v-model="query.mimeType" placeholder="如：image/png" clearable />
        </el-form-item>
        <el-form-item label="上传时间">
          <el-date-picker
            v-model="query.startTime"
            type="datetime"
            placeholder="开始时间"
            value-format="YYYY-MM-DD HH:mm:ss"
            style="width: 180px"
          />
        </el-form-item>
        <el-form-item>
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
          <span>文件列表</span>
          <label class="upload-btn">
            <el-button type="primary" :loading="uploading">上传文件</el-button>
            <input type="file" style="display: none" @change="handleUpload" />
          </label>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="originalName" label="文件名" min-width="200" show-overflow-tooltip />
        <el-table-column prop="suffix" label="后缀" width="80" align="center" />
        <el-table-column prop="mimeType" label="类型" min-width="140" show-overflow-tooltip />
        <el-table-column label="大小" width="100" align="right">
          <template #default="{ row }">
            {{ formatFileSize(row.fileSize) }}
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="上传时间" width="160" />
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="handleDownload(row)">下载</el-button>
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

.upload-btn {
  cursor: pointer;
}

.pagination-wrapper {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}
</style>
