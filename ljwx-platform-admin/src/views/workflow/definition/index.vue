<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete, View } from '@element-plus/icons-vue'
import {
  getDefinitionList,
  createDefinition,
  updateDefinition,
  deleteDefinition,
  type WfDefinitionVO,
  type WfDefinitionDTO,
  type WfDefinitionQueryDTO
} from '@/api/workflow/definition'

const loading = ref(false)
const tableData = ref<WfDefinitionVO[]>([])
const total = ref(0)
const queryParams = ref<WfDefinitionQueryDTO>({
  pageNum: 1,
  pageSize: 10
})

const dialogVisible = ref(false)
const dialogTitle = ref('')
const formData = ref<WfDefinitionDTO>({
  flowKey: '',
  flowName: '',
  flowConfig: '{}'
})
const formRef = ref()
const isEdit = ref(false)
const currentId = ref<number>()

const rules = {
  flowKey: [{ required: true, message: '请输入流程标识', trigger: 'blur' }],
  flowName: [{ required: true, message: '请输入流程名称', trigger: 'blur' }],
  flowConfig: [{ required: true, message: '请输入流程配置', trigger: 'blur' }]
}

const statusOptions = [
  { label: '草稿', value: 'DRAFT' },
  { label: '已发布', value: 'PUBLISHED' },
  { label: '已归档', value: 'ARCHIVED' }
]

async function fetchData() {
  loading.value = true
  try {
    const res = await getDefinitionList(queryParams.value)
    tableData.value = res.rows
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function handleQuery() {
  queryParams.value.pageNum = 1
  fetchData()
}

function handleReset() {
  queryParams.value = {
    pageNum: 1,
    pageSize: 10
  }
  fetchData()
}

function handleAdd() {
  isEdit.value = false
  dialogTitle.value = '新增流程定义'
  formData.value = {
    flowKey: '',
    flowName: '',
    flowConfig: '{}'
  }
  dialogVisible.value = true
}

function handleEdit(row: WfDefinitionVO) {
  isEdit.value = true
  dialogTitle.value = '编辑流程定义'
  currentId.value = row.id
  formData.value = {
    flowKey: row.flowKey,
    flowName: row.flowName,
    flowConfig: row.flowConfig
  }
  dialogVisible.value = true
}

async function handleDelete(row: WfDefinitionVO) {
  try {
    await ElMessageBox.confirm('确认删除该流程定义吗？', '提示', {
      type: 'warning'
    })
    await deleteDefinition(row.id)
    ElMessage.success('删除成功')
    fetchData()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

async function handleSubmit() {
  try {
    await formRef.value.validate()
    if (isEdit.value && currentId.value) {
      await updateDefinition(currentId.value, formData.value)
      ElMessage.success('更新成功')
    } else {
      await createDefinition(formData.value)
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    fetchData()
  } catch (error) {
    ElMessage.error('操作失败')
  }
}

function handlePageChange(page: number) {
  queryParams.value.pageNum = page
  fetchData()
}

function getStatusType(status: string) {
  const map: Record<string, 'info' | 'success' | 'warning'> = {
    DRAFT: 'info',
    PUBLISHED: 'success',
    ARCHIVED: 'warning'
  }
  return map[status] || 'info'
}

function getStatusLabel(status: string) {
  const map: Record<string, string> = {
    DRAFT: '草稿',
    PUBLISHED: '已发布',
    ARCHIVED: '已归档'
  }
  return map[status] || status
}

onMounted(() => {
  fetchData()
})
</script>

<template>
  <div class="workflow-definition-container">
    <el-card class="search-card">
      <el-form :model="queryParams" inline>
        <el-form-item label="流程标识">
          <el-input v-model="queryParams.flowKey" placeholder="请输入流程标识" clearable />
        </el-form-item>
        <el-form-item label="流程名称">
          <el-input v-model="queryParams.flowName" placeholder="请输入流程名称" clearable />
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
          <el-button type="primary" @click="handleQuery">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>流程定义列表</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="flowKey" label="流程标识" width="150" />
        <el-table-column prop="flowName" label="流程名称" width="200" />
        <el-table-column prop="flowVersion" label="版本号" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column prop="updatedTime" label="更新时间" width="180" />
        <el-table-column label="操作" fixed="right" width="180">
          <template #default="{ row }">
            <el-button type="primary" :icon="Edit" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" :icon="Delete" link @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="queryParams.pageNum"
        :page-size="queryParams.pageSize"
        :total="total"
        layout="total, prev, pager, next"
        @current-change="handlePageChange"
      />
    </el-card>

    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="600px"
    >
      <el-form
        ref="formRef"
        :model="formData"
        :rules="rules"
        label-width="100px"
      >
        <el-form-item label="流程标识" prop="flowKey">
          <el-input v-model="formData.flowKey" placeholder="请输入流程标识" />
        </el-form-item>
        <el-form-item label="流程名称" prop="flowName">
          <el-input v-model="formData.flowName" placeholder="请输入流程名称" />
        </el-form-item>
        <el-form-item label="流程配置" prop="flowConfig">
          <el-input
            v-model="formData.flowConfig"
            type="textarea"
            :rows="10"
            placeholder="请输入 JSON 格式的流程配置"
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
.workflow-definition-container {
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
