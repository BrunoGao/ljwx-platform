<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Search, Plus, Edit, Delete, Refresh } from '@element-plus/icons-vue'
import {
  listSubscriptions,
  createSubscription,
  updateSubscription,
  deleteSubscription,
  type MsgSubscriptionVO,
  type MsgSubscriptionDTO,
  type MsgSubscriptionQueryDTO
} from '@/api/message/subscription'

const loading = ref(false)
const tableData = ref<MsgSubscriptionVO[]>([])
const total = ref(0)
const queryParams = ref<MsgSubscriptionQueryDTO>({
  pageNum: 1,
  pageSize: 10
})

const dialogVisible = ref(false)
const dialogTitle = ref('新增订阅')
const formRef = ref()
const formData = ref<MsgSubscriptionDTO>({
  userId: 0,
  templateId: 0,
  channel: 'EMAIL',
  status: 'ACTIVE',
  preference: ''
})

const formRules = {
  userId: [{ required: true, message: '请输入用户ID', trigger: 'blur' }],
  templateId: [{ required: true, message: '请输入模板ID', trigger: 'blur' }],
  channel: [{ required: true, message: '请选择渠道', trigger: 'change' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }]
}

const channelOptions = [
  { label: '邮件', value: 'EMAIL' },
  { label: '短信', value: 'SMS' },
  { label: '微信', value: 'WECHAT' },
  { label: '推送', value: 'PUSH' }
]

const statusOptions = [
  { label: '激活', value: 'ACTIVE' },
  { label: '停用', value: 'INACTIVE' }
]

const currentEditId = ref<number | null>(null)

async function fetchList() {
  loading.value = true
  try {
    const res = await listSubscriptions(queryParams.value)
    tableData.value = res.data.rows
    total.value = res.data.total
  } catch (error) {
    ElMessage.error('获取订阅列表失败')
  } finally {
    loading.value = false
  }
}

function handleQuery() {
  queryParams.value.pageNum = 1
  fetchList()
}

function handleReset() {
  queryParams.value = {
    pageNum: 1,
    pageSize: 10
  }
  fetchList()
}

function handleAdd() {
  dialogTitle.value = '新增订阅'
  currentEditId.value = null
  formData.value = {
    userId: 0,
    templateId: 0,
    channel: 'EMAIL',
    status: 'ACTIVE',
    preference: ''
  }
  dialogVisible.value = true
}

function handleEdit(row: MsgSubscriptionVO) {
  dialogTitle.value = '编辑订阅'
  currentEditId.value = row.id
  formData.value = {
    userId: row.userId,
    templateId: row.templateId,
    channel: row.channel,
    status: row.status,
    preference: row.preference
  }
  dialogVisible.value = true
}

async function handleDelete(id: number) {
  try {
    await ElMessageBox.confirm('确认删除该订阅吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await deleteSubscription(id)
    ElMessage.success('删除成功')
    fetchList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

async function handleSubmit() {
  if (!formRef.value) return
  await formRef.value.validate()

  try {
    if (currentEditId.value) {
      await updateSubscription(currentEditId.value, formData.value)
      ElMessage.success('更新成功')
    } else {
      await createSubscription(formData.value)
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    fetchList()
  } catch (error) {
    ElMessage.error(currentEditId.value ? '更新失败' : '创建失败')
  }
}

function handlePageChange(page: number) {
  queryParams.value.pageNum = page
  fetchList()
}

function handleSizeChange(size: number) {
  queryParams.value.pageSize = size
  queryParams.value.pageNum = 1
  fetchList()
}

onMounted(() => {
  fetchList()
})
</script>

<template>
  <div class="subscription-container">
    <el-card class="search-card">
      <el-form :inline="true" :model="queryParams">
        <el-form-item label="用户ID">
          <el-input v-model="queryParams.userId" placeholder="请输入用户ID" clearable />
        </el-form-item>
        <el-form-item label="模板ID">
          <el-input v-model="queryParams.templateId" placeholder="请输入模板ID" clearable />
        </el-form-item>
        <el-form-item label="渠道">
          <el-select v-model="queryParams.channel" placeholder="请选择渠道" clearable>
            <el-option
              v-for="item in channelOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryParams.status" placeholder="请选择状态" clearable>
            <el-option
              v-for="item in statusOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :icon="Search" @click="handleQuery">查询</el-button>
          <el-button :icon="Refresh" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card">
      <template #header>
        <div class="card-header">
          <span>订阅列表</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增订阅</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="userId" label="用户ID" width="100" />
        <el-table-column prop="userName" label="用户名" width="120" />
        <el-table-column prop="templateId" label="模板ID" width="100" />
        <el-table-column prop="templateName" label="模板名称" min-width="150" />
        <el-table-column prop="channel" label="渠道" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.channel === 'EMAIL'" type="primary">邮件</el-tag>
            <el-tag v-else-if="row.channel === 'SMS'" type="success">短信</el-tag>
            <el-tag v-else-if="row.channel === 'WECHAT'" type="warning">微信</el-tag>
            <el-tag v-else-if="row.channel === 'PUSH'" type="info">推送</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.status === 'ACTIVE'" type="success">激活</el-tag>
            <el-tag v-else type="info">停用</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="preference" label="订阅偏好" min-width="150" show-overflow-tooltip />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" :icon="Edit" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" :icon="Delete" link @click="handleDelete(row.id)">删除</el-button>
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
        @size-change="handleSizeChange"
      />
    </el-card>

    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="600px"
      :close-on-click-modal="false"
    >
      <el-form ref="formRef" :model="formData" :rules="formRules" label-width="100px">
        <el-form-item label="用户ID" prop="userId">
          <el-input v-model.number="formData.userId" placeholder="请输入用户ID" />
        </el-form-item>
        <el-form-item label="模板ID" prop="templateId">
          <el-input v-model.number="formData.templateId" placeholder="请输入模板ID" />
        </el-form-item>
        <el-form-item label="渠道" prop="channel">
          <el-select v-model="formData.channel" placeholder="请选择渠道" style="width: 100%">
            <el-option
              v-for="item in channelOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="formData.status" placeholder="请选择状态" style="width: 100%">
            <el-option
              v-for="item in statusOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="订阅偏好" prop="preference">
          <el-input
            v-model="formData.preference"
            type="textarea"
            :rows="4"
            placeholder="请输入订阅偏好（JSON格式）"
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

