<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type {
  TenantPackageVO,
  TenantPackageQueryDTO,
  TenantPackageCreateDTO,
  TenantPackageUpdateDTO,
  PageResult,
} from '@ljwx/shared'
import {
  getTenantPackageList,
  createTenantPackage,
  updateTenantPackage,
  deleteTenantPackage,
} from '@/api/tenantPackage'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<TenantPackageVO[]>([])
const total = ref(0)

const query = reactive<TenantPackageQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  name: undefined,
  status: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<TenantPackageVO> = await getTenantPackageList(query)
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
const dialogTitle = ref('新增套餐')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface PackageForm {
  name: string
  menuIds: string
  maxUsers: number
  maxStorageMb: number
  status: number
}

const formData = reactive<PackageForm>({
  name: '',
  menuIds: '',
  maxUsers: 100,
  maxStorageMb: 1024,
  status: 1,
})

const rules: FormRules<PackageForm> = {
  name: [{ required: true, message: '请输入套餐名称', trigger: 'blur' }],
  maxUsers: [{ required: true, message: '请输入最大用户数', trigger: 'blur' }],
  maxStorageMb: [{ required: true, message: '请输入最大存储空间', trigger: 'blur' }],
}

function openCreate(): void {
  editingId.value = null
  dialogTitle.value = '新增套餐'
  formData.name = ''
  formData.menuIds = ''
  formData.maxUsers = 100
  formData.maxStorageMb = 1024
  formData.status = 1
  dialogVisible.value = true
}

function openEdit(row: TenantPackageVO): void {
  editingId.value = row.id
  dialogTitle.value = '编辑套餐'
  formData.name = row.name
  formData.menuIds = row.menuIds ?? ''
  formData.maxUsers = row.maxUsers
  formData.maxStorageMb = row.maxStorageMb
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
      const createData: TenantPackageCreateDTO = {
        name: formData.name,
        menuIds: formData.menuIds,
        maxUsers: formData.maxUsers,
        maxStorageMb: formData.maxStorageMb,
      }
      await createTenantPackage(createData)
      ElMessage.success('创建成功')
    } else {
      const updateData: TenantPackageUpdateDTO = {
        name: formData.name,
        menuIds: formData.menuIds,
        maxUsers: formData.maxUsers,
        maxStorageMb: formData.maxStorageMb,
        status: formData.status,
      }
      await updateTenantPackage(editingId.value, updateData)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    // error handled by interceptor
  }
}

async function confirmDelete(row: TenantPackageVO): Promise<void> {
  try {
    await ElMessageBox.confirm(`确定删除套餐 "${row.name}" 吗？`, '删除确认', { type: 'warning' })
    await deleteTenantPackage(row.id)
    ElMessage.success('删除成功')
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
        <el-form-item label="套餐名称">
          <el-input v-model="query.name" placeholder="请输入套餐名称" clearable />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="请选择状态" clearable style="width: 120px">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
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
          <span>套餐列表</span>
          <el-button
            v-if="userStore.hasAuthority('tenant-package:write')"
            type="primary"
            @click="openCreate"
          >新增套餐</el-button>
        </div>
      </template>
      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="套餐名称" min-width="160" />
        <el-table-column prop="maxUsers" label="最大用户数" width="120" align="right" />
        <el-table-column label="最大存储" width="120" align="right">
          <template #default="{ row }">{{ row.maxStorageMb }} MB</template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
              {{ row.status === 1 ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="160" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="openEdit(row)">编辑</el-button>
            <el-button type="danger" link size="small" @click="confirmDelete(row)">删除</el-button>
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
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="520px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="100px">
        <el-form-item label="套餐名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入套餐名称" />
        </el-form-item>
        <el-form-item label="菜单 ID 列表">
          <el-input v-model="formData.menuIds" placeholder="逗号分隔的菜单 ID，如：1,2,3" clearable />
        </el-form-item>
        <el-form-item label="最大用户数" prop="maxUsers">
          <el-input-number v-model="formData.maxUsers" :min="1" :max="99999" />
        </el-form-item>
        <el-form-item label="最大存储(MB)" prop="maxStorageMb">
          <el-input-number v-model="formData.maxStorageMb" :min="1" :max="1048576" />
        </el-form-item>
        <el-form-item v-if="editingId !== null" label="状态">
          <el-select v-model="formData.status">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
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
