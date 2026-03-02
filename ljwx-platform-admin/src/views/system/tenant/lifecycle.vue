<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import { getTenantList, freezeTenant, unfreezeTenant, cancelTenant, initializeTenant } from '@/api/tenant'
import type { TenantVO, TenantQueryDTO, TenantFreezeDTO, TenantCancelDTO, PageResult } from '@ljwx/shared'

const loading = ref(false)
const tenants = ref<TenantVO[]>([])
const total = ref(0)

const queryParams = reactive<TenantQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  name: undefined,
  code: undefined,
  status: undefined,
})

const freezeDialogVisible = ref(false)
const cancelDialogVisible = ref(false)
const detailDialogVisible = ref(false)
const currentTenant = ref<TenantVO | null>(null)
const freezeFormRef = ref<FormInstance>()
const cancelFormRef = ref<FormInstance>()

interface FreezeForm {
  reason: string
}

interface CancelForm {
  reason: string
}

const freezeForm = reactive<FreezeForm>({ reason: '' })
const cancelForm = reactive<CancelForm>({ reason: '' })

const freezeRules: FormRules<FreezeForm> = {
  reason: [
    { required: true, message: '请输入冻结原因', trigger: 'blur' },
    { max: 500, message: '冻结原因不能超过500个字符', trigger: 'blur' },
  ],
}

const cancelRules: FormRules<CancelForm> = {
  reason: [
    { required: true, message: '请输入注销原因', trigger: 'blur' },
    { max: 500, message: '注销原因不能超过500个字符', trigger: 'blur' },
  ],
}

async function loadTenants(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<TenantVO> = await getTenantList(queryParams)
    tenants.value = res.rows
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function handleQuery(): void {
  queryParams.pageNum = 1
  loadTenants()
}

function handleReset(): void {
  queryParams.name = undefined
  queryParams.code = undefined
  queryParams.status = undefined
  queryParams.pageNum = 1
  loadTenants()
}

function handleSizeChange(size: number): void {
  queryParams.pageSize = size
  queryParams.pageNum = 1
  loadTenants()
}

function handlePageChange(page: number): void {
  queryParams.pageNum = page
  loadTenants()
}

function getLifecycleStatusTag(status: string): { type: 'success' | 'warning' | 'danger'; label: string } {
  const statusMap: Record<string, { type: 'success' | 'warning' | 'danger'; label: string }> = {
    ACTIVE: { type: 'success', label: '活跃' },
    FROZEN: { type: 'warning', label: '冻结' },
    CANCELLED: { type: 'danger', label: '注销' },
  }
  return statusMap[status] || { type: 'success', label: status }
}

function showFreezeDialog(tenant: TenantVO): void {
  currentTenant.value = tenant
  freezeForm.reason = ''
  freezeDialogVisible.value = true
}

async function handleFreeze(): Promise<void> {
  try {
    await freezeFormRef.value?.validate()
  } catch {
    return
  }
  try {
    const data: TenantFreezeDTO = { reason: freezeForm.reason }
    await freezeTenant(currentTenant.value!.id, data)
    ElMessage.success('冻结成功')
    freezeDialogVisible.value = false
    loadTenants()
  } catch {
    // error handled by interceptor
  }
}

async function handleUnfreeze(tenant: TenantVO): Promise<void> {
  try {
    await ElMessageBox.confirm(
      `确定解冻租户 "${tenant.name}" 吗？解冻后租户将恢复正常访问。`,
      '解冻确认',
      { type: 'warning' },
    )
    await unfreezeTenant(tenant.id)
    ElMessage.success('解冻成功')
    loadTenants()
  } catch {
    // cancelled or error
  }
}

function showCancelDialog(tenant: TenantVO): void {
  currentTenant.value = tenant
  cancelForm.reason = ''
  cancelDialogVisible.value = true
}

async function handleCancel(): Promise<void> {
  try {
    await cancelFormRef.value?.validate()
  } catch {
    return
  }
  try {
    await ElMessageBox.confirm(
      `确定注销租户 "${currentTenant.value!.name}" 吗？注销后租户将无法访问系统，此操作不可逆！`,
      '注销确认',
      { type: 'error', confirmButtonText: '确定注销', cancelButtonText: '取消' },
    )
    const data: TenantCancelDTO = { reason: cancelForm.reason }
    await cancelTenant(currentTenant.value!.id, data)
    ElMessage.success('注销成功')
    cancelDialogVisible.value = false
    loadTenants()
  } catch {
    // cancelled or error
  }
}

async function handleInitialize(tenant: TenantVO): Promise<void> {
  try {
    await ElMessageBox.confirm(
      `确定初始化租户 "${tenant.name}" 吗？将创建默认管理员、角色和部门。`,
      '初始化确认',
      { type: 'warning' },
    )
    await initializeTenant(tenant.id)
    ElMessage.success('初始化成功')
    loadTenants()
  } catch {
    // cancelled or error
  }
}

function showDetail(tenant: TenantVO): void {
  currentTenant.value = tenant
  detailDialogVisible.value = true
}

onMounted(() => {
  loadTenants()
})
</script>

<template>
  <div class="page-container">
    <!-- 搜索栏 -->
    <el-card class="search-card" shadow="never">
      <el-form :model="queryParams" inline>
        <el-form-item label="租户名称">
          <el-input
            v-model="queryParams.name"
            placeholder="请输入租户名称"
            clearable
            @keyup.enter="handleQuery"
          />
        </el-form-item>
        <el-form-item label="租户编码">
          <el-input
            v-model="queryParams.code"
            placeholder="请输入租户编码"
            clearable
            @keyup.enter="handleQuery"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>租户生命周期管理</span>
        </div>
      </template>

      <el-table v-loading="loading" :data="tenants" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="租户名称" min-width="140" />
        <el-table-column prop="code" label="租户编码" min-width="140" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
              {{ row.status === 1 ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="生命周期状态" width="120" align="center">
          <template #default="{ row }">
            <el-tag :type="getLifecycleStatusTag(row.lifecycleStatus).type" size="small">
              {{ getLifecycleStatusTag(row.lifecycleStatus).label }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="frozenReason" label="冻结原因" min-width="140" show-overflow-tooltip />
        <el-table-column prop="frozenTime" label="冻结时间" width="160" />
        <el-table-column prop="cancelledReason" label="注销原因" min-width="140" show-overflow-tooltip />
        <el-table-column prop="cancelledTime" label="注销时间" width="160" />
        <el-table-column label="操作" width="300" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="row.lifecycleStatus === 'ACTIVE'"
              type="warning"
              link
              size="small"
              @click="showFreezeDialog(row)"
            >
              冻结
            </el-button>
            <el-button
              v-if="row.lifecycleStatus === 'FROZEN'"
              type="success"
              link
              size="small"
              @click="handleUnfreeze(row)"
            >
              解冻
            </el-button>
            <el-button
              v-if="row.lifecycleStatus === 'ACTIVE'"
              type="danger"
              link
              size="small"
              @click="showCancelDialog(row)"
            >
              注销
            </el-button>
            <el-button
              v-if="row.lifecycleStatus === 'ACTIVE'"
              type="primary"
              link
              size="small"
              @click="handleInitialize(row)"
            >
              初始化
            </el-button>
            <el-button type="info" link size="small" @click="showDetail(row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="queryParams.pageNum"
          v-model:page-size="queryParams.pageSize"
          :total="total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handlePageChange"
        />
      </div>
    </el-card>

    <!-- 冻结弹窗 -->
    <el-dialog v-model="freezeDialogVisible" title="冻结租户" width="480px" destroy-on-close>
      <el-alert
        v-if="currentTenant"
        :title="`即将冻结租户：${currentTenant.name}`"
        type="warning"
        :closable="false"
        style="margin-bottom: 16px"
      />
      <el-form ref="freezeFormRef" :model="freezeForm" :rules="freezeRules" label-width="90px">
        <el-form-item label="冻结原因" prop="reason">
          <el-input
            v-model="freezeForm.reason"
            type="textarea"
            :rows="4"
            placeholder="请输入冻结原因"
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="freezeDialogVisible = false">取消</el-button>
        <el-button type="warning" @click="handleFreeze">确定冻结</el-button>
      </template>
    </el-dialog>

    <!-- 注销弹窗 -->
    <el-dialog v-model="cancelDialogVisible" title="注销租户" width="480px" destroy-on-close>
      <el-alert
        v-if="currentTenant"
        :title="`即将注销租户：${currentTenant.name}`"
        type="error"
        description="注销后租户将无法访问系统，此操作不可逆！"
        :closable="false"
        style="margin-bottom: 16px"
      />
      <el-form ref="cancelFormRef" :model="cancelForm" :rules="cancelRules" label-width="90px">
        <el-form-item label="注销原因" prop="reason">
          <el-input
            v-model="cancelForm.reason"
            type="textarea"
            :rows="4"
            placeholder="请输入注销原因"
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="cancelDialogVisible = false">取消</el-button>
        <el-button type="danger" @click="handleCancel">确定注销</el-button>
      </template>
    </el-dialog>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailDialogVisible" title="租户生命周期详情" width="600px" destroy-on-close>
      <el-descriptions v-if="currentTenant" :column="1" border>
        <el-descriptions-item label="租户ID">{{ currentTenant.id }}</el-descriptions-item>
        <el-descriptions-item label="租户名称">{{ currentTenant.name }}</el-descriptions-item>
        <el-descriptions-item label="租户编码">{{ currentTenant.code }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="currentTenant.status === 1 ? 'success' : 'danger'" size="small">
            {{ currentTenant.status === 1 ? '启用' : '禁用' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="生命周期状态">
          <el-tag :type="getLifecycleStatusTag(currentTenant.lifecycleStatus).type" size="small">
            {{ getLifecycleStatusTag(currentTenant.lifecycleStatus).label }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item v-if="currentTenant.frozenReason" label="冻结原因">
          {{ currentTenant.frozenReason }}
        </el-descriptions-item>
        <el-descriptions-item v-if="currentTenant.frozenTime" label="冻结时间">
          {{ currentTenant.frozenTime }}
        </el-descriptions-item>
        <el-descriptions-item v-if="currentTenant.cancelledReason" label="注销原因">
          {{ currentTenant.cancelledReason }}
        </el-descriptions-item>
        <el-descriptions-item v-if="currentTenant.cancelledTime" label="注销时间">
          {{ currentTenant.cancelledTime }}
        </el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ currentTenant.createdTime }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ currentTenant.updatedTime }}</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button type="primary" @click="detailDialogVisible = false">关闭</el-button>
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
</style>
