<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type {
  RoleVO,
  RoleQueryDTO,
  RoleCreateDTO,
  RoleUpdateDTO,
  PermissionVO,
  PageResult,
} from '@ljwx/shared'
import { getRoleList, createRole, updateRole, deleteRole, getPermissionList } from '@/api/role'
import DataScopeDialog from './components/DataScopeDialog.vue'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<RoleVO[]>([])
const total = ref(0)

const query = reactive<RoleQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  name: undefined,
  code: undefined,
  status: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<RoleVO> = await getRoleList(query)
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

// ─── 权限列表 ────────────────────────────────────────────────
const permissionOptions = ref<PermissionVO[]>([])

async function loadPermissions(): Promise<void> {
  permissionOptions.value = await getPermissionList()
}

// ─── 弹窗状态 ────────────────────────────────────────────────
const dialogVisible = ref(false)
const dialogTitle = ref('新增角色')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface RoleForm {
  name: string
  code: string
  description: string
  status: number
  permissionIds: number[]
}

const formData = reactive<RoleForm>({
  name: '',
  code: '',
  description: '',
  status: 1,
  permissionIds: [],
})

const rules: FormRules<RoleForm> = {
  name: [{ required: true, message: '请输入角色名称', trigger: 'blur' }],
  code: [{ required: true, message: '请输入角色编码', trigger: 'blur' }],
}

function openCreate(): void {
  editingId.value = null
  dialogTitle.value = '新增角色'
  formData.name = ''
  formData.code = ''
  formData.description = ''
  formData.status = 1
  formData.permissionIds = []
  dialogVisible.value = true
}

function openEdit(row: RoleVO): void {
  editingId.value = row.id
  dialogTitle.value = '编辑角色'
  formData.name = row.name
  formData.code = row.code
  formData.description = row.description
  formData.status = row.status
  formData.permissionIds = row.permissions.map((p) => p.id)
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
      const createData: RoleCreateDTO = {
        name: formData.name,
        code: formData.code,
        description: formData.description || undefined,
        permissionIds: formData.permissionIds.length > 0 ? formData.permissionIds : undefined,
      }
      await createRole(createData)
      ElMessage.success('创建成功')
    } else {
      const updateData: RoleUpdateDTO = {
        name: formData.name,
        code: formData.code,
        description: formData.description || undefined,
        status: formData.status,
        permissionIds: formData.permissionIds,
      }
      await updateRole(editingId.value, updateData)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    // error handled by interceptor
  }
}

async function handleDelete(row: RoleVO): Promise<void> {
  try {
    await ElMessageBox.confirm(`确定删除角色 "${row.name}" 吗？`, '删除确认', {
      type: 'warning',
    })
    await deleteRole(row.id)
    ElMessage.success('删除成功')
    loadData()
  } catch {
    // cancelled or error
  }
}

// ─── 数据范围弹窗 ────────────────────────────────────────────────
const dataScopeDialogVisible = ref(false)
const dataScopeRoleId = ref<number | null>(null)
const dataScopeRoleName = ref('')

function openDataScope(row: RoleVO): void {
  dataScopeRoleId.value = row.id
  dataScopeRoleName.value = row.name
  dataScopeDialogVisible.value = true
}

function handleDataScopeSuccess(): void {
  ElMessage.success('数据范围更新成功')
  dataScopeDialogVisible.value = false
}

onMounted(() => {
  loadData()
  loadPermissions()
})
</script>

<template>
  <div class="page-container">
    <!-- 搜索栏 -->
    <el-card class="search-card" shadow="never">
      <el-form :model="query" inline>
        <el-form-item label="角色名称">
          <el-input v-model="query.name" placeholder="请输入角色名称" clearable />
        </el-form-item>
        <el-form-item label="角色编码">
          <el-input v-model="query.code" placeholder="请输入角色编码" clearable />
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
          <span>角色列表</span>
          <el-button type="primary" @click="openCreate">新增角色</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="name" label="角色名称" min-width="120" />
        <el-table-column prop="code" label="角色编码" min-width="120" />
        <el-table-column prop="description" label="描述" min-width="160" show-overflow-tooltip />
        <el-table-column label="权限数" width="90" align="center">
          <template #default="{ row }">
            <el-tag size="small" type="info">{{ row.permissions.length }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
              {{ row.status === 1 ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="220" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="openEdit(row)">编辑</el-button>
            <el-button type="warning" link size="small" @click="openDataScope(row)">数据范围</el-button>
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

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="600px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="90px">
        <el-form-item label="角色名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入角色名称" />
        </el-form-item>
        <el-form-item label="角色编码" prop="code">
          <el-input
            v-model="formData.code"
            :disabled="editingId !== null"
            placeholder="请输入角色编码"
          />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="formData.description" type="textarea" :rows="2" placeholder="请输入描述" />
        </el-form-item>
        <el-form-item v-if="editingId !== null" label="状态">
          <el-select v-model="formData.status">
            <el-option label="启用" :value="1" />
            <el-option label="禁用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="权限">
          <el-select
            v-model="formData.permissionIds"
            multiple
            placeholder="请选择权限"
            style="width: 100%"
          >
            <el-option
              v-for="perm in permissionOptions"
              :key="perm.id"
              :label="`${perm.name} (${perm.code})`"
              :value="perm.id"
            />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>

    <!-- 数据范围弹窗 -->
    <DataScopeDialog
      v-model:visible="dataScopeDialogVisible"
      :role-id="dataScopeRoleId"
      :role-name="dataScopeRoleName"
      @success="handleDataScopeSuccess"
    />
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
