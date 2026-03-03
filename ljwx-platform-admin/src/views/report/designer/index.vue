<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type {
  ReportDefVO,
  ReportDefQueryDTO,
  ReportDefCreateDTO,
  ReportDefUpdateDTO,
  ColumnDefItem,
  FilterDefItem,
} from '@/api/report/report-def'
import type { PageResult } from '@ljwx/shared'
import {
  getReportDefList,
  getReportDefById,
  createReportDef,
  updateReportDef,
  deleteReportDef,
} from '@/api/report/report-def'

// ─── 报表定义列表 ─────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<ReportDefVO[]>([])
const total = ref(0)

const query = reactive<ReportDefQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  reportName: undefined,
  reportKey: undefined,
  status: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<ReportDefVO> = await getReportDefList(query)
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
  query.reportName = undefined
  query.reportKey = undefined
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

// ─── 报表定义弹窗 ─────────────────────────────────────────────
const dialogVisible = ref(false)
const dialogTitle = ref('新增报表')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface ReportDefForm {
  reportName: string
  reportKey: string
  dataSourceType: string
  queryTemplate: string
  columnDef: ColumnDefItem[]
  filterDef: FilterDefItem[]
  status: number
  remark: string
}

const formData = reactive<ReportDefForm>({
  reportName: '',
  reportKey: '',
  dataSourceType: 'SQL',
  queryTemplate: '',
  columnDef: [],
  filterDef: [],
  status: 1,
  remark: '',
})

const rules: FormRules<ReportDefForm> = {
  reportName: [{ required: true, message: '请输入报表名称', trigger: 'blur' }],
  reportKey: [
    { required: true, message: '请输入报表标识', trigger: 'blur' },
    { pattern: /^[a-z][a-z0-9_]*$/, message: '只能包含小写字母、数字和下划线，且以小写字母开头', trigger: 'blur' },
  ],
  queryTemplate: [{ required: true, message: '请输入 SQL 查询模板', trigger: 'blur' }],
}

function openCreate(): void {
  editingId.value = null
  dialogTitle.value = '新增报表'
  formData.reportName = ''
  formData.reportKey = ''
  formData.dataSourceType = 'SQL'
  formData.queryTemplate = ''
  formData.columnDef = []
  formData.filterDef = []
  formData.status = 1
  formData.remark = ''
  dialogVisible.value = true
}

async function openEdit(row: ReportDefVO): Promise<void> {
  editingId.value = row.id
  dialogTitle.value = '编辑报表'
  try {
    const detail = await getReportDefById(row.id)
    formData.reportName = detail.reportName
    formData.reportKey = detail.reportKey
    formData.dataSourceType = detail.dataSourceType
    formData.queryTemplate = detail.queryTemplate
    formData.columnDef = detail.columnDef || []
    formData.filterDef = detail.filterDef || []
    formData.status = detail.status
    formData.remark = detail.remark || ''
    dialogVisible.value = true
  } catch {
    // error handled by interceptor
  }
}

async function handleSubmit(): Promise<void> {
  try {
    await formRef.value?.validate()
  } catch {
    return
  }

  if (formData.columnDef.length === 0) {
    ElMessage.warning('请至少添加一个列定义')
    return
  }

  try {
    if (editingId.value === null) {
      const createData: ReportDefCreateDTO = {
        reportName: formData.reportName,
        reportKey: formData.reportKey,
        dataSourceType: formData.dataSourceType,
        queryTemplate: formData.queryTemplate,
        columnDef: formData.columnDef,
        filterDef: formData.filterDef.length > 0 ? formData.filterDef : undefined,
        remark: formData.remark || undefined,
      }
      await createReportDef(createData)
      ElMessage.success('创建成功')
    } else {
      const updateData: ReportDefUpdateDTO = {
        reportName: formData.reportName,
        dataSourceType: formData.dataSourceType,
        queryTemplate: formData.queryTemplate,
        columnDef: formData.columnDef,
        filterDef: formData.filterDef.length > 0 ? formData.filterDef : undefined,
        status: formData.status,
        remark: formData.remark || undefined,
      }
      await updateReportDef(editingId.value, updateData)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    // error handled by interceptor
  }
}

async function handleDelete(row: ReportDefVO): Promise<void> {
  try {
    await ElMessageBox.confirm(`确定删除报表 "${row.reportName}" 吗？`, '提示', {
      type: 'warning',
    })
    await deleteReportDef(row.id)
    ElMessage.success('删除成功')
    loadData()
  } catch {
    // user cancelled or error handled by interceptor
  }
}

// ─── 列定义管理 ─────────────────────────────────────────────
const columnDialogVisible = ref(false)
const columnFormRef = ref<FormInstance>()

interface ColumnForm {
  name: string
  title: string
  type: string
  width: number | undefined
  format: string
}

const columnForm = reactive<ColumnForm>({
  name: '',
  title: '',
  type: 'string',
  width: undefined,
  format: '',
})

const columnRules: FormRules<ColumnForm> = {
  name: [{ required: true, message: '请输入列名', trigger: 'blur' }],
  title: [{ required: true, message: '请输入列标题', trigger: 'blur' }],
  type: [{ required: true, message: '请选择列类型', trigger: 'change' }],
}

function openAddColumn(): void {
  columnForm.name = ''
  columnForm.title = ''
  columnForm.type = 'string'
  columnForm.width = undefined
  columnForm.format = ''
  columnDialogVisible.value = true
}

async function handleAddColumn(): Promise<void> {
  try {
    await columnFormRef.value?.validate()
  } catch {
    return
  }
  formData.columnDef.push({
    name: columnForm.name,
    title: columnForm.title,
    type: columnForm.type,
    width: columnForm.width,
    format: columnForm.format || undefined,
  })
  columnDialogVisible.value = false
}

function handleRemoveColumn(index: number): void {
  formData.columnDef.splice(index, 1)
}

// ─── 过滤器定义管理 ─────────────────────────────────────────────
const filterDialogVisible = ref(false)
const filterFormRef = ref<FormInstance>()

interface FilterForm {
  paramName: string
  paramType: string
  label: string
  required: boolean
  defaultValue: string
}

const filterForm = reactive<FilterForm>({
  paramName: '',
  paramType: 'string',
  label: '',
  required: false,
  defaultValue: '',
})

const filterRules: FormRules<FilterForm> = {
  paramName: [{ required: true, message: '请输入参数名', trigger: 'blur' }],
  paramType: [{ required: true, message: '请选择参数类型', trigger: 'change' }],
  label: [{ required: true, message: '请输入标签', trigger: 'blur' }],
}

function openAddFilter(): void {
  filterForm.paramName = ''
  filterForm.paramType = 'string'
  filterForm.label = ''
  filterForm.required = false
  filterForm.defaultValue = ''
  filterDialogVisible.value = true
}

async function handleAddFilter(): Promise<void> {
  try {
    await filterFormRef.value?.validate()
  } catch {
    return
  }
  formData.filterDef.push({
    paramName: filterForm.paramName,
    paramType: filterForm.paramType,
    label: filterForm.label,
    required: filterForm.required,
    defaultValue: filterForm.defaultValue || undefined,
  })
  filterDialogVisible.value = false
}

function handleRemoveFilter(index: number): void {
  formData.filterDef.splice(index, 1)
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
        <el-form-item label="报表名称">
          <el-input v-model="query.reportName" placeholder="请输入报表名称" clearable />
        </el-form-item>
        <el-form-item label="报表标识">
          <el-input v-model="query.reportKey" placeholder="请输入报表标识" clearable />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="请选择状态" clearable style="width: 120px">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
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
          <span>报表定义列表</span>
          <el-button type="primary" @click="openCreate">新增报表</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="reportName" label="报表名称" min-width="160" />
        <el-table-column prop="reportKey" label="报表标识" min-width="160" />
        <el-table-column prop="dataSourceType" label="数据源类型" width="120" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
              {{ row.status === 1 ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="160" show-overflow-tooltip />
        <el-table-column prop="createdTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="openEdit(row)">编辑</el-button>
            <el-button type="info" link size="small" @click="$router.push(`/report/preview?id=${row.id}`)">
              预览
            </el-button>
            <el-button type="danger" link size="small" @click="handleDelete(row)">删除</el-button>
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
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="800px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="110px">
        <el-form-item label="报表名称" prop="reportName">
          <el-input v-model="formData.reportName" placeholder="请输入报表名称" />
        </el-form-item>
        <el-form-item label="报表标识" prop="reportKey">
          <el-input
            v-model="formData.reportKey"
            :disabled="editingId !== null"
            placeholder="请输入报表标识（小写字母、数字、下划线）"
          />
        </el-form-item>
        <el-form-item label="数据源类型">
          <el-input v-model="formData.dataSourceType" disabled />
        </el-form-item>
        <el-form-item label="SQL 模板" prop="queryTemplate">
          <el-input
            v-model="formData.queryTemplate"
            type="textarea"
            :rows="6"
            placeholder="请输入 SQL 查询模板，使用 #{paramName} 作为参数占位符"
          />
        </el-form-item>
        <el-form-item label="列定义">
          <div class="def-list-wrapper">
            <el-button type="primary" size="small" @click="openAddColumn">添加列</el-button>
            <el-table :data="formData.columnDef" border size="small" style="margin-top: 8px">
              <el-table-column prop="name" label="列名" width="120" />
              <el-table-column prop="title" label="标题" width="120" />
              <el-table-column prop="type" label="类型" width="100" />
              <el-table-column prop="width" label="宽度" width="80" />
              <el-table-column prop="format" label="格式化" min-width="100" />
              <el-table-column label="操作" width="80" align="center">
                <template #default="{ $index }">
                  <el-button type="danger" link size="small" @click="handleRemoveColumn($index)">
                    删除
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-form-item>
        <el-form-item label="过滤器定义">
          <div class="def-list-wrapper">
            <el-button type="primary" size="small" @click="openAddFilter">添加过滤器</el-button>
            <el-table :data="formData.filterDef" border size="small" style="margin-top: 8px">
              <el-table-column prop="paramName" label="参数名" width="120" />
              <el-table-column prop="label" label="标签" width="120" />
              <el-table-column prop="paramType" label="类型" width="100" />
              <el-table-column label="必填" width="80" align="center">
                <template #default="{ row }">
                  <el-tag :type="row.required ? 'danger' : 'info'" size="small">
                    {{ row.required ? '是' : '否' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="defaultValue" label="默认值" min-width="100" />
              <el-table-column label="操作" width="80" align="center">
                <template #default="{ $index }">
                  <el-button type="danger" link size="small" @click="handleRemoveFilter($index)">
                    删除
                  </el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </el-form-item>
        <el-form-item v-if="editingId !== null" label="状态">
          <el-select v-model="formData.status">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
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

    <!-- 添加列弹窗 -->
    <el-dialog v-model="columnDialogVisible" title="添加列" width="480px" destroy-on-close>
      <el-form ref="columnFormRef" :model="columnForm" :rules="columnRules" label-width="90px">
        <el-form-item label="列名" prop="name">
          <el-input v-model="columnForm.name" placeholder="请输入列名（对应 SQL 查询结果的字段名）" />
        </el-form-item>
        <el-form-item label="列标题" prop="title">
          <el-input v-model="columnForm.title" placeholder="请输入列标题（显示在表头）" />
        </el-form-item>
        <el-form-item label="列类型" prop="type">
          <el-select v-model="columnForm.type" style="width: 100%">
            <el-option label="字符串" value="string" />
            <el-option label="数字" value="number" />
            <el-option label="日期" value="date" />
            <el-option label="布尔" value="boolean" />
          </el-select>
        </el-form-item>
        <el-form-item label="列宽度">
          <el-input-number v-model="columnForm.width" :min="50" :max="500" placeholder="可选" />
        </el-form-item>
        <el-form-item label="格式化">
          <el-input v-model="columnForm.format" placeholder="可选，如日期格式 YYYY-MM-DD" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="columnDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleAddColumn">确定</el-button>
      </template>
    </el-dialog>

    <!-- 添加过滤器弹窗 -->
    <el-dialog v-model="filterDialogVisible" title="添加过滤器" width="480px" destroy-on-close>
      <el-form ref="filterFormRef" :model="filterForm" :rules="filterRules" label-width="90px">
        <el-form-item label="参数名" prop="paramName">
          <el-input v-model="filterForm.paramName" placeholder="请输入参数名（对应 SQL 模板中的 #{paramName}）" />
        </el-form-item>
        <el-form-item label="标签" prop="label">
          <el-input v-model="filterForm.label" placeholder="请输入标签（显示在过滤器表单）" />
        </el-form-item>
        <el-form-item label="参数类型" prop="paramType">
          <el-select v-model="filterForm.paramType" style="width: 100%">
            <el-option label="字符串" value="string" />
            <el-option label="数字" value="number" />
            <el-option label="日期" value="date" />
            <el-option label="布尔" value="boolean" />
          </el-select>
        </el-form-item>
        <el-form-item label="是否必填">
          <el-switch v-model="filterForm.required" />
        </el-form-item>
        <el-form-item label="默认值">
          <el-input v-model="filterForm.defaultValue" placeholder="可选" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="filterDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleAddFilter">确定</el-button>
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

.def-list-wrapper {
  width: 100%;
}
</style>
