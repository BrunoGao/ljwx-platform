<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus, Edit, Delete, Refresh } from '@element-plus/icons-vue'
import {
  listDefinitions,
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
const dialogTitle = ref('新增流程定义')
const formRef = ref()
const formData = ref<WfDefinitionDTO>({
  flowKey: '',
  flowName: '',
  flowConfig: '',
  status: 'DRAFT'
})

const formRules = {
  flowKey: [
    { required: true, message: '请输入流程标识', trigger: 'blur' },
    { max: 50, message: '流程标识长度不能超过50', trigger: 'blur' }
  ],
  flowName: [
    { required: true, message: '请输入流程名称', trigger: 'blur' },
    { max: 100, message: '流程名称长度不能超过100', trigger: 'blur' }
  ],
  flowConfig: [{ required: true, message: '请输入流程配置', trigger: 'blur' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }]
}

const statusOptions = [
  { label: '草稿', value: 'DRAFT' },
  { label: '已发布', value: 'PUBLISHED' },
  { label: '已归档', value: 'ARCHIVED' }
]

const currentEditId = ref<number | null>(null)

async function fetchList() {
  loading.value = true
  try {
    const res = await listDefinitions(queryParams.value)
    tableData.value = res.data.rows
    total.value = res.data.total
  } catch (error) {
    ElMessage.error('获取流程定义列表失败')
  } finally {
    loading.value = false
  }
}

function handleQuery() {
  queryParams.value.pageNum = 1
  fetchList()
}

function handleReset() {
  queryParams.value = {
    pageNum: 1,
    pageSize: 10
  }
  fetchList()
}

function handleAdd() {
  dialogTitle.value = '新增流程定义'
  currentEditId.value = null
  formData.value = {
    flowKey: '',
    flowName: '',
    flowConfig: '',
    status: 'DRAFT'
  }
  dialogVisible.value = true
}

function handleEdit(row: WfDefinitionVO) {
  dialogTitle.value = '编辑流程定义'
  currentEditId.value = row.id
  formData.value = {
    flowKey: row.flowKey,
    flowName: row.flowName,
    flowConfig: row.flowConfig,
    status: row.status
  }
  dialogVisible.value = true
}

async function handleDelete(id: number) {
  try {
    await ElMessageBox.confirm('确认删除该流程定义吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await deleteDefinition(id)
    ElMessage.success('删除成功')
    fetchList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

async function handleSubmit() {
  if (!formRef.value) return
  await formRef.value.validate()

  try {
    if (currentEditId.value) {
      await updateDefinition(currentEditId.value, formData.value)
      ElMessage.success('更新成功')
    } else {
      await createDefinition(formData.value)
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    fetchList()
  } catch (error) {
    ElMessage.error(currentEditId.value ? '更新失败' : '创建失败')
  }
}

function handlePageChange(page: number) {
  queryParams.value.pageNum = page
  fetchList()
}

function handleSizeChange(size: number) {
  queryParams.value.pageSize = size
  queryParams.value.pageNum = 1
  fetchList()
}

onMounted(() => {
  fetchList()
})
</script>

<template>
  <div class="definition-container">
    <el-card class="search-card">
      <el-form :inline="true" :model="queryParams">
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
          <el-button type="primary" :icon="Search" @click="handleQuery">查询</el-button>
          <el-button :icon="Refresh" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>流程定义列表</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增流程定义</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="flowKey" label="流程标识" width="150" />
        <el-table-column prop="flowName" label="流程名称" min-width="150" />
        <el-table-column prop="flowVersion" label="版本号" width="100" />
        <el-table-column prop="flowConfig" label="流程配置" min-width="200" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.status === 'DRAFT'" type="info">草稿</el-tag>
            <el-tag v-else-if="row.status === 'PUBLISHED'" type="success">已发布</el-tag>
            <el-tag v-else-if="row.status === 'ARCHIVED'" type="warning">已归档</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" :icon="Edit" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" :icon="Delete" link @click="handleDelete(row.id)">删除</el-button>
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
        @size-change="handleSizeChange"
      />
    </el-card>

    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="700px"
      :close-on-click-modal="false"
    >
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="流程标识" prop="flowKey">
          <el-input v-model="formData.flowKey" placeholder="请输入流程标识" :disabled="!!currentEditId" />
        </el-form-item>
        <el-form-item label="流程名称" prop="flowName">
          <el-input v-model="formData.flowName" placeholder="请输入流程名称" />
        </el-form-item>
        <el-form-item label="流程配置" prop="flowConfig">
          <el-input
            v-model="formData.flowConfig"
            type="textarea"
            :rows="8"
            placeholder="请输入流程配置（JSON格式）"
          />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="formData.status" placeholder="请选择状态" style="width: 100%">
            <el-option
              v-for="item in statusOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
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
.definition-container {
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
