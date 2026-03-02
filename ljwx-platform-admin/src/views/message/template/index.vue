<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import {
  getTemplateList,
  createTemplate,
  updateTemplate,
  deleteTemplate,
  type MsgTemplateVO,
  type MsgTemplateQueryDTO,
  type MsgTemplateCreateDTO,
  type MsgTemplateUpdateDTO,
} from '@/api/message/template'
import type { PageResult } from '@ljwx/shared'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<MsgTemplateVO[]>([])
const total = ref(0)

const query = reactive<MsgTemplateQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  templateCode: undefined,
  templateName: undefined,
  templateType: undefined,
  status: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<MsgTemplateVO> = await getTemplateList(query)
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
  query.templateCode = undefined
  query.templateName = undefined
  query.templateType = undefined
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
const dialogTitle = ref('新增模板')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface TemplateForm {
  templateCode: string
  templateName: string
  templateType: string
  subject: string
  content: string
  variables: string
  status: string
}

const formData = reactive<TemplateForm>({
  templateCode: '',
  templateName: '',
  templateType: 'INBOX',
  subject: '',
  content: '',
  variables: '',
  status: 'ENABLED',
})

const rules: FormRules<TemplateForm> = {
  templateCode: [
    { required: true, message: '请输入模板编码', trigger: 'blur' },
    { max: 50, message: '模板编码长度不能超过50', trigger: 'blur' },
  ],
  templateName: [
    { required: true, message: '请输入模板名称', trigger: 'blur' },
    { max: 100, message: '模板名称长度不能超过100', trigger: 'blur' },
  ],
  templateType: [{ required: true, message: '请选择模板类型', trigger: 'change' }],
  content: [{ required: true, message: '请输入模板内容', trigger: 'blur' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }],
}

function openCreate(): void {
  editingId.value = null
  dialogTitle.value = '新增模板'
  formData.templateCode = ''
  formData.templateName = ''
  formData.templateType = 'INBOX'
  formData.subject = ''
  formData.content = ''
  formData.variables = ''
  formData.status = 'ENABLED'
  dialogVisible.value = true
}

function openEdit(row: MsgTemplateVO): void {
  editingId.value = row.id
  dialogTitle.value = '编辑模板'
  formData.templateCode = row.templateCode
  formData.templateName = row.templateName
  formData.templateType = row.templateType
  formData.subject = row.subject || ''
  formData.content = row.content
  formData.variables = row.variables || ''
  formData.status = row.status
  dialogVisible.value = true
}

async function handleSubmit(): Promise<void> {
  if (!formRef.value) return
  await formRef.value.validate()

  try {
    if (editingId.value) {
      const dto: MsgTemplateUpdateDTO = {
        templateCode: formData.templateCode,
        templateName: formData.templateName,
        templateType: formData.templateType,
        subject: formData.subject || undefined,
        content: formData.content,
        variables: formData.variables || undefined,
        status: formData.status,
      }
      await updateTemplate(editingId.value, dto)
      ElMessage.success('更新成功')
    } else {
      const dto: MsgTemplateCreateDTO = {
        templateCode: formData.templateCode,
        templateName: formData.templateName,
        templateType: formData.templateType,
        subject: formData.subject || undefined,
        content: formData.content,
        variables: formData.variables || undefined,
        status: formData.status,
      }
      await createTemplate(dto)
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    loadData()
  } catch (error) {
    // Error handled by axios interceptor
  }
}

async function handleDelete(id: number): Promise<void> {
  try {
    await ElMessageBox.confirm('确认删除该模板吗？', '提示', {
      type: 'warning',
    })
    await deleteTemplate(id)
    ElMessage.success('删除成功')
    loadData()
  } catch (error) {
    // User cancelled or error handled by interceptor
  }
}

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="template-container">
    <!-- 搜索栏 -->
    <el-card class="search-card">
      <el-form :inline="true" :model="query">
        <el-form-item label="模板编码">
          <el-input v-model="query.templateCode" placeholder="请输入模板编码" clearable />
        </el-form-item>
        <el-form-item label="模板名称">
          <el-input v-model="query.templateName" placeholder="请输入模板名称" clearable />
        </el-form-item>
        <el-form-item label="模板类型">
          <el-select v-model="query.templateType" placeholder="请选择模板类型" clearable>
            <el-option label="站内信" value="INBOX" />
            <el-option label="邮件" value="EMAIL" />
            <el-option label="短信" value="SMS" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="请选择状态" clearable>
            <el-option label="启用" value="ENABLED" />
            <el-option label="禁用" value="DISABLED" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>消息模板列表</span>
          <el-button type="primary" @click="openCreate">新增模板</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="templateCode" label="模板编码" width="150" />
        <el-table-column prop="templateName" label="模板名称" width="150" />
        <el-table-column prop="templateType" label="模板类型" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.templateType === 'INBOX'" type="primary">站内信</el-tag>
            <el-tag v-else-if="row.templateType === 'EMAIL'" type="success">邮件</el-tag>
            <el-tag v-else-if="row.templateType === 'SMS'" type="warning">短信</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="subject" label="邮件主题" width="150" show-overflow-tooltip />
        <el-table-column prop="content" label="模板内容" min-width="200" show-overflow-tooltip />
        <el-table-column prop="variables" label="变量列表" width="150" show-overflow-tooltip />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.status === 'ENABLED'" type="success">启用</el-tag>
            <el-tag v-else type="info">禁用</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="openEdit(row)">编辑</el-button>
            <el-button type="danger" size="small" @click="handleDelete(row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="query.pageNum"
        v-model:page-size="query.pageSize"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="600px">
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="100px">
        <el-form-item label="模板编码" prop="templateCode">
          <el-input v-model="formData.templateCode" placeholder="请输入模板编码" />
        </el-form-item>
        <el-form-item label="模板名称" prop="templateName">
          <el-input v-model="formData.templateName" placeholder="请输入模板名称" />
        </el-form-item>
        <el-form-item label="模板类型" prop="templateType">
          <el-select v-model="formData.templateType" placeholder="请选择模板类型">
            <el-option label="站内信" value="INBOX" />
            <el-option label="邮件" value="EMAIL" />
            <el-option label="短信" value="SMS" />
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
            placeholder='请输入变量列表（JSON 数组格式，如：["userName", "orderNo"]）'
          />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="formData.status">
            <el-radio value="ENABLED">启用</el-radio>
            <el-radio value="DISABLED">禁用</el-radio>
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

