<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type {
  SysNoticeVO,
  NoticeQueryDTO,
  NoticeCreateDTO,
  NoticeUpdateDTO,
  PageResult,
} from '@ljwx/shared'
import { getNoticeList, createNotice, updateNotice } from '@/api/notice'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<SysNoticeVO[]>([])
const total = ref(0)

const query = reactive<NoticeQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  title: undefined,
  type: undefined,
  status: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<SysNoticeVO> = await getNoticeList(query)
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
  query.title = undefined
  query.type = undefined
  query.status = undefined
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

// ─── 弹窗状态 ────────────────────────────────────────────────
const dialogVisible = ref(false)
const dialogTitle = ref('发布通知')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface NoticeForm {
  title: string
  content: string
  type: number
  status: number
}

const formData = reactive<NoticeForm>({
  title: '',
  content: '',
  type: 1,
  status: 1,
})

const rules: FormRules<NoticeForm> = {
  title: [{ required: true, message: '请输入标题', trigger: 'blur' }],
  content: [{ required: true, message: '请输入内容', trigger: 'blur' }],
  type: [{ required: true, message: '请选择类型', trigger: 'change' }],
}

function openCreate(): void {
  editingId.value = null
  dialogTitle.value = '发布通知'
  formData.title = ''
  formData.content = ''
  formData.type = 1
  formData.status = 1
  dialogVisible.value = true
}

function openEdit(row: SysNoticeVO): void {
  editingId.value = row.id
  dialogTitle.value = '编辑通知'
  formData.title = row.title
  formData.content = row.content
  formData.type = row.type
  formData.status = row.status
  dialogVisible.value = true
}

async function handleSubmit(): Promise<void> {
  try {
    await formRef.value?.validate()
  } catch {
    return
  }
  try {
    if (editingId.value === null) {
      const createData: NoticeCreateDTO = {
        title: formData.title,
        content: formData.content,
        type: formData.type,
      }
      await createNotice(createData)
      ElMessage.success('发布成功')
    } else {
      const updateData: NoticeUpdateDTO = {
        title: formData.title,
        content: formData.content,
        type: formData.type,
        status: formData.status,
      }
      await updateNotice(editingId.value, updateData)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    // error handled by interceptor
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
        <el-form-item label="标题">
          <el-input v-model="query.title" placeholder="请输入标题" clearable />
        </el-form-item>
        <el-form-item label="类型">
          <el-select v-model="query.type" placeholder="请选择类型" clearable style="width: 120px">
            <el-option label="通知" :value="1" />
            <el-option label="公告" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="请选择状态" clearable style="width: 120px">
            <el-option label="发布" :value="1" />
            <el-option label="草稿" :value="0" />
          </el-select>
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
          <span>通知公告列表</span>
          <el-button type="primary" @click="openCreate">发布通知</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="title" label="标题" min-width="200" show-overflow-tooltip />
        <el-table-column label="类型" width="90" align="center">
          <template #default="{ row }">
            <el-tag :type="row.type === 1 ? 'primary' : 'warning'" size="small">
              {{ row.type === 1 ? '通知' : '公告' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">
              {{ row.status === 1 ? '发布' : '草稿' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="发布时间" width="160" />
        <el-table-column prop="updatedTime" label="更新时间" width="160" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="openEdit(row)">编辑</el-button>
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

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="600px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="80px">
        <el-form-item label="标题" prop="title">
          <el-input v-model="formData.title" placeholder="请输入标题" />
        </el-form-item>
        <el-form-item label="类型" prop="type">
          <el-select v-model="formData.type" style="width: 100%">
            <el-option label="通知" :value="1" />
            <el-option label="公告" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="editingId !== null" label="状态">
          <el-select v-model="formData.status" style="width: 100%">
            <el-option label="发布" :value="1" />
            <el-option label="草稿" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="内容" prop="content">
          <el-input
            v-model="formData.content"
            type="textarea"
            :rows="6"
            placeholder="请输入通知内容"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
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
</style>
