<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type {
  OpenAppVO,
  OpenAppQueryDTO,
  OpenAppCreateDTO,
  OpenAppUpdateDTO,
} from '@/api/system/open-api-app'
import {
  getAppList,
  createApp,
  updateApp,
  deleteApp,
  regenerateSecret,
} from '@/api/system/open-api-app'

const loading = ref(false)
const tableData = ref<OpenAppVO[]>([])
const total = ref(0)

const queryForm = reactive<OpenAppQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  appName: '',
  appType: '',
  status: '',
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res = await getAppList(queryForm)
    tableData.value = res.rows
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function handleQuery(): void {
  queryForm.pageNum = 1
  loadData()
}

function handleReset(): void {
  queryForm.pageNum = 1
  queryForm.pageSize = 10
  queryForm.appName = ''
  queryForm.appType = ''
  queryForm.status = ''
  loadData()
}

const dialogVisible = ref(false)
const dialogTitle = ref('新增应用')
const isEdit = ref(false)
const currentId = ref<number>(0)
const formRef = ref<FormInstance>()

interface AppForm {
  appName: string
  appType: 'INTERNAL' | 'EXTERNAL'
  rateLimit: number
  ipWhitelist: string
  expireTime: string
}

const formData = reactive<AppForm>({
  appName: '',
  appType: 'INTERNAL',
  rateLimit: 100,
  ipWhitelist: '',
  expireTime: '',
})

const rules: FormRules<AppForm> = {
  appName: [{ required: true, message: '请输入应用名称', trigger: 'blur' }],
  appType: [{ required: true, message: '请选择应用类型', trigger: 'change' }],
  rateLimit: [
    { required: true, message: '请输入限流配置', trigger: 'blur' },
    { type: 'number', min: 1, message: '限流值至少为 1', trigger: 'blur' },
  ],
}

function handleCreate(): void {
  dialogTitle.value = '新增应用'
  isEdit.value = false
  formData.appName = ''
  formData.appType = 'INTERNAL'
  formData.rateLimit = 100
  formData.ipWhitelist = ''
  formData.expireTime = ''
  dialogVisible.value = true
}

function handleEdit(row: OpenAppVO): void {
  dialogTitle.value = '编辑应用'
  isEdit.value = true
  currentId.value = row.id
  formData.appName = row.appName
  formData.appType = row.appType
  formData.rateLimit = row.rateLimit
  formData.ipWhitelist = row.ipWhitelist || ''
  formData.expireTime = row.expireTime || ''
  dialogVisible.value = true
}

async function handleSubmit(): Promise<void> {
  if (!formRef.value) return
  await formRef.value.validate()

  if (isEdit.value) {
    const dto: OpenAppUpdateDTO = {
      appName: formData.appName,
      rateLimit: formData.rateLimit,
      ipWhitelist: formData.ipWhitelist || undefined,
      expireTime: formData.expireTime || undefined,
    }
    await updateApp(currentId.value, dto)
    ElMessage.success('更新成功')
  } else {
    const dto: OpenAppCreateDTO = {
      appName: formData.appName,
      appType: formData.appType,
      rateLimit: formData.rateLimit,
      ipWhitelist: formData.ipWhitelist || undefined,
      expireTime: formData.expireTime || undefined,
    }
    const result = await createApp(dto)
    ElMessage.success('创建成功')
    if (result.appKey) {
      ElMessageBox.alert(
        `应用密钥（请妥善保管，仅显示一次）：${result.appKey}`,
        '创建成功',
        { type: 'success' }
      )
    }
  }
  dialogVisible.value = false
  loadData()
}

function handleCancel(): void {
  dialogVisible.value = false
  formRef.value?.resetFields()
}

async function handleDelete(row: OpenAppVO): Promise<void> {
  await ElMessageBox.confirm('确认删除该应用？删除后无法恢复', '警告', {
    type: 'warning',
  })
  await deleteApp(row.id)
  ElMessage.success('删除成功')
  loadData()
}

async function handleRegenerateSecret(row: OpenAppVO): Promise<void> {
  await ElMessageBox.confirm(
    '重新生成密钥后，旧密钥将立即失效，确认继续？',
    '警告',
    { type: 'warning' }
  )
  const newSecret = await regenerateSecret(row.id)
  ElMessageBox.alert(`新密钥（请妥善保管）：${newSecret}`, '密钥已重新生成', {
    type: 'success',
  })
  loadData()
}

function getStatusType(status: string): 'success' | 'info' {
  return status === 'ENABLED' ? 'success' : 'info'
}

function getStatusText(status: string): string {
  return status === 'ENABLED' ? '启用' : '禁用'
}

function getAppTypeText(type: string): string {
  return type === 'INTERNAL' ? '内部' : '外部'
}

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="app-container">
    <el-card class="search-card">
      <el-form :model="queryForm" inline>
        <el-form-item label="应用名称">
          <el-input
            v-model="queryForm.appName"
            placeholder="请输入应用名称"
            clearable
            @keyup.enter="handleQuery"
          />
        </el-form-item>
        <el-form-item label="应用类型">
          <el-select v-model="queryForm.appType" placeholder="请选择" clearable>
            <el-option label="内部" value="INTERNAL" />
            <el-option label="外部" value="EXTERNAL" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryForm.status" placeholder="请选择" clearable>
            <el-option label="启用" value="ENABLED" />
            <el-option label="禁用" value="DISABLED" />
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
          <span>开放 API 应用列表</span>
          <el-button type="primary" @click="handleCreate">新增应用</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="appKey" label="应用标识" min-width="200" />
        <el-table-column prop="appName" label="应用名称" min-width="150" />
        <el-table-column prop="appType" label="应用类型" width="100">
          <template #default="{ row }">
            {{ getAppTypeText(row.appType) }}
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="rateLimit" label="限流（次/秒）" width="120" />
        <el-table-column prop="expireTime" label="过期时间" width="180" />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="280" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="handleEdit(row)">
              编辑
            </el-button>
            <el-button
              type="warning"
              size="small"
              @click="handleRegenerateSecret(row)"
            >
              重新生成密钥
            </el-button>
            <el-button type="danger" size="small" @click="handleDelete(row)">
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="queryForm.pageNum"
        v-model:page-size="queryForm.pageSize"
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
        <el-form-item label="应用名称" prop="appName">
          <el-input
            v-model="formData.appName"
            placeholder="请输入应用名称"
            maxlength="100"
          />
        </el-form-item>
        <el-form-item v-if="!isEdit" label="应用类型" prop="appType">
          <el-radio-group v-model="formData.appType">
            <el-radio value="INTERNAL">内部</el-radio>
            <el-radio value="EXTERNAL">外部</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="限流配置" prop="rateLimit">
          <el-input-number
            v-model="formData.rateLimit"
            :min="1"
            :max="10000"
            placeholder="每秒请求数"
          />
          <span style="margin-left: 10px; color: #909399">次/秒</span>
        </el-form-item>
        <el-form-item label="IP 白名单">
          <el-input
            v-model="formData.ipWhitelist"
            type="textarea"
            :rows="3"
            placeholder="IP 地址列表（JSON 数组格式，如：[&quot;192.168.1.1&quot;, &quot;10.0.0.1&quot;]）"
          />
        </el-form-item>
        <el-form-item label="过期时间">
          <el-date-picker
            v-model="formData.expireTime"
            type="datetime"
            placeholder="选择过期时间"
            format="YYYY-MM-DD HH:mm:ss"
            value-format="YYYY-MM-DD HH:mm:ss"
          />
        </el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="handleCancel">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.app-container {
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

