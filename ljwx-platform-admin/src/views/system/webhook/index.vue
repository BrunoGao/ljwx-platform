<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type {
  WebhookConfigVO,
  WebhookConfigDTO,
  WebhookConfigQueryDTO,
  WebhookLogVO,
  WebhookLogQueryDTO,
} from '@/api/system/webhook'
import {
  createWebhook,
  updateWebhook,
  deleteWebhook,
  getWebhook,
  listWebhooks,
  listWebhookLogs,
} from '@/api/system/webhook'

const loading = ref(false)
const tableData = ref<WebhookConfigVO[]>([])
const total = ref(0)

const queryParams = reactive<WebhookConfigQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  webhookName: '',
  status: '',
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res = await listWebhooks(queryParams)
    tableData.value = res.rows
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function handleQuery(): void {
  queryParams.pageNum = 1
  loadData()
}

function handleReset(): void {
  queryParams.webhookName = ''
  queryParams.status = ''
  handleQuery()
}

const dialogVisible = ref(false)
const dialogTitle = ref('新增 Webhook')
const formRef = ref<FormInstance>()
const isEdit = ref(false)
const currentId = ref<number>()

interface WebhookForm {
  webhookName: string
  webhookUrl: string
  eventTypes: string[]
  secretKey: string
  status: 'ENABLED' | 'DISABLED'
  retryCount: number
  timeoutSeconds: number
}

const formData = reactive<WebhookForm>({
  webhookName: '',
  webhookUrl: '',
  eventTypes: [],
  secretKey: '',
  status: 'ENABLED',
  retryCount: 5,
  timeoutSeconds: 5,
})

const eventTypeOptions = [
  { label: '用户创建', value: 'user.created' },
  { label: '用户更新', value: 'user.updated' },
  { label: '用户删除', value: 'user.deleted' },
  { label: '订单创建', value: 'order.created' },
  { label: '订单支付', value: 'order.paid' },
  { label: '订单完成', value: 'order.completed' },
]

const rules: FormRules<WebhookForm> = {
  webhookName: [{ required: true, message: '请输入 Webhook 名称', trigger: 'blur' }],
  webhookUrl: [
    { required: true, message: '请输入 Webhook URL', trigger: 'blur' },
    { pattern: /^https?:\/\/.+/, message: 'URL 格式不正确', trigger: 'blur' },
  ],
  eventTypes: [{ required: true, message: '请选择事件类型', trigger: 'change' }],
  secretKey: [{ required: true, message: '请输入签名密钥', trigger: 'blur' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }],
}

function handleCreate(): void {
  dialogTitle.value = '新增 Webhook'
  isEdit.value = false
  currentId.value = undefined
  Object.assign(formData, {
    webhookName: '',
    webhookUrl: '',
    eventTypes: [],
    secretKey: '',
    status: 'ENABLED',
    retryCount: 5,
    timeoutSeconds: 5,
  })
  dialogVisible.value = true
}

async function handleEdit(row: WebhookConfigVO): Promise<void> {
  dialogTitle.value = '编辑 Webhook'
  isEdit.value = true
  currentId.value = row.id

  const res = await getWebhook(row.id)
  Object.assign(formData, {
    webhookName: res.webhookName,
    webhookUrl: res.webhookUrl,
    eventTypes: res.eventTypes,
    secretKey: '',
    status: res.status,
    retryCount: res.retryCount,
    timeoutSeconds: res.timeoutSeconds,
  })
  dialogVisible.value = true
}

async function handleSubmit(): Promise<void> {
  if (!formRef.value) return
  await formRef.value.validate()

  const dto: WebhookConfigDTO = {
    webhookName: formData.webhookName,
    webhookUrl: formData.webhookUrl,
    eventTypes: formData.eventTypes,
    secretKey: formData.secretKey,
    status: formData.status,
    retryCount: formData.retryCount,
    timeoutSeconds: formData.timeoutSeconds,
  }

  if (isEdit.value && currentId.value) {
    await updateWebhook(currentId.value, dto)
    ElMessage.success('更新成功')
  } else {
    await createWebhook(dto)
    ElMessage.success('创建成功')
  }

  dialogVisible.value = false
  loadData()
}

function handleCancel(): void {
  dialogVisible.value = false
  formRef.value?.resetFields()
}

async function handleDelete(row: WebhookConfigVO): Promise<void> {
  await ElMessageBox.confirm('确认删除该 Webhook 配置？', '警告', {
    type: 'warning',
  })

  await deleteWebhook(row.id)
  ElMessage.success('删除成功')
  loadData()
}

const logDialogVisible = ref(false)
const logLoading = ref(false)
const logTableData = ref<WebhookLogVO[]>([])
const logTotal = ref(0)
const currentWebhookId = ref<number>()
const currentWebhookName = ref('')

const logQueryParams = reactive<WebhookLogQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  eventType: '',
  status: '',
})

async function handleViewLogs(row: WebhookConfigVO): Promise<void> {
  currentWebhookId.value = row.id
  currentWebhookName.value = row.webhookName
  logQueryParams.pageNum = 1
  logQueryParams.eventType = ''
  logQueryParams.status = ''
  logDialogVisible.value = true
  loadLogData()
}

async function loadLogData(): Promise<void> {
  if (!currentWebhookId.value) return
  logLoading.value = true
  try {
    const res = await listWebhookLogs(currentWebhookId.value, logQueryParams)
    logTableData.value = res.rows
    logTotal.value = res.total
  } finally {
    logLoading.value = false
  }
}

function handleLogQuery(): void {
  logQueryParams.pageNum = 1
  loadLogData()
}

function getStatusType(status: string): 'success' | 'info' | 'warning' | 'danger' {
  return status === 'ENABLED' ? 'success' : 'info'
}

function getStatusText(status: string): string {
  return status === 'ENABLED' ? '启用' : '禁用'
}

function getLogStatusType(status: string): 'success' | 'danger' {
  return status === 'SUCCESS' ? 'success' : 'danger'
}

function getLogStatusText(status: string): string {
  return status === 'SUCCESS' ? '成功' : '失败'
}

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="webhook-container">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>Webhook 配置管理</span>
        </div>
      </template>

      <el-form :inline="true" :model="queryParams">
        <el-form-item label="Webhook 名称">
          <el-input
            v-model="queryParams.webhookName"
            placeholder="请输入 Webhook 名称"
            clearable
            @keyup.enter="handleQuery"
          />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryParams.status" placeholder="请选择状态" clearable>
            <el-option label="启用" value="ENABLED" />
            <el-option label="禁用" value="DISABLED" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
          <el-button type="success" @click="handleCreate">新增</el-button>
        </el-form-item>
      </el-form>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="webhookName" label="Webhook 名称" min-width="150" />
        <el-table-column prop="webhookUrl" label="推送 URL" min-width="200" show-overflow-tooltip />
        <el-table-column prop="eventTypes" label="事件类型" min-width="200">
          <template #default="{ row }">
            <el-tag
              v-for="(event, index) in row.eventTypes"
              :key="index"
              size="small"
              style="margin-right: 5px"
            >
              {{ event }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="retryCount" label="重试次数" width="100" />
        <el-table-column prop="timeoutSeconds" label="超时时间(秒)" width="120" />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="250" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="handleEdit(row)">
              编辑
            </el-button>
            <el-button type="info" size="small" @click="handleViewLogs(row)">
              日志
            </el-button>
            <el-button type="danger" size="small" @click="handleDelete(row)">
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="queryParams.pageNum"
        v-model:page-size="queryParams.pageSize"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="loadData"
        @current-change="loadData"
      />
    </el-card>

    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="600px"
      @close="handleCancel"
    >
      <el-form
        ref="formRef"
        :model="formData"
        :rules="rules"
        label-width="120px"
      >
        <el-form-item label="Webhook 名称" prop="webhookName">
          <el-input
            v-model="formData.webhookName"
            placeholder="请输入 Webhook 名称"
          />
        </el-form-item>
        <el-form-item label="推送 URL" prop="webhookUrl">
          <el-input
            v-model="formData.webhookUrl"
            placeholder="请输入推送 URL"
          />
        </el-form-item>
        <el-form-item label="事件类型" prop="eventTypes">
          <el-select
            v-model="formData.eventTypes"
            multiple
            placeholder="请选择事件类型"
            style="width: 100%"
          >
            <el-option
              v-for="item in eventTypeOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="签名密钥" prop="secretKey">
          <el-input
            v-model="formData.secretKey"
            type="password"
            placeholder="请输入签名密钥"
            show-password
          />
          <span style="color: #909399; font-size: 12px">
            用于 HMAC-SHA256 签名验证
          </span>
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="formData.status">
            <el-radio label="ENABLED">启用</el-radio>
            <el-radio label="DISABLED">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="重试次数" prop="retryCount">
          <el-input-number
            v-model="formData.retryCount"
            :min="0"
            :max="10"
          />
          <span style="margin-left: 10px; color: #909399">次（默认 5 次）</span>
        </el-form-item>
        <el-form-item label="超时时间" prop="timeoutSeconds">
          <el-input-number
            v-model="formData.timeoutSeconds"
            :min="1"
            :max="60"
          />
          <span style="margin-left: 10px; color: #909399">秒（默认 5 秒）</span>
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="handleCancel">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>

    <el-dialog
      v-model="logDialogVisible"
      :title="`推送日志 - ${currentWebhookName}`"
      width="90%"
      top="5vh"
    >
      <el-form :inline="true" :model="logQueryParams">
        <el-form-item label="事件类型">
          <el-input
            v-model="logQueryParams.eventType"
            placeholder="请输入事件类型"
            clearable
          />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="logQueryParams.status" placeholder="请选择状态" clearable>
            <el-option label="成功" value="SUCCESS" />
            <el-option label="失败" value="FAILURE" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleLogQuery">查询</el-button>
        </el-form-item>
      </el-form>

      <el-table v-loading="logLoading" :data="logTableData" border stripe max-height="500">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="eventType" label="事件类型" width="150" />
        <el-table-column prop="requestUrl" label="请求 URL" min-width="200" show-overflow-tooltip />
        <el-table-column prop="responseStatus" label="响应状态码" width="120" />
        <el-table-column prop="retryTimes" label="重试次数" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getLogStatusType(row.status)">
              {{ getLogStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="errorMessage" label="错误信息" min-width="200" show-overflow-tooltip />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
      </el-table>

      <el-pagination
        v-model:current-page="logQueryParams.pageNum"
        v-model:page-size="logQueryParams.pageSize"
        :total="logTotal"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="loadLogData"
        @current-change="loadLogData"
      />
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.webhook-container {
  padding: 20px;

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
</style>
