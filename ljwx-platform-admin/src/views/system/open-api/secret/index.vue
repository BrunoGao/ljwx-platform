<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import { useRoute } from 'vue-router'
import type { OpenAppSecretVO, OpenAppSecretDTO } from '@/api/system/open-api-secret'
import { createSecret, rotateSecret, deleteSecret, listSecrets } from '@/api/system/open-api-secret'

const route = useRoute()
const appId = computed(() => Number(route.params.appId))

const loading = ref(false)
const tableData = ref<OpenAppSecretVO[]>([])

async function loadData(): Promise<void> {
  if (!appId.value) {
    ElMessage.error('应用 ID 不能为空')
    return
  }
  loading.value = true
  try {
    const res = await listSecrets(appId.value)
    tableData.value = res
  } finally {
    loading.value = false
  }
}

const dialogVisible = ref(false)
const dialogTitle = ref('生成密钥')
const formRef = ref<FormInstance>()

interface SecretForm {
  validDays: number
}

const formData = reactive<SecretForm>({
  validDays: 365,
})

const rules: FormRules<SecretForm> = {
  validDays: [
    { required: true, message: '请输入有效天数', trigger: 'blur' },
    { type: 'number', min: 1, max: 3650, message: '有效天数范围 1-3650', trigger: 'blur' },
  ],
}

function handleCreate(): void {
  dialogTitle.value = '生成密钥'
  formData.validDays = 365
  dialogVisible.value = true
}

async function handleSubmit(): Promise<void> {
  if (!formRef.value) return
  await formRef.value.validate()

  const dto: OpenAppSecretDTO = {
    appId: appId.value,
    validDays: formData.validDays,
  }

  await createSecret(appId.value, dto)
  ElMessage.success('密钥生成成功')
  dialogVisible.value = false
  loadData()
}

function handleCancel(): void {
  dialogVisible.value = false
  formRef.value?.resetFields()
}

async function handleRotate(row: OpenAppSecretVO): Promise<void> {
  await ElMessageBox.confirm('轮换密钥后，旧密钥将立即失效，确认继续？', '警告', {
    type: 'warning',
  })

  await rotateSecret(appId.value, row.id)
  ElMessage.success('密钥轮换成功')
  loadData()
}

async function handleDelete(row: OpenAppSecretVO): Promise<void> {
  await ElMessageBox.confirm('确认删除该密钥？删除后无法恢复', '警告', {
    type: 'warning',
  })

  await deleteSecret(appId.value, row.id)
  ElMessage.success('删除成功')
  loadData()
}

function maskSecret(secret: string): string {
  if (secret.length <= 8) return '****'
  return secret.substring(0, 4) + '****' + secret.substring(secret.length - 4)
}

function getStatusType(status: string): 'success' | 'info' | 'warning' | 'danger' {
  return status === 'ACTIVE' ? 'success' : 'info'
}

function getStatusText(status: string): string {
  return status === 'ACTIVE' ? '激活' : '已过期'
}

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="secret-container">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>密钥管理</span>
          <el-button type="primary" @click="handleCreate">生成密钥</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="secretKey" label="密钥" min-width="200">
          <template #default="{ row }">
            <span>{{ maskSecret(row.secretKey) }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="secretVersion" label="版本" width="80" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="expireTime" label="过期时间" width="180" />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 'ACTIVE'"
              type="warning"
              size="small"
              @click="handleRotate(row)"
            >
              轮换
            </el-button>
            <el-button type="danger" size="small" @click="handleDelete(row)">
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="500px"
      @close="handleCancel"
    >
      <el-form
        ref="formRef"
        :model="formData"
        :rules="rules"
        label-width="100px"
      >
        <el-form-item label="有效天数" prop="validDays">
          <el-input-number
            v-model="formData.validDays"
            :min="1"
            :max="3650"
            placeholder="请输入有效天数"
          />
          <span style="margin-left: 10px; color: #909399">天（默认 365 天）</span>
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
.secret-container {
  padding: 20px;

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
}
</style>

