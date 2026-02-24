<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type {
  SysConfigVO,
  ConfigQueryDTO,
  ConfigCreateDTO,
  ConfigUpdateDTO,
  PageResult,
} from '@ljwx/shared'
import { getConfigList, createConfig, updateConfig } from '@/api/config'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<SysConfigVO[]>([])
const total = ref(0)

const query = reactive<ConfigQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  configKey: undefined,
  configName: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<SysConfigVO> = await getConfigList(query)
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
  query.configKey = undefined
  query.configName = undefined
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
const dialogTitle = ref('新增配置')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface ConfigForm {
  configKey: string
  configValue: string
  configName: string
  remark: string
}

const formData = reactive<ConfigForm>({
  configKey: '',
  configValue: '',
  configName: '',
  remark: '',
})

const rules: FormRules<ConfigForm> = {
  configKey: [{ required: true, message: '请输入配置键名', trigger: 'blur' }],
  configValue: [{ required: true, message: '请输入配置值', trigger: 'blur' }],
  configName: [{ required: true, message: '请输入配置名称', trigger: 'blur' }],
}

function openCreate(): void {
  editingId.value = null
  dialogTitle.value = '新增配置'
  formData.configKey = ''
  formData.configValue = ''
  formData.configName = ''
  formData.remark = ''
  dialogVisible.value = true
}

function openEdit(row: SysConfigVO): void {
  editingId.value = row.id
  dialogTitle.value = '编辑配置'
  formData.configKey = row.configKey
  formData.configValue = row.configValue
  formData.configName = row.configName
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
      const createData: ConfigCreateDTO = {
        configKey: formData.configKey,
        configValue: formData.configValue,
        configName: formData.configName,
        remark: formData.remark || undefined,
      }
      await createConfig(createData)
      ElMessage.success('创建成功')
    } else {
      const updateData: ConfigUpdateDTO = {
        configKey: formData.configKey,
        configValue: formData.configValue,
        configName: formData.configName,
        remark: formData.remark || undefined,
      }
      await updateConfig(editingId.value, updateData)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    // error handled by interceptor
  }
}

async function handleViewDetail(row: SysConfigVO): Promise<void> {
  await ElMessageBox.alert(
    `<strong>键名：</strong>${row.configKey}<br/>
     <strong>配置值：</strong>${row.configValue}<br/>
     <strong>备注：</strong>${row.remark || '-'}`,
    `${row.configName} — 详情`,
    { dangerouslyUseHTMLString: true },
  )
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
        <el-form-item label="配置键名">
          <el-input v-model="query.configKey" placeholder="请输入配置键名" clearable />
        </el-form-item>
        <el-form-item label="配置名称">
          <el-input v-model="query.configName" placeholder="请输入配置名称" clearable />
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
          <span>系统配置列表</span>
          <el-button type="primary" @click="openCreate">新增配置</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="configName" label="配置名称" min-width="160" />
        <el-table-column prop="configKey" label="配置键名" min-width="160" />
        <el-table-column prop="configValue" label="配置值" min-width="160" show-overflow-tooltip />
        <el-table-column prop="remark" label="备注" min-width="160" show-overflow-tooltip />
        <el-table-column prop="createdTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="openEdit(row)">编辑</el-button>
            <el-button type="info" link size="small" @click="handleViewDetail(row)">详情</el-button>
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
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="520px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="90px">
        <el-form-item label="配置名称" prop="configName">
          <el-input v-model="formData.configName" placeholder="请输入配置名称" />
        </el-form-item>
        <el-form-item label="配置键名" prop="configKey">
          <el-input
            v-model="formData.configKey"
            :disabled="editingId !== null"
            placeholder="请输入配置键名"
          />
        </el-form-item>
        <el-form-item label="配置值" prop="configValue">
          <el-input
            v-model="formData.configValue"
            type="textarea"
            :rows="3"
            placeholder="请输入配置值"
          />
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
