<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type { MenuTreeVO, MenuCreateDTO, MenuUpdateDTO } from '@ljwx/shared'
import { getMenuList, createMenu, updateMenu, deleteMenu } from '@/api/menu'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<MenuTreeVO[]>([])

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const list = await getMenuList()
    tableData.value = buildTree(list)
  } finally {
    loading.value = false
  }
}

interface FlatMenu {
  id: number
  parentId: number
  name: string
  path: string
  component: string
  icon: string
  sort: number
  menuType: number
  permission: string
  visible: number
  createdTime: string
  updatedTime: string
}

function buildTree(list: FlatMenu[]): MenuTreeVO[] {
  const map = new Map<number, MenuTreeVO>()
  const roots: MenuTreeVO[] = []
  list.forEach((item) => {
    map.set(item.id, { ...item, children: [] })
  })
  map.forEach((node) => {
    if (node.parentId === 0) {
      roots.push(node)
    } else {
      const parent = map.get(node.parentId)
      if (parent) {
        parent.children = parent.children ?? []
        parent.children.push(node)
      } else {
        roots.push(node)
      }
    }
  })
  return roots
}

// ─── 弹窗状态 ────────────────────────────────────────────────
const dialogVisible = ref(false)
const dialogTitle = ref('新增菜单')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface MenuForm {
  parentId: number
  name: string
  path: string
  component: string
  icon: string
  sort: number
  menuType: number
  permission: string
  visible: number
}

const formData = reactive<MenuForm>({
  parentId: 0,
  name: '',
  path: '',
  component: '',
  icon: '',
  sort: 0,
  menuType: 0,
  permission: '',
  visible: 1,
})

const rules: FormRules<MenuForm> = {
  name: [{ required: true, message: '请输入菜单名称', trigger: 'blur' }],
  menuType: [{ required: true, message: '请选择菜单类型', trigger: 'change' }],
}

function resetForm(): void {
  formData.parentId = 0
  formData.name = ''
  formData.path = ''
  formData.component = ''
  formData.icon = ''
  formData.sort = 0
  formData.menuType = 0
  formData.permission = ''
  formData.visible = 1
}

function openCreate(parentId = 0): void {
  editingId.value = null
  dialogTitle.value = '新增菜单'
  resetForm()
  formData.parentId = parentId
  dialogVisible.value = true
}

function openEdit(row: MenuTreeVO): void {
  editingId.value = row.id
  dialogTitle.value = '编辑菜单'
  formData.parentId = row.parentId
  formData.name = row.name
  formData.path = row.path
  formData.component = row.component
  formData.icon = row.icon
  formData.sort = row.sort
  formData.menuType = row.menuType
  formData.permission = row.permission
  formData.visible = row.visible
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
      const dto: MenuCreateDTO = {
        parentId: formData.parentId,
        name: formData.name,
        path: formData.path || undefined,
        component: formData.component || undefined,
        icon: formData.icon || undefined,
        sort: formData.sort,
        menuType: formData.menuType,
        permission: formData.permission || undefined,
        visible: formData.visible,
      }
      await createMenu(dto)
      ElMessage.success('创建成功')
    } else {
      const dto: MenuUpdateDTO = {
        parentId: formData.parentId,
        name: formData.name,
        path: formData.path || undefined,
        component: formData.component || undefined,
        icon: formData.icon || undefined,
        sort: formData.sort,
        menuType: formData.menuType,
        permission: formData.permission || undefined,
        visible: formData.visible,
      }
      await updateMenu(editingId.value, dto)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    // error handled by interceptor
  }
}

async function handleDelete(row: MenuTreeVO): Promise<void> {
  try {
    await ElMessageBox.confirm(`确定删除菜单 "${row.name}" 吗？`, '删除确认', { type: 'warning' })
    await deleteMenu(row.id)
    ElMessage.success('删除成功')
    loadData()
  } catch {
    // cancelled or error
  }
}

const menuTypeLabel: Record<number, string> = { 0: '目录', 1: '菜单', 2: '按钮' }
const menuTypeTagType: Record<number, 'primary' | 'success' | 'warning'> = {
  0: 'primary',
  1: 'success',
  2: 'warning',
}

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="page-container">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>菜单管理</span>
          <el-button type="primary" @click="openCreate()">新增菜单</el-button>
        </div>
      </template>

      <el-table
        v-loading="loading"
        :data="tableData"
        row-key="id"
        default-expand-all
        :tree-props="{ children: 'children' }"
        border
      >
        <el-table-column prop="name" label="菜单名称" min-width="160" />
        <el-table-column label="类型" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="menuTypeTagType[row.menuType as number]" size="small">
              {{ menuTypeLabel[row.menuType as number] }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="icon" label="图标" width="100" />
        <el-table-column prop="path" label="路由路径" min-width="160" show-overflow-tooltip />
        <el-table-column prop="component" label="组件路径" min-width="160" show-overflow-tooltip />
        <el-table-column prop="permission" label="权限字符串" min-width="160" show-overflow-tooltip />
        <el-table-column prop="sort" label="排序" width="70" align="center" />
        <el-table-column label="显示" width="70" align="center">
          <template #default="{ row }">
            <el-tag :type="row.visible === 1 ? 'success' : 'info'" size="small">
              {{ row.visible === 1 ? '显示' : '隐藏' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="row.menuType !== 2"
              type="primary"
              link
              size="small"
              @click="openCreate(row.id)"
            >新增子项</el-button>
            <el-button type="primary" link size="small" @click="openEdit(row)">编辑</el-button>
            <el-button type="danger" link size="small" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="560px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="90px">
        <el-form-item label="菜单类型" prop="menuType">
          <el-radio-group v-model="formData.menuType">
            <el-radio :value="0">目录</el-radio>
            <el-radio :value="1">菜单</el-radio>
            <el-radio :value="2">按钮</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="菜单名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入菜单名称" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="formData.sort" :min="0" :max="9999" />
        </el-form-item>
        <el-form-item v-if="formData.menuType !== 2" label="路由路径">
          <el-input v-model="formData.path" placeholder="请输入路由路径" />
        </el-form-item>
        <el-form-item v-if="formData.menuType === 1" label="组件路径">
          <el-input v-model="formData.component" placeholder="如 system/user/index" />
        </el-form-item>
        <el-form-item v-if="formData.menuType !== 2" label="图标">
          <el-input v-model="formData.icon" placeholder="图标名称" />
        </el-form-item>
        <el-form-item v-if="formData.menuType === 2" label="权限字符串">
          <el-input v-model="formData.permission" placeholder="如 system:user:list" />
        </el-form-item>
        <el-form-item v-if="formData.menuType !== 2" label="显示状态">
          <el-radio-group v-model="formData.visible">
            <el-radio :value="1">显示</el-radio>
            <el-radio :value="0">隐藏</el-radio>
          </el-radio-group>
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

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
