<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type {
  TenantVO,
  TenantQueryDTO,
  TenantCreateDTO,
  TenantUpdateDTO,
  PageResult,
} from '@ljwx/shared'
import { getTenantList, createTenant, updateTenant } from '@/api/tenant'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<TenantVO[]>([])
const total = ref(0)

const query = reactive<TenantQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  name: undefined,
  code: undefined,
  status: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<TenantVO> = await getTenantList(query)
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
  query.name = undefined
  query.code = undefined
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
const dialogTitle = ref('新增租户')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface TenantForm {
  name: string
  code: string
  status: number
}

const formData = reactive<TenantForm>({
  name: '',
  code: '',
  status: 1,
})

const rules: FormRules<TenantForm> = {
  name: [{ required: true, message: '请输入租户名称', trigger: 'blur' }],
  code: [{ required: true, message: '请输入租户编码', trigger: 'blur' }],
}

function openCreate(): void {
  editingId.value = null
  dialogTitle.value = '新增租户'
  formData.name = ''
  formData.code = ''
  formData.status = 1
  dialogVisible.value = true
}

function openEdit(row: TenantVO): void {
  editingId.value = row.id
  dialogTitle.value = '编辑租户'
  formData.name = row.name
  formData.code = row.code
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
      const createData: TenantCreateDTO = {
        name: formData.name,
        code: formData.code,
      }
      await createTenant(createData)
      ElMessage.success('创建成功')
    } else {
      const updateData: TenantUpdateDTO = {
        name: formData.name,
        code: formData.code,
        status: formData.status,
      }
      await updateTenant(editingId.value, updateData)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    // error handled by interceptor
  }
}

async function confirmDisable(row: TenantVO): Promise<void> {
  try {
    await ElMessageBox.confirm(
      `确定${row.status === 1 ? '禁用' : '启用'}租户 "${row.name}" 吗？`,
      '操作确认',
      { type: 'warning' },
    )
    await updateTenant(row.id, { status: row.status === 1 ? 0 : 1 })
    ElMessage.success('操作成功')
    loadData()
  } catch {
    // cancelled or error
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
        <el-form-item label="租户名称">
          <el-input v-model="query.name" placeholder="请输入租户名称" clearable />
        </el-form-item>
        <el-form-item label="租户编码">
          <el-input v-model="query.code" placeholder="请输入租户编码" clearable />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="请选择状态" clearable style="width: 120px">
            <el-option label="启用" :value="1" />
            <el-option label="禁用" :value="0" />
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
          <span>租户列表</span>
          <el-button type="primary" @click="openCreate">新增租户</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="租户名称" min-width="160" />
        <el-table-column prop="code" label="租户编码" min-width="160" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
              {{ row.status === 1 ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="openEdit(row)">编辑</el-button>
            <el-button
              :type="row.status === 1 ? 'warning' : 'success'"
              link
              size="small"
              @click="confirmDisable(row)"
            >
              {{ row.status === 1 ? '禁用' : '启用' }}
            </el-button>
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
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="480px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="90px">
        <el-form-item label="租户名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入租户名称" />
        </el-form-item>
        <el-form-item label="租户编码" prop="code">
          <el-input
            v-model="formData.code"
            :disabled="editingId !== null"
            placeholder="请输入租户编码"
          />
        </el-form-item>
        <el-form-item v-if="editingId !== null" label="状态">
          <el-select v-model="formData.status">
            <el-option label="启用" :value="1" />
            <el-option label="禁用" :value="0" />
          </el-select>
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
