<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import {
  getSubscriptionList,
  createSubscription,
  updateSubscription,
  deleteSubscription,
  updateSubscriptionStatus,
  type MsgSubscriptionVO,
  type MsgSubscriptionQueryDTO,
  type MsgSubscriptionCreateDTO,
  type MsgSubscriptionUpdateDTO,
} from '@/api/message/subscription'
import type { PageResult } from '@ljwx/shared'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<MsgSubscriptionVO[]>([])
const total = ref(0)

const query = reactive<MsgSubscriptionQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  userId: undefined,
  templateId: undefined,
  channel: undefined,
  status: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<MsgSubscriptionVO> = await getSubscriptionList(query)
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
  query.userId = undefined
  query.templateId = undefined
  query.channel = undefined
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
const dialogTitle = ref('新增订阅')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface SubscriptionForm {
  userId: number | undefined
  templateId: number | undefined
  channel: string
  status: string
  preference: string
}

const formData = reactive<SubscriptionForm>({
  userId: undefined,
  templateId: undefined,
  channel: 'EMAIL',
  status: 'ACTIVE',
  preference: '',
})

const rules: FormRules<SubscriptionForm> = {
  userId: [{ required: true, message: '请输入用户ID', trigger: 'blur' }],
  templateId: [{ required: true, message: '请输入模板ID', trigger: 'blur' }],
  channel: [{ required: true, message: '请选择渠道', trigger: 'change' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }],
}

function openCreate(): void {
  editingId.value = null
  dialogTitle.value = '新增订阅'
  formData.userId = undefined
  formData.templateId = undefined
  formData.channel = 'EMAIL'
  formData.status = 'ACTIVE'
  formData.preference = ''
  dialogVisible.value = true
}

function openEdit(row: MsgSubscriptionVO): void {
  editingId.value = row.id
  dialogTitle.value = '编辑订阅'
  formData.userId = row.userId
  formData.templateId = row.templateId
  formData.channel = row.channel
  formData.status = row.status
  formData.preference = row.preference || ''
  dialogVisible.value = true
}

async function handleSubmit(): Promise<void> {
  if (!formRef.value) return
  await formRef.value.validate()

  try {
    if (editingId.value) {
      const dto: MsgSubscriptionUpdateDTO = {
        userId: formData.userId!,
        templateId: formData.templateId!,
        channel: formData.channel,
        status: formData.status,
        preference: formData.preference || undefined,
      }
      await updateSubscription(editingId.value, dto)
      ElMessage.success('更新成功')
    } else {
      const dto: MsgSubscriptionCreateDTO = {
        userId: formData.userId!,
        templateId: formData.templateId!,
        channel: formData.channel,
        status: formData.status,
        preference: formData.preference || undefined,
      }
      await createSubscription(dto)
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
    await ElMessageBox.confirm('确认删除该订阅吗？', '提示', {
      type: 'warning',
    })
    await deleteSubscription(id)
    ElMessage.success('删除成功')
    loadData()
  } catch (error) {
    // User cancelled or error handled by interceptor
  }
}

async function handleStatusChange(row: MsgSubscriptionVO): Promise<void> {
  try {
    const newStatus = row.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE'
    await updateSubscriptionStatus(row.id, newStatus)
    ElMessage.success('状态更新成功')
    loadData()
  } catch (error) {
    // Error handled by axios interceptor
  }
}

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="subscription-container">
    <!-- 搜索栏 -->
    <el-card class="search-card">
      <el-form :inline="true" :model="query">
        <el-form-item label="用户ID">
          <el-input v-model.number="query.userId" placeholder="请输入用户ID" clearable />
        </el-form-item>
        <el-form-item label="模板ID">
          <el-input v-model.number="query.templateId" placeholder="请输入模板ID" clearable />
        </el-form-item>
        <el-form-item label="渠道">
          <el-select v-model="query.channel" placeholder="请选择渠道" clearable>
            <el-option label="邮件" value="EMAIL" />
            <el-option label="短信" value="SMS" />
            <el-option label="微信" value="WECHAT" />
            <el-option label="推送" value="PUSH" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="请选择状态" clearable>
            <el-option label="激活" value="ACTIVE" />
            <el-option label="未激活" value="INACTIVE" />
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
          <span>消息订阅列表</span>
          <el-button type="primary" @click="openCreate">新增订阅</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="userId" label="用户ID" width="100" />
        <el-table-column prop="userName" label="用户名" width="120" />
        <el-table-column prop="templateId" label="模板ID" width="100" />
        <el-table-column prop="templateName" label="模板名称" width="150" show-overflow-tooltip />
        <el-table-column prop="channel" label="渠道" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.channel === 'EMAIL'" type="success">邮件</el-tag>
            <el-tag v-else-if="row.channel === 'SMS'" type="warning">短信</el-tag>
            <el-tag v-else-if="row.channel === 'WECHAT'" type="primary">微信</el-tag>
            <el-tag v-else-if="row.channel === 'PUSH'" type="info">推送</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.status === 'ACTIVE'" type="success">激活</el-tag>
            <el-tag v-else type="info">未激活</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="preference" label="订阅偏好" min-width="150" show-overflow-tooltip />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="240" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="openEdit(row)">编辑</el-button>
            <el-button type="warning" size="small" @click="handleStatusChange(row)">
              {{ row.status === 'ACTIVE' ? '停用' : '启用' }}
            </el-button>
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
        <el-form-item label="用户ID" prop="userId">
          <el-input v-model.number="formData.userId" placeholder="请输入用户ID" />
        </el-form-item>
        <el-form-item label="模板ID" prop="templateId">
          <el-input v-model.number="formData.templateId" placeholder="请输入模板ID" />
        </el-form-item>
        <el-form-item label="渠道" prop="channel">
          <el-select v-model="formData.channel" placeholder="请选择渠道">
            <el-option label="邮件" value="EMAIL" />
            <el-option label="短信" value="SMS" />
            <el-option label="微信" value="WECHAT" />
            <el-option label="推送" value="PUSH" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="formData.status">
            <el-radio value="ACTIVE">激活</el-radio>
            <el-radio value="INACTIVE">未激活</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="订阅偏好" prop="preference">
          <el-input
            v-model="formData.preference"
            type="textarea"
            :rows="4"
            placeholder='请输入订阅偏好（JSON 格式，如：{"frequency": "daily", "time": "09:00"}）'
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
.subscription-container {
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
