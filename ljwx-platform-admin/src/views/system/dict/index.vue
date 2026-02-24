<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type {
  SysDictTypeVO,
  SysDictDataVO,
  DictTypeQueryDTO,
  DictTypeCreateDTO,
  DictTypeUpdateDTO,
  PageResult,
} from '@ljwx/shared'
import { getDictList, createDict, updateDict, getDictDataByType } from '@/api/dict'

// ─── 字典类型列表 ─────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<SysDictTypeVO[]>([])
const total = ref(0)

const query = reactive<DictTypeQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  name: undefined,
  type: undefined,
  status: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<SysDictTypeVO> = await getDictList(query)
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
  query.name = undefined
  query.type = undefined
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

// ─── 字典类型弹窗 ─────────────────────────────────────────────
const dialogVisible = ref(false)
const dialogTitle = ref('新增字典类型')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface DictTypeForm {
  name: string
  type: string
  status: number
  remark: string
}

const formData = reactive<DictTypeForm>({
  name: '',
  type: '',
  status: 1,
  remark: '',
})

const rules: FormRules<DictTypeForm> = {
  name: [{ required: true, message: '请输入字典名称', trigger: 'blur' }],
  type: [{ required: true, message: '请输入字典类型', trigger: 'blur' }],
}

function openCreate(): void {
  editingId.value = null
  dialogTitle.value = '新增字典类型'
  formData.name = ''
  formData.type = ''
  formData.status = 1
  formData.remark = ''
  dialogVisible.value = true
}

function openEdit(row: SysDictTypeVO): void {
  editingId.value = row.id
  dialogTitle.value = '编辑字典类型'
  formData.name = row.name
  formData.type = row.type
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
      const createData: DictTypeCreateDTO = {
        name: formData.name,
        type: formData.type,
        remark: formData.remark || undefined,
      }
      await createDict(createData)
      ElMessage.success('创建成功')
    } else {
      const updateData: DictTypeUpdateDTO = {
        name: formData.name,
        type: formData.type,
        status: formData.status,
        remark: formData.remark || undefined,
      }
      await updateDict(editingId.value, updateData)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadData()
  } catch {
    // error handled by interceptor
  }
}

// ─── 字典数据预览 ─────────────────────────────────────────────
const dataDrawerVisible = ref(false)
const dataDrawerTitle = ref('')
const dataLoading = ref(false)
const dictDataList = ref<SysDictDataVO[]>([])

async function viewDictData(row: SysDictTypeVO): Promise<void> {
  dataDrawerTitle.value = `${row.name} — 字典数据`
  dataDrawerVisible.value = true
  dataLoading.value = true
  try {
    dictDataList.value = await getDictDataByType(row.type)
  } finally {
    dataLoading.value = false
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
        <el-form-item label="字典名称">
          <el-input v-model="query.name" placeholder="请输入字典名称" clearable />
        </el-form-item>
        <el-form-item label="字典类型">
          <el-input v-model="query.type" placeholder="请输入字典类型" clearable />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" placeholder="请选择状态" clearable style="width: 120px">
            <el-option label="启用" :value="1" />
            <el-option label="禁用" :value="0" />
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
          <span>字典类型列表</span>
          <el-button type="primary" @click="openCreate">新增字典</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="name" label="字典名称" min-width="160" />
        <el-table-column prop="type" label="字典类型" min-width="160" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
              {{ row.status === 1 ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="160" show-overflow-tooltip />
        <el-table-column prop="createdTime" label="创建时间" width="160" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="openEdit(row)">编辑</el-button>
            <el-button type="info" link size="small" @click="viewDictData(row)">字典数据</el-button>
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
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="480px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="90px">
        <el-form-item label="字典名称" prop="name">
          <el-input v-model="formData.name" placeholder="请输入字典名称" />
        </el-form-item>
        <el-form-item label="字典类型" prop="type">
          <el-input
            v-model="formData.type"
            :disabled="editingId !== null"
            placeholder="请输入字典类型"
          />
        </el-form-item>
        <el-form-item v-if="editingId !== null" label="状态">
          <el-select v-model="formData.status">
            <el-option label="启用" :value="1" />
            <el-option label="禁用" :value="0" />
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

    <!-- 字典数据抽屉 -->
    <el-drawer
      v-model="dataDrawerVisible"
      :title="dataDrawerTitle"
      size="600px"
      destroy-on-close
    >
      <el-table v-loading="dataLoading" :data="dictDataList" border stripe>
        <el-table-column prop="dictLabel" label="标签" min-width="120" />
        <el-table-column prop="dictValue" label="键值" min-width="120" />
        <el-table-column prop="sort" label="排序" width="80" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'" size="small">
              {{ row.status === 1 ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="120" show-overflow-tooltip />
      </el-table>
    </el-drawer>
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
