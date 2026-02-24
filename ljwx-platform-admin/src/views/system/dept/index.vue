<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type { DeptVO, DeptTreeVO, DeptCreateDTO, DeptUpdateDTO } from '@/api/dept'
import { getDeptTree, createDept, updateDept, deleteDept } from '@/api/dept'

// ─── 树形数据 ────────────────────────────────────────────────
const loading = ref(false)
const treeData = ref<DeptTreeVO[]>([])
const selectedDept = ref<DeptVO | null>(null)

async function loadTree(): Promise<void> {
  loading.value = true
  try {
    treeData.value = await getDeptTree()
  } finally {
    loading.value = false
  }
}

function handleNodeClick(data: DeptVO): void {
  selectedDept.value = data
}

// ─── 弹窗状态 ────────────────────────────────────────────────
const dialogVisible = ref(false)
const dialogTitle = ref('新增部门')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface DeptForm {
  parentId: number
  name: string
  sort: number
  leader: string
  phone: string
  email: string
  status: number
  remark: string
}

const formData = reactive<DeptForm>({
  parentId: 0,
  name: '',
  sort: 0,
  leader: '',
  phone: '',
  email: '',
  status: 1,
  remark: '',
})

const rules: FormRules<DeptForm> = {
  name: [{ required: true, message: '请输入部门名称', trigger: 'blur' }],
  parentId: [{ required: true, message: '请选择上级部门', trigger: 'change' }],
}

function openCreate(parentId = 0): void {
  editingId.value = null
  dialogTitle.value = '新增部门'
  formData.parentId = parentId
  formData.name = ''
  formData.sort = 0
  formData.leader = ''
  formData.phone = ''
  formData.email = ''
  formData.status = 1
  formData.remark = ''
  dialogVisible.value = true
}

function openEdit(row: DeptVO): void {
  editingId.value = row.id
  dialogTitle.value = '编辑部门'
  formData.parentId = row.parentId
  formData.name = row.name
  formData.sort = row.sort
  formData.leader = row.leader
  formData.phone = row.phone
  formData.email = row.email
  formData.status = row.status
  formData.remark = row.remark
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
      const createData: DeptCreateDTO = {
        parentId: formData.parentId,
        name: formData.name,
        sort: formData.sort,
        leader: formData.leader || undefined,
        phone: formData.phone || undefined,
        email: formData.email || undefined,
        status: formData.status,
        remark: formData.remark || undefined,
      }
      await createDept(createData)
      ElMessage.success('创建成功')
    } else {
      const updateData: DeptUpdateDTO = {
        parentId: formData.parentId,
        name: formData.name,
        sort: formData.sort,
        leader: formData.leader || undefined,
        phone: formData.phone || undefined,
        email: formData.email || undefined,
        status: formData.status,
        remark: formData.remark || undefined,
      }
      await updateDept(editingId.value, updateData)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadTree()
  } catch {
    // error handled by interceptor
  }
}

async function handleDelete(row: DeptVO): Promise<void> {
  try {
    await ElMessageBox.confirm(`确定删除部门 "${row.name}" 吗？`, '删除确认', { type: 'warning' })
    await deleteDept(row.id)
    ElMessage.success('删除成功')
    selectedDept.value = null
    loadTree()
  } catch {
    // cancelled or error
  }
}

onMounted(() => {
  loadTree()
})
</script>

<template>
  <div class="page-container">
    <el-row :gutter="16">
      <!-- 左侧部门树 -->
      <el-col :span="8">
        <el-card shadow="never">
          <template #header>
            <div class="card-header">
              <span>部门树</span>
              <el-button type="primary" size="small" @click="openCreate(0)">新增根部门</el-button>
            </div>
          </template>
          <el-tree
            v-loading="loading"
            :data="treeData"
            :props="{ label: 'name', children: 'children' }"
            node-key="id"
            highlight-current
            default-expand-all
            @node-click="handleNodeClick"
          >
            <template #default="{ node, data }">
              <div class="tree-node">
                <span>{{ node.label }}</span>
                <div class="tree-actions">
                  <el-button type="primary" link size="small" @click.stop="openCreate(data.id)">
                    新增
                  </el-button>
                  <el-button type="primary" link size="small" @click.stop="openEdit(data)">
                    编辑
                  </el-button>
                  <el-button type="danger" link size="small" @click.stop="handleDelete(data)">
                    删除
                  </el-button>
                </div>
              </div>
            </template>
          </el-tree>
        </el-card>
      </el-col>

      <!-- 右侧详情 -->
      <el-col :span="16">
        <el-card shadow="never">
          <template #header>
            <span>部门详情</span>
          </template>
          <el-empty v-if="!selectedDept" description="请在左侧选择部门" />
          <el-descriptions v-else :column="2" border>
            <el-descriptions-item label="部门名称">{{ selectedDept.name }}</el-descriptions-item>
            <el-descriptions-item label="排序">{{ selectedDept.sort }}</el-descriptions-item>
            <el-descriptions-item label="负责人">{{ selectedDept.leader }}</el-descriptions-item>
            <el-descriptions-item label="联系电话">{{ selectedDept.phone }}</el-descriptions-item>
            <el-descriptions-item label="邮箱" :span="2">{{ selectedDept.email }}</el-descriptions-item>
            <el-descriptions-item label="状态">
              <el-tag :type="selectedDept.status === 1 ? 'success' : 'danger'" size="small">
                {{ selectedDept.status === 1 ? '启用' : '禁用' }}
              </el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ selectedDept.createdTime }}</el-descriptions-item>
            <el-descriptions-item label="备注" :span="2">{{ selectedDept.remark }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
    </el-row>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="480px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="90px">
        <el-form-item label="上级部门" prop="parentId">
          <el-tree-select
            v-model="formData.parentId"
            :data="treeData"
            :props="{ label: 'name', value: 'id', children: 'children' }"
            placeholder="请选择上级部门（0为根）"
            check-strictly
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="部门名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入部门名称" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="formData.sort" :min="0" />
        </el-form-item>
        <el-form-item label="负责人">
          <el-input v-model="formData.leader" placeholder="请输入负责人" />
        </el-form-item>
        <el-form-item label="联系电话">
          <el-input v-model="formData.phone" placeholder="请输入联系电话" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="formData.email" placeholder="请输入邮箱" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="formData.status">
            <el-option label="启用" :value="1" />
            <el-option label="禁用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="请输入备注" />
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
  padding: 0;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.tree-node {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  padding-right: 8px;
}

.tree-actions {
  display: none;
}

.el-tree-node:hover .tree-actions {
  display: flex;
}
</style>
