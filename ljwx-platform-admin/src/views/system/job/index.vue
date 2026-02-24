<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type {
  SysJobVO,
  JobQueryDTO,
  JobCreateDTO,
  JobUpdateDTO,
  PageResult,
} from '@ljwx/shared'
import {
  getJobList,
  createJob,
  updateJob,
  executeJob,
  pauseJob,
  resumeJob,
} from '@/api/job'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<SysJobVO[]>([])
const total = ref(0)

const query = reactive<JobQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  jobName: undefined,
  jobGroup: undefined,
  status: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<SysJobVO> = await getJobList(query)
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
  query.jobName = undefined
  query.jobGroup = undefined
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
const dialogTitle = ref('新增任务')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface JobForm {
  jobName: string
  jobGroup: string
  jobClass: string
  cronExpression: string
  status: number
  remark: string
}

const formData = reactive<JobForm>({
  jobName: '',
  jobGroup: '',
  jobClass: '',
  cronExpression: '',
  status: 1,
  remark: '',
})

const rules: FormRules<JobForm> = {
  jobName: [{ required: true, message: '请输入任务名称', trigger: 'blur' }],
  jobClass: [{ required: true, message: '请输入执行类', trigger: 'blur' }],
  cronExpression: [{ required: true, message: '请输入 Cron 表达式', trigger: 'blur' }],
}

function openCreate(): void {
  editingId.value = null
  dialogTitle.value = '新增任务'
  formData.jobName = ''
  formData.jobGroup = ''
  formData.jobClass = ''
  formData.cronExpression = ''
  formData.status = 1
  formData.remark = ''
  dialogVisible.value = true
}

function openEdit(row: SysJobVO): void {
  editingId.value = row.id
  dialogTitle.value = '编辑任务'
  formData.jobName = row.jobName
  formData.jobGroup = row.jobGroup
  formData.jobClass = row.jobClass
  formData.cronExpression = row.cronExpression
  formData.status = row.status
  formData.remark = row.remark
  dialogVisible.value = true
}

async function handleSubmit(): Promise<void> {
  try {
    await formRef.value?.validate()
  } catch {
    return
  }
  try {
    if (editingId.value === null) {
      const createData: JobCreateDTO = {
        jobName: formData.jobName,
        jobGroup: formData.jobGroup || undefined,
        jobClass: formData.jobClass,
        cronExpression: formData.cronExpression,
        remark: formData.remark || undefined,
      }
      await createJob(createData)
      ElMessage.success('创建成功')
    } else {
      const updateData: JobUpdateDTO = {
        jobName: formData.jobName,
        jobGroup: formData.jobGroup || undefined,
        jobClass: formData.jobClass,
        cronExpression: formData.cronExpression,
        status: formData.status,
        remark: formData.remark || undefined,
      }
      await updateJob(editingId.value, updateData)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    // error handled by interceptor
  }
}

async function handleExecute(row: SysJobVO): Promise<void> {
  try {
    await ElMessageBox.confirm(`确定立即执行任务 "${row.jobName}" 吗？`, '执行确认', {
      type: 'warning',
    })
    await executeJob(row.id)
    ElMessage.success('执行成功')
    loadData()
  } catch {
    // cancelled or error
  }
}

async function handlePause(row: SysJobVO): Promise<void> {
  try {
    await pauseJob(row.id)
    ElMessage.success('暂停成功')
    loadData()
  } catch {
    // error handled by interceptor
  }
}

async function handleResume(row: SysJobVO): Promise<void> {
  try {
    await resumeJob(row.id)
    ElMessage.success('恢复成功')
    loadData()
  } catch {
    // error handled by interceptor
  }
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
        <el-form-item label="任务名称">
          <el-input v-model="query.jobName" placeholder="请输入任务名称" clearable />
        </el-form-item>
        <el-form-item label="任务组">
          <el-input v-model="query.jobGroup" placeholder="请输入任务组" clearable />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="请选择状态" clearable style="width: 120px">
            <el-option label="运行" :value="1" />
            <el-option label="暂停" :value="0" />
          </el-select>
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
          <span>定时任务列表</span>
          <el-button type="primary" @click="openCreate">新增任务</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="jobName" label="任务名称" min-width="160" show-overflow-tooltip />
        <el-table-column prop="jobGroup" label="任务组" min-width="120" />
        <el-table-column
          prop="jobClass"
          label="执行类"
          min-width="200"
          show-overflow-tooltip
        />
        <el-table-column prop="cronExpression" label="Cron 表达式" width="160" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'warning'" size="small">
              {{ row.status === 1 ? '运行' : '暂停' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createdTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="240" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="openEdit(row)">编辑</el-button>
            <el-button type="success" link size="small" @click="handleExecute(row)">执行</el-button>
            <el-button
              v-if="row.status === 1"
              type="warning"
              link
              size="small"
              @click="handlePause(row)"
            >
              暂停
            </el-button>
            <el-button
              v-else
              type="success"
              link
              size="small"
              @click="handleResume(row)"
            >
              恢复
            </el-button>
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

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="560px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="100px">
        <el-form-item label="任务名称" prop="jobName">
          <el-input v-model="formData.jobName" placeholder="请输入任务名称" />
        </el-form-item>
        <el-form-item label="任务组">
          <el-input v-model="formData.jobGroup" placeholder="请输入任务组（可选）" />
        </el-form-item>
        <el-form-item label="执行类" prop="jobClass">
          <el-input v-model="formData.jobClass" placeholder="请输入执行类全路径" />
        </el-form-item>
        <el-form-item label="Cron 表达式" prop="cronExpression">
          <el-input v-model="formData.cronExpression" placeholder="如：0 0/5 * * * ?" />
        </el-form-item>
        <el-form-item v-if="editingId !== null" label="状态">
          <el-select v-model="formData.status">
            <el-option label="运行" :value="1" />
            <el-option label="暂停" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" type="textarea" :rows="2" placeholder="请输入备注" />
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
