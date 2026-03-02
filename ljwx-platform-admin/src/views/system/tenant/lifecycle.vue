<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getTenantList, freezeTenant, unfreezeTenant, cancelTenant, initializeTenant } from '@/api/tenant'
import type { TenantVO } from '@ljwx/shared'

const loading = ref(false)
const tenants = ref<TenantVO[]>([])
const total = ref(0)
const queryParams = ref({
  pageNum: 1,
  pageSize: 10,
  name: '',
  code: '',
})

const freezeDialogVisible = ref(false)
const cancelDialogVisible = ref(false)
const currentTenant = ref<TenantVO | null>(null)
const freezeForm = ref({ reason: '' })
const cancelForm = ref({ reason: '' })

onMounted(() => {
  loadTenants()
})

async function loadTenants() {
  loading.value = true
  try {
    const res = await getTenantList(queryParams.value)
    tenants.value = res.rows
    total.value = res.total
  } catch (error) {
    ElMessage.error('加载租户列表失败')
  } finally {
    loading.value = false
  }
}

function handleQuery() {
  queryParams.value.pageNum = 1
  loadTenants()
}

function handleReset() {
  queryParams.value = {
    pageNum: 1,
    pageSize: 10,
    name: '',
    code: '',
  }
  loadTenants()
}

function getLifecycleStatusTag(status: string) {
  const statusMap: Record<string, { type: 'success' | 'warning' | 'danger'; label: string }> = {
    ACTIVE: { type: 'success', label: '活跃' },
    FROZEN: { type: 'warning', label: '冻结' },
    CANCELLED: { type: 'danger', label: '注销' },
  }
  return statusMap[status] || { type: 'success', label: status }
}

function showFreezeDialog(tenant: TenantVO) {
  currentTenant.value = tenant
  freezeForm.value.reason = ''
  freezeDialogVisible.value = true
}

async function handleFreeze() {
  if (!currentTenant.value) return
  if (!freezeForm.value.reason.trim()) {
    ElMessage.warning('请输入冻结原因')
    return
  }

  try {
    await freezeTenant(currentTenant.value.id, freezeForm.value)
    ElMessage.success('冻结成功')
    freezeDialogVisible.value = false
    loadTenants()
  } catch (error) {
    ElMessage.error('冻结失败')
  }
}

async function handleUnfreeze(tenant: TenantVO) {
  try {
    await ElMessageBox.confirm('确认解冻该租户吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })
    await unfreezeTenant(tenant.id)
    ElMessage.success('解冻成功')
    loadTenants()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('解冻失败')
    }
  }
}

function showCancelDialog(tenant: TenantVO) {
  currentTenant.value = tenant
  cancelForm.value.reason = ''
  cancelDialogVisible.value = true
}

async function handleCancel() {
  if (!currentTenant.value) return
  if (!cancelForm.value.reason.trim()) {
    ElMessage.warning('请输入注销原因')
    return
  }

  try {
    await cancelTenant(currentTenant.value.id, cancelForm.value)
    ElMessage.success('注销成功')
    cancelDialogVisible.value = false
    loadTenants()
  } catch (error) {
    ElMessage.error('注销失败')
  }
}

async function handleInitialize(tenant: TenantVO) {
  try {
    await ElMessageBox.confirm('确认初始化该租户吗？将创建默认管理员、角色和部门。', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })
    await initializeTenant(tenant.id)
    ElMessage.success('初始化成功')
    loadTenants()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('初始化失败')
    }
  }
}

function handlePageChange(page: number) {
  queryParams.value.pageNum = page
  loadTenants()
}
</script>

<template>
  <div class="tenant-lifecycle-container">
    <el-card class="search-card">
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

    <el-card class="table-card">
      <el-table v-loading="loading" :data="tenants" border>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="租户名称" />
        <el-table-column prop="code" label="租户编码" />
        <el-table-column label="生命周期状态" width="120">
          <template #default="{ row }">
            <el-tag :type="getLifecycleStatusTag(row.lifecycleStatus).type">
              {{ getLifecycleStatusTag(row.lifecycleStatus).label }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="frozenReason" label="冻结原因" show-overflow-tooltip />
        <el-table-column prop="frozenTime" label="冻结时间" width="180" />
        <el-table-column prop="cancelledReason" label="注销原因" show-overflow-tooltip />
        <el-table-column prop="cancelledTime" label="注销时间" width="180" />
        <el-table-column label="操作" width="300" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="row.lifecycleStatus === 'ACTIVE'"
              type="warning"
              size="small"
              @click="showFreezeDialog(row)"
            >
              冻结
            </el-button>
            <el-button
              v-if="row.lifecycleStatus === 'FROZEN'"
              type="success"
              size="small"
              @click="handleUnfreeze(row)"
            >
              解冻
            </el-button>
            <el-button
              v-if="row.lifecycleStatus === 'ACTIVE'"
              type="danger"
              size="small"
              @click="showCancelDialog(row)"
            >
              注销
            </el-button>
            <el-button
              v-if="row.lifecycleStatus === 'ACTIVE'"
              type="primary"
              size="small"
              @click="handleInitialize(row)"
            >
              初始化
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
        @current-change="handlePageChange"
        @size-change="loadTenants"
      />
    </el-card>

    <el-dialog v-model="freezeDialogVisible" title="冻结租户" width="500px">
      <el-form :model="freezeForm" label-width="100px">
        <el-form-item label="冻结原因" required>
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
        <el-button type="primary" @click="handleFreeze">确定</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="cancelDialogVisible" title="注销租户" width="500px">
      <el-form :model="cancelForm" label-width="100px">
        <el-form-item label="注销原因" required>
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
        <el-button type="danger" @click="handleCancel">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.tenant-lifecycle-container {
  padding: 20px;

  .search-card {
    margin-bottom: 20px;
  }

  .table-card {
    .el-pagination {
      margin-top: 20px;
      justify-content: flex-end;
    }
  }
}
</style>
