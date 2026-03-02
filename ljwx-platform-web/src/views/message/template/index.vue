<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus, Edit, Delete, Refresh } from '@element-plus/icons-vue'
import {
  listTemplates,
  createTemplate,
  updateTemplate,
  deleteTemplate,
  type MsgTemplateVO,
  type MsgTemplateDTO,
  type MsgTemplateQueryDTO
} from '@/api/message/template'

const loading = ref(false)
const tableData = ref<MsgTemplateVO[]>([])
const total = ref(0)
const queryParams = ref<MsgTemplateQueryDTO>({
  pageNum: 1,
  pageSize: 10
})

const dialogVisible = ref(false)
const dialogTitle = ref('新增模板')
const formRef = ref()
const formData = ref<MsgTemplateDTO>({
  templateCode: '',
  templateName: '',
  templateType: 'INBOX',
  subject: '',
  content: '',
  variables: '',
  status: 'ENABLED'
})

const formRules = {
  templateCode: [
    { required: true, message: '请输入模板编码', trigger: 'blur' },
    { max: 50, message: '模板编码长度不能超过50', trigger: 'blur' }
  ],
  templateName: [
    { required: true, message: '请输入模板名称', trigger: 'blur' },
    { max: 100, message: '模板名称长度不能超过100', trigger: 'blur' }
  ],
  templateType: [{ required: true, message: '请选择模板类型', trigger: 'change' }],
  content: [{ required: true, message: '请输入模板内容', trigger: 'blur' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }]
}

const templateTypeOptions = [
  { label: '站内信', value: 'INBOX' },
  { label: '邮件', value: 'EMAIL' },
  { label: '短信', value: 'SMS' }
]

const statusOptions = [
  { label: '启用', value: 'ENABLED' },
  { label: '禁用', value: 'DISABLED' }
]

const currentEditId = ref<number | null>(null)

async function fetchList() {
  loading.value = true
  try {
    const res = await listTemplates(queryParams.value)
    tableData.value = res.data.rows
    total.value = res.data.total
  } catch (error) {
    ElMessage.error('获取模板列表失败')
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
  dialogTitle.value = '新增模板'
  currentEditId.value = null
  formData.value = {
    templateCode: '',
    templateName: '',
    templateType: 'INBOX',
    subject: '',
    content: '',
    variables: '',
    status: 'ENABLED'
  }
  dialogVisible.value = true
}

function handleEdit(row: MsgTemplateVO) {
  dialogTitle.value = '编辑模板'
  currentEditId.value = row.id
  formData.value = {
    templateCode: row.templateCode,
    templateName: row.templateName,
    templateType: row.templateType,
    subject: row.subject,
    content: row.content,
    variables: row.variables,
    status: row.status
  }
  dialogVisible.value = true
}

async function handleDelete(id: number) {
  try {
    await ElMessageBox.confirm('确认删除该模板吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await deleteTemplate(id)
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
      await updateTemplate(currentEditId.value, formData.value)
      ElMessage.success('更新成功')
    } else {
      await createTemplate(formData.value)
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
  <div class="template-container">
    <el-card class="search-card">
      <el-form :inline="true" :model="queryParams">
        <el-form-item label="模板编码">
          <el-input v-model="queryParams.templateCode" placeholder="请输入模板编码" clearable />
        </el-form-item>
        <el-form-item label="模板名称">
          <el-input v-model="queryParams.templateName" placeholder="请输入模板名称" clearable />
        </el-form-item>
        <el-form-item label="模板类型">
          <el-select v-model="queryParams.templateType" placeholder="请选择模板类型" clearable>
            <el-option
              v-for="item in templateTypeOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
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
          <span>模板列表</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增模板</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="templateCode" label="模板编码" width="150" />
        <el-table-column prop="templateName" label="模板名称" min-width="150" />
        <el-table-column prop="templateType" label="模板类型" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.templateType === 'INBOX'" type="primary">站内信</el-tag>
            <el-tag v-else-if="row.templateType === 'EMAIL'" type="success">邮件</el-tag>
            <el-tag v-else-if="row.templateType === 'SMS'" type="warning">短信</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="subject" label="邮件主题" min-width="150" show-overflow-tooltip />
        <el-table-column prop="content" label="模板内容" min-width="200" show-overflow-tooltip />
        <el-table-column prop="variables" label="变量列表" min-width="150" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.status === 'ENABLED'" type="success">启用</el-tag>
            <el-tag v-else type="info">禁用</el-tag>
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
        <el-form-item label="模板编码" prop="templateCode">
          <el-input v-model="formData.templateCode" placeholder="请输入模板编码" :disabled="!!currentEditId" />
        </el-form-item>
        <el-form-item label="模板名称" prop="templateName">
          <el-input v-model="formData.templateName" placeholder="请输入模板名称" />
        </el-form-item>
        <el-form-item label="模板类型" prop="templateType">
          <el-select v-model="formData.templateType" placeholder="请选择模板类型" style="width: 100%">
            <el-option
              v-for="item in templateTypeOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="邮件主题" prop="subject">
          <el-input v-model="formData.subject" placeholder="请输入邮件主题（邮件类型必填）" />
        </el-form-item>
        <el-form-item label="模板内容" prop="content">
          <el-input
            v-model="formData.content"
            type="textarea"
            :rows="6"
            placeholder="请输入模板内容，使用 {{variable_name}} 格式定义变量"
          />
        </el-form-item>
        <el-form-item label="变量列表" prop="variables">
          <el-input
            v-model="formData.variables"
            type="textarea"
            :rows="3"
            placeholder="请输入变量列表（JSON数组格式，如：[&quot;userName&quot;, &quot;orderNo&quot;]）"
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
.template-container {
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


