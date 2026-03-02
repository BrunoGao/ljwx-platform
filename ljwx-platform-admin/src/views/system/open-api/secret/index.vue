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

  const result = await createSecret(appId.value, dto)
  ElMessage.success('密钥生成成功')

  // Show plaintext secret only on creation (AC-02)
  if (result.secretKey) {
    await ElMessageBox.alert(
      `密钥（请妥善保管，仅显示一次）：\n\n${result.secretKey}`,
      '密钥已生成',
      {
        type: 'success',
        confirmButtonText: '已复制保存',
      }
    )
  }

  dialogVisible.value = false
  loadData()
}

function handleCancel(): void {
  dialogVisible.value = false
  formRef.value?.resetFields()
}

async function handleRotate(row: OpenAppSecretVO): Promise<void> {
  await ElMessageBox.confirm(
    '轮换密钥后，旧密钥将立即失效，确认继续？',
    '警告',
    {
      type: 'warning',
      confirmButtonText: '确认轮换',
      cancelButtonText: '取消',
    }
  )

  const result = await rotateSecret(appId.value, row.id)
  ElMessage.success('密钥轮换成功')

  // Show new secret after rotation (AC-03)
  if (result.secretKey) {
    await ElMessageBox.alert(
      `新密钥（请妥善保管，仅显示一次）：\n\n${result.secretKey}`,
      '密钥已轮换',
      {
        type: 'success',
        confirmButtonText: '已复制保存',
      }
    )
  }

  loadData()
}

async function handleDelete(row: OpenAppSecretVO): Promise<void> {
  await ElMessageBox.confirm(
    '确认删除该密钥？删除后无法恢复',
    '警告',
    {
      type: 'warning',
      confirmButtonText: '确认删除',
      cancelButtonText: '取消',
    }
  )

  await deleteSecret(appId.value, row.id)
  ElMessage.success('删除成功')
  loadData()
}

function maskSecret(secret: string): string {
  if (!secret || secret.length <= 8) return '****'
  return secret.substring(0, 4) + '****' + secret.substring(secret.length - 4)
}

function getStatusType(status: string): 'success' | 'info' {
  return status === 'ACTIVE' ? 'success' : 'info'
}

function getStatusText(status: string): string {
  return status === 'ACTIVE' ? '激活' : '已过期'
}

function isExpiringSoon(expireTime?: string): boolean {
  if (!expireTime) return false
  const expire = new Date(expireTime)
  const now = new Date()
  const daysUntilExpire = (expire.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
  return daysUntilExpire > 0 && daysUntilExpire <= 30
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
          <div class="header-actions">
            <el-alert
              v-if="tableData.filter(s => s.status === 'ACTIVE').length >= 3"
              type="warning"
              :closable="false"
              show-icon
              style="margin-right: 12px"
            >
              已达到最大密钥数量限制（3个）
            </el-alert>
            <el-button
              type="primary"
              :disabled="tableData.filter(s => s.status === 'ACTIVE').length >= 3"
              @click="handleCreate"
            >
              生成密钥
            </el-button>
          </div>
        </div>
      </template>

      <el-alert
        type="info"
        :closable="false"
        show-icon
        style="margin-bottom: 16px"
      >
        <template #title>
          <div>密钥说明</div>
        </template>
        <ul style="margin: 8px 0; padding-left: 20px">
          <li>密钥用于 HMAC-SHA256 签名验证，确保 API 请求的安全性</li>
          <li>每个应用最多保留 3 个激活状态的密钥</li>
          <li>密钥仅在生成和轮换时显示一次，请妥善保管</li>
          <li>密钥过期后将自动标记为"已过期"状态</li>
          <li>建议定期轮换密钥以提高安全性</li>
        </ul>
      </el-alert>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="secretKey" label="密钥" min-width="200">
          <template #default="{ row }">
            <el-tooltip content="密钥已加密存储，仅在生成时显示明文" placement="top">
              <span class="secret-masked">{{ maskSecret(row.secretKey) }}</span>
            </el-tooltip>
          </template>
        </el-table-column>
        <el-table-column prop="secretVersion" label="版本" width="100" align="center">
          <template #default="{ row }">
            <el-tag size="small">v{{ row.secretVersion }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">
              {{ getStatusText(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="expireTime" label="过期时间" width="180">
          <template #default="{ row }">
            <div v-if="row.expireTime">
              <span :class="{ 'expire-warning': isExpiringSoon(row.expireTime) }">
                {{ row.expireTime }}
              </span>
              <el-tag
                v-if="isExpiringSoon(row.expireTime)"
                type="warning"
                size="small"
                style="margin-left: 8px"
              >
                即将过期
              </el-tag>
            </div>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="200" fixed="right" align="center">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 'ACTIVE'"
              type="warning"
              size="small"
              @click="handleRotate(row)"
            >
              轮换
            </el-button>
            <el-button
              type="danger"
              size="small"
              @click="handleDelete(row)"
            >
              删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-empty
        v-if="!loading && tableData.length === 0"
        description="暂无密钥，请点击"生成密钥"按钮创建"
      />
    </el-card>

    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="500px"
      :close-on-click-modal="false"
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
            :step="30"
            placeholder="请输入有效天数"
            style="width: 200px"
          />
          <span style="margin-left: 10px; color: #909399">天（默认 365 天）</span>
        </el-form-item>
        <el-alert
          type="warning"
          :closable="false"
          show-icon
          style="margin-top: 16px"
        >
          密钥生成后仅显示一次，请务必妥善保管
        </el-alert>
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

    .header-actions {
      display: flex;
      align-items: center;
    }
  }

  .secret-masked {
    font-family: 'Courier New', monospace;
    color: #606266;
  }

  .expire-warning {
    color: #e6a23c;
    font-weight: 500;
  }
}
</style>
