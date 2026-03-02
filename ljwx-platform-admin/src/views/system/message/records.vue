<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type {
  MsgRecordVO,
  MsgRecordQueryDTO,
  MessageSendDTO,
} from '@/api/system/message'
import { listMessageRecords, sendMessage, getMessageRecord } from '@/api/system/message'
import type { PageResult } from '@ljwx/shared'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<MsgRecordVO[]>([])
const total = ref(0)

const query = reactive<MsgRecordQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  messageType: undefined,
  sendStatus: undefined,
  receiverId: undefined,
  startTime: undefined,
  endTime: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<MsgRecordVO> = await listMessageRecords(query)
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
  query.messageType = undefined
  query.sendStatus = undefined
  query.receiverId = undefined
  query.startTime = undefined
  query.endTime = undefined
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

// ─── 发送消息弹窗 ────────────────────────────────────────────────
const dialogVisible = ref(false)
const formRef = ref<FormInstance>()

interface MessageForm {
  templateId: number | undefined
  messageType: 'INBOX' | 'EMAIL' | 'SMS'
  receiverId: number | undefined
  receiverAddress: string
  subject: string
  content: string
}

const formData = reactive<MessageForm>({
  templateId: undefined,
  messageType: 'INBOX',
  receiverId: undefined,
  receiverAddress: '',
  subject: '',
  content: '',
})

const rules: FormRules<MessageForm> = {
  templateId: [{ required: true, message: '请输入消息模板ID', trigger: 'blur' }],
  messageType: [{ required: true, message: '请选择消息类型', trigger: 'change' }],
  receiverId: [{ required: true, message: '请输入接收用户ID', trigger: 'blur' }],
  subject: [{ required: true, message: '请输入消息主题', trigger: 'blur' }],
  content: [{ required: true, message: '请输入消息内容', trigger: 'blur' }],
}

function openSendDialog(): void {
  formData.templateId = undefined
  formData.messageType = 'INBOX'
  formData.receiverId = undefined
  formData.receiverAddress = ''
  formData.subject = ''
  formData.content = ''
  dialogVisible.value = true
}

async function handleSend(): Promise<void> {
  try {
    await formRef.value?.validate()
  } catch {
    return
  }
  try {
    const sendData: MessageSendDTO = {
      templateId: formData.templateId!,
      messageType: formData.messageType,
      receiverId: formData.receiverId!,
      subject: formData.subject,
      content: formData.content,
    }
    if (formData.receiverAddress) {
      sendData.receiverAddress = formData.receiverAddress
    }
    await sendMessage(sendData)
    ElMessage.success('消息发送成功')
    dialogVisible.value = false
    loadData()
  } catch {
    // error handled by interceptor
  }
}

// ─── 查看详情 ────────────────────────────────────────────────
const detailDialogVisible = ref(false)
const detailData = ref<MsgRecordVO | null>(null)

async function handleViewDetail(row: MsgRecordVO): Promise<void> {
  try {
    detailData.value = await getMessageRecord(row.id)
    detailDialogVisible.value = true
  } catch {
    // error handled by interceptor
  }
}

// ─── 消息类型标签 ────────────────────────────────────────────────
function getMessageTypeTag(type: string): { type: 'primary' | 'success' | 'warning'; label: string } {
  const map: Record<string, { type: 'primary' | 'success' | 'warning'; label: string }> = {
    INBOX: { type: 'primary', label: '站内信' },
    EMAIL: { type: 'success', label: '邮件' },
    SMS: { type: 'warning', label: '短信' },
  }
  return map[type] || { type: 'primary', label: type }
}

// ─── 发送状态标签 ────────────────────────────────────────────────
function getSendStatusTag(status: string): { type: 'info' | 'success' | 'danger'; label: string } {
  const map: Record<string, { type: 'info' | 'success' | 'danger'; label: string }> = {
    PENDING: { type: 'info', label: '待发送' },
    SUCCESS: { type: 'success', label: '成功' },
    FAILURE: { type: 'danger', label: '失败' },
  }
  return map[status] || { type: 'info', label: status }
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
        <el-form-item label="消息类型">
          <el-select v-model="query.messageType" placeholder="请选择消息类型" clearable style="width: 120px">
            <el-option label="站内信" value="INBOX" />
            <el-option label="邮件" value="EMAIL" />
            <el-option label="短信" value="SMS" />
          </el-select>
        </el-form-item>
        <el-form-item label="发送状态">
          <el-select v-model="query.sendStatus" placeholder="请选择发送状态" clearable style="width: 120px">
            <el-option label="待发送" value="PENDING" />
            <el-option label="成功" value="SUCCESS" />
            <el-option label="失败" value="FAILURE" />
          </el-select>
        </el-form-item>
        <el-form-item label="接收用户ID">
          <el-input v-model.number="query.receiverId" placeholder="请输入接收用户ID" clearable />
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
          <span>消息记录列表</span>
          <el-button type="primary" @click="openSendDialog">发送消息</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column label="消息类型" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="getMessageTypeTag(row.messageType).type" size="small">
              {{ getMessageTypeTag(row.messageType).label }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="subject" label="消息主题" min-width="200" show-overflow-tooltip />
        <el-table-column prop="receiverId" label="接收用户ID" width="120" />
        <el-table-column prop="receiverAddress" label="接收地址" width="180" show-overflow-tooltip />
        <el-table-column label="发送状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="getSendStatusTag(row.sendStatus).type" size="small">
              {{ getSendStatusTag(row.sendStatus).label }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="sendTime" label="发送时间" width="160" />
        <el-table-column prop="createdTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="handleViewDetail(row)">详情</el-button>
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

    <!-- 发送消息弹窗 -->
    <el-dialog v-model="dialogVisible" title="发送消息" width="600px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="100px">
        <el-form-item label="模板ID" prop="templateId">
          <el-input v-model.number="formData.templateId" placeholder="请输入消息模板ID" />
        </el-form-item>
        <el-form-item label="消息类型" prop="messageType">
          <el-select v-model="formData.messageType" style="width: 100%">
            <el-option label="站内信" value="INBOX" />
            <el-option label="邮件" value="EMAIL" />
            <el-option label="短信" value="SMS" />
          </el-select>
        </el-form-item>
        <el-form-item label="接收用户ID" prop="receiverId">
          <el-input v-model.number="formData.receiverId" placeholder="请输入接收用户ID" />
        </el-form-item>
        <el-form-item
          v-if="formData.messageType === 'EMAIL' || formData.messageType === 'SMS'"
          label="接收地址"
        >
          <el-input
            v-model="formData.receiverAddress"
            :placeholder="formData.messageType === 'EMAIL' ? '请输入邮箱地址' : '请输入手机号'"
          />
        </el-form-item>
        <el-form-item label="消息主题" prop="subject">
          <el-input v-model="formData.subject" placeholder="请输入消息主题" />
        </el-form-item>
        <el-form-item label="消息内容" prop="content">
          <el-input
            v-model="formData.content"
            type="textarea"
            :rows="6"
            placeholder="请输入消息内容"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSend">发送</el-button>
      </template>
    </el-dialog>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailDialogVisible" title="消息详情" width="700px" destroy-on-close>
      <el-descriptions v-if="detailData" :column="2" border>
        <el-descriptions-item label="消息ID">{{ detailData.id }}</el-descriptions-item>
        <el-descriptions-item label="模板ID">{{ detailData.templateId }}</el-descriptions-item>
        <el-descriptions-item label="消息类型">
          <el-tag :type="getMessageTypeTag(detailData.messageType).type" size="small">
            {{ getMessageTypeTag(detailData.messageType).label }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="发送状态">
          <el-tag :type="getSendStatusTag(detailData.sendStatus).type" size="small">
            {{ getSendStatusTag(detailData.sendStatus).label }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="接收用户ID">{{ detailData.receiverId }}</el-descriptions-item>
        <el-descriptions-item label="接收地址">{{ detailData.receiverAddress || '-' }}</el-descriptions-item>
        <el-descriptions-item label="消息主题" :span="2">{{ detailData.subject }}</el-descriptions-item>
        <el-descriptions-item label="消息内容" :span="2">
          <div class="content-text">{{ detailData.content }}</div>
        </el-descriptions-item>
        <el-descriptions-item label="发送时间">{{ detailData.sendTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ detailData.createdTime }}</el-descriptions-item>
        <el-descriptions-item v-if="detailData.errorMessage" label="错误信息" :span="2">
          <div class="error-text">{{ detailData.errorMessage }}</div>
        </el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
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

.content-text {
  white-space: pre-wrap;
  word-break: break-word;
  max-height: 200px;
  overflow-y: auto;
}

.error-text {
  color: var(--el-color-danger);
  white-space: pre-wrap;
  word-break: break-word;
}
</style>