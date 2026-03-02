<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Refresh, Delete, Key, CopyDocument } from '@element-plus/icons-vue'
import {
  listSecrets,
  createSecret,
  rotateSecret,
  deleteSecret,
  type OpenAppSecretVO,
  type OpenAppSecretDTO
} from '@/api/system/open-api-secret'

const route = useRoute()
const appId = ref<number>(Number(route.params.appId))

const loading = ref(false)
const tableData = ref<OpenAppSecretVO[]>([])

const dialogVisible = ref(false)
const formRef = ref()
const formData = ref<OpenAppSecretDTO>({
  appId: appId.value,
  validDays: 365
})

const formRules = {
  validDays: [
    { required: true, message: '请输入有效天数', trigger: 'blur' },
    { type: 'number', min: 1, max: 3650, message: '有效天数范围为 1-3650 天', trigger: 'blur' }
  ]
}

const newSecretKey = ref<string>('')
const showSecretDialog = ref(false)

async function fetchList() {
  loading.value = true
  try {
    const res = await listSecrets(appId.value)
    tableData.value = res.data
  } catch (error) {
    ElMessage.error('获取密钥列表失败')
  } finally {
    loading.value = false
  }
}

function handleAdd() {
  formData.value = {
    appId: appId.value,
    validDays: 365
  }
  dialogVisible.value = true
}

async function handleSubmit() {
  if (!formRef.value) return
  await formRef.value.validate()

  try {
    const res = await createSecret(appId.value, formData.value)
    newSecretKey.value = res.data.secretKey
    showSecretDialog.value = true
    dialogVisible.value = false
    fetchList()
    ElMessage.success('密钥生成成功')
  } catch (error) {
    ElMessage.error('密钥生成失败')
  }
}

async function handleRotate(row: OpenAppSecretVO) {
  try {
    await ElMessageBox.confirm('轮换密钥后，旧密钥将立即失效。确认轮换吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    const res = await rotateSecret(appId.value, row.id)
    newSecretKey.value = res.data.secretKey
    showSecretDialog.value = true
    fetchList()
    ElMessage.success('密钥轮换成功')
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('密钥轮换失败')
    }
  }
}

async function handleDelete(id: number) {
  try {
    await ElMessageBox.confirm('确认删除该密钥吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await deleteSecret(appId.value, id)
    ElMessage.success('删除成功')
    fetchList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

function copyToClipboard(text: string) {
  navigator.clipboard.writeText(text).then(() => {
    ElMessage.success('已复制到剪贴板')
  }).catch(() => {
    ElMessage.error('复制失败')
  })
}

function maskSecret(secret: string): string {
  if (secret.length <= 8) return '****'
  return secret.substring(0, 4) + '****' + secret.substring(secret.length - 4)
}

function getStatusType(status: string) {
  return status === 'ACTIVE' ? 'success' : 'info'
}

function getStatusText(status: string) {
  return status === 'ACTIVE' ? '激活' : '已过期'
}

onMounted(() => {
  fetchList()
})
</script>

<template>
  <div class="secret-container">
    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>密钥列表</span>
          <div>
            <el-button :icon="Refresh" @click="fetchList">刷新</el-button>
            <el-button type="primary" :icon="Plus" @click="handleAdd">生成密钥</el-button>
          </div>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="secretVersion" label="版本" width="80" />
        <el-table-column label="密钥" min-width="200">
          <template #default="{ row }">
            <span>{{ maskSecret(row.secretKey) }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="getStatusType(row.status)">{{ getStatusText(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="expireTime" label="过期时间" width="180" />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 'ACTIVE'"
              type="warning"
              :icon="Key"
              link
              @click="handleRotate(row)"
            >
              轮换
            </el-button>
            <el-button type="danger" :icon="Delete" link @click="handleDelete(row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog
      v-model="dialogVisible"
      title="生成密钥"
      width="500px"
      :close-on-click-modal="false"
    >
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="有效天数" prop="validDays">
          <el-input-number
            v-model="formData.validDays"
            :min="1"
            :max="3650"
            placeholder="请输入有效天数"
            style="width: 100%"
          />
        </el-form-item>
        <el-alert
          title="提示"
          type="info"
          :closable="false"
          show-icon
        >
          密钥生成后仅显示一次，请妥善保管
        </el-alert>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>

    <el-dialog
      v-model="showSecretDialog"
      title="密钥已生成"
      width="600px"
      :close-on-click-modal="false"
    >
      <el-alert
        title="请妥善保管密钥，关闭后将无法再次查看完整密钥"
        type="warning"
        :closable="false"
        show-icon
        style="margin-bottom: 20px"
      />
      <el-form label-width="80px">
        <el-form-item label="密钥">
          <el-input
            v-model="newSecretKey"
            readonly
            type="textarea"
            :rows="3"
          >
            <template #append>
              <el-button :icon="CopyDocument" @click="copyToClipboard(newSecretKey)">复制</el-button>
            </template>
          </el-input>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button type="primary" @click="showSecretDialog = false">我已保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.secret-container {
  padding: 20px;

  .table-card {
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
  }
}
</style>

